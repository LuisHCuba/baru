package com.lhcx.baru_app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor

/**
 * Filtro de sites adultos no celular da criança (Android).
 *
 * Uma VPN só de DNS: o aparelho passa a perguntar endereços ao DNS "família"
 * da Cloudflare (1.1.1.3 / 1.0.0.3), que responde vazio para sites adultos e
 * de malware. Nenhum tráfego passa pelo Baru — a VPN não declara rota, só os
 * servidores de DNS —, então não há leitura do que a criança acessa.
 *
 * O Android pede uma vez a permissão de VPN (o responsável aceita no celular
 * da criança). Quem liga e desliga é a regra "filtro de sites" da família.
 */
class FiltroDeSites : VpnService() {

    companion object {
        const val ACAO_LIGA = "com.lhcx.baru_app.filtro.LIGA"
        const val ACAO_DESLIGA = "com.lhcx.baru_app.filtro.DESLIGA"
        private const val ARQUIVO = "baru_familia"
        private const val K_LIGADO = "filtroLigado"

        /** Já tem a permissão de VPN do Android? */
        fun preparado(ctx: Context): Boolean = prepare(ctx) == null

        /** Abre o pedido do sistema. Devolve false se já estava permitido. */
        fun pede(activity: Activity, codigo: Int): Boolean {
            val i = prepare(activity) ?: return false
            activity.startActivityForResult(i, codigo)
            return true
        }

        fun liga(ctx: Context, ligado: Boolean) {
            ctx.getSharedPreferences(ARQUIVO, Context.MODE_PRIVATE).edit().putBoolean(K_LIGADO, ligado).apply()
            if (ligado && !preparado(ctx)) return
            ctx.startService(Intent(ctx, FiltroDeSites::class.java).setAction(if (ligado) ACAO_LIGA else ACAO_DESLIGA))
        }

        fun deveriaEstarLigado(ctx: Context): Boolean =
            ctx.getSharedPreferences(ARQUIVO, Context.MODE_PRIVATE).getBoolean(K_LIGADO, false)
    }

    private var tunel: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACAO_DESLIGA || !deveriaEstarLigado(this)) {
            fecha()
            stopSelf()
            return START_NOT_STICKY
        }
        if (tunel == null) {
            tunel = try {
                Builder()
                    .setSession("Baru: filtro de sites")
                    .addAddress("10.77.0.2", 32)
                    .addDnsServer("1.1.1.3")
                    .addDnsServer("1.0.0.3")
                    .setBlocking(false)
                    .establish()
            } catch (_: Exception) {
                null
            }
        }
        return START_STICKY
    }

    override fun onRevoke() {
        // A criança (ou o sistema) desligou a VPN: fica registrado para o
        // próximo envio do dia avisar o responsável.
        getSharedPreferences(ARQUIVO, Context.MODE_PRIVATE).edit().putBoolean("filtroRevogado", true).apply()
        fecha()
        super.onRevoke()
    }

    override fun onDestroy() {
        fecha()
        super.onDestroy()
    }

    private fun fecha() {
        try {
            tunel?.close()
        } catch (_: Exception) {
        }
        tunel = null
    }
}
