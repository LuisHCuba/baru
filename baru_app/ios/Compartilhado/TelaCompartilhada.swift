// Estado do tempo de tela que o app e as extensões dividem pelo App Group.
//
// Regra da Apple: os dados do Screen Time não saem do aparelho. Aqui só
// circulam a escolha de apps (tokens opacos), a meta e os limiares que o
// sistema avisou que foram atingidos hoje. Nunca nomes de apps nem minutos
// por app.
import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

@available(iOS 16.0, *)
enum TelaCompartilhada {
  static let grupo = "group.tech.lhcx.baru"
  static let atividade = DeviceActivityName("baru.dia")
  static let loja = ManagedSettingsStore(named: ManagedSettingsStore.Name("baru.escudo"))

  private static let chaveSelecao = "tela.selecao"
  private static let chaveMeta = "tela.metaMin"
  private static let chaveModo = "tela.modo"
  private static let chaveEscudo = "tela.escudoAoEstourar"
  private static let chaveDia = "tela.dia"
  private static let chaveAtingidos = "tela.limiaresAtingidos"

  static var defaults: UserDefaults { UserDefaults(suiteName: grupo) ?? .standard }

  /// Frações da meta que geram aviso. 1.0 = meta batida.
  static let fracoes: [Double] = [0.25, 0.5, 0.75, 1.0, 1.5, 2.0]

  static var selecao: FamilyActivitySelection {
    get {
      guard let dados = defaults.data(forKey: chaveSelecao),
            let s = try? JSONDecoder().decode(FamilyActivitySelection.self, from: dados) else {
        return FamilyActivitySelection()
      }
      return s
    }
    set { defaults.set(try? JSONEncoder().encode(newValue), forKey: chaveSelecao) }
  }

  static var metaMin: Int {
    get { defaults.integer(forKey: chaveMeta) }
    set { defaults.set(newValue, forKey: chaveMeta) }
  }

  /// "individual" (a pessoa cuida do próprio tempo) ou "crianca" (o responsável autorizou).
  static var modo: String {
    get { defaults.string(forKey: chaveModo) ?? "individual" }
    set { defaults.set(newValue, forKey: chaveModo) }
  }

  /// Se ligado (só o responsável liga), os apps escolhidos pausam ao estourar a meta.
  static var escudoAoEstourar: Bool {
    get { defaults.bool(forKey: chaveEscudo) }
    set { defaults.set(newValue, forKey: chaveEscudo) }
  }

  static func hoje() -> String {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: Date())
  }

  /// Minutos dos limiares atingidos hoje (zera quando o dia muda).
  static var atingidosHoje: [Int] {
    guard defaults.string(forKey: chaveDia) == hoje() else { return [] }
    return (defaults.array(forKey: chaveAtingidos) as? [Int]) ?? []
  }

  static func registraAtingido(_ minutos: Int) {
    var lista = atingidosHoje
    if !lista.contains(minutos) { lista.append(minutos) }
    defaults.set(hoje(), forKey: chaveDia)
    defaults.set(lista.sorted(), forKey: chaveAtingidos)
  }

  static func zeraDia() {
    defaults.set(hoje(), forKey: chaveDia)
    defaults.set([Int](), forKey: chaveAtingidos)
  }

  static func nomeDoEvento(_ minutos: Int) -> DeviceActivityEvent.Name {
    DeviceActivityEvent.Name("limiar_\(minutos)")
  }

  static func minutos(de evento: DeviceActivityEvent.Name) -> Int? {
    Int(evento.rawValue.replacingOccurrences(of: "limiar_", with: ""))
  }

  static func aplicaEscudo() {
    let s = selecao
    loja.shield.applications = s.applicationTokens.isEmpty ? nil : s.applicationTokens
    loja.shield.applicationCategories = s.categoryTokens.isEmpty ? nil : .specific(s.categoryTokens)
    loja.shield.webDomains = s.webDomainTokens.isEmpty ? nil : s.webDomainTokens
  }

  static func tiraEscudo() {
    loja.clearAllSettings()
  }

  // ------------------------------------------------ pausa e horários sem tela (regras da família)

  /// Loja separada da do escudo da meta: tirar a pausa não tira o escudo da meta.
  static let lojaPausa = ManagedSettingsStore(named: ManagedSettingsStore.Name("baru.pausa"))
  static let lojaFiltro = ManagedSettingsStore(named: ManagedSettingsStore.Name("baru.filtro"))
  static let prefixoSemTela = "baru.semtela."
  static let atividadePausa = DeviceActivityName("baru.pausa")
  private static let chaveHorarios = "tela.horarios"
  private static let chavePausaAte = "tela.pausaAte"

  /// Horários sem tela: [{"dias":[1..7 ISO],"inicio":"21:00","fim":"07:00"}].
  static var horarios: [[String: Any]] {
    get {
      guard let d = defaults.data(forKey: chaveHorarios),
            let a = try? JSONSerialization.jsonObject(with: d) as? [[String: Any]] else { return [] }
      return a
    }
    set { defaults.set(try? JSONSerialization.data(withJSONObject: newValue), forKey: chaveHorarios) }
  }

  static var pausaAte: Date? {
    get { defaults.object(forKey: chavePausaAte) as? Date }
    set { defaults.set(newValue, forKey: chavePausaAte) }
  }

  static func pausaAtiva(_ agora: Date = Date()) -> Bool {
    guard let ate = pausaAte else { return false }
    return agora < ate
  }

  /// A tela toda (todas as categorias de app e de site), não só os apps escolhidos.
  static func pausaTotal(_ ativo: Bool) {
    if ativo {
      lojaPausa.shield.applicationCategories = .all()
      lojaPausa.shield.webDomainCategories = .all()
    } else {
      lojaPausa.clearAllSettings()
    }
  }

  // ------------------------------------------------ sessão de foco (no lugar da sobreposição do Android)

  /// Durante o foco, os apps escolhidos mostram a tela do Baru. Loja própria:
  /// acabar o foco não tira o escudo da meta nem a pausa da família.
  static let lojaFoco = ManagedSettingsStore(named: ManagedSettingsStore.Name("baru.foco"))
  static let atividadeFoco = DeviceActivityName("baru.foco")
  private static let chaveFocoAte = "foco.ate"

  static var focoAte: Date? {
    get { defaults.object(forKey: chaveFocoAte) as? Date }
    set { defaults.set(newValue, forKey: chaveFocoAte) }
  }

  static func focoAtivo(_ agora: Date = Date()) -> Bool {
    guard let ate = focoAte else { return false }
    return agora < ate
  }

  static func aplicaFoco() {
    let s = selecao
    lojaFoco.shield.applications = s.applicationTokens.isEmpty ? nil : s.applicationTokens
    lojaFoco.shield.applicationCategories = s.categoryTokens.isEmpty ? nil : .specific(s.categoryTokens)
    lojaFoco.shield.webDomains = s.webDomainTokens.isEmpty ? nil : s.webDomainTokens
  }

  static func tiraFoco() {
    focoAte = nil
    lojaFoco.clearAllSettings()
  }

  static func filtroDeSites(_ ativo: Bool) {
    lojaFiltro.webContent.blockedByFilter = ativo ? .auto() : nil
  }

  /// Dia ISO de hoje (1 = segunda … 7 = domingo).
  static func diaIso(_ data: Date = Date()) -> Int {
    let w = Calendar(identifier: .gregorian).component(.weekday, from: data) // 1 = domingo
    return w == 1 ? 7 : w - 1
  }

  static func minutos(_ hhmm: String) -> (Int, Int) {
    let p = hhmm.split(separator: ":").compactMap { Int($0) }
    return (p.first ?? 0, p.count > 1 ? p[1] : 0)
  }

  /// Algum horário sem tela vale agora? (Faixa que vira a meia-noite conta o dia em que começou.)
  static func horarioAgora(_ agora: Date = Date()) -> Bool {
    let cal = Calendar(identifier: .gregorian)
    let m = cal.component(.hour, from: agora) * 60 + cal.component(.minute, from: agora)
    let hoje = diaIso(agora)
    let ontem = hoje == 1 ? 7 : hoje - 1
    for h in horarios {
      let dias = (h["dias"] as? [Int]) ?? []
      let (hi, mi) = minutos(h["inicio"] as? String ?? "")
      let (hf, mf) = minutos(h["fim"] as? String ?? "")
      let ini = hi * 60 + mi, fim = hf * 60 + mf
      if ini <= fim {
        if dias.contains(hoje) && m >= ini && m < fim { return true }
      } else if (m >= ini && dias.contains(hoje)) || (m < fim && dias.contains(ontem)) {
        return true
      }
    }
    return false
  }

  /// Liga ou desliga a pausa total conforme a pausa e os horários de agora.
  static func reavaliaPausa() {
    pausaTotal(pausaAtiva() || horarioAgora())
  }
}
