package com.lhcx.baru_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import androidx.core.app.NotificationCompat

/**
 * SOS no celular do responsável: o próprio Baru toca o alarme, em loop, no
 * volume máximo do alarme, com vibração, até a pessoa tocar em "Parar" ou
 * abrir o app (ou 2 minutos). Não depende do som da notificação, que alguns
 * celulares (Samsung) calam no modo vibrar.
 *
 * Serviço em primeiro plano do tipo "shortService" (Android 14+): pode começar
 * a partir de um push de prioridade alta e dura no máximo 3 minutos.
 */
class AlarmeDoSos : Service() {

    companion object {
        private const val CANAL = "baru_familia_sos_alarme"
        /** Aviso que aparece por cima da tela (heads-up) e fica depois do som parar. */
        private const val CANAL_AVISO = "baru_familia_sos_aviso"
        private const val NOTIF = 2999
        private const val NOTIF_AVISO = 2998
        private const val PARAR = "tech.lhcx.baru.PARAR_SOS"
        private const val DURACAO_MS = 120_000L

        fun toca(ctx: Context, titulo: String, texto: String, nomeDoCanal: String) {
            val i = Intent(ctx, AlarmeDoSos::class.java)
                .putExtra("titulo", titulo).putExtra("texto", texto).putExtra("canal", nomeDoCanal)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) ctx.startForegroundService(i) else ctx.startService(i)
            } catch (e: Exception) {
                android.util.Log.w("BaruPush", "alarme do SOS não começou: ${e.message}")
            }
        }

        fun para(ctx: Context) {
            try { ctx.startService(Intent(ctx, AlarmeDoSos::class.java).setAction(PARAR)) } catch (_: Exception) {}
        }
    }

    private var toque: Ringtone? = null
    private var volumeAntes = -1
    private val relogio = Handler(Looper.getMainLooper())

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == PARAR) { encerra(); return START_NOT_STICKY }
        val titulo = intent?.getStringExtra("titulo") ?: "SOS"
        val texto = intent?.getStringExtra("texto") ?: ""
        val nm = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && nm.getNotificationChannel(CANAL) == null) {
            // Canal sem som: quem toca é o próprio serviço.
            nm.createNotificationChannel(NotificationChannel(CANAL, intent?.getStringExtra("canal") ?: "SOS",
                NotificationManager.IMPORTANCE_HIGH).apply {
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            })
        }
        val abre = PendingIntent.getActivity(this, 1,
            packageManager.getLaunchIntentForPackage(packageName)?.putExtra("baru_rota", "/familia"),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val parar = PendingIntent.getService(this, 2, Intent(this, AlarmeDoSos::class.java).setAction(PARAR),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val n = NotificationCompat.Builder(this, CANAL)
            .setSmallIcon(R.drawable.ic_stat_baru)
            .setContentTitle(titulo)
            .setContentText(texto)
            .setColor(android.graphics.Color.RED)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setContentIntent(abre)
            .setDeleteIntent(parar)
            .addAction(0, "Parar", parar)
            .build()
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(NOTIF, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SHORT_SERVICE)
        } else {
            startForeground(NOTIF, n)
        }
        // O aviso do serviço o Samsung esconde em "em andamento". Este aqui é o
        // que a pessoa vê: por cima da tela, na tela de bloqueio, e fica depois
        // que o som para, para ela saber o que aconteceu.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && nm.getNotificationChannel(CANAL_AVISO) == null) {
            nm.createNotificationChannel(NotificationChannel(CANAL_AVISO, intent?.getStringExtra("canal") ?: "SOS",
                NotificationManager.IMPORTANCE_HIGH).apply {
                setSound(null, null) // o som é o do alarme, tocado pelo serviço
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 300)
                enableLights(true)
                lightColor = android.graphics.Color.RED
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            })
        }
        val aviso = NotificationCompat.Builder(this, CANAL_AVISO)
            .setSmallIcon(R.drawable.ic_stat_baru)
            .setContentTitle(titulo)
            .setContentText(texto)
            .setStyle(NotificationCompat.BigTextStyle().bigText(texto))
            .setColor(android.graphics.Color.RED)
            .setColorized(true)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setWhen(System.currentTimeMillis())
            .setShowWhen(true)
            .setAutoCancel(true)
            .setContentIntent(abre)
            // Sem a permissão de tela cheia, o Android mostra por cima da tela (heads-up).
            .setFullScreenIntent(abre, true)
            .addAction(0, "Ver onde está", abre)
            .addAction(0, "Parar alarme", parar)
            .build()
        try { nm.notify(NOTIF_AVISO, aviso) } catch (_: SecurityException) {}
        toca()
        relogio.removeCallbacksAndMessages(null)
        relogio.postDelayed({ encerra() }, DURACAO_MS)
        return START_NOT_STICKY
    }

    private fun toca() {
        if (toque?.isPlaying == true) return
        val audio = getSystemService(AudioManager::class.java)
        // Volume do alarme no máximo enquanto toca; volta ao normal no fim.
        if (volumeAntes < 0) volumeAntes = audio.getStreamVolume(AudioManager.STREAM_ALARM)
        try { audio.setStreamVolume(AudioManager.STREAM_ALARM, audio.getStreamMaxVolume(AudioManager.STREAM_ALARM), 0) } catch (_: Exception) {}
        val som = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
        toque = RingtoneManager.getRingtone(this, som)?.apply {
            audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) isLooping = true
            play()
        }
        val v = getSystemService(Vibrator::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            v?.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 800, 400, 800, 400, 1500, 600), 0))
        }
    }

    private fun encerra() {
        relogio.removeCallbacksAndMessages(null)
        toque?.stop(); toque = null
        getSystemService(Vibrator::class.java)?.cancel()
        if (volumeAntes >= 0) {
            try { getSystemService(AudioManager::class.java).setStreamVolume(AudioManager.STREAM_ALARM, volumeAntes, 0) } catch (_: Exception) {}
            volumeAntes = -1
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) stopForeground(STOP_FOREGROUND_REMOVE) else @Suppress("DEPRECATION") stopForeground(true)
        stopSelf()
    }

    /** Android 14+: o shortService passou do tempo. */
    override fun onTimeout(startId: Int) { encerra() }

    override fun onDestroy() {
        toque?.stop()
        getSystemService(Vibrator::class.java)?.cancel()
        super.onDestroy()
    }
}
