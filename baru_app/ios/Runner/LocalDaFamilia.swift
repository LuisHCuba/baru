// Localização da família no iPhone (canal "baru/local", o mesmo nome do Android).
//
// Celular da criança, com a localização ligada pelo responsável:
//   - mudanças significativas de lugar (a Apple acorda o app mesmo fechado,
//     a cada ~500 m) mandam a posição;
//   - uma cerca de ~200 m em volta da última posição enviada: ao sair dela,
//     o iPhone acorda o Baru e manda a posição nova (pega deslocamentos
//     curtos, que a mudança significativa ignora);
//   - visitas (chegou e saiu de um lugar onde a criança parou) também mandam;
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
  private static let cerca = "baru.familia.cerca"
  private static let raioDaCerca: CLLocationDistance = 200

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
    contaEstado()
  }

  /// Conta ao servidor a permissão atual (o responsável vê o motivo quando
  /// não há posição). Só no celular da criança, que tem a chave do aparelho.
  func contaEstado() {
    guard let chave = d.string(forKey: "familia.chave"), chave.count == 64,
          let url = d.string(forKey: "familia.url"), let anon = d.string(forKey: "familia.anon"),
          let alvo = URL(string: "\(url)/rest/v1/rpc/baru_familia_aparelho_estado") else { return }
    var r = URLRequest(url: alvo, timeoutInterval: 20)
    r.httpMethod = "POST"
    r.setValue("application/json", forHTTPHeaderField: "Content-Type")
    r.setValue(anon, forHTTPHeaderField: "apikey")
    r.setValue("Bearer \(anon)", forHTTPHeaderField: "Authorization")
    r.httpBody = try? JSONSerialization.data(withJSONObject: ["p_chave": chave, "p_local": estado])
    let tarefa = tarefaDeFundo("estado")
    URLSession.shared.dataTask(with: r) { _, _, _ in tarefa() }.resume()
  }

  /// Pede ao iOS alguns segundos a mais com o app em segundo plano, para a
  /// posição chegar ao servidor antes de o sistema suspender o Baru.
  private func tarefaDeFundo(_ nome: String) -> () -> Void {
    var id = UIBackgroundTaskIdentifier.invalid
    id = UIApplication.shared.beginBackgroundTask(withName: "baru.local.\(nome)") {
      UIApplication.shared.endBackgroundTask(id)
      id = .invalid
    }
    return {
      DispatchQueue.main.async {
        guard id != .invalid else { return }
        UIApplication.shared.endBackgroundTask(id)
        id = .invalid
      }
    }
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
    // Mudança significativa ou saída da cerca (app em segundo plano ou fechado).
    if d.bool(forKey: "local.ligada") {
      let ultima = d.double(forKey: "local.ultimaEnviada")
      if Date().timeIntervalSince1970 - ultima > 120 { envia(l, motivo: "periodico") { _ in } }
    }
  }

  /// Saiu da cerca em volta da última posição: pede uma posição nova.
  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    guard region.identifier == Self.cerca, d.bool(forKey: "local.ligada") else { return }
    let fim = tarefaDeFundo("cerca")
    agora { [weak self] l in
      guard let self, let l else { fim(); return }
      self.envia(l, motivo: "periodico") { _ in fim() }
    }
  }

  /// Chegou ou saiu de um lugar onde ficou parada (visita do iOS).
  func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
    guard d.bool(forKey: "local.ligada"), visit.horizontalAccuracy >= 0 else { return }
    let l = CLLocation(coordinate: visit.coordinate, altitude: 0,
                       horizontalAccuracy: visit.horizontalAccuracy, verticalAccuracy: -1, timestamp: Date())
    let fim = tarefaDeFundo("visita")
    envia(l, motivo: "lugar") { _ in fim() }
  }

  /// Uma cerca nova em volta de onde a criança está.
  private func moveCerca(para l: CLLocation) {
    guard gerente.authorizationStatus == .authorizedAlways,
          CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { return }
    gerente.monitoredRegions.filter { $0.identifier == Self.cerca }.forEach { gerente.stopMonitoring(for: $0) }
    let r = CLCircularRegion(center: l.coordinate, radius: Self.raioDaCerca, identifier: Self.cerca)
    r.notifyOnExit = true
    r.notifyOnEntry = false
    gerente.startMonitoring(for: r)
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
    if l.horizontalAccuracy >= 0 && l.horizontalAccuracy <= 500 { moveCerca(para: l) }
    let tarefa = tarefaDeFundo("envia")
    URLSession.shared.dataTask(with: r) { _, resp, _ in
      fim((resp as? HTTPURLResponse)?.statusCode == 200)
      tarefa()
    }.resume()
  }

  // MARK: - ligar e desligar (celular da criança)

  /// Chamado ao abrir o app e quando o iOS relança o Baru por uma mudança de lugar.
  func retoma() {
    guard d.bool(forKey: "local.ligada") else { return }
    let s = gerente.authorizationStatus
    guard s == .authorizedAlways || s == .authorizedWhenInUse else { return }
    // Sem rastreio contínuo (diretriz 2.5.4 da Apple): só mudança
    // significativa, visitas e a cerca, que acordam o app sem o modo
    // "location" em segundo plano.
    gerente.pausesLocationUpdatesAutomatically = true
    gerente.startMonitoringSignificantLocationChanges()
    if s == .authorizedAlways {
      gerente.startMonitoringVisits()
      if let l = gerente.location { moveCerca(para: l) }
    }
  }

  func configura(ligada: Bool) {
    d.set(ligada, forKey: "local.ligada")
    if ligada {
      retoma()
    } else {
      gerente.stopMonitoringSignificantLocationChanges()
      gerente.stopMonitoringVisits()
      gerente.monitoredRegions.filter { $0.identifier == Self.cerca }.forEach { gerente.stopMonitoring(for: $0) }
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
    let tarefa = tarefaDeFundo("pedido")
    agora { [weak self] l in
      guard let self, let l else { fim(); tarefa(); return }
      self.envia(l, motivo: "pedido") { _ in fim(); tarefa() }
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
      contaEstado()
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
