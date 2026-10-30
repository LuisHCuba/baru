package com.lhcx.baru_app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import org.json.JSONObject
import java.io.File

/**
 * As cenas das notificacoes animadas: os quadros do bicho e os fundos.
 *
 * **De onde vem.** O Dart rasteriza o `PetView` de verdade, um bicho por tema
 * de recado (bocejando na pausa, contente no convite, radiante na raiz,
 * dormindo na despedida), e um fundo por tema e por luz do dia
 * (`lib/services/cenas_dos_recados.dart`). Aqui so se guardam os caminhos e
 * se le de volta na hora de postar — com o processo do Flutter morto, que e
 * o caso normal de um recado agendado.
 *
 * Mesmo padrao do [QuadrosDoBicho]: troca atomica num `commit`, arquivos
 * antigos apagados depois, e versao do app conferida — desenho de uma versao
 * velha mostraria o bicho antigo.
 */
object CenasDosRecados {

    private const val ARQUIVO = "baru_cenas"
    private const val K_CHAVE = "chave"
    private const val K_TEMAS = "temas"
    private const val K_VERSAO = "versaoDoApp"

    class Cena(val respiro: List<Bitmap>, val pisca: Bitmap, val fundo: Bitmap?)

    private fun prefs(ctx: Context) =
        ctx.getSharedPreferences(ARQUIVO, Context.MODE_PRIVATE)

    /**
     * Guarda os caminhos. Recusa o conjunto se algum arquivo nao existir: o
     * Dart tenta de novo na proxima saida do app.
     */
    fun grava(ctx: Context, chave: String, temas: Map<*, *>): Boolean {
        val json = JSONObject()
        val todos = mutableListOf<String>()
        for ((nome, valor) in temas) {
            val t = valor as? Map<*, *> ?: return false
            val respiro = (t["respiro"] as? List<*>)?.map { it as? String ?: "" }.orEmpty()
            val pisca = t["pisca"] as? String ?: ""
            val fundos = (t["fundos"] as? Map<*, *>).orEmpty()
            if (respiro.size < 2) return false
            val f = JSONObject()
            for ((luz, caminho) in fundos) f.put(luz.toString(), caminho.toString())
            json.put(
                nome.toString(),
                JSONObject()
                    .put("respiro", respiro.joinToString("\n"))
                    .put("pisca", pisca)
                    .put("fundos", f),
            )
            todos += respiro + pisca + fundos.values.map { it.toString() }
        }
        if (todos.any { it.isEmpty() || !File(it).isFile }) {
            Log.w(VigiaDaSessao.TAG_LOG, "cenas: recusadas (faltam arquivos)")
            return false
        }
        val p = prefs(ctx)
        val antigos = caminhos(p.getString(K_TEMAS, null))
        p.edit()
            .putString(K_CHAVE, chave)
            .putString(K_TEMAS, json.toString())
            .putLong(K_VERSAO, versaoDoApp(ctx))
            .commit()
        for (velho in antigos - todos.toSet()) {
            try {
                File(velho).delete()
            } catch (_: Exception) {
            }
        }
        return true
    }

    fun chaveAtual(ctx: Context): String? {
        val p = prefs(ctx)
        if (p.getLong(K_VERSAO, -1L) != versaoDoApp(ctx)) return null
        return p.getString(K_CHAVE, null)
    }

    /**
     * A cena de um tema numa luz, com os quadros reduzidos a [alturaPx].
     * `null` quando nao ha cena gravada — o recado sai na forma comum.
     */
    fun carrega(ctx: Context, tema: String, luz: String, alturaPx: Int): Cena? {
        if (chaveAtual(ctx) == null) return null
        return try {
            val todos = JSONObject(prefs(ctx).getString(K_TEMAS, null) ?: return null)
            val t = todos.optJSONObject(tema) ?: return null
            val respiro = t.optString("respiro").split("\n").filter { it.isNotEmpty() }
                .map { le(it, alturaPx) ?: return null }
            val pisca = le(t.optString("pisca"), alturaPx) ?: return null
            val fundo = t.optJSONObject("fundos")?.optString(luz)?.let { le(it, Int.MAX_VALUE) }
            if (respiro.size < 2) null else Cena(respiro, pisca, fundo)
        } catch (e: Exception) {
            Log.w(VigiaDaSessao.TAG_LOG, "cenas: leitura falhou", e)
            null
        }
    }

    private fun caminhos(json: String?): Set<String> {
        if (json == null) return emptySet()
        return try {
            val o = JSONObject(json)
            buildSet {
                for (nome in o.keys()) {
                    val t = o.getJSONObject(nome)
                    addAll(t.optString("respiro").split("\n").filter { it.isNotEmpty() })
                    add(t.optString("pisca"))
                    val f = t.optJSONObject("fundos") ?: continue
                    for (luz in f.keys()) add(f.getString(luz))
                }
            }
        } catch (_: Exception) {
            emptySet()
        }
    }

    private fun le(caminho: String, alturaPx: Int): Bitmap? {
        if (caminho.isEmpty() || !File(caminho).isFile) return null
        val medida = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(caminho, medida)
        if (medida.outHeight <= 0) return null
        var amostra = 1
        while (medida.outHeight / (amostra * 2) >= alturaPx) amostra *= 2
        return BitmapFactory.decodeFile(
            caminho,
            BitmapFactory.Options().apply { inSampleSize = amostra },
        )
    }

    @Suppress("DEPRECATION")
    private fun versaoDoApp(ctx: Context): Long = try {
        val info = ctx.packageManager.getPackageInfo(ctx.packageName, 0)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
            info.longVersionCode
        } else {
            info.versionCode.toLong()
        }
    } catch (_: Exception) {
        0L
    }
}
