// Ponte do Screen Time da Apple com o Flutter (canal "baru/tempo_de_tela").
//
// Métodos:
//   estado               -> {suportado, autorizacao, modo, metaMin, apps, categorias, sites, monitorando, atingidosHoje, escudoAoEstourar}
//   pedirAutorizacao     {modo: "individual" | "crianca"} -> estado
//   escolherApps         -> estado (abre o seletor da Apple)
//   definirMeta          {minutos} -> estado (liga o monitoramento diário)
//   pararMonitoramento   -> estado
//   definirEscudo        {ativo} -> estado (pausar apps ao estourar; só o responsável)
import Flutter
import SwiftUI
import UIKit
import FamilyControls
import DeviceActivity
import ManagedSettings

final class TempoDeTelaPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let canal = FlutterMethodChannel(name: "baru/tempo_de_tela", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(TempoDeTelaPlugin(), channel: canal)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard #available(iOS 16.0, *) else {
      result(["suportado": false])
      return
    }
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "estado":
      result(Self.estado())
    case "pedirAutorizacao":
      let modo = args["modo"] as? String ?? "individual"
      Task { @MainActor in
        do {
          try await AuthorizationCenter.shared.requestAuthorization(for: modo == "crianca" ? .child : .individual)
          TelaCompartilhada.modo = modo
          result(Self.estado())
        } catch {
          result(FlutterError(code: "autorizacao", message: Self.mensagem(error), details: nil))
        }
      }
    case "escolherApps":
      Task { @MainActor in self.abreSeletor(result: result) }
    case "definirMeta":
      let minutos = args["minutos"] as? Int ?? 0
      do {
        try Self.agenda(metaMin: minutos)
        result(Self.estado())
      } catch {
        result(FlutterError(code: "monitor", message: Self.mensagem(error), details: nil))
      }
    case "pararMonitoramento":
      DeviceActivityCenter().stopMonitoring([TelaCompartilhada.atividade])
      TelaCompartilhada.tiraEscudo()
      result(Self.estado())
    case "aplicarRegras":
      do {
        try Self.aplicaRegras(
          horarios: args["horarios"] as? [[String: Any]] ?? [],
          pausaAte: (args["pausaAteMs"] as? NSNumber).map { Date(timeIntervalSince1970: $0.doubleValue / 1000) },
          filtro: args["filtro"] as? Bool ?? false
        )
        result(Self.estado())
      } catch {
        result(FlutterError(code: "regras", message: Self.mensagem(error), details: nil))
      }
    case "guardaChave":
      RegrasRemotas.guarda(
        chave: args["chave"] as? String,
        url: args["url"] as? String,
        anon: args["anon"] as? String,
        sandbox: args["sandbox"] as? Bool ?? false
      )
      result(Self.estado())
    case "definirEscudo":
      TelaCompartilhada.escudoAoEstourar = args["ativo"] as? Bool ?? false
      if !TelaCompartilhada.escudoAoEstourar { TelaCompartilhada.tiraEscudo() }
      result(Self.estado())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @available(iOS 16.0, *)
  static func estado() -> [String: Any] {
    let s = TelaCompartilhada.selecao
    let autorizacao: String
    switch AuthorizationCenter.shared.authorizationStatus {
    case .approved: autorizacao = "aprovado"
    case .denied: autorizacao = "negado"
    default: autorizacao = "naoDecidido"
    }
    return [
      "suportado": true,
      "autorizacao": autorizacao,
      "modo": TelaCompartilhada.modo,
      "metaMin": TelaCompartilhada.metaMin,
      "apps": s.applicationTokens.count,
      "categorias": s.categoryTokens.count,
      "sites": s.webDomainTokens.count,
      "monitorando": DeviceActivityCenter().activities.contains(TelaCompartilhada.atividade),
      "atingidosHoje": TelaCompartilhada.atingidosHoje,
      "escudoAoEstourar": TelaCompartilhada.escudoAoEstourar,
      "pausadoAgora": TelaCompartilhada.pausaAtiva() || TelaCompartilhada.horarioAgora(),
    ]
  }

  /// Monitora o dia inteiro, todo dia, com um evento por fração da meta.
  @available(iOS 16.0, *)
  static func agenda(metaMin: Int) throws {
    let centro = DeviceActivityCenter()
    centro.stopMonitoring([TelaCompartilhada.atividade])
    TelaCompartilhada.metaMin = metaMin
    guard metaMin > 0 else { return }
    let s = TelaCompartilhada.selecao
    var eventos: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
    for f in TelaCompartilhada.fracoes {
      let minutos = max(1, Int((Double(metaMin) * f).rounded()))
      eventos[TelaCompartilhada.nomeDoEvento(minutos)] = DeviceActivityEvent(
        applications: s.applicationTokens,
        categories: s.categoryTokens,
        webDomains: s.webDomainTokens,
        threshold: DateComponents(minute: minutos)
      )
    }
    let dia = DeviceActivitySchedule(
      intervalStart: DateComponents(hour: 0, minute: 0),
      intervalEnd: DateComponents(hour: 23, minute: 59),
      repeats: true
    )
    try centro.startMonitoring(TelaCompartilhada.atividade, during: dia, events: eventos)
  }

  /// Horários sem tela, pausa e filtro de sites da família, entregues ao sistema:
  /// valem com o Baru fechado. Um horário = uma atividade diária; a extensão
  /// confere o dia da semana quando ela começa.
  @available(iOS 16.0, *)
  static func aplicaRegras(horarios: [[String: Any]], pausaAte: Date?, filtro: Bool) throws {
    let centro = DeviceActivityCenter()
    let antigas = centro.activities.filter {
      $0.rawValue.hasPrefix(TelaCompartilhada.prefixoSemTela) || $0 == TelaCompartilhada.atividadePausa
    }
    centro.stopMonitoring(antigas)

    TelaCompartilhada.horarios = horarios
    for (i, h) in horarios.prefix(8).enumerated() {
      let (hi, mi) = TelaCompartilhada.minutos(h["inicio"] as? String ?? "")
      let (hf, mf) = TelaCompartilhada.minutos(h["fim"] as? String ?? "")
      let agenda = DeviceActivitySchedule(
        intervalStart: DateComponents(hour: hi, minute: mi),
        intervalEnd: DateComponents(hour: hf, minute: mf),
        repeats: true
      )
      try? centro.startMonitoring(DeviceActivityName(TelaCompartilhada.prefixoSemTela + String(i)), during: agenda)
    }

    TelaCompartilhada.pausaAte = pausaAte
    if let ate = pausaAte, ate > Date() {
      let cal = Calendar(identifier: .gregorian)
      // O sistema exige intervalo de pelo menos 15 minutos.
      let fim = max(ate, Date().addingTimeInterval(15 * 60))
      let campos: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
      let agenda = DeviceActivitySchedule(
        intervalStart: cal.dateComponents(campos, from: Date()),
        intervalEnd: cal.dateComponents(campos, from: fim),
        repeats: false
      )
      try? centro.startMonitoring(TelaCompartilhada.atividadePausa, during: agenda)
    }

    TelaCompartilhada.reavaliaPausa()
    TelaCompartilhada.filtroDeSites(filtro)
  }

  @available(iOS 16.0, *)
  @MainActor
  private func abreSeletor(result: @escaping FlutterResult) {
    guard let raiz = Self.telaDeCima() else {
      result(FlutterError(code: "seletor", message: "Sem tela para abrir o seletor.", details: nil))
      return
    }
    var controle: UIViewController?
    let tela = SeletorDeApps(inicial: TelaCompartilhada.selecao) { escolha in
      if let escolha {
        TelaCompartilhada.selecao = escolha
        if TelaCompartilhada.metaMin > 0 { try? Self.agenda(metaMin: TelaCompartilhada.metaMin) }
      }
      controle?.dismiss(animated: true)
      result(Self.estado())
    }
    let hospede = UIHostingController(rootView: tela)
    controle = hospede
    raiz.present(hospede, animated: true)
  }

  private static func telaDeCima() -> UIViewController? {
    let cena = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    var vc = cena?.windows.first(where: { $0.isKeyWindow })?.rootViewController
    while let p = vc?.presentedViewController { vc = p }
    return vc
  }

  private static func mensagem(_ erro: Error) -> String {
    if #available(iOS 16.0, *), let e = erro as? FamilyControlsError {
      switch e {
      case .restricted: return "O Tempo de Uso está restrito neste aparelho."
      case .unavailable: return "O Tempo de Uso não está disponível neste aparelho."
      case .invalidAccountType: return "Para o modo criança, este iPhone precisa estar com a conta da criança no Compartilhamento Familiar."
      case .invalidArgument: return "Pedido inválido ao Tempo de Uso."
      case .authorizationConflict: return "Outro app de controle parental já está autorizado neste aparelho."
      case .authorizationCanceled: return "O responsável cancelou a autorização."
      case .networkError: return "Sem internet para confirmar com a Apple."
      default: break
      }
    }
    return erro.localizedDescription
  }
}

@available(iOS 16.0, *)
private struct SeletorDeApps: View {
  @State var escolha: FamilyActivitySelection
  let aoTerminar: (FamilyActivitySelection?) -> Void

  init(inicial: FamilyActivitySelection, aoTerminar: @escaping (FamilyActivitySelection?) -> Void) {
    _escolha = State(initialValue: inicial)
    self.aoTerminar = aoTerminar
  }

  var body: some View {
    NavigationView {
      FamilyActivityPicker(selection: $escolha)
        .navigationTitle("Apps que contam")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { aoTerminar(nil) } }
          ToolbarItem(placement: .confirmationAction) { Button("Pronto") { aoTerminar(escolha) } }
        }
    }
  }
}
