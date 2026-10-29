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
class BaruWidget : AppWidgetProvider() {

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

        fun leDia(texto: String?): LocalDate? =
            try {
                if (texto.isNullOrEmpty()) null else LocalDate.parse(texto)
            } catch (_: Exception) {
                null
            }

        /** Pede ao launcher para redesenhar todos os widgets do Baru. */
        fun atualizaTodos(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, BaruWidget::class.java),
            )
            if (ids.isEmpty()) return
            context.sendBroadcast(
                Intent(context, BaruWidget::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                },
            )
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
            Intent.ACTION_MY_PACKAGE_REPLACED -> atualizaTodos(context)
            else -> super.onReceive(context, intent)
        }
    }

    override fun onDisabled(context: Context) {
        // O ultimo widget saiu da tela: o alarme nao tem mais o que trocar.
        (context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager)
            ?.cancel(alarme(context))
        super.onDisabled(context)
    }

    private fun alarme(context: Context): PendingIntent {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(
            ComponentName(context, BaruWidget::class.java),
        )
        return PendingIntent.getBroadcast(
            context,
            7301,
            Intent(context, BaruWidget::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            },
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

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

    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        ids: IntArray,
    ) {
        val dados = HomeWidgetPlugin.getData(context)
        val agora = LocalDateTime.now()
        val presenteEm = leDia(dados.getString("baru_presente_em", null))
        val qual = momento(presenteEm, agora)
        // A raiz gravada vale ate a meia-noite do dia seguinte a ultima
        // presenca. Depois disso ela pode ter quebrado, segurado no
        // congelamento ou crescido noutro aparelho: o numero sai em vez de
        // mentir, e volta certo quando o app abrir.
        val raizValida = presenteEm != null &&
            !presenteEm.isBefore(agora.toLocalDate().minusDays(1))

        for (id in ids) {
            val v = RemoteViews(context.packageName, R.layout.baru_widget)

            // O bicho. `decodeFile` e nao `setImageViewUri`: o launcher e
            // outro processo e nao teria permissao de ler o nosso arquivo
            // por Uri sem um provider so para isso.
            val caminho = dados.getString("baru_png_$qual", null)
                ?: dados.getString("baru_pet_png", null)
            val bicho = if (caminho != null) leCabendoNoBinder(caminho) else null
            if (bicho != null) {
                v.setViewVisibility(R.id.baru_pet, View.VISIBLE)
                v.setImageViewBitmap(R.id.baru_pet, bicho)
            } else {
                // Sem imagem, o `ImageView` fica um retangulo vazio e o
                // widget parece quebrado. Escondendo, o nome e a raiz
                // ocupam o espaco e o widget continua dizendo alguma coisa.
                v.setViewVisibility(R.id.baru_pet, View.GONE)
            }

            val frase = dados.getString("baru_frase_$qual", "") ?: ""
            v.setTextViewText(R.id.baru_frase, frase)
            v.setViewVisibility(
                R.id.baru_frase,
                if (frase.isEmpty()) View.GONE else View.VISIBLE,
            )
            v.setContentDescription(R.id.baru_pet, frase)

            val nome = dados.getString("baru_nome", "") ?: ""
            v.setTextViewText(R.id.baru_nome, nome)

            val raiz = dados.getInt("baru_raiz", 0)
            v.setTextViewText(R.id.baru_raiz, if (raizValida) raiz.toString() else "")

            // A barra da meta. `coerceIn` porque estourar a meta e comum, e
            // uma barra de 140% desenha lixo.
            val uso = dados.getInt("baru_uso", 0)
            val meta = dados.getInt("baru_meta", 0)
            val pct = if (meta > 0) (uso * 100 / meta).coerceIn(0, 100) else 0
            v.setProgressBar(R.id.baru_meta, 100, pct, false)

            // Cada pedaco leva ao seu lugar. Um widget que so abre a home
            // e um atalho com desenho bonito; o valor esta em cortar
            // caminho para onde a pessoa ja queria ir.
            //
            // `data` diferente por destino de proposito: `PendingIntent`
            // com o mesmo request code e o mesmo Intent e **reaproveitado**
            // pelo Android, e os tres cliques abririam a mesma tela.
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
            abre("sequencia", R.id.baru_raiz, 1)
            abre("tempo", R.id.baru_meta, 2)

            manager.updateAppWidget(id, v)
        }
        agendaProximaVirada(context, agora)
    }
}
