package com.lhcx.baru_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.telecom.TelecomManager
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.Calendar
import kotlin.concurrent.thread

/**
 * As regras da família no celular da criança (Android).
 *
 * O Dart grava aqui o que o responsável definiu (horários sem tela, pausa,
 * meta de hoje, pausar ao estourar) e os textos já traduzidos. O serviço lê
 * daqui, inclusive depois de o celular reiniciar, sem o Flutter junto.
 */
object RegrasDaFamilia {
    private const val ARQUIVO = "baru_familia"
    private const val K_JSON = "regras"

    data class Regras(
        val horarios: List<Horario>,
        val pausaAte: Long,
        val metaMin: Int,
        val pausarAoEstourar: Boolean,
        val titulo: String,
        val corpoPausa: String,
        val corpoHorario: String,
        val corpoMeta: String,
        val botao: String,
        val notifTitulo: String,
        val notifCorpo: String,
        val localizacao: Boolean = false,
        val localPedidoMs: Long = 0L,
        val notifCorpoLocal: String = "",
    )

    data class Horario(val dias: Set<Int>, val inicio: Int, val fim: Int)

    fun grava(ctx: Context, json: String?) {
        ctx.getSharedPreferences(ARQUIVO, Context.MODE_PRIVATE).edit().putString(K_JSON, json).apply()
    }

    fun texto(ctx: Context): String? =
        ctx.getSharedPreferences(ARQUIVO, Context.MODE_PRIVATE).getString(K_JSON, null)

    fun le(ctx: Context): Regras? {
        val texto = ctx.getSharedPreferences(ARQUIVO, Context.MODE_PRIVATE).getString(K_JSON, null) ?: return null
        return try {
            val o = JSONObject(texto)
            val hs = o.optJSONArray("horarios") ?: JSONArray()
            Regras(
                horarios = (0 until hs.length()).mapNotNull { i ->
                    val h = hs.optJSONObject(i) ?: return@mapNotNull null
                    val ds = h.optJSONArray("dias") ?: JSONArray()
                    Horario(
                        dias = (0 until ds.length()).map { ds.optInt(it) }.toSet(),
                        inicio = minutos(h.optString("inicio")),
                        fim = minutos(h.optString("fim")),
                    )
                },
                pausaAte = o.optLong("pausaAteMs", 0L),
                metaMin = o.optInt("metaMin", 0),
                pausarAoEstourar = o.optBoolean("pausarAoEstourar", false),
                titulo = o.optString("titulo", "Hora de uma pausa"),
                corpoPausa = o.optString("corpoPausa"),
                corpoHorario = o.optString("corpoHorario"),
                corpoMeta = o.optString("corpoMeta"),
                botao = o.optString("botao", "Abrir o Baru"),
                notifTitulo = o.optString("notifTitulo", "Baru"),
                notifCorpo = o.optString("notifCorpo"),
                localizacao = o.optBoolean("localizacao", false),
                localPedidoMs = o.optLong("localPedidoMs", 0L),
                notifCorpoLocal = o.optString("notifCorpoLocal"),
            )
        } catch (e: Exception) {
            null
        }
    }

    private fun minutos(hhmm: String): Int {
        val p = hhmm.split(":")
        return (p.getOrNull(0)?.toIntOrNull() ?: 0) * 60 + (p.getOrNull(1)?.toIntOrNull() ?: 0)
    }

    /** Dia ISO (1 = segunda … 7 = domingo). */
    fun diaIso(c: Calendar): Int {
        val w = c.get(Calendar.DAY_OF_WEEK) // 1 = domingo
        return if (w == Calendar.SUNDAY) 7 else w - 1
    }

    /** Algum horário vale agora? Faixa que vira a meia-noite conta o dia em que começou. */
    fun horarioAgora(r: Regras, agora: Calendar = Calendar.getInstance()): Boolean {
        val m = agora.get(Calendar.HOUR_OF_DAY) * 60 + agora.get(Calendar.MINUTE)
        val hoje = diaIso(agora)
        val ontem = if (hoje == 1) 7 else hoje - 1
        return r.horarios.any { h ->
            if (h.inicio <= h.fim) hoje in h.dias && m >= h.inicio && m < h.fim
            else (m >= h.inicio && hoje in h.dias) || (m < h.fim && ontem in h.dias)
        }
    }
}

/**
 * O guarda: de três em três segundos olha qual app está na frente e, se a
 * tela deveria estar parada, cobre com o aviso do Baru. Ficam livres o
 * próprio Baru, a tela inicial e o telefone (para ligar em emergência).
 */
class GuardaDaFamilia : Service() {

    companion object {
        const val ACAO_LIGA = "com.lhcx.baru_app.familia.LIGA"
        const val ACAO_DESLIGA = "com.lhcx.baru_app.familia.DESLIGA"
        private const val CANAL = "baru_familia"
        private const val NOTIF_ID = 1010
        private const val PASSO_MS = 3_000L
        private const val USO_A_CADA_MS = 60_000L
        private const val REGRAS_A_CADA_MS = 120_000L
        /** Com a localização ligada, o pedido "onde está agora?" chega em até 1 minuto. */
        private const val REGRAS_COM_LOCAL_MS = 60_000L
        private const val POSICAO_A_CADA_MS = 10 * 60_000L

        fun liga(ctx: Context) {
            ContextCompat.startForegroundService(ctx, Intent(ctx, GuardaDaFamilia::class.java).setAction(ACAO_LIGA))
        }

        fun desliga(ctx: Context) {
            ctx.startService(Intent(ctx, GuardaDaFamilia::class.java).setAction(ACAO_DESLIGA))
        }
    }

    private val mao = Handler(Looper.getMainLooper())
    private var capa: View? = null
    private var usoHojeMin = 0
    private var ultimoUso = 0L
    private var ultimaBusca = 0L
    @Volatile private var buscando = false
    private var livres: Set<String> = emptySet()
    private var ultimaPosicao = 0L
    private var pedidoAtendido = 0L
    @Volatile private var localizando = false
    private var barraComLocal: Boolean? = null

    private val volta = object : Runnable {
        override fun run() {
            confere()
            mao.postDelayed(this, PASSO_MS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACAO_DESLIGA || RegrasDaFamilia.le(this) == null) {
            tiraCapa()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }
        sobeNaBarra()
        // Posição também com a tela apagada (o laço abaixo para no Doze).
        PosicaoDaFamilia.agenda(this, RegrasDaFamilia.le(this)?.localizacao == true)
        livres = appsLivres()
        // Regras novas (ou a chave do aparelho) acabaram de chegar: consulta já.
        ultimaBusca = 0L
        mao.removeCallbacks(volta)
        mao.post(volta)
        return START_STICKY
    }

    override fun onDestroy() {
        mao.removeCallbacks(volta)
        tiraCapa()
        super.onDestroy()
    }

    private fun sobeNaBarra() {
        val r = RegrasDaFamilia.le(this)
        val nm = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(NotificationChannel(CANAL, r?.notifTitulo ?: "Baru", NotificationManager.IMPORTANCE_MIN))
        }
        val abre = PendingIntent.getActivity(
            this, 0, packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        // Localização ligada: a criança sempre vê, na barra, que a família vê onde ela está.
        val comLocal = r?.localizacao == true && LocalDaFamilia.temPermissao(this)
        barraComLocal = comLocal
        val corpo = if (r?.localizacao == true && !r.notifCorpoLocal.isNullOrEmpty()) r.notifCorpoLocal else r?.notifCorpo ?: ""
        val n: Notification = NotificationCompat.Builder(this, CANAL)
            .setSmallIcon(R.drawable.ic_stat_baru)
            .setContentTitle(r?.notifTitulo ?: "Baru")
            .setContentText(corpo)
            .setStyle(NotificationCompat.BigTextStyle().bigText(corpo))
            .setOngoing(true)
            .setSilent(true)
            .setContentIntent(abre)
            .build()
        if (Build.VERSION.SDK_INT >= 34) {
            val tipo = android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE or
                (if (comLocal) android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION else 0)
            try {
                startForeground(NOTIF_ID, n, tipo)
            } catch (_: Exception) {
                // Sem a permissão "o tempo todo", o Android não deixa o tipo localização
                // num serviço que voltou sozinho (depois de reiniciar): segue sem ele.
                startForeground(NOTIF_ID, n, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
            }
        } else if (Build.VERSION.SDK_INT >= 29) {
            startForeground(NOTIF_ID, n, if (comLocal) android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION else 0)
        } else {
            startForeground(NOTIF_ID, n)
        }
    }

    private fun appsLivres(): Set<String> {
        val s = mutableSetOf(packageName, "com.android.systemui")
        val casa = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        packageManager.queryIntentActivities(casa, 0).forEach { s.add(it.activityInfo.packageName) }
        try {
            (getSystemService(TELECOM_SERVICE) as? TelecomManager)?.defaultDialerPackage?.let { s.add(it) }
        } catch (_: SecurityException) {
        }
        return s
    }

    private fun confere() {
        val r = RegrasDaFamilia.le(this) ?: run { tiraCapa(); return }
        val agora = System.currentTimeMillis()
        if (agora - ultimaBusca > (if (r.localizacao) REGRAS_COM_LOCAL_MS else REGRAS_A_CADA_MS)) {
            ultimaBusca = agora
            buscaRegras()
        }
        localiza(r, agora)
        if (barraComLocal != (r.localizacao && LocalDaFamilia.temPermissao(this))) sobeNaBarra()
        if (agora - ultimoUso > USO_A_CADA_MS) {
            usoHojeMin = usoDeHoje()
            ultimoUso = agora
        }
        val motivo = when {
            r.pausaAte > agora -> r.corpoPausa
            RegrasDaFamilia.horarioAgora(r) -> r.corpoHorario
            r.pausarAoEstourar && r.metaMin > 0 && usoHojeMin >= r.metaMin -> r.corpoMeta
            else -> null
        }
        val frente = appNaFrente()
        if (motivo != null && frente != null && frente !in livres) poeCapa(r, motivo) else tiraCapa()
    }

    /** Manda a posição de tempos em tempos e quando o responsável pede. */
    private fun localiza(r: RegrasDaFamilia.Regras, agora: Long) {
        if (!r.localizacao || localizando || !LocalDaFamilia.temPermissao(this)) return
        val pedido = r.localPedidoMs > pedidoAtendido && agora - r.localPedidoMs < 10 * 60_000L
        if (!pedido && agora - ultimaPosicao < POSICAO_A_CADA_MS) return
        val base = try { JSONObject(RegrasDaFamilia.texto(this) ?: return) } catch (_: Exception) { return }
        val chave = base.optString("chave"); val url = base.optString("url"); val anon = base.optString("anon")
        if (chave.length != 64) return
        localizando = true
        ultimaPosicao = agora
        if (pedido) pedidoAtendido = r.localPedidoMs
        LocalDaFamilia.enviaPosicao(this, chave, url, anon, if (pedido) "pedido" else "periodico") { localizando = false }
    }

    /**
     * O responsável pode pausar ou mudar as regras com o Baru fechado neste
     * celular. De dois em dois minutos o guarda pergunta ao banco, com a
     * chave do aparelho (não com o login, que expira). Sem rede, mantém o
     * que já tinha; família desfeita (resposta `null`), desliga.
     */
    private fun buscaRegras() {
        if (buscando) return
        val atual = RegrasDaFamilia.texto(this) ?: return
        val base = try { JSONObject(atual) } catch (_: Exception) { return }
        val chave = base.optString("chave")
        val url = base.optString("url")
        val anon = base.optString("anon")
        if (chave.length != 64 || url.isEmpty() || anon.isEmpty()) return
        buscando = true
        thread(name = "baru-familia") {
            try {
                val c = URL("$url/rest/v1/rpc/baru_familia_regras_do_aparelho").openConnection() as HttpURLConnection
                c.requestMethod = "POST"
                c.connectTimeout = 10_000
                c.readTimeout = 10_000
                c.doOutput = true
                c.setRequestProperty("Content-Type", "application/json")
                c.setRequestProperty("apikey", anon)
                c.setRequestProperty("Authorization", "Bearer $anon")
                c.outputStream.use { it.write(JSONObject().put("p_chave", chave).toString().toByteArray()) }
                if (c.responseCode != 200) return@thread
                val corpo = c.inputStream.bufferedReader().use { it.readText() }.trim()
                mao.post { aplicaDoBanco(base, corpo) }
            } catch (_: Exception) {
            } finally {
                buscando = false
            }
        }
    }

    private fun aplicaDoBanco(base: JSONObject, corpo: String) {
        if (corpo == "null") {
            RegrasDaFamilia.grava(this, null)
            tiraCapa()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return
        }
        val r = try { JSONObject(corpo) } catch (_: Exception) { return }
        val pausa = r.optString("pausa_ate", "")
        // O banco devolve em UTC ("2026-11-19T03:11:44.02+00:00"): os 19
        // primeiros caracteres bastam, em qualquer versão do Android.
        val pausaMs = if (pausa.length < 19 || pausa == "null") 0L else try {
            java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", java.util.Locale.US).apply {
                timeZone = java.util.TimeZone.getTimeZone("UTC")
            }.parse(pausa.substring(0, 19))?.time ?: 0L
        } catch (_: Exception) { 0L }
        base.put("horarios", r.optJSONArray("horarios_sem_tela") ?: JSONArray())
        base.put("pausaAteMs", pausaMs)
        base.put("metaMin", r.optInt("meta_hoje", r.optInt("meta_min", 0)))
        base.put("pausarAoEstourar", r.optBoolean("pausar_ao_estourar", false))
        base.put("localizacao", r.optBoolean("localizacao", false))
        base.put("localPedidoMs", utcMs(r.optString("local_pedido_em", "")))
        RegrasDaFamilia.grava(this, base.toString())
        confere()
    }

    private fun utcMs(s: String): Long = if (s.length < 19 || s == "null") 0L else try {
        java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", java.util.Locale.US).apply {
            timeZone = java.util.TimeZone.getTimeZone("UTC")
        }.parse(s.substring(0, 19))?.time ?: 0L
    } catch (_: Exception) { 0L }

    private fun appNaFrente(): String? {
        val uso = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val agora = System.currentTimeMillis()
        val eventos = uso.queryEvents(agora - 5 * 60_000, agora)
        val e = UsageEvents.Event()
        var ultimo: String? = null
        while (eventos.hasNextEvent()) {
            eventos.getNextEvent(e)
            if (e.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND || e.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                ultimo = e.packageName
            }
        }
        return ultimo
    }

    /** Minutos de tela hoje, sem o Baru e sem a tela inicial. */
    private fun usoDeHoje(): Int {
        val uso = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val inicio = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        val total = uso.queryAndAggregateUsageStats(inicio, System.currentTimeMillis())
            .filterKeys { it !in livres }
            .values.sumOf { it.totalTimeInForeground }
        return (total / 60_000).toInt()
    }

    private fun dp(v: Float) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v, resources.displayMetrics)

    private fun poeCapa(r: RegrasDaFamilia.Regras, motivo: String) {
        if (capa != null) {
            (capa?.findViewWithTag<TextView>("corpo"))?.text = motivo
            return
        }
        if (!Settings.canDrawOverlays(this)) return
        val wm = getSystemService(WINDOW_SERVICE) as WindowManager
        val caixa = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#FBF6EC"))
            val p = dp(32f).toInt()
            setPadding(p, p, p, p)
            isClickable = true
        }
        caixa.addView(TextView(this).apply {
            text = r.titulo
            setTextColor(Color.parseColor("#3D332A"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 28f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        })
        caixa.addView(TextView(this).apply {
            tag = "corpo"
            text = motivo
            setTextColor(Color.parseColor("#66594D"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            gravity = Gravity.CENTER
            setPadding(0, dp(12f).toInt(), 0, dp(28f).toInt())
        })
        caixa.addView(Button(this).apply {
            text = r.botao
            isAllCaps = false
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            background = GradientDrawable().apply {
                cornerRadius = dp(28f)
                setColor(Color.parseColor("#428130"))
            }
            val p = dp(16f).toInt()
            setPadding(p * 2, p, p * 2, p)
            setOnClickListener {
                packageManager.getLaunchIntentForPackage(packageName)?.let {
                    startActivity(it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                }
            }
        })
        val tipo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE
        val lp = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT, tipo,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN, PixelFormat.OPAQUE,
        )
        try {
            wm.addView(caixa, lp)
            capa = caixa
        } catch (_: Exception) {
        }
    }

    private fun tiraCapa() {
        val v = capa ?: return
        try {
            (getSystemService(WINDOW_SERVICE) as WindowManager).removeView(v)
        } catch (_: Exception) {
        }
        capa = null
    }
}

/** Depois de reiniciar o celular, o guarda volta se a criança está numa família. */
class GuardaNoBoot : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        if (RegrasDaFamilia.le(ctx) != null) {
            try {
                GuardaDaFamilia.liga(ctx)
            } catch (_: Exception) {
            }
        }
    }
}
