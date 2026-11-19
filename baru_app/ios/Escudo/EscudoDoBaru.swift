// Tela de pausa do iPhone com o visual do Baru (no lugar da tela cinza da
// Apple), quando a meta estoura, numa pausa do responsável ou num horário
// sem tela.
import ManagedSettings
import ManagedSettingsUI
import UIKit

final class EscudoDoBaru: ShieldConfigurationDataSource {
  private func textos() -> (titulo: String, corpo: String, botao: String) {
    switch Locale.current.language.languageCode?.identifier ?? "pt" {
    case "en": return ("Time for a break", "Your screen time is paused for now. How about doing something else for a bit?", "Close")
    case "es": return ("Hora de una pausa", "Tu tiempo de pantalla está en pausa. ¿Qué tal hacer otra cosa un rato?", "Cerrar")
    case "zh": return ("休息一下吧", "屏幕时间暂停中。去做点别的事吧？", "关闭")
    default: return ("Hora de uma pausa", "A tela está em pausa agora. Que tal fazer outra coisa um pouco?", "Fechar")
    }
  }

  private func escudo() -> ShieldConfiguration {
    let t = textos()
    let creme = UIColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1)
    let tinta = UIColor(red: 0.24, green: 0.20, blue: 0.16, alpha: 1)
    let folha = UIColor(red: 0.26, green: 0.51, blue: 0.19, alpha: 1)
    return ShieldConfiguration(
      backgroundBlurStyle: .systemUltraThinMaterialLight,
      backgroundColor: creme,
      icon: UIImage(named: "bicho", in: Bundle(for: EscudoDoBaru.self), with: nil),
      title: .init(text: t.titulo, color: tinta),
      subtitle: .init(text: t.corpo, color: tinta.withAlphaComponent(0.8)),
      primaryButtonLabel: .init(text: t.botao, color: .white),
      primaryButtonBackgroundColor: folha
    )
  }

  override func configuration(shielding application: Application) -> ShieldConfiguration { escudo() }
  override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration { escudo() }
  override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration { escudo() }
  override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration { escudo() }
}
