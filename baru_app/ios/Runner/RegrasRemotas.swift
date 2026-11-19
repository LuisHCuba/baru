// Push silencioso da família: o iPhone da criança acorda em segundo plano,
// busca as regras com a chave do aparelho (sem login) e aplica — pausa,
// horários sem tela, filtro de sites e meta —, mesmo com o Baru fechado.
import Foundation
import UIKit

@available(iOS 16.0, *)
enum RegrasRemotas {
  private static var d: UserDefaults { TelaCompartilhada.defaults }

  /// Guardado pelo Dart quando a criança entra na família.
  static func guarda(chave: String?, url: String?, anon: String?, sandbox: Bool) {
    d.set(chave, forKey: "familia.chave")
    d.set(url, forKey: "familia.url")
    d.set(anon, forKey: "familia.anon")
    d.set(sandbox, forKey: "familia.sandbox")
    registraToken()
  }

  static func guardaToken(_ token: Data) {
    d.set(token.map { String(format: "%02x", $0) }.joined(), forKey: "familia.pushToken")
    registraToken()
  }

  private static func chama(_ funcao: String, _ corpo: [String: Any], _ fim: @escaping (Data?) -> Void) {
    guard let url = d.string(forKey: "familia.url"), let anon = d.string(forKey: "familia.anon"),
          let alvo = URL(string: "\(url)/rest/v1/rpc/\(funcao)") else { fim(nil); return }
    var r = URLRequest(url: alvo, timeoutInterval: 20)
    r.httpMethod = "POST"
    r.setValue("application/json", forHTTPHeaderField: "Content-Type")
    r.setValue(anon, forHTTPHeaderField: "apikey")
    r.setValue("Bearer \(anon)", forHTTPHeaderField: "Authorization")
    r.httpBody = try? JSONSerialization.data(withJSONObject: corpo)
    URLSession.shared.dataTask(with: r) { dados, resp, _ in
      fim((resp as? HTTPURLResponse)?.statusCode == 200 ? dados : nil)
    }.resume()
  }

  /// Conta ao banco o token de push deste iPhone (com a chave do aparelho).
  static func registraToken() {
    guard let chave = d.string(forKey: "familia.chave"), chave.count == 64,
          let token = d.string(forKey: "familia.pushToken") else { return }
    chama("baru_familia_push_token", [
      "p_chave": chave, "p_token": token, "p_plataforma": "ios",
      "p_ambiente": d.bool(forKey: "familia.sandbox") ? "sandbox" : "producao",
    ]) { _ in }
  }

  /// Busca as regras e aplica. `fim(true)` se algo mudou.
  static func buscaEAplica(_ fim: @escaping (Bool) -> Void) {
    guard let chave = d.string(forKey: "familia.chave"), chave.count == 64 else { fim(false); return }
    chama("baru_familia_regras_do_aparelho", ["p_chave": chave]) { dados in
      guard let dados, let r = try? JSONSerialization.jsonObject(with: dados) as? [String: Any] else {
        fim(false); return
      }
      let horarios = (r["horarios_sem_tela"] as? [[String: Any]]) ?? []
      var pausa: Date?
      if let s = r["pausa_ate"] as? String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        pausa = f.date(from: s) ?? ISO8601DateFormatter().date(from: s)
      }
      let filtro = r["filtro_sites"] as? Bool ?? false
      let meta = (r["meta_hoje"] as? Int) ?? (r["meta_min"] as? Int) ?? 0
      let escudo = r["pausar_ao_estourar"] as? Bool ?? false
      DispatchQueue.main.async {
        try? TempoDeTelaPlugin.aplicaRegras(horarios: horarios, pausaAte: pausa, filtro: filtro)
        TelaCompartilhada.escudoAoEstourar = escudo
        if !escudo { TelaCompartilhada.tiraEscudo() }
        let s = TelaCompartilhada.selecao
        if meta != TelaCompartilhada.metaMin,
           !(s.applicationTokens.isEmpty && s.categoryTokens.isEmpty && s.webDomainTokens.isEmpty) {
          try? TempoDeTelaPlugin.agenda(metaMin: meta)
        }
        fim(true)
      }
    }
  }
}
