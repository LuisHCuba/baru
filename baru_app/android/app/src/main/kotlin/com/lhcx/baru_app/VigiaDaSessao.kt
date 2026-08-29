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
import android.content.SharedPreferences
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import org.json.JSONObject

/**
 * A contagem que a barra de notificacoes mostra, escrita pelo Dart.
 *
 * **Por que ela precisa morar fora do `Intent`.** O servico e levantado por
 * `vigiaComeca`, que nao sabe nada de prazo; quem sabe o instante em que a
 * sessao (ou o descanso) acaba e o `BaruNotifications`, do lado Dart, e ele
 * chega por outro caminho — o canal `baru/barra`. Os dois se encontram
 * aqui, e nao num extra, porque a ordem entre eles nao e garantida: o
 * servico pode subir antes de o prazo chegar, ou depois.
 *
 * **Por que em disco e nao em memoria.** Se o processo do app morrer no meio
 * de uma sessao, o servico sobe de novo sem o Dart junto — e e exatamente
 * essa a hora em que a contagem mais importa. Em memoria ela se perderia
 * justamente no caso que ela existe para cobrir.
 *
 * **Nenhuma palavra nasce aqui.** Titulo, corpo e rotulos chegam prontos e
 * traduzidos, como as falas do [OverlayDoBaru]. Este objeto so guarda e
 * devolve.
 */
object ContagemDaBarra {

    private const val ARQUIVO = "baru_barra"

    private const val K_ID = "id"
    private const val K_CANAL = "canal"
    private const val K_TERMINA = "terminaEm"
    private const val K_TITULO = "titulo"
    private const val K_CORPO = "corpo"
    private const val K_ROTULO_DESISTIR = "rotuloDesistir"
    private const val K_ACAO_DESISTIR = "idDesistir"
    private const val K_ROTULO_VOLTAR = "rotuloVoltar"
    private const val K_ACAO_VOLTAR = "idVoltar"

    /**
     * O id e o canal de reserva.
     *
     * Tem de bater com `BaruNotifications.sessaoId` e
     * `BaruNotifications.canalSessao`. **E o casamento desses dois numeros
     * que faz a notificacao ser uma so**: ids diferentes nao se
     * sobrescrevem, e era assim que a sessao aparecia duas vezes na barra.
     * Travado por teste (`test/uma_contagem_test.dart`), que le este arquivo.
     */
    const val ID_PADRAO = 1004
    const val CANAL_PADRAO = "baru_sessao"

    data class Contagem(
        val id: Int,
        val canal: String,
        val terminaEm: Long,
        val titulo: String,
        val corpo: String,
        val rotuloDesistir: String,
        val acaoDesistir: String,
        val rotuloVoltar: String,
        val acaoVoltar: String,
    ) {
        /** Prazo no passado nao e contagem: e um zero parado na barra. */
        fun viva(agora: Long): Boolean = terminaEm > agora
    }

    private fun prefs(ctx: Context): SharedPreferences =
        ctx.getSharedPreferences(ARQUIVO, Context.MODE_PRIVATE)

    fun grava(
        ctx: Context,
        id: Int,
        canal: String,
        terminaEm: Long,
        titulo: String,
        corpo: String,
        rotuloDesistir: String,
        acaoDesistir: String,
        rotuloVoltar: String,
        acaoVoltar: String,
    ) {
        prefs(ctx).edit()
            .putInt(K_ID, id)
            .putString(K_CANAL, canal)
            .putLong(K_TERMINA, terminaEm)
            .putString(K_TITULO, titulo)
            .putString(K_CORPO, corpo)
            .putString(K_ROTULO_DESISTIR, rotuloDesistir)
            .putString(K_ACAO_DESISTIR, acaoDesistir)
            .putString(K_ROTULO_VOLTAR, rotuloVoltar)
            .putString(K_ACAO_VOLTAR, acaoVoltar)
            .apply()
    }

    /** O Dart avisou que nao ha mais o que contar. */
    fun limpa(ctx: Context) {
        prefs(ctx).edit().putLong(K_TERMINA, 0L).apply()
    }

    fun le(ctx: Context): Contagem {
        val p = prefs(ctx)
        return Contagem(
            id = p.getInt(K_ID, ID_PADRAO),
            canal = p.getString(K_CANAL, CANAL_PADRAO) ?: CANAL_PADRAO,
            terminaEm = p.getLong(K_TERMINA, 0L),
            titulo = p.getString(K_TITULO, "").orEmpty(),
            corpo = p.getString(K_CORPO, "").orEmpty(),
            rotuloDesistir = p.getString(K_ROTULO_DESISTIR, "").orEmpty(),
            acaoDesistir = p.getString(K_ACAO_DESISTIR, "").orEmpty(),
            rotuloVoltar = p.getString(K_ROTULO_VOLTAR, "").orEmpty(),
            acaoVoltar = p.getString(K_ACAO_VOLTAR, "").orEmpty(),
        )
    }
}

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
 * **A fala varia com o app.** "O YouTube de novo?" nao e a mesma frase que
 * "o TikTok de novo?", e so aqui se sabe qual app esta na frente no instante
 * da aparicao. Ver [falaPara].
 *
 * **O que ele nao faz.** Nao bloqueia nada, nao fecha nada, nao mede nada
 * alem do pacote da frente, e **nao escreve texto**: as falas chegam prontas
 * e traduzidas do Dart, como no [OverlayDoBaru]. Escolher entre elas nao e
 * escrever.
 */
class VigiaDaSessao : Service() {

    companion object {
        const val ACAO_COMECA = "com.lhcx.baru_app.VIGIA_COMECA"
        const val ACAO_PARA = "com.lhcx.baru_app.VIGIA_PARA"

        /**
         * Redesenha a notificacao com a contagem que o Dart acabou de gravar.
         *
         * Nao levanta o servico: quem nao esta de pe nao tem notificacao para
         * atualizar, e subir um servico em primeiro plano so para desenhar
         * numero seria peso sem promessa por tras.
         */
        const val ACAO_ATUALIZA = "com.lhcx.baru_app.VIGIA_ATUALIZA"

        /** O servico esta de pe neste processo. */
        @JvmStatic
        var dePe = false
            private set

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

        /**
         * Codigos de requisicao dos tres `PendingIntent` da notificacao.
         *
         * **Precisam ser diferentes.** Com `FLAG_IMMUTABLE` e o mesmo codigo,
         * o Android devolve o **mesmo** `PendingIntent` para os tres e os
         * extras do primeiro valem para todos: "Desistir" abriria o app sem
         * desistir de nada.
         */
        private const val PEDIDO_ABRIR = 0
        private const val PEDIDO_DESISTIR = 1
        private const val PEDIDO_VOLTAR = 2

        /**
         * A chave da fala padrao dentro do dicionario que vem do Dart.
         *
         * Um sublinhado porque nenhum pacote Android se chama assim: nao ha
         * como um app real colidir com ela.
         */
        private const val CHAVE_PADRAO = "_"

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

    /**
     * O que a notificacao diz quando nao ha contagem gravada.
     *
     * Acontece na janela entre `vigiaComeca` e a primeira gravacao do Dart,
     * e quando a permissao de notificacao esta negada — ai `mostraSessao`
     * nem chega a publicar, mas o servico continua tendo de ter notificacao,
     * porque o Android obriga.
     */
    private var tituloDeReserva = ""
    private var corpoDeReserva = ""

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACAO_PARA -> {
                para()
                return START_NOT_STICKY
            }

            ACAO_ATUALIZA -> {
                // So redesenha. Nao chama `startForeground` sozinho: um
                // servico que ninguem pediu nao pode nascer de uma
                // atualizacao de texto.
                //
                // O `stopSelf` fecha o unico buraco: se o sistema tiver
                // matado o servico sem passar por `onDestroy`, [dePe] fica
                // desatualizado e este `startService` cria um servico que
                // nao vira primeiro plano e nunca mais para.
                if (dePe) desenha() else stopSelf()
            }

            ACAO_COMECA -> {
                fala = intent.getStringExtra(EXTRA_FALA)
                pelo = intent.getIntExtra(EXTRA_PELO, pelo)
                especie = intent.getStringExtra(EXTRA_ESPECIE)
                acaoFechar = intent.getStringExtra(EXTRA_ACAO_FECHAR)
                acaoMais = intent.getStringExtra(EXTRA_ACAO_MAIS)
                tituloDeReserva = intent.getStringExtra(EXTRA_NOTIF_TITULO).orEmpty()
                corpoDeReserva = intent.getStringExtra(EXTRA_NOTIF_CORPO).orEmpty()

                dePe = true
                desenha()
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

    /**
     * Poe (ou repoe) a notificacao do servico.
     *
     * `startForeground` de novo com o mesmo id nao cria uma segunda
     * notificacao: **atualiza** a que ja esta la. E o caminho documentado
     * para mexer na notificacao de um servico em primeiro plano, e e o que
     * faz a contagem aparecer quando o Dart grava o prazo depois de o
     * servico ja ter subido.
     */
    private fun desenha() {
        val contagem = ContagemDaBarra.le(this)
        startForeground(contagem.id, notificacao(contagem))
    }

    private fun comeca() {
        if (rodando) return
        rodando = true
        // A primeira rodada ja vale: a pessoa pode ter saido no instante em
        // que a sessao comecou.
        laco.post(rodada)
    }

    /**
     * Desliga o vigia — e decide o que fazer com a notificacao.
     *
     * **`REMOVE` nem sempre.** O vigia e desligado tambem quando a *missao do
     * descanso* acaba, e nada impede que uma sessao de foco esteja correndo
     * ao mesmo tempo. Como agora a notificacao do servico e a mesma da
     * contagem, um `REMOVE` cego apagaria da barra o cronometro de uma sessao
     * que continua correndo — o timer "sumindo" sozinho, que e a queixa que
     * este trabalho inteiro existe para resolver.
     *
     * `DETACH` desfaz o vinculo e **deixa a notificacao**: ela passa a ser
     * uma notificacao comum, do dono que a escreveu (o Dart), que a cancela
     * no fim da sessao. Sem contagem gravada nao ha o que preservar, e ai
     * `REMOVE` — nada de notificacao presa depois que a sessao acabou.
     */
    private fun para() {
        rodando = false
        dePe = false
        laco.removeCallbacks(rodada)
        val aindaConta = ContagemDaBarra.le(this).viva(System.currentTimeMillis())
        stopForeground(if (aindaConta) STOP_FOREGROUND_DETACH else STOP_FOREGROUND_REMOVE)
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
                putExtra(OverlayDoBaru.EXTRA_FALA, falaPara(naFrente))
                putExtra(OverlayDoBaru.EXTRA_PELO, pelo)
                putExtra(OverlayDoBaru.EXTRA_ESPECIE, especie)
                putExtra(OverlayDoBaru.EXTRA_ACAO_FECHAR, acaoFechar)
                putExtra(OverlayDoBaru.EXTRA_ACAO_MAIS, acaoMais)
            },
        )
    }

    /**
     * A fala para o app que esta na frente.
     *
     * **Nenhuma frase nasce aqui.** O Dart manda um dicionario pronto,
     * traduzido no idioma da pessoa, e este metodo so escolhe a linha. Era
     * essa a regra que estava sendo cumprida por acidente — antes so havia
     * uma fala, entao nao havia escolha a fazer.
     *
     * O dicionario chega dentro do proprio [EXTRA_FALA] porque o caminho
     * ate aqui passa pelo `MainActivity`, que copia extras nomeados um a um:
     * um extra novo seria descartado em silencio. Formato: JSON de um nivel,
     * `{"pacote": "fala"}`, com a fala padrao em `_`.
     *
     * Texto que nao e JSON continua valendo como fala unica — e o que
     * acontece quando ninguem passou o mapa, e nao pode virar tela em
     * branco.
     */
    private fun falaPara(pacote: String): String? {
        val bruto = fala ?: return null
        if (!bruto.startsWith("{")) return bruto
        val dicionario = try {
            JSONObject(bruto)
        } catch (_: Exception) {
            // Uma fala que por acaso comece com chave nao pode sumir.
            return bruto
        }
        val doApp = dicionario.optString(pacote)
        if (doApp.isNotEmpty()) return doApp
        val padrao = dicionario.optString(CHAVE_PADRAO)
        return if (padrao.isNotEmpty()) padrao else null
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

    /**
     * A notificacao do servico — **a unica contagem da barra**.
     *
     * Antes eram duas: esta, com id 4711 no canal `baru_vigia`, e a do
     * plugin, com id 1004 no canal `baru_sessao`. Ids diferentes nao se
     * sobrescrevem, entao a pessoa via duas linhas iguais e so uma contando.
     * Agora as duas escrevem no id de [ContagemDaBarra], e o que sai e uma
     * notificacao so.
     *
     * **A contagem quem desenha e o Android**, a partir de `setWhen` no
     * instante de termino mais `setUsesChronometer`/`setChronometerCountDown`
     * (ADR-011). Ela anda no processo do system UI: continua correndo com o
     * app fechado, morto, ou sem nenhum Dart vivo — que e o estado normal de
     * uma pausa que deu certo.
     *
     * **Tela de bloqueio.** `VISIBILITY_PUBLIC` porque o padrao do Android e
     * esconder o conteudo em bloqueio seguro, e o conteudo aqui e a propria
     * contagem. Nao ha segredo em "faltam 12 minutos da sua pausa", e
     * esconde-lo tira exatamente o que a pessoa precisa ver sem desbloquear.
     *
     * **Nenhuma palavra nasce aqui.** Titulo, corpo e rotulos vem do Dart
     * traduzidos, via [ContagemDaBarra]; sem eles a notificacao sai com o
     * texto de reserva que o `vigiaComeca` trouxe, que tambem veio de la.
     */
    private fun notificacao(c: ContagemDaBarra.Contagem): Notification {
        garanteCanal(c.canal)

        val titulo = c.titulo.ifEmpty { tituloDeReserva }
        val corpo = c.corpo.ifEmpty { corpoDeReserva }

        val b = NotificationCompat.Builder(this, c.canal)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(titulo)
            .setContentText(corpo)
            .setContentIntent(abrirComAcao(PEDIDO_ABRIR, null))
            .setOngoing(true)
            .setSilent(true)
            .setOnlyAlertOnce(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            // `stopwatch` e o que isto e. A categoria alimenta a ordenacao e
            // o filtro de "nao perturbe"; escolher `alarm` ou `call` compraria
            // destaque com um nome falso.
            .setCategory(NotificationCompat.CATEGORY_STOPWATCH)

        if (c.viva(System.currentTimeMillis())) {
            b.setShowWhen(true)
                .setWhen(c.terminaEm)
                .setUsesChronometer(true)
                .setChronometerCountDown(true)
        } else {
            // Sem prazo valido, `usesChronometer` mostraria um contador
            // subindo a partir de um instante qualquer. Melhor nenhum numero
            // que um numero errado.
            b.setShowWhen(false)
        }

        // Os rotulos mandam: sem texto nao ha botao. Um botao sem palavra
        // seria o lado nativo inventando uma, que e a regra que nao se quebra.
        if (c.rotuloDesistir.isNotEmpty()) {
            b.addAction(
                0,
                c.rotuloDesistir,
                abrirComAcao(PEDIDO_DESISTIR, c.acaoDesistir),
            )
        }
        if (c.rotuloVoltar.isNotEmpty()) {
            b.addAction(
                0,
                c.rotuloVoltar,
                abrirComAcao(PEDIDO_VOLTAR, c.acaoVoltar),
            )
        }

        return b.build()
    }

    /**
     * O canal da contagem, criado so se ainda nao existir.
     *
     * Quem cria de verdade e o Dart, no arranque, com o nome traduzido. Este
     * ramo existe porque um servico em primeiro plano **sem canal valido nao
     * sobe** — e derrubar a sessao da pessoa por causa de um nome de canal
     * seria trocar um defeito de texto por um travamento. O nome de reserva e
     * o rotulo do proprio app, tirado do manifesto: nao e frase escrita aqui.
     */
    private fun garanteCanal(canal: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(canal) != null) return
        nm.createNotificationChannel(
            NotificationChannel(
                canal,
                applicationInfo.loadLabel(packageManager),
                // `LOW`: a barra tem de mostrar que a sessao corre, sem som
                // nem vibracao a cada vez.
                NotificationManager.IMPORTANCE_LOW,
            ).apply { setShowBadge(false) },
        )
    }

    /**
     * Abre o app, opcionalmente carregando uma acao para o Dart executar.
     *
     * **Por que abrir e nao resolver aqui.** "Desistir" tem de abandonar a
     * sessao *dentro do app*: mexer em folhas, sequencia e historico. Nada
     * disso mora no Kotlin, e nada disso pode acontecer com o Dart morto sem
     * duplicar a regra de negocio de um lado que nao a conhece. Abrir o app
     * com a acao no `Intent` faz a decisao chegar inteira a quem sabe
     * aplica-la — e desistir leva a tela de resultado de qualquer forma.
     *
     * `FLAG_UPDATE_CURRENT` porque o rotulo e a acao mudam entre a sessao e o
     * descanso: sem ele o Android reaproveitaria o `PendingIntent` antigo,
     * com os extras antigos.
     */
    private fun abrirComAcao(pedido: Int, acao: String?): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            if (acao != null) putExtra(MainActivity.EXTRA_ACAO_DA_BARRA, acao)
        }
        return PendingIntent.getActivity(
            this,
            pedido,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }
}
