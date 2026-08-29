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

    // Um companion so, e publico, porque o `VigiaDaSessao` precisa do nome do
    // extra. O que ninguem de fora usa continua privado.
    companion object {
        private const val CANAL = "baru/overlay"

        /**
         * O canal da barra de notificacoes.
         *
         * Separado de [CANAL] porque tem outro dono: a frente da
         * notificacao, e nao a da sobreposicao. Dois donos no mesmo canal e
         * como se perde um metodo num merge.
         */
        private const val CANAL_DA_BARRA = "baru/barra"

        /**
         * A acao que a pessoa tocou na notificacao do servico.
         *
         * Viaja como extra do `Intent` que abre esta activity, e nao por um
         * `BroadcastReceiver`, porque com o app morto so a abertura garante
         * que a decisao chegue ao Dart — que e quem sabe o que "desistir"
         * custa em folhas, sequencia e historico.
         */
        const val EXTRA_ACAO_DA_BARRA = "baru_acao_da_barra"

        /** Tem de bater com os `activity-alias` do manifesto. */
        private val ESPECIES = listOf(
            "capybara", "otter", "tortoise", "owl",
            "axolotl", "penguin", "cat", "fox", "frenchie",
        )
    }

    private var canalDaBarra: MethodChannel? = null

    /**
     * A acao que chegou antes de o Dart estar de pe.
     *
     * O caso normal do arranque a frio: a activity nasce por causa do toque
     * na notificacao, e o motor Flutter so existe alguns quadros depois. Sem
     * esta gaveta, o toque em "Desistir" com o app fechado sumiria — que era
     * exatamente o defeito.
     */
    private var acaoPendente: String? = null

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

    /**
     * A ponte da barra de notificacoes.
     *
     * Dois sentidos: o Dart grava aqui a contagem que o servico em primeiro
     * plano tem de desenhar, e a activity devolve para o Dart a acao que a
     * pessoa tocou na notificacao.
     */
    private fun ligaABarra(flutterEngine: FlutterEngine) {
        val canal = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CANAL_DA_BARRA,
        )
        canalDaBarra = canal
        canal.setMethodCallHandler { call, result ->
            when (call.method) {
                // A contagem, escrita pelo Dart. O servico le dela; nenhuma
                // palavra e inventada deste lado.
                "contagem" -> {
                    val terminaEm = (call.argument<Number>("terminaEm") ?: 0).toLong()
                    if (terminaEm <= 0L) {
                        ContagemDaBarra.limpa(this)
                    } else {
                        ContagemDaBarra.grava(
                            ctx = this,
                            id = call.argument<Int>("id")
                                ?: ContagemDaBarra.ID_PADRAO,
                            canal = call.argument<String>("canal")
                                ?: ContagemDaBarra.CANAL_PADRAO,
                            terminaEm = terminaEm,
                            titulo = call.argument<String>("titulo").orEmpty(),
                            corpo = call.argument<String>("corpo").orEmpty(),
                            rotuloDesistir =
                                call.argument<String>("rotuloDesistir").orEmpty(),
                            acaoDesistir =
                                call.argument<String>("idDesistir").orEmpty(),
                            rotuloVoltar =
                                call.argument<String>("rotuloVoltar").orEmpty(),
                            acaoVoltar =
                                call.argument<String>("idVoltar").orEmpty(),
                        )
                    }
                    // So avisa quem ja esta de pe: `startService` com o vigia
                    // parado subiria um servico que ninguem pediu.
                    if (VigiaDaSessao.dePe) {
                        startService(
                            Intent(this, VigiaDaSessao::class.java).apply {
                                action = VigiaDaSessao.ACAO_ATUALIZA
                            },
                        )
                    }
                    result.success(null)
                }

                // O Dart **puxa** a acao guardada no arranque.
                //
                // Empurrar aqui nao serviria: o canal e ligado em
                // `configureFlutterEngine`, e o handler do lado Dart so
                // existe depois, no `BaruNotifications.init()`. Um
                // `invokeMethod` no meio disso cai num canal sem ouvinte.
                // Quem chega depois pergunta; quem pergunta recebe.
                "acaoPendente" -> {
                    val acao = acaoPendente
                    acaoPendente = null
                    result.success(acao)
                }

                else -> result.notImplemented()
            }
        }
    }

    /**
     * Empurra ao Dart a acao tocada na notificacao com o app ja de pe.
     *
     * So limpa depois de entregar. Um toque que chegou antes do motor Flutter
     * nao pode virar clique perdido — e esse caso, o do arranque a frio, e
     * atendido pelo `acaoPendente` acima, nao por aqui.
     */
    private fun entregaAcaoPendente() {
        val acao = acaoPendente ?: return
        val canal = canalDaBarra ?: return
        acaoPendente = null
        canal.invokeMethod("acaoDaBarra", acao)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // `setIntent` para que uma consulta posterior ao intent da activity
        // veja o que de fato a trouxe para a frente.
        setIntent(intent)
        guardaAcaoDe(intent)
        entregaAcaoPendente()
    }

    private fun guardaAcaoDe(intent: Intent?) {
        val acao = intent?.getStringExtra(EXTRA_ACAO_DA_BARRA) ?: return
        acaoPendente = acao
        // Consome: uma activity retomada do historico traz o mesmo intent de
        // volta, e a acao seria executada de novo — desistir duas vezes da
        // mesma sessao.
        intent.removeExtra(EXTRA_ACAO_DA_BARRA)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Antes de ligar o canal: a acao pode ter vindo no intent que abriu
        // esta activity, e `ligaABarra` termina entregando o que estiver
        // guardado.
        guardaAcaoDe(intent)
        ligaABarra(flutterEngine)

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
