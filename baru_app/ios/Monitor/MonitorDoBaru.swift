// Extensão DeviceActivityMonitor: o iOS acorda este código quando o uso dos
// apps escolhidos passa de cada limiar da meta. Ela não vê quais apps nem
// quanto tempo exato: só "o limiar X foi atingido".
import DeviceActivity
import Foundation
import ManagedSettings
import UserNotifications

@available(iOS 16.0, *)
class MonitorDoBaru: DeviceActivityMonitor {
  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    if activity == TelaCompartilhada.atividade {
      TelaCompartilhada.zeraDia()
      TelaCompartilhada.tiraEscudo()
    }
    // Pausa do responsável ou começo de um horário sem tela: confere o dia e liga.
    if activity == TelaCompartilhada.atividadePausa || activity.rawValue.hasPrefix(TelaCompartilhada.prefixoSemTela) {
      TelaCompartilhada.reavaliaPausa()
    }
  }

  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    if activity == TelaCompartilhada.atividade {
      TelaCompartilhada.tiraEscudo()
    }
    if activity == TelaCompartilhada.atividadePausa || activity.rawValue.hasPrefix(TelaCompartilhada.prefixoSemTela) {
      TelaCompartilhada.reavaliaPausa()
    }
  }

  override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    super.eventDidReachThreshold(event, activity: activity)
    guard let minutos = TelaCompartilhada.minutos(de: event) else { return }
    TelaCompartilhada.registraAtingido(minutos)

    let meta = TelaCompartilhada.metaMin
    guard meta > 0 else { return }
    if minutos >= meta && TelaCompartilhada.escudoAoEstourar {
      TelaCompartilhada.aplicaEscudo()
    }
    avisa(minutos: minutos, meta: meta)
  }

  /// A Nina não pode aparecer por cima de outro app no iPhone; o "oi" vira notificação.
  private func avisa(minutos: Int, meta: Int) {
    let texto: String
    if minutos < meta {
      guard minutos * 4 >= meta * 3 else { return } // só avisa a partir de 75%
      texto = "Falta pouco para a meta de hoje. Que tal uma pausa?"
    } else if minutos == meta {
      texto = "A meta de tela de hoje acabou. Bora fazer outra coisa um pouco?"
    } else {
      texto = "Já passou bastante da meta de hoje. Seu bicho está com saudade de você fora da tela."
    }
    let c = UNMutableNotificationContent()
    c.title = "Baru"
    c.body = texto
    c.sound = .default
    c.threadIdentifier = "baru.tela"
    let pedido = UNNotificationRequest(identifier: "baru.tela.\(minutos)", content: c, trigger: nil)
    UNUserNotificationCenter.current().add(pedido)
  }
}
