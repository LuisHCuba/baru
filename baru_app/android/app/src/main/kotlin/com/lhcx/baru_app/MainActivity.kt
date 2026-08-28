package com.lhcx.baru_app

import android.content.Intent
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

                else -> result.notImplemented()
            }
        }
    }
}
