package com.lhcx.baru_app

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * A ponte do overlay.
 *
 * O Dart decide **quando** e **o que** falar; o Android só sabe desenhar. É
 * por isso que nenhum texto de produto mora do lado nativo: a fala chega
 * pronta e traduzida.
 */
// `FlutterFragmentActivity`, nao `FlutterActivity`: o `local_auth` mostra o
// dialogo de biometria com o `BiometricPrompt` do AndroidX, que precisa de
// um `FragmentActivity` para se ancorar. Com a activity comum o dialogo nao
// abre — e o erro chega no Dart como "no_fragment_activity".
class MainActivity : FlutterFragmentActivity() {

    private companion object {
        const val CANAL = "baru/overlay"

        /** Tem de bater com os `activity-alias` do manifesto. */
        val ESPECIES = listOf(
            "capybara", "otter", "tortoise", "owl",
            "axolotl", "penguin", "cat", "fox", "frenchie",
        )
    }

    /**
     * Liga o alias da especie e desliga os outros.
     *
     * `DONT_KILL_APP` porque sem ele o Android encerra o processo no meio
     * da troca — a pessoa esta escolhendo o bicho e o app fecha na cara
     * dela.
     */
    private fun trocaIcone(especie: String): Boolean {
        val nome = ESPECIES.firstOrNull { it.equals(especie, true) }
            ?: return false
        val pm = packageManager
        val ligar = ComponentName(this, "$packageName.Icone${nome.replaceFirstChar { it.uppercase() }}")

        pm.setComponentEnabledSetting(
            ligar,
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )
        for (outra in ESPECIES) {
            if (outra == nome) continue
            pm.setComponentEnabledSetting(
                ComponentName(this, "$packageName.Icone${outra.replaceFirstChar { it.uppercase() }}"),
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
        return true
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CANAL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "temPermissao" ->
                    result.success(OverlayDoBaru.temPermissao(this))

                "pedePermissao" -> {
                    // Não dá para conceder por código: o Android exige que o
                    // usuário ligue na tela do sistema. Levamos ele até lá.
                    startActivity(OverlayDoBaru.intentDePermissao(this))
                    result.success(null)
                }

                "mostra" -> {
                    if (!OverlayDoBaru.temPermissao(this)) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    startService(
                        Intent(this, OverlayDoBaru::class.java).apply {
                            action = OverlayDoBaru.ACAO_MOSTRAR
                            putExtra(
                                OverlayDoBaru.EXTRA_FALA,
                                call.argument<String>("fala"),
                            )
                            putExtra(
                                OverlayDoBaru.EXTRA_PELO,
                                call.argument<Int>("pelo")
                                    ?: 0xFFB07A4E.toInt(),
                            )
                            putExtra(
                                OverlayDoBaru.EXTRA_ESPECIE,
                                call.argument<String>("especie"),
                            )
                            putExtra(
                                OverlayDoBaru.EXTRA_ACAO_FECHAR,
                                call.argument<String>("acaoFechar"),
                            )
                            putExtra(
                                OverlayDoBaru.EXTRA_ACAO_MAIS,
                                call.argument<String>("acaoMais"),
                            )
                        },
                    )
                    result.success(true)
                }

                "esconde" -> {
                    startService(
                        Intent(this, OverlayDoBaru::class.java).apply {
                            action = OverlayDoBaru.ACAO_ESCONDER
                        },
                    )
                    result.success(null)
                }

                // O vigia da sessao. Comeca quando o foco comeca, para
                // quando ele acaba, e e a unica coisa do Baru que roda com
                // o app fechado.
                "vigiaComeca" -> {
                    ContextCompat.startForegroundService(
                        this,
                        Intent(this, VigiaDaSessao::class.java).apply {
                            action = VigiaDaSessao.ACAO_COMECA
                            putExtra(
                                VigiaDaSessao.EXTRA_FALA,
                                call.argument<String>("fala"),
                            )
                            putExtra(
                                VigiaDaSessao.EXTRA_PELO,
                                call.argument<Int>("pelo")
                                    ?: 0xFFB07A4E.toInt(),
                            )
                            putExtra(
                                VigiaDaSessao.EXTRA_ESPECIE,
                                call.argument<String>("especie"),
                            )
                            putExtra(
                                VigiaDaSessao.EXTRA_ACAO_FECHAR,
                                call.argument<String>("acaoFechar"),
                            )
                            putExtra(
                                VigiaDaSessao.EXTRA_ACAO_MAIS,
                                call.argument<String>("acaoMais"),
                            )
                            putExtra(
                                VigiaDaSessao.EXTRA_NOTIF_TITULO,
                                call.argument<String>("notifTitulo"),
                            )
                            putExtra(
                                VigiaDaSessao.EXTRA_NOTIF_CORPO,
                                call.argument<String>("notifCorpo"),
                            )
                        },
                    )
                    result.success(true)
                }

                "vigiaPara" -> {
                    startService(
                        Intent(this, VigiaDaSessao::class.java).apply {
                            action = VigiaDaSessao.ACAO_PARA
                        },
                    )
                    result.success(null)
                }

                // O icone da gaveta passa a ser o bicho da pessoa.
                //
                // O Android nao deixa trocar o icone de um app: o que se
                // troca e qual componente responde por LAUNCHER. Por isso os
                // `activity-alias`, um por especie, e por isso o novo e
                // ligado **antes** de o antigo ser desligado — na ordem
                // inversa o app some da gaveta no intervalo.
                "trocaIcone" -> {
                    val alvo = call.argument<String>("especie").orEmpty()
                    result.success(trocaIcone(alvo))
                }

                else -> result.notImplemented()
            }
        }
    }
}
