package com.lhcx.baru_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper

/**
 * O vigia da sessao de foco.
 *
 * **Por que isto existe.** Durante a sessao, sair do Baru para outro app nao
 * fazia absolutamente nada: nenhum aviso, nenhuma chamada de volta. A causa
 * nao estava em lugar nenhum do Dart — com o app em segundo plano o Flutter
 * **nao executa**. Todo o gatilho do companheiro morava em
 * `didChangeAppLifecycleState`, que so dispara quando a pessoa **volta**: o
 * aviso chegava sempre tarde demais para servir de alguma coisa.
 *
 * O ADR-011 tinha descartado servico em primeiro plano por peso. Estava
 * errado — sem ele, a promessa central do produto nao acontece.
 *
 * **O que ele faz.** Enquanto a sessao corre, pergunta a cada
 * [INTERVALO_MS] qual app esta na frente. Se nao for o Baru, o companheiro
 * aparece por cima — uma vez, e so de novo passado o [DESCANSO_MS], porque
 * insistir a cada dois segundos e assedio, nao companhia.
 *
 * **O que ele nao faz.** Nao bloqueia nada, nao fecha nada, nao mede nada
 * alem do pacote da frente, e nao escreve texto: a fala chega pronta e
 * traduzida do Dart, como no [OverlayDoBaru].
 */
class VigiaDaSessao : Service() {

    companion object {
        const val ACAO_COMECA = "com.lhcx.baru_app.VIGIA_COMECA"
        const val ACAO_PARA = "com.lhcx.baru_app.VIGIA_PARA"

        const val EXTRA_FALA = "fala"
        const val EXTRA_PELO = "pelo"
        const val EXTRA_ESPECIE = "especie"
        const val EXTRA_ACAO_FECHAR = "acaoFechar"
        const val EXTRA_ACAO_MAIS = "acaoMais"
        const val EXTRA_NOTIF_TITULO = "notifTitulo"
        const val EXTRA_NOTIF_CORPO = "notifCorpo"

        /** De quanto em quanto se pergunta quem esta na frente. */
        private const val INTERVALO_MS = 2_000L

        /**
         * Silencio entre duas aparicoes.
         *
         * Quem trocou de app de proposito nao precisa ser lembrado a cada
         * dois segundos. Um minuto da tempo de a pessoa notar e voltar por
         * conta propria antes do segundo toque no ombro.
         */
        private const val DESCANSO_MS = 60_000L

        private const val CANAL = "baru_vigia"
        private const val ID_NOTIF = 4711

        /**
         * A janela consultada em `queryEvents`.
         *
         * Precisa ser bem maior que [INTERVALO_MS]: o `UsageStatsManager`
         * entrega eventos com atraso, e uma janela justa devolveria nada em
         * boa parte das rodadas.
         */
        private const val JANELA_MS = 10_000L
    }

    private val laco = Handler(Looper.getMainLooper())
    private var rodando = false
    private var ultimaAparicao = 0L

    private var fala: String? = null
    private var pelo = 0xFFB07A4E.toInt()
    private var especie: String? = null
    private var acaoFechar: String? = null
    private var acaoMais: String? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACAO_PARA -> {
                para()
                return START_NOT_STICKY
            }

            ACAO_COMECA -> {
                fala = intent.getStringExtra(EXTRA_FALA)
                pelo = intent.getIntExtra(EXTRA_PELO, pelo)
                especie = intent.getStringExtra(EXTRA_ESPECIE)
                acaoFechar = intent.getStringExtra(EXTRA_ACAO_FECHAR)
                acaoMais = intent.getStringExtra(EXTRA_ACAO_MAIS)

                startForeground(
                    ID_NOTIF,
                    notificacao(
                        intent.getStringExtra(EXTRA_NOTIF_TITULO).orEmpty(),
                        intent.getStringExtra(EXTRA_NOTIF_CORPO).orEmpty(),
                    ),
                )
                comeca()
            }
        }
        // `START_STICKY` traria o servico de volta sem os extras — sem fala,
        // sem especie, sem cor. Um vigia sem o que dizer nao serve.
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        para()
        super.onDestroy()
    }

    private fun comeca() {
        if (rodando) return
        rodando = true
        // A primeira rodada ja vale: a pessoa pode ter saido no instante em
        // que a sessao comecou.
        laco.post(rodada)
    }

    private fun para() {
        rodando = false
        laco.removeCallbacks(rodada)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private val rodada = object : Runnable {
        override fun run() {
            if (!rodando) return
            try {
                olha()
            } catch (_: Exception) {
                // Sem acesso ao uso, sem servico do sistema, aparelho
                // exotico: nada disso pode derrubar a sessao da pessoa.
            }
            if (rodando) laco.postDelayed(this, INTERVALO_MS)
        }
    }

    private fun olha() {
        val naFrente = pacoteDaFrente() ?: return
        if (naFrente == packageName) return
        // Launcher e telas do sistema nao sao fuga: sao o caminho.
        if (ehDoSistema(naFrente)) return

        val agora = System.currentTimeMillis()
        if (agora - ultimaAparicao < DESCANSO_MS) return
        ultimaAparicao = agora

        if (!OverlayDoBaru.temPermissao(this)) return
        startService(
            Intent(this, OverlayDoBaru::class.java).apply {
                action = OverlayDoBaru.ACAO_MOSTRAR
                putExtra(OverlayDoBaru.EXTRA_FALA, fala)
                putExtra(OverlayDoBaru.EXTRA_PELO, pelo)
                putExtra(OverlayDoBaru.EXTRA_ESPECIE, especie)
                putExtra(OverlayDoBaru.EXTRA_ACAO_FECHAR, acaoFechar)
                putExtra(OverlayDoBaru.EXTRA_ACAO_MAIS, acaoMais)
            },
        )
    }

    /**
     * Quem esta na frente agora.
     *
     * `queryEvents` e nao `queryUsageStats`: o segundo devolve totais do
     * dia, nao quem esta na tela neste instante.
     */
    private fun pacoteDaFrente(): String? {
        val uso = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return null
        val agora = System.currentTimeMillis()
        val eventos = uso.queryEvents(agora - JANELA_MS, agora)
        val e = UsageEvents.Event()
        var ultimo: String? = null
        while (eventos.hasNextEvent()) {
            eventos.getNextEvent(e)
            if (e.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND ||
                e.eventType == UsageEvents.Event.ACTIVITY_RESUMED
            ) {
                ultimo = e.packageName
            }
        }
        return ultimo
    }

    private fun ehDoSistema(pacote: String): Boolean {
        return pacote.startsWith("com.android.systemui") ||
            pacote.startsWith("com.google.android.apps.nexuslauncher") ||
            pacote.startsWith("com.android.launcher") ||
            pacote.endsWith(".launcher") ||
            pacote.contains("inputmethod")
    }

    private fun notificacao(titulo: String, corpo: String): Notification {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(
                    CANAL,
                    "Sessao de foco",
                    // `LOW`: a barra tem de mostrar que a sessao corre, sem
                    // som nem vibracao a cada vez.
                    NotificationManager.IMPORTANCE_LOW,
                ).apply { setShowBadge(false) },
            )
        }
        val abrir = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_IMMUTABLE,
        )
        return Notification.Builder(this, CANAL)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(titulo)
            .setContentText(corpo)
            .setContentIntent(abrir)
            .setOngoing(true)
            .build()
    }
}
