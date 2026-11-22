package com.lhcx.baru_app

import android.Manifest
import android.app.NotificationChannel
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread

/**
 * Localização da família no Android.
 *
 * - No celular da criança, o guarda (GuardaDaFamilia) chama [enviaPosicao]
 *   quando o responsável liga a localização: a cada 10 minutos, quando o
 *   responsável pede "onde está agora?" e no SOS. Quem decide chegou/saiu de
 *   um lugar é o banco.
 * - No celular do responsável, [AvisosDaFamilia] confere de 15 em 15 minutos
 *   os avisos novos (SOS, chegou, saiu, meta) e mostra como notificação.
 */
object LocalDaFamilia {

    fun temPermissao(ctx: Context): Boolean =
        ContextCompat.checkSelfPermission(ctx, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(ctx, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

    fun temSempre(ctx: Context): Boolean =
        temPermissao(ctx) && (Build.VERSION.SDK_INT < 29 ||
            ContextCompat.checkSelfPermission(ctx, Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED)

    /** "desligada" (sistema), "negada", "quando_usa" ou "sempre". */
    fun estado(ctx: Context): String {
        val lm = ctx.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val ligada = if (Build.VERSION.SDK_INT >= 28) lm.isLocationEnabled
        else lm.isProviderEnabled(LocationManager.GPS_PROVIDER) || lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        return when {
            !ligada -> "desligada"
            !temPermissao(ctx) -> "negada"
            temSempre(ctx) -> "sempre"
            else -> "quando_usa"
        }
    }

    fun bateria(ctx: Context): Int =
        (ctx.getSystemService(Context.BATTERY_SERVICE) as BatteryManager).getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)

    /**
     * Uma posição nova, em até ~12 s. Usa a última conhecida se for recente
     * (menos de 2 minutos) e boa o bastante. `fim(null)` sem permissão ou sinal.
     */
    @Suppress("MissingPermission")
    fun agora(ctx: Context, fim: (Location?) -> Unit) {
        if (!temPermissao(ctx)) { fim(null); return }
        val lm = ctx.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val provedores = buildList {
            if (Build.VERSION.SDK_INT >= 31 && lm.allProviders.contains(LocationManager.FUSED_PROVIDER)) add(LocationManager.FUSED_PROVIDER)
            if (lm.isProviderEnabled(LocationManager.GPS_PROVIDER)) add(LocationManager.GPS_PROVIDER)
            if (lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) add(LocationManager.NETWORK_PROVIDER)
        }
        val recente = provedores.mapNotNull { try { lm.getLastKnownLocation(it) } catch (_: Exception) { null } }
            .filter { System.currentTimeMillis() - it.time < 120_000 && it.accuracy <= 100f }
            .maxByOrNull { it.time } // a mais nova: quem se mexeu não pode aparecer onde estava
        if (recente != null) { fim(recente); return }
        val provedor = provedores.firstOrNull() ?: run { fim(null); return }
        val mao = Handler(Looper.getMainLooper())
        var feito = false
        val entrega = { l: Location? -> if (!feito) { feito = true; fim(l) } }
        try {
            if (Build.VERSION.SDK_INT >= 30) {
                lm.getCurrentLocation(provedor, null, ContextCompat.getMainExecutor(ctx)) { l -> entrega(l) }
            } else {
                val ouvinte = object : LocationListener {
                    override fun onLocationChanged(l: Location) { lm.removeUpdates(this); entrega(l) }
                    @Deprecated("API antiga") override fun onStatusChanged(p: String?, s: Int, e: Bundle?) {}
                    override fun onProviderEnabled(p: String) {}
                    override fun onProviderDisabled(p: String) {}
                }
                @Suppress("DEPRECATION")
                lm.requestSingleUpdate(provedor, ouvinte, Looper.getMainLooper())
                mao.postDelayed({ lm.removeUpdates(ouvinte) }, 25_000)
            }
        } catch (_: Exception) {
            entrega(null); return
        }
        // Sem resposta em 12 s: fica com a última conhecida, mesmo velha (no SOS, rapidez vale mais).
        mao.postDelayed({
            entrega(provedores.mapNotNull { try { lm.getLastKnownLocation(it) } catch (_: Exception) { null } }.maxByOrNull { it.time })
        }, 12_000)
    }

    /** Chama uma função do banco com a chave anônima (sem login). Roda fora da thread principal. */
    fun rpc(url: String, anon: String, funcao: String, corpo: JSONObject): String? = try {
        val c = URL("$url/rest/v1/rpc/$funcao").openConnection() as HttpURLConnection
        c.requestMethod = "POST"
        c.connectTimeout = 15_000
        c.readTimeout = 15_000
        c.doOutput = true
        c.setRequestProperty("Content-Type", "application/json")
        c.setRequestProperty("apikey", anon)
        c.setRequestProperty("Authorization", "Bearer $anon")
        c.outputStream.use { it.write(corpo.toString().toByteArray()) }
        if (c.responseCode == 200) c.inputStream.bufferedReader().use { it.readText() }.trim() else null
    } catch (_: Exception) {
        null
    }

    /** Pega a posição e manda para a família. `fim(true)` se o banco aceitou. */
    fun enviaPosicao(ctx: Context, chave: String, url: String, anon: String, motivo: String, fim: (Boolean) -> Unit = {}) {
        agora(ctx) { l ->
            if (l == null) { fim(false); return@agora }
            val bat = bateria(ctx)
            thread(name = "baru-local") {
                val r = rpc(url, anon, "baru_familia_posicao", JSONObject()
                    .put("p_chave", chave).put("p_lat", l.latitude).put("p_lng", l.longitude)
                    .put("p_precisao", l.accuracy.toInt()).put("p_bateria", bat).put("p_motivo", motivo))
                fim(r != null && r != "null")
            }
        }
    }
}

/**
 * Celular da criança (Android): de 15 em 15 minutos, mesmo com a tela apagada
 * e o celular "dormindo" (o laço do guarda para quando o Android entra em
 * Doze), manda a posição e conta a permissão ao servidor.
 *
 * Precisa da permissão "o tempo todo": sem ela o Android não entrega posição
 * com o Baru fechado, e o responsável vê esse motivo no painel.
 */
class PosicaoDaFamilia : JobService() {

    companion object {
        private const val JOB_ID = 1030

        /** Agenda (ou cancela) conforme a localização está ligada para esta criança. */
        fun agenda(ctx: Context, ligada: Boolean) {
            val js = ctx.getSystemService(JobScheduler::class.java) ?: return
            if (!ligada) { js.cancel(JOB_ID); return }
            if (js.getPendingJob(JOB_ID) != null) return
            js.schedule(JobInfo.Builder(JOB_ID, ComponentName(ctx, PosicaoDaFamilia::class.java))
                .setPeriodic(15 * 60_000L)
                .setRequiredNetworkType(JobInfo.NETWORK_TYPE_ANY)
                .setPersisted(true)
                .build())
        }
    }

    override fun onStartJob(params: JobParameters?): Boolean {
        val base = try { JSONObject(RegrasDaFamilia.texto(this) ?: run { agenda(this, false); return false }) } catch (_: Exception) { return false }
        if (!base.optBoolean("localizacao", false)) { agenda(this, false); return false }
        val chave = base.optString("chave"); val url = base.optString("url"); val anon = base.optString("anon")
        if (chave.length != 64 || url.isEmpty()) return false
        val estado = LocalDaFamilia.estado(this)
        thread(name = "baru-estado") {
            LocalDaFamilia.rpc(url, anon, "baru_familia_aparelho_estado", JSONObject().put("p_chave", chave).put("p_local", estado))
        }
        if (estado != "sempre") { jobFinished(params, false); return true }
        LocalDaFamilia.enviaPosicao(this, chave, url, anon, "periodico") { jobFinished(params, false) }
        return true
    }

    override fun onStopJob(params: JobParameters?): Boolean = true
}

/**
 * Celular do responsável (Android): de 15 em 15 minutos, mesmo com o Baru
 * fechado, pergunta ao banco se há aviso novo e mostra como notificação.
 */
class AvisosDaFamilia : JobService() {

    companion object {
        private const val JOB_ID = 1020
        private const val ARQUIVO = "baru_familia_avisos"
        private const val CANAL = "baru_familia_avisos"
        private const val CANAL_SOS = "baru_familia_sos"
        private val VIBRACAO_SOS = longArrayOf(0, 800, 300, 800, 300, 800, 300, 1500)

        /** Grava a chave do responsável e os textos, e agenda a conferência. `null` desliga. */
        fun configura(ctx: Context, json: String?) {
            ctx.getSharedPreferences(ARQUIVO, Context.MODE_PRIVATE).edit().putString("cfg", json).apply()
            val js = ctx.getSystemService(JobScheduler::class.java)
            if (json == null) { js.cancel(JOB_ID); return }
            pedeToken(ctx)
            if (js.getPendingJob(JOB_ID) != null) return
            js.schedule(JobInfo.Builder(JOB_ID, ComponentName(ctx, AvisosDaFamilia::class.java))
                .setPeriodic(15 * 60_000L)
                .setRequiredNetworkType(JobInfo.NETWORK_TYPE_ANY)
                .setPersisted(true)
                .build())
        }


        /** Aviso que chegou pelo push do Firebase: mostra na hora e marca como visto. */
        fun doPush(ctx: Context, dados: Map<String, String>) {
            val prefs = ctx.getSharedPreferences(ARQUIVO, Context.MODE_PRIVATE)
            val cfg = try { JSONObject(prefs.getString("cfg", null) ?: return) } catch (_: Exception) { return }
            val id = dados["id"]?.toLongOrNull() ?: return
            // Já mostrado (pela conferência periódica ou por um push repetido).
            if (id <= prefs.getLong("ultimo", -1L)) return
            val e = JSONObject()
                .put("id", id)
                .put("tipo", dados["tipo"] ?: return)
                .put("crianca", dados["crianca"] ?: "—")
                .put("detalhe", JSONObject().put("lugar", dados["lugar"] ?: ""))
            if (e.optString("tipo") == "sos") alarme(ctx, cfg, e) else mostra(ctx, cfg, e)
            prefs.edit().putLong("ultimo", id).apply()
        }

        /** SOS: o próprio Baru toca o alarme (ver [AlarmeDoSos]). */
        private fun alarme(ctx: Context, cfg: JSONObject, e: JSONObject) {
            val par = cfg.optJSONObject("textos")?.optJSONArray("sos") ?: return mostra(ctx, cfg, e)
            val crianca = e.optString("crianca", "—")
            AlarmeDoSos.toca(ctx, par.optString(0).replace("{c}", crianca), par.optString(1).replace("{c}", crianca),
                cfg.optString("canalSos", "SOS"))
        }

        /** Manda o token do Firebase deste celular para o servidor, junto da chave do responsável. */
        fun registraToken(ctx: Context, token: String?) {
            val prefs = ctx.getSharedPreferences(ARQUIVO, Context.MODE_PRIVATE)
            val cfg = try { JSONObject(prefs.getString("cfg", null) ?: return) } catch (_: Exception) { return }
            val chave = cfg.optString("chave"); val url = cfg.optString("url"); val anon = cfg.optString("anon")
            if (chave.length != 64 || token.isNullOrBlank()) return
            thread(name = "baru-token") {
                val r = LocalDaFamilia.rpc(url, anon, "baru_familia_resp_push_token", JSONObject()
                    .put("p_chave", chave).put("p_token", token).put("p_plataforma", "android")
                    .put("p_ambiente", "producao").put("p_idioma", cfg.optString("idioma", "pt")))
                android.util.Log.i("BaruPush", "token registrado: $r")
            }
        }

        private fun pedeToken(ctx: Context) {
            try {
                com.google.firebase.messaging.FirebaseMessaging.getInstance().token
                    .addOnSuccessListener { registraToken(ctx, it) }
                    .addOnFailureListener { android.util.Log.w("BaruPush", "sem token do Firebase: ${it.message}") }
            } catch (e: Exception) {
                android.util.Log.w("BaruPush", "Firebase indisponível: ${e.message}")
                // Build sem google-services.json: segue só com a conferência periódica.
            }
        }


        /**
         * Adulto que escolheu aparecer no mapa: manda a posição com o Baru
         * fechado. Precisa da localização "o tempo todo"; sem ela, não manda.
         */
        fun mandaMinhaPosicao(ctx: Context, fim: () -> Unit = {}) {
            val prefs = ctx.getSharedPreferences(ARQUIVO, Context.MODE_PRIVATE)
            val cfg = try { JSONObject(prefs.getString("cfg", null) ?: run { fim(); return }) } catch (_: Exception) { fim(); return }
            val chave = cfg.optString("chave"); val url = cfg.optString("url"); val anon = cfg.optString("anon")
            if (!cfg.optBoolean("meuLocal") || chave.length != 64 || !LocalDaFamilia.temSempre(ctx)) { fim(); return }
            LocalDaFamilia.agora(ctx) { l ->
                if (l == null) { fim(); return@agora }
                val bat = LocalDaFamilia.bateria(ctx)
                thread(name = "baru-meu-local") {
                    try {
                        LocalDaFamilia.rpc(url, anon, "baru_familia_resp_posicao", JSONObject()
                            .put("p_chave", chave).put("p_lat", l.latitude).put("p_lng", l.longitude)
                            .put("p_precisao", l.accuracy.toInt()).put("p_bateria", if (bat >= 0) bat else JSONObject.NULL))
                    } finally {
                        fim()
                    }
                }
            }
        }

        /** Confere agora (ao abrir o app) e mostra o que for novo. */
        fun confere(ctx: Context, fim: () -> Unit = {}) {
            val prefs = ctx.getSharedPreferences(ARQUIVO, Context.MODE_PRIVATE)
            val cfg = try { JSONObject(prefs.getString("cfg", null) ?: run { fim(); return }) } catch (_: Exception) { fim(); return }
            val chave = cfg.optString("chave"); val url = cfg.optString("url"); val anon = cfg.optString("anon")
            if (chave.length != 64) { fim(); return }
            val depois = prefs.getLong("ultimo", -1L)
            thread(name = "baru-avisos") {
                try {
                    val resp = LocalDaFamilia.rpc(url, anon, "baru_familia_avisos_do_responsavel",
                        JSONObject().put("p_chave", chave).put("p_depois", if (depois < 0) 0 else depois))
                    if (resp == null || resp == "null") return@thread
                    val lista = JSONArray(resp)
                    var maior = depois
                    for (i in 0 until lista.length()) {
                        val e = lista.getJSONObject(i)
                        val id = e.optLong("id")
                        if (id > maior) maior = id
                        // Na primeira vez só marca até onde já foi: não despeja o dia inteiro.
                        if (depois >= 0) { if (e.optString("tipo") == "sos") alarme(ctx, cfg, e) else mostra(ctx, cfg, e) }
                    }
                    prefs.edit().putLong("ultimo", maxOf(maior, 0L)).apply()
                } finally {
                    fim()
                }
            }
        }

        /** Vencedores do ranking semanal: o servidor já manda o texto no idioma do celular. */
        fun mostraSelo(ctx: Context, dados: Map<String, String>) {
            val titulo = dados["titulo"] ?: return
            val texto = dados["texto"] ?: return
            val prefs = ctx.getSharedPreferences(ARQUIVO, Context.MODE_PRIVATE)
            val cfg = try { JSONObject(prefs.getString("cfg", null) ?: "{}") } catch (_: Exception) { JSONObject() }
            val nm = ctx.getSystemService(NotificationManager::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                nm.createNotificationChannel(NotificationChannel(CANAL, cfg.optString("canal", "Família"),
                    NotificationManager.IMPORTANCE_HIGH))
            }
            val abre = PendingIntent.getActivity(ctx, 1,
                ctx.packageManager.getLaunchIntentForPackage(ctx.packageName)?.putExtra("baru_rota", "/familia"),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
            val n = NotificationCompat.Builder(ctx, CANAL)
                .setSmallIcon(R.drawable.ic_stat_baru)
                .setContentTitle(titulo)
                .setContentText(texto)
                .setStyle(NotificationCompat.BigTextStyle().bigText(texto))
                .setAutoCancel(true)
                .setContentIntent(abre)
                .build()
            try { nm.notify(3000 + ((dados["id"]?.toLongOrNull() ?: 0L) % 1000).toInt(), n) } catch (_: SecurityException) {}
        }

        internal fun mostra(ctx: Context, cfg: JSONObject, e: JSONObject) {
            val textos = cfg.optJSONObject("textos") ?: return
            val par = textos.optJSONArray(e.optString("tipo")) ?: return
            val crianca = e.optString("crianca", "—")
            val lugar = e.optJSONObject("detalhe")?.optString("lugar", "") ?: ""
            fun troca(s: String) = s.replace("{c}", crianca).replace("{l}", lugar)
            val nm = ctx.getSystemService(NotificationManager::class.java)
            val sos = e.optString("tipo") == "sos"
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                nm.createNotificationChannel(NotificationChannel(CANAL, cfg.optString("canal", "Família"),
                    NotificationManager.IMPORTANCE_HIGH))
                // SOS tem canal próprio: som de alarme (toca no modo vibrar e no
                // volume do alarme) e vibração longa. Canal criado uma vez; o
                // som do canal não muda depois de criado.
                if (nm.getNotificationChannel(CANAL_SOS) == null) {
                    val alarme = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                        ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                    nm.createNotificationChannel(NotificationChannel(CANAL_SOS, cfg.optString("canalSos", "SOS"),
                        NotificationManager.IMPORTANCE_HIGH).apply {
                        setSound(alarme, AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build())
                        enableVibration(true)
                        vibrationPattern = VIBRACAO_SOS
                        enableLights(true)
                        lightColor = android.graphics.Color.RED
                        lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                    })
                }
            }
            val abre = PendingIntent.getActivity(ctx, 0,
                ctx.packageManager.getLaunchIntentForPackage(ctx.packageName)?.putExtra("baru_rota", "/familia"),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
            val n = NotificationCompat.Builder(ctx, if (sos) CANAL_SOS else CANAL)
                .setSmallIcon(R.drawable.ic_stat_baru)
                .setContentTitle(troca(par.optString(0)))
                .setContentText(troca(par.optString(1)))
                .setPriority(if (sos) NotificationCompat.PRIORITY_MAX else NotificationCompat.PRIORITY_DEFAULT)
                .setCategory(if (sos) NotificationCompat.CATEGORY_ALARM else NotificationCompat.CATEGORY_STATUS)
                .setAutoCancel(true)
                .setContentIntent(abre)
                .apply {
                    if (sos) {
                        setColor(android.graphics.Color.RED)
                        setVibrate(VIBRACAO_SOS)
                        setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                    }
                }
                .build()
            // SOS insiste: o som repete até alguém abrir ou dispensar o aviso.
            if (sos) n.flags = n.flags or android.app.Notification.FLAG_INSISTENT
            try { nm.notify(2000 + (e.optLong("id") % 1000).toInt(), n) } catch (_: SecurityException) {}
        }
    }

    override fun onStartJob(params: JobParameters?): Boolean {
        // Os avisos e, se a pessoa escolheu aparecer no mapa, a posição dela.
        var faltam = 2
        val fim = { synchronized(this) { if (--faltam == 0) jobFinished(params, false) } }
        confere(this) { fim() }
        mandaMinhaPosicao(this) { fim() }
        return true
    }

    override fun onStopJob(params: JobParameters?): Boolean = true
}
