package com.lhcx.baru_app

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import java.io.File

/**
 * Os quadros do bicho real que a sobreposicao anima.
 *
 * **De onde vem.** O Dart rasteriza o `PetView` — o mesmo desenho da home,
 * com especie, pelagem e roupa — em alguns PNGs ao sair do app
 * (`lib/services/quadros_do_bicho.dart`) e manda so os caminhos. Este objeto
 * guarda os caminhos em disco e os le de volta na hora de aparecer.
 *
 * **Por que em `SharedPreferences` e nao em memoria.** O [VigiaDaSessao]
 * levanta a sobreposicao mesmo com o processo do Flutter morto, e e
 * exatamente ai que o bicho real mais importa.
 *
 * **Sem quadros, sem drama.** Qualquer falha devolve `null` e a
 * sobreposicao volta ao desenho de reserva.
 */
object QuadrosDoBicho {

    private const val ARQUIVO = "baru_quadros"
    private const val K_CHAVE = "chave"
    private const val K_RESPIRO = "respiro"
    private const val K_PISCAR = "piscar"
    private const val K_VERSAO = "versaoDoApp"

    /** Respiro em ordem (peito vazio → cheio) e o olho fechado. */
    class Quadros(val respiro: List<Bitmap>, val piscar: Bitmap)

    private fun prefs(ctx: Context): SharedPreferences =
        ctx.getSharedPreferences(ARQUIVO, Context.MODE_PRIVATE)

    /**
     * Guarda os caminhos. Recusa (devolve `false`) o que nao esta no disco:
     * o Dart entao tenta de novo na proxima saida, em vez de a sobreposicao
     * descobrir o buraco na hora de aparecer.
     */
    fun grava(
        ctx: Context,
        chave: String,
        respiro: List<String>,
        piscar: String,
    ): Boolean {
        val todos = respiro + piscar
        if (respiro.size < 2 || todos.any { it.isEmpty() || !File(it).isFile }) {
            Log.w(VigiaDaSessao.TAG_LOG, "quadros: recusados (faltam arquivos)")
            return false
        }
        val p = prefs(ctx)
        val antigos = caminhosGravados(p).toSet()
        // As preferências trocam **depois** de os arquivos novos existirem
        // (conferido acima) e num `commit` só: quem ler no meio vê o
        // conjunto velho inteiro ou o novo inteiro, nunca metade de cada.
        p.edit()
            .putString(K_CHAVE, chave)
            // Quebra de linha como separador: nenhum caminho do Android a tem.
            .putString(K_RESPIRO, respiro.joinToString("\n"))
            .putString(K_PISCAR, piscar)
            .putLong(K_VERSAO, versaoDoApp(ctx))
            .commit()
        // Os arquivos da aparência anterior saem. Uma sobreposição que
        // esteja na tela já os decodificou; ninguém mais os lê.
        for (velho in antigos - todos.toSet()) {
            try {
                File(velho).delete()
            } catch (_: Exception) {
            }
        }
        return true
    }

    /**
     * A chave dos quadros que estão valendo, ou `null`.
     *
     * Nula também quando o app foi atualizado desde a gravação: o desenho do
     * bicho pode ter mudado, e quadros de uma versão velha mostrariam o
     * bicho antigo por cima dos outros apps.
     */
    fun chaveAtual(ctx: Context): String? {
        val p = prefs(ctx)
        if (p.getLong(K_VERSAO, -1L) != versaoDoApp(ctx)) return null
        return p.getString(K_CHAVE, null)
    }

    private fun caminhosGravados(p: SharedPreferences): List<String> =
        (p.getString(K_RESPIRO, null)?.split("\n").orEmpty() +
            listOfNotNull(p.getString(K_PISCAR, null)))
            .filter { it.isNotEmpty() }

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

    /**
     * Le os quadros, reduzidos para a altura em que vao aparecer.
     *
     * `inSampleSize` como no [BaruWidget]: so potencias de dois, e so para
     * baixo. Num aparelho de densidade baixa os PNGs de 2× seriam o dobro do
     * necessario — memoria que a sobreposicao, rodando por cima de outro app,
     * nao tem por que gastar.
     */
    fun carrega(ctx: Context, alturaPx: Int): Quadros? {
        val p = prefs(ctx)
        val caminhos = p.getString(K_RESPIRO, null)
            ?.split("\n")
            ?.filter { it.isNotEmpty() }
            .orEmpty()
        val piscar = p.getString(K_PISCAR, null)
        if (caminhos.size < 2 || piscar.isNullOrEmpty()) return null
        return try {
            val respiro = caminhos.map { le(it, alturaPx) ?: return null }
            val olho = le(piscar, alturaPx) ?: return null
            Quadros(respiro, olho)
        } catch (e: Exception) {
            Log.w(VigiaDaSessao.TAG_LOG, "quadros: leitura falhou", e)
            null
        }
    }

    private fun le(caminho: String, alturaPx: Int): Bitmap? {
        if (!File(caminho).isFile) return null
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
}
