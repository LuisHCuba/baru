package com.lhcx.baru_app

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject
import java.io.File
import java.time.Instant
import java.time.ZoneId

/**
 * Os recados animados: o bicho respirando e piscando dentro da notificacao.
 *
 * **Por que nativo.** O `flutter_local_notifications` so monta notificacao
 * de modelo pronto. O bicho que se mexe precisa de `RemoteViews` com um
 * `ViewFlipper` — a mesma tecnica do widget, que o sistema anima sozinho
 * enquanto a notificacao esta na tela, sem acordar o app.
 *
 * **Quem decide o que.** O Dart decide quando, o que dizer e sobre o que
 * (`BaruNotifications._agendaAnimado`): titulo e corpo chegam traduzidos,
 * e nenhuma palavra nasce aqui. Este lado guarda o recado em disco, arma o
 * alarme inexato, e na hora monta a cena: o fundo do tema na luz da hora,
 * o bicho do tema por cima, e o texto.
 *
 * **Sem cena, sem drama.** Sem os quadros gravados (antes da primeira saida
 * do app, ou com o disco cheio), o recado sai como notificacao comum, com o
 * rosto do bicho — o mesmo que o plugin mandaria.
 */
object RecadoAnimado {

    private const val ARQUIVO = "baru_recados_animados"
    const val ACAO_TOCA = "tech.lhcx.baru.RECADO_TOCA"
    const val EXTRA_ID = "baru_recado_id"

    /** Depois disto, o recado atrasado nao sai: avisa tarde, ensina a ignorar. */
    private const val ATRASO_MAXIMO_MS = 2 * 60 * 60 * 1000L

    /** Quanto cada quadro fica na tela. Com a fusao, a respiracao sai continua. */
    private const val INTERVALO_MS = 260

    /** A ordem dos quadros: o peito sobe e desce duas vezes; na segunda, pisca. */
    private const val PISCA = -1
    private val SEQUENCIA = intArrayOf(0, 1, 2, 3, 2, 1, 0, 1, 2, PISCA, 2, 1)

    data class Recado(
        val id: Int,
        val quando: Long,
        val canal: String,
        val titulo: String,
        val corpo: String,
        val tema: String,
        val rota: String,
        val rosto: String,
        val alta: Boolean,
    ) {
        fun json(): String = JSONObject()
            .put("id", id).put("quando", quando).put("canal", canal)
            .put("titulo", titulo).put("corpo", corpo).put("tema", tema)
            .put("rota", rota).put("rosto", rosto).put("alta", alta)
            .toString()

        companion object {
            fun de(json: String?): Recado? = try {
                val o = JSONObject(json ?: return null)
                Recado(
                    id = o.getInt("id"),
                    quando = o.getLong("quando"),
                    canal = o.getString("canal"),
                    titulo = o.optString("titulo"),
                    corpo = o.optString("corpo"),
                    tema = o.optString("tema"),
                    rota = o.optString("rota"),
                    rosto = o.optString("rosto"),
                    alta = o.optBoolean("alta"),
                )
            } catch (_: Exception) {
                null
            }
        }
    }

    private fun prefs(ctx: Context) =
        ctx.getSharedPreferences(ARQUIVO, Context.MODE_PRIVATE)

    /** Manha ate 12h, tarde ate 18h, noite depois. Espelho de `luzDa` (Dart). */
    fun luzDa(hora: Int): String = when (hora) {
        in 5..11 -> "manha"
        in 12..17 -> "tarde"
        else -> "noite"
    }

    fun agenda(ctx: Context, r: Recado): Boolean {
        prefs(ctx).edit().putString(r.id.toString(), r.json()).apply()
        return arma(ctx, r)
    }

    fun cancela(ctx: Context, id: Int) {
        prefs(ctx).edit().remove(id.toString()).apply()
        alarmes(ctx)?.cancel(alarme(ctx, id))
        NotificationManagerCompat.from(ctx).cancel(id)
    }

    /** Depois de religar o aparelho os alarmes somem; os recados, nao. */
    fun rearmaTodos(ctx: Context) {
        val agora = System.currentTimeMillis()
        val p = prefs(ctx)
        for ((chave, valor) in p.all) {
            val r = Recado.de(valor as? String)
            if (r == null || r.quando < agora) {
                p.edit().remove(chave).apply()
                continue
            }
            arma(ctx, r)
        }
    }

    /** O mesmo modo do plugin (`inexactAllowWhileIdle`): pode tocar em repouso. */
    private fun arma(ctx: Context, r: Recado): Boolean {
        val am = alarmes(ctx) ?: return false
        return try {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, r.quando, alarme(ctx, r.id))
            true
        } catch (e: Exception) {
            Log.w(VigiaDaSessao.TAG_LOG, "recado: alarme recusado", e)
            false
        }
    }

    private fun alarmes(ctx: Context) =
        ctx.getSystemService(Context.ALARM_SERVICE) as? AlarmManager

    private fun alarme(ctx: Context, id: Int): PendingIntent = PendingIntent.getBroadcast(
        ctx,
        id,
        Intent(ctx, RecadoAnimadoReceiver::class.java).apply {
            action = ACAO_TOCA
            putExtra(EXTRA_ID, id)
        },
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    /** O alarme tocou: posta, se ainda fizer sentido. */
    fun toca(ctx: Context, id: Int) {
        val p = prefs(ctx)
        val r = Recado.de(p.getString(id.toString(), null)) ?: return
        p.edit().remove(id.toString()).apply()
        if (System.currentTimeMillis() - r.quando > ATRASO_MAXIMO_MS) return
        posta(ctx, r)
    }

    private fun podeNotificar(ctx: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(ctx, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return false
        }
        return NotificationManagerCompat.from(ctx).areNotificationsEnabled()
    }

    fun posta(ctx: Context, r: Recado) {
        if (!podeNotificar(ctx)) return
        garanteCanal(ctx, r)

        val abre = PendingIntent.getActivity(
            ctx,
            r.id,
            Intent(ctx, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra(MainActivity.EXTRA_ROTA_DA_BARRA, r.rota)
            },
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        val b = NotificationCompat.Builder(ctx, r.canal)
            .setSmallIcon(R.drawable.ic_stat_baru)
            .setColor(0xFF4B7343.toInt())
            // Titulo e corpo tambem no modelo padrao: e o que o leitor de
            // tela le, o que o relogio mostra e o que aparece se o sistema
            // nao desenhar a vista propria.
            .setContentTitle(r.titulo)
            .setContentText(r.corpo)
            .setContentIntent(abre)
            .setAutoCancel(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setPriority(
                if (r.alta) NotificationCompat.PRIORITY_HIGH else NotificationCompat.PRIORITY_DEFAULT,
            )

        val densidade = ctx.resources.displayMetrics.density
        val luz = luzDa(Instant.ofEpochMilli(System.currentTimeMillis())
            .atZone(ZoneId.systemDefault()).hour)
        val cena = CenasDosRecados.carrega(ctx, r.tema, luz, Int.MAX_VALUE)

        if (cena == null) {
            rosto(r.rosto)?.let { b.setLargeIcon(it) }
            b.setStyle(NotificationCompat.BigTextStyle().bigText(r.corpo))
        } else {
            // **O teto do Binder.** A notificacao inteira atravessa para o
            // sistema numa transacao de ~1 MB, com cada bitmap descomprimido.
            // Por isso: quadros pequenos na vista curta (no maximo 84 px), o
            // fundo sem canal alfa (2 bytes por pixel), e nenhuma vista
            // propria para o heads-up — sem ela o sistema usa a curta, em vez
            // de mandar a mesma vista duas vezes.
            val alturaCurta = (40 * densidade).toInt().coerceIn(32, 84)
            b.setStyle(NotificationCompat.DecoratedCustomViewStyle())
                .setCustomContentView(vistaCurta(ctx, r, cena, alturaCurta))
                .setCustomBigContentView(vistaGrande(ctx, r, cena))
        }

        try {
            NotificationManagerCompat.from(ctx).notify(r.id, b.build())
        } catch (e: Exception) {
            // Vista grande demais para o Binder, ou permissao tirada no meio:
            // tenta a forma comum antes de desistir.
            Log.w(VigiaDaSessao.TAG_LOG, "recado: vista animada recusada", e)
            try {
                val simples = NotificationCompat.Builder(ctx, r.canal)
                    .setSmallIcon(R.drawable.ic_stat_baru)
                    .setColor(0xFF4B7343.toInt())
                    .setContentTitle(r.titulo)
                    .setContentText(r.corpo)
                    .setStyle(NotificationCompat.BigTextStyle().bigText(r.corpo))
                    .setContentIntent(abre)
                    .setAutoCancel(true)
                    .build()
                NotificationManagerCompat.from(ctx).notify(r.id, simples)
            } catch (_: Exception) {
            }
        }
    }

    /** O bicho num `ViewFlipper`: o sistema troca os quadros sozinho. */
    private fun bichoAnimado(
        ctx: Context,
        vista: RemoteViews,
        idDoFlipper: Int,
        cena: CenasDosRecados.Cena,
        alturaPx: Int,
    ) {
        val quadros = cena.respiro.map { escala(it, alturaPx) }
        val pisca = escala(cena.pisca, alturaPx)
        vista.removeAllViews(idDoFlipper)
        for (i in SEQUENCIA) {
            val q = RemoteViews(ctx.packageName, R.layout.baru_recado_quadro)
            // O mesmo `Bitmap` em varios quadros: o `RemoteViews` guarda uma
            // copia so de cada um.
            q.setImageViewBitmap(
                R.id.baru_recado_quadro,
                if (i == PISCA) pisca else quadros[i.coerceAtMost(quadros.size - 1)],
            )
            vista.addView(idDoFlipper, q)
        }
        vista.setInt(idDoFlipper, "setFlipInterval", INTERVALO_MS)
    }

    private fun vistaCurta(
        ctx: Context,
        r: Recado,
        cena: CenasDosRecados.Cena,
        alturaPx: Int,
    ): RemoteViews {
        val v = RemoteViews(ctx.packageName, R.layout.baru_recado_curto)
        v.setTextViewText(R.id.baru_recado_titulo, r.titulo)
        v.setTextViewText(R.id.baru_recado_corpo, r.corpo)
        bichoAnimado(ctx, v, R.id.baru_recado_bicho, cena, alturaPx)
        return v
    }

    private fun vistaGrande(ctx: Context, r: Recado, cena: CenasDosRecados.Cena): RemoteViews {
        val v = RemoteViews(ctx.packageName, R.layout.baru_recado_grande)
        v.setTextViewText(R.id.baru_recado_titulo, r.titulo)
        v.setTextViewText(R.id.baru_recado_corpo, r.corpo)
        cena.fundo?.let {
            v.setImageViewBitmap(R.id.baru_recado_fundo, it.copy(Bitmap.Config.RGB_565, false) ?: it)
        }
        bichoAnimado(ctx, v, R.id.baru_recado_bicho, cena, cena.respiro.first().height)
        return v
    }

    private fun escala(b: Bitmap, alturaPx: Int): Bitmap {
        if (b.height <= alturaPx) return b
        val largura = (b.width * alturaPx.toFloat() / b.height).toInt().coerceAtLeast(1)
        return Bitmap.createScaledBitmap(b, largura, alturaPx, true)
    }

    private fun rosto(caminho: String): Bitmap? =
        if (caminho.isEmpty() || !File(caminho).isFile) null else BitmapFactory.decodeFile(caminho)

    /**
     * O canal ja existe quase sempre — o Dart cria todos no arranque, com
     * nome traduzido e importancia. Este ramo cobre a notificacao que toca
     * antes disso (reinstalacao com recado guardado): o nome de reserva e o
     * rotulo do app, nao frase escrita aqui.
     */
    private fun garanteCanal(ctx: Context, r: Recado) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(r.canal) != null) return
        nm.createNotificationChannel(
            NotificationChannel(
                r.canal,
                ctx.applicationInfo.loadLabel(ctx.packageManager),
                if (r.alta) NotificationManager.IMPORTANCE_HIGH else NotificationManager.IMPORTANCE_DEFAULT,
            ),
        )
    }
}

/** O alarme do recado e a volta do aparelho ligado. */
class RecadoAnimadoReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            RecadoAnimado.ACAO_TOCA ->
                RecadoAnimado.toca(context, intent.getIntExtra(RecadoAnimado.EXTRA_ID, -1))

            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            -> RecadoAnimado.rearmaTodos(context)
        }
    }
}
