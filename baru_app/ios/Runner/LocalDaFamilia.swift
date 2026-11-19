// Localização da família no iPhone (canal "baru/local", o mesmo nome do Android).
//
// Celular da criança, com a localização ligada pelo responsável:
//   - mudanças significativas de lugar (a Apple acorda o app mesmo fechado,
//     a cada ~500 m) mandam a posição;
//   - o push silencioso "regras" traz o pedido "onde está agora?" e o iPhone
//     responde com uma posição nova (RegrasRemotas chama `atendePedido`);
//   - a barra azul de localização fica visível: a criança sempre sabe.
// Quem decide se chegou ou saiu de um lugar é o banco.
//
// Celular do responsável: guarda a chave dele e registra o token de push,
// para receber SOS, chegou e saiu como notificação.
//
// Métodos: estado, pedir {sempre}, agora, configura {ligada, chave, url, anon, sandbox},
//          avisos {json}, abrirAjustes.
import CoreLocation
import Flutter
import UIKit
import UserNotifications

final class LocalDaFamilia: NSObject, CLLocationManagerDelegate {
  static let shared = LocalDaFamilia()

  private let gerente = CLLocationManager()
  private var pedidos: [(CLLocation?) -> Void] = []
  private var aoMudarPermissao: [() -> Void] = []
  private var querSempre = false
  private var d: UserDefaults { UserDefaults(suiteName: "group.tech.lhcx.baru") ?? .standard }

  private override init() {
    super.init()
    gerente.delegate = self
    gerente.desiredAccuracy = kCLLocationAccuracyHundredMeters
  }

  static func register(with messenger: FlutterBinaryMessenger) {
    let canal = FlutterMethodChannel(name: "baru/local", binaryMessenger: messenger)
    canal.setMethodCallHandler { call, result in shared.handle(call, result) }
  }

  // MARK: - estado e permissão

  var estado: String {
    guard CLLocationManager.locationServicesEnabled() else { return "desligada" }
    switch gerente.authorizationStatus {
    case .authorizedAlways: return "sempre"
    case .authorizedWhenInUse: return "quando_usa"
    case .notDetermined: return "nao_pedida"
    default: return "negada"
    }
  }

  private func pedir(sempre: Bool, _ fim: @escaping () -> Void) {
    querSempre = sempre
    switch gerente.authorizationStatus {
    case .notDetermined:
      aoMudarPermissao.append(fim)
      gerente.requestWhenInUseAuthorization()
    case .authorizedWhenInUse where sempre:
      // A Apple mostra o "permitir sempre" uma vez; depois só em Ajustes.
      aoMudarPermissao.append(fim)
      gerente.requestAlwaysAuthorization()
      DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in self?.chamaPermissao() }
    default:
      fim()
    }
  }

  private func chamaPermissao() {
    let lista = aoMudarPermissao
    aoMudarPermissao.removeAll()
    lista.forEach { $0() }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    if querSempre && manager.authorizationStatus == .authorizedWhenInUse && !aoMudarPermissao.isEmpty {
      querSempre = false
      manager.requestAlwaysAuthorization()
      return
    }
    chamaPermissao()
    if d.bool(forKey: "local.ligada") { retoma() }
  }

  // MARK: - posição

  func agora(_ fim: @escaping (CLLocation?) -> Void) {
    let s = gerente.authorizationStatus
    guard s == .authorizedAlways || s == .authorizedWhenInUse else { fim(nil); return }
    if let l = gerente.location, -l.timestamp.timeIntervalSinceNow < 120, l.horizontalAccuracy <= 100 {
      fim(l); return
    }
    pedidos.append(fim)
    if pedidos.count == 1 { gerente.requestLocation() }
    DispatchQueue.main.asyncAfter(deadline: .now() + 12) { [weak self] in self?.entrega(self?.gerente.location) }
  }

  private func entrega(_ l: CLLocation?) {
    let lista = pedidos
    pedidos.removeAll()
    lista.forEach { $0(l) }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let l = locations.last else { return }
    if !pedidos.isEmpty { entrega(l); return }
    // Mudança significativa (app em segundo plano ou fechado).
    if d.bool(forKey: "local.ligada") {
      let ultima = d.double(forKey: "local.ultimaEnviada")
      if Date().timeIntervalSince1970 - ultima > 240 { envia(l, motivo: "periodico") { _ in } }
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    if !pedidos.isEmpty { entrega(nil) }
  }

  private var bateria: Int {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let b = UIDevice.current.batteryLevel
    return b < 0 ? -1 : Int((b * 100).rounded())
  }

  /// Manda a posição para a família com a chave do aparelho (sem login).
  func envia(_ l: CLLocation, motivo: String, _ fim: @escaping (Bool) -> Void) {
    guard let chave = d.string(forKey: "familia.chave"), chave.count == 64,
          let url = d.string(forKey: "familia.url"), let anon = d.string(forKey: "familia.anon"),
          let alvo = URL(string: "\(url)/rest/v1/rpc/baru_familia_posicao") else { fim(false); return }
    var corpo: [String: Any] = [
      "p_chave": chave, "p_lat": l.coordinate.latitude, "p_lng": l.coordinate.longitude,
      "p_precisao": Int(l.horizontalAccuracy.rounded()), "p_motivo": motivo,
    ]
    if bateria >= 0 { corpo["p_bateria"] = bateria }
    var r = URLRequest(url: alvo, timeoutInterval: 20)
    r.httpMethod = "POST"
    r.setValue("application/json", forHTTPHeaderField: "Content-Type")
    r.setValue(anon, forHTTPHeaderField: "apikey")
    r.setValue("Bearer \(anon)", forHTTPHeaderField: "Authorization")
    r.httpBody = try? JSONSerialization.data(withJSONObject: corpo)
    d.set(Date().timeIntervalSince1970, forKey: "local.ultimaEnviada")
    URLSession.shared.dataTask(with: r) { _, resp, _ in
      fim((resp as? HTTPURLResponse)?.statusCode == 200)
    }.resume()
  }

  // MARK: - ligar e desligar (celular da criança)

  /// Chamado ao abrir o app e quando o iOS relança o Baru por uma mudança de lugar.
  func retoma() {
    guard d.bool(forKey: "local.ligada") else { return }
    let s = gerente.authorizationStatus
    guard s == .authorizedAlways || s == .authorizedWhenInUse else { return }
    if s == .authorizedAlways {
      gerente.allowsBackgroundLocationUpdates = true
      gerente.showsBackgroundLocationIndicator = true
    }
    gerente.pausesLocationUpdatesAutomatically = true
    gerente.startMonitoringSignificantLocationChanges()
  }

  func configura(ligada: Bool) {
    d.set(ligada, forKey: "local.ligada")
    if ligada {
      retoma()
    } else {
      gerente.stopMonitoringSignificantLocationChanges()
      gerente.allowsBackgroundLocationUpdates = false
    }
  }

  /// Regras novas chegaram (push silencioso ou busca): liga/desliga e atende o "onde está agora?".
  func aplicaRegras(_ r: [String: Any], _ fim: @escaping () -> Void) {
    let ligada = r["localizacao"] as? Bool ?? false
    if ligada != d.bool(forKey: "local.ligada") { configura(ligada: ligada) }
    guard ligada, let s = r["local_pedido_em"] as? String, let pedido = Self.data(s),
          -pedido.timeIntervalSinceNow < 600,
          pedido.timeIntervalSince1970 > d.double(forKey: "local.pedidoAtendido") else { fim(); return }
    d.set(pedido.timeIntervalSince1970, forKey: "local.pedidoAtendido")
    agora { [weak self] l in
      guard let self, let l else { fim(); return }
      self.envia(l, motivo: "pedido") { _ in fim() }
    }
  }

  static func data(_ s: String) -> Date? {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f.date(from: s) ?? ISO8601DateFormatter().date(from: s)
  }

  // MARK: - celular do responsável

  private func guardaAvisos(_ json: String?) {
    guard let json, let dados = json.data(using: .utf8),
          let o = try? JSONSerialization.jsonObject(with: dados) as? [String: Any],
          let chave = o["chave"] as? String, chave.count == 64 else {
      d.removeObject(forKey: "resp.chave")
      return
    }
    d.set(chave, forKey: "resp.chave")
    d.set(o["idioma"] as? String ?? "pt", forKey: "resp.idioma")
    if let url = o["url"] as? String { d.set(url, forKey: "familia.url") }
    if let anon = o["anon"] as? String { d.set(anon, forKey: "familia.anon") }
    d.set(o["sandbox"] as? Bool ?? false, forKey: "resp.sandbox")
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
      DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
    }
    registraTokenDoResponsavel()
  }

  func guardaToken(_ token: Data) {
    d.set(token.map { String(format: "%02x", $0) }.joined(), forKey: "familia.pushToken")
    registraTokenDoResponsavel()
  }

  private func registraTokenDoResponsavel() {
    guard let chave = d.string(forKey: "resp.chave"), chave.count == 64,
          let token = d.string(forKey: "familia.pushToken"),
          let url = d.string(forKey: "familia.url"), let anon = d.string(forKey: "familia.anon"),
          let alvo = URL(string: "\(url)/rest/v1/rpc/baru_familia_resp_push_token") else { return }
    var r = URLRequest(url: alvo, timeoutInterval: 20)
    r.httpMethod = "POST"
    r.setValue("application/json", forHTTPHeaderField: "Content-Type")
    r.setValue(anon, forHTTPHeaderField: "apikey")
    r.setValue("Bearer \(anon)", forHTTPHeaderField: "Authorization")
    r.httpBody = try? JSONSerialization.data(withJSONObject: [
      "p_chave": chave, "p_token": token, "p_plataforma": "ios",
      "p_ambiente": d.bool(forKey: "resp.sandbox") ? "sandbox" : "producao",
      "p_idioma": d.string(forKey: "resp.idioma") ?? "pt",
    ])
    URLSession.shared.dataTask(with: r).resume()
  }

  // MARK: - canal

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "estado":
      result(estado)
    case "pedir":
      pedir(sempre: args["sempre"] as? Bool ?? false) { [weak self] in result(self?.estado ?? "negada") }
    case "agora":
      agora { [weak self] l in
        guard let l else { result(nil); return }
        var m: [String: Any] = ["lat": l.coordinate.latitude, "lng": l.coordinate.longitude,
                                "precisao": Int(l.horizontalAccuracy.rounded())]
        if let b = self?.bateria, b >= 0 { m["bateria"] = b }
        result(m)
      }
    case "configura":
      if let chave = args["chave"] as? String, chave.count == 64 { d.set(chave, forKey: "familia.chave") }
      if let url = args["url"] as? String { d.set(url, forKey: "familia.url") }
      if let anon = args["anon"] as? String { d.set(anon, forKey: "familia.anon") }
      configura(ligada: args["ligada"] as? Bool ?? false)
      result(true)
    case "avisos":
      guardaAvisos(args["json"] as? String)
      result(true)
    case "abrirAjustes":
      if let u = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(u) }
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
