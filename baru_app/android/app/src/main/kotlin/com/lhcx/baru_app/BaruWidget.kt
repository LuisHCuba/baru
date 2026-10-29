package com.lhcx.baru_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.io.File
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId

/**
 * O Baru na tela inicial do aparelho.
 *
 * **O que um widget consegue desenhar.** `RemoteViews` roda no processo do
 * launcher, nao no nosso: sabe `TextView`, `ImageView`, `ProgressBar` e
 * pouco mais. Nao executa `CustomPainter`, entao o bicho aqui **nao pode
 * ser** o mesmo objeto que o bicho da tela. O Dart rasteriza o painter num
 * PNG, grava em disco, e este arquivo aponta um `ImageView` para ele.
 *
 * **Por que o texto vem do Dart.** Mesma regra do overlay e do vigia: o lado
 * nativo nao escreve produto. Nome, raiz e meta chegam prontos e traduzidos.
 * Sem isso, o widget falaria portugues para quem escolheu chines.
 *
 * **O widget muda sozinho ao longo do dia** (pesquisa 26, como o do
 * Duolingo): o Dart deixa gravados os cinco momentos — imagem e frase — e
 * aqui se escolhe qual mostrar pela hora e por "a raiz ja cresceu hoje",
 * sem o app aberto. A regra e a mesma de `momentoDoWidget` no Dart.
 *
 * A troca seguinte e agendada com alarme **inexato e sem acordar o
 * aparelho** (`AlarmManager.RTC`): com a tela apagada ninguem esta vendo o
 * widget, e ele se atualiza quando o aparelho acorda. Nada de
 * `updatePeriodMillis`, que redesenharia a cada 30 min o que nao mudou.
 */
open class BaruWidget : AppWidgetProvider() {

    private companion object {
        /** ~4 bytes por pixel; 250 mil ja encostam no teto do Binder. */
        const val MAX_PIXELS = 200_000

        /** As horas em que o momento muda: madrugada, manha, tarde, noite. */
        val VIRADAS = intArrayOf(0, 5, 12, 18, 23)

        /** O momento agora. Espelho de `momentoDoWidget` (widget_service.dart). */
        fun momento(presenteEm: LocalDate?, agora: LocalDateTime): String {
            if (presenteEm != null && presenteEm == agora.toLocalDate()) {
                return "feito"
            }
            val h = agora.hour
            return when {
                h < 5 || h >= 23 -> "madrugada"
                h < 12 -> "manha"
                h < 18 -> "tarde"
                else -> "noite"
            }
        }

        /** A proxima virada depois de [agora]. */
        fun proximaVirada(agora: LocalDateTime): LocalDateTime {
            val dia = agora.toLocalDate()
            for (h in VIRADAS) {
                val t = dia.atTime(h, 0)
                if (t.isAfter(agora)) return t
            }
            return dia.plusDays(1).atStartOfDay()
        }

        /**
         * A semana no dia [hoje] a partir da gravada em [escritaEm]. Espelho
         * exato de `semanaNoDia` (widget_service.dart): `p` presente, `f`
         * congelado, `t` hoje sem presenca ainda, `e` vazio.
         */
        fun semanaNoDia(
            codigos: String,
            escritaEm: LocalDate,
            presenteEm: LocalDate?,
            hoje: LocalDate,
        ): String {
            val desloca = java.time.temporal.ChronoUnit.DAYS
                .between(escritaEm, hoje).toInt().coerceIn(0, 7)
            val out = StringBuilder()
            for (i in 0 until 7) {
                val data = hoje.minusDays((6 - i).toLong())
                if (presenteEm != null && presenteEm == data) {
                    out.append('p')
                    continue
                }
                if (i == 6) {
                    out.append('t')
                    continue
                }
                val c = codigos.getOrNull(i + desloca) ?: 'e'
                out.append(if (c == 't') 'e' else c)
            }
            return out.toString()
        }

        fun leDia(texto: String?): LocalDate? =
            try {
                if (texto.isNullOrEmpty()) null else LocalDate.parse(texto)
            } catch (_: Exception) {
                null
            }

        /**
         * Os dois widgets da lista do Android: o quadrado (2x2) e o
         * retangular (4x2, com a semana). Mesma logica, formatos de partida
         * diferentes.
         */
        val PROVEDORES = listOf(BaruWidget::class.java, BaruWidgetLargo::class.java)

        /** O alarme da troca de momento: um so, para os dois widgets. */
        const val ACAO_VIRADA = "com.lhcx.baru_app.WIDGET_VIRADA"

        fun temAlgum(context: Context): Boolean {
            val manager = AppWidgetManager.getInstance(context)
            return PROVEDORES.any {
                manager.getAppWidgetIds(ComponentName(context, it)).isNotEmpty()
            }
        }

        /** Pede ao launcher para redesenhar todos os widgets do Baru. */
        fun atualizaTodos(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            for (classe in PROVEDORES) {
                val ids = manager.getAppWidgetIds(ComponentName(context, classe))
                if (ids.isEmpty()) continue
                context.sendBroadcast(
                    Intent(context, classe).apply {
                        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                    },
                )
            }
        }
    }

    /**
     * Relogio mudado, fuso trocado, aparelho religado: o alarme agendado
     * ficou errado ou sumiu (o Android apaga alarmes no reboot). Redesenhar
     * reagenda.
     */
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            ACAO_VIRADA -> atualizaTodos(context)
            else -> super.onReceive(context, intent)
        }
    }

    override fun onDisabled(context: Context) {
        // O ultimo widget **deste formato** saiu da tela. O alarme so cai
        // se nao sobrou nenhum do outro.
        if (!temAlgum(context)) {
            (context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager)
                ?.cancel(alarme(context))
        }
        super.onDisabled(context)
    }

    private fun alarme(context: Context): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            7301,
            Intent(context, BaruWidget::class.java).setAction(ACAO_VIRADA),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

    /** Agenda a proxima troca de momento. Inexato e sem acordar o aparelho. */
    private fun agendaProximaVirada(context: Context, agora: LocalDateTime) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            ?: return
        val quando = proximaVirada(agora)
            .atZone(ZoneId.systemDefault())
            .toInstant()
            .toEpochMilli()
        try {
            am.set(AlarmManager.RTC, quando, alarme(context))
        } catch (_: Exception) {
            // Sem alarme o widget ainda se atualiza quando o app sai de
            // cena; so deixa de trocar de momento sozinho.
        }
    }


    /**
     * Le o PNG do bicho num tamanho que o Binder aceite.
     *
     * `setImageViewBitmap` serializa o bitmap **descomprimido** para o
     * processo do launcher, e a transacao do Binder tem limite pratico de
     * ~1 MB. Um PNG grande decodifica em varios megabytes, a transacao e
     * recusada e o launcher fica com o `ImageView` vazio — sem erro
     * nenhum, so o quadrado.
     *
     * O Dart ja grava no tamanho certo; esta funcao e o cinto de seguranca
     * para o caso de um PNG antigo ter sobrado no disco.
     */
    private fun leCabendoNoBinder(caminho: String): Bitmap? {
        val arquivo = File(caminho)
        if (!arquivo.exists()) return null
        return try {
            val medida = BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
            BitmapFactory.decodeFile(caminho, medida)
            var amostra = 1
            while (
                (medida.outWidth / amostra) * (medida.outHeight / amostra) >
                MAX_PIXELS
            ) {
                amostra *= 2
            }
            BitmapFactory.decodeFile(
                caminho,
                BitmapFactory.Options().apply { inSampleSize = amostra },
            )
        } catch (_: Exception) {
            // Arquivo pela metade, disco cheio, PNG corrompido: o widget
            // some com o bicho, nao com o app.
            null
        }
    }

    /** A pessoa redimensionou: 2x2 e 4x2 sao layouts diferentes. */
    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        id: Int,
        novas: android.os.Bundle,
    ) {
        onUpdate(context, manager, intArrayOf(id))
    }

    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        ids: IntArray,
    ) {
        val dados = HomeWidgetPlugin.getData(context)
        val agora = LocalDateTime.now()
        val hoje = agora.toLocalDate()
        val presenteEm = leDia(dados.getString("baru_presente_em", null))
        val qual = momento(presenteEm, agora)
        // A raiz gravada vale ate a meia-noite do dia seguinte a ultima
        // presenca. Depois disso ela pode ter quebrado, segurado no
        // congelamento ou crescido noutro aparelho: o numero sai em vez de
        // mentir, e volta certo quando o app abrir.
        val raizValida = presenteEm != null &&
            !presenteEm.isBefore(hoje.minusDays(1))
        val raiz = dados.getInt("baru_raiz", 0)
        val frase = dados.getString("baru_frase_$qual", "") ?: ""
        val semana = semanaNoDia(
            dados.getString("baru_semana", "") ?: "",
            leDia(dados.getString("baru_semana_em", null)) ?: hoje,
            presenteEm,
            hoje,
        )
        val letras = dados.getString("baru_letras", "") ?: ""

        for (id in ids) {
            // O formato pelo tamanho em que a pessoa deixou o widget: a
            // partir de ~4 colunas, o largo, com a semana.
            val largura = manager.getAppWidgetOptions(id)
                .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
            val largo = largura >= 230
            val v = RemoteViews(
                context.packageName,
                if (largo) R.layout.baru_widget_largo else R.layout.baru_widget,
            )

            // A cena. `decodeFile` e nao `setImageViewUri`: o launcher e
            // outro processo e nao teria permissao de ler o nosso arquivo
            // por Uri sem um provider so para isso.
            val caminho = dados.getString(
                "baru_png_${qual}_${if (largo) "l" else "q"}",
                null,
            )
            val cena = if (caminho != null) leCabendoNoBinder(caminho) else null
            if (cena != null) {
                v.setViewVisibility(R.id.baru_pet, View.VISIBLE)
                v.setImageViewBitmap(R.id.baru_pet, cena)
            } else {
                // Sem cena ainda (app nunca foi ao segundo plano): fica o
                // fundo liso, e o numero e a frase continuam dizendo algo.
                v.setViewVisibility(R.id.baru_pet, View.GONE)
            }

            v.setTextViewText(R.id.baru_frase, frase)
            v.setViewVisibility(
                R.id.baru_frase,
                if (frase.isEmpty()) View.GONE else View.VISIBLE,
            )
            v.setContentDescription(R.id.baru_pet, frase)

            v.setTextViewText(R.id.baru_raiz, raiz.toString())
            v.setViewVisibility(
                R.id.baru_raiz_linha,
                if (raizValida) View.VISIBLE else View.GONE,
            )

            if (largo) pintaSemana(v, semana, letras, hoje)

            // Cada pedaco leva ao seu lugar. `data` diferente por destino:
            // `PendingIntent` com o mesmo request code e o mesmo Intent e
            // **reaproveitado** pelo Android, e os cliques abririam a mesma
            // tela.
            fun abre(destino: String, vista: Int, codigo: Int) {
                v.setOnClickPendingIntent(
                    vista,
                    PendingIntent.getActivity(
                        context,
                        codigo,
                        Intent(context, MainActivity::class.java).apply {
                            action = Intent.ACTION_VIEW
                            data = Uri.parse("baru://$destino")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                                Intent.FLAG_ACTIVITY_CLEAR_TOP
                        },
                        PendingIntent.FLAG_IMMUTABLE,
                    ),
                )
            }

            abre("home", R.id.baru_raiz_widget, 0)
            abre("sequencia", R.id.baru_raiz_linha, 1)
            if (largo) abre("sequencia", R.id.baru_semana, 2)

            manager.updateAppWidget(id, v)
        }
        agendaProximaVirada(context, agora)
    }

    /** Os 7 circulos da semana, com a inicial do dia em cima. */
    private fun pintaSemana(
        v: RemoteViews,
        semana: String,
        letras: String,
        hoje: LocalDate,
    ) {
        val letraIds = intArrayOf(
            R.id.baru_l0, R.id.baru_l1, R.id.baru_l2, R.id.baru_l3,
            R.id.baru_l4, R.id.baru_l5, R.id.baru_l6,
        )
        val diaIds = intArrayOf(
            R.id.baru_d0, R.id.baru_d1, R.id.baru_d2, R.id.baru_d3,
            R.id.baru_d4, R.id.baru_d5, R.id.baru_d6,
        )
        for (i in 0 until 7) {
            val data = hoje.minusDays((6 - i).toLong())
            val k = data.dayOfWeek.value - 1
            v.setTextViewText(
                letraIds[i],
                if (k < letras.length) letras[k].toString() else "",
            )
            val (fundo, marca, cor) = when (semana.getOrNull(i)) {
                'p' -> Triple(R.drawable.baru_dia_feito, "\u2713", 0xFF2F6F3E.toInt())
                'f' -> Triple(R.drawable.baru_dia_congelado, "\u2744", 0xFF2A7FBF.toInt())
                't' -> Triple(R.drawable.baru_dia_hoje, "", 0xFFFFFFFF.toInt())
                else -> Triple(R.drawable.baru_dia_vazio, "", 0xFFFFFFFF.toInt())
            }
            v.setInt(diaIds[i], "setBackgroundResource", fundo)
            v.setTextViewText(diaIds[i], marca)
            v.setTextColor(diaIds[i], cor)
        }
    }
}

/**
 * O widget retangular (4x2) na lista do Android. A logica e a mesma do
 * quadrado — o layout sai do tamanho (ver `onUpdate`) —; o que muda e o
 * `appwidget-provider`: tamanho de partida, prévia e descricao.
 */
class BaruWidgetLargo : BaruWidget()
