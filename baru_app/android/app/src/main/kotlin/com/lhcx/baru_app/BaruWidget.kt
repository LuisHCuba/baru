package com.lhcx.baru_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
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

    private companion object {
        /** ~4 bytes por pixel; 250 mil ja encostam no teto do Binder. */
        const val MAX_PIXELS = 200_000
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

        for (id in ids) {
            val v = RemoteViews(context.packageName, R.layout.baru_widget)

            // O bicho. `decodeFile` e nao `setImageViewUri`: o launcher e
            // outro processo e nao teria permissao de ler o nosso arquivo
            // por Uri sem um provider so para isso.
            val caminho = dados.getString("baru_pet_png", null)
            val bicho = if (caminho != null) leCabendoNoBinder(caminho) else null
            if (bicho != null) {
                v.setImageViewBitmap(R.id.baru_pet, bicho)
            } else {
                // Sem imagem, o `ImageView` fica um retangulo vazio e o
                // widget parece quebrado. Escondendo, o nome e a raiz
                // ocupam o espaco e o widget continua dizendo alguma coisa.
                v.setViewVisibility(R.id.baru_pet, View.GONE)
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
    }
}
