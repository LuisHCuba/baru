// Tela de pausa do iPhone com o visual do Baru (no lugar da tela cinza da
// Apple), quando a meta estoura, numa pausa do responsável ou num horário
// sem tela.
import ManagedSettings
import ManagedSettingsUI
import UIKit

final class EscudoDoBaru: ShieldConfigurationDataSource {
  private func textos() -> (titulo: String, corpo: String, botao: String) {
    switch Locale.current.language.languageCode?.identifier ?? "pt" {
    // Um texto só serve à sessão de foco, à pausa da família e à meta estourada.
    case "en": return ("Not now", "This app is paused for now. Your companion is waiting for you away from the screen.", "Close")
    case "es": return ("Ahora no", "Esta app está en pausa ahora. Tu compañero te espera lejos de la pantalla.", "Cerrar")
    case "zh": return ("现在不行", "这个应用暂时暂停了。你的小伙伴在屏幕外等你。", "关闭")
    default: return ("Agora não", "Este app está pausado agora. Seu bicho te espera longe da tela.", "Fechar")
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
