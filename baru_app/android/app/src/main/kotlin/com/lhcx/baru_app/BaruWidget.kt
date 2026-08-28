package com.lhcx.baru_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.io.File

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
 */
class BaruWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        ids: IntArray,
    ) {
        val dados = HomeWidgetPlugin.getData(context)

        for (id in ids) {
            val v = RemoteViews(context.packageName, R.layout.baru_widget)

            // O bicho. `decodeFile` e nao `setImageViewUri`: o launcher e
            // outro processo e nao teria permissao de ler o nosso arquivo
            // por Uri sem um provider so para isso.
            val caminho = dados.getString("baru_pet_png", null)
            if (caminho != null && File(caminho).exists()) {
                BitmapFactory.decodeFile(caminho)?.let {
                    v.setImageViewBitmap(R.id.baru_pet, it)
                }
            }

            val nome = dados.getString("baru_nome", "") ?: ""
            v.setTextViewText(R.id.baru_nome, nome)

            val raiz = dados.getInt("baru_raiz", 0)
            v.setTextViewText(R.id.baru_raiz, raiz.toString())

            // A barra da meta. `coerceIn` porque estourar a meta e comum, e
            // uma barra de 140% desenha lixo.
            val uso = dados.getInt("baru_uso", 0)
            val meta = dados.getInt("baru_meta", 0)
            val pct = if (meta > 0) (uso * 100 / meta).coerceIn(0, 100) else 0
            v.setProgressBar(R.id.baru_meta, 100, pct, false)

            // Tocar abre o app. Um widget que nao leva a lugar nenhum e um
            // adesivo.
            v.setOnClickPendingIntent(
                R.id.baru_raiz_widget,
                PendingIntent.getActivity(
                    context,
                    0,
                    Intent(context, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP
                    },
                    PendingIntent.FLAG_IMMUTABLE,
                ),
            )

            manager.updateAppWidget(id, v)
        }
    }
}
