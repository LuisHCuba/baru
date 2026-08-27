package com.lhcx.baru_app

import android.animation.ValueAnimator
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.RectF
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.animation.OvershootInterpolator
import kotlin.math.min

/**
 * O companheiro por cima dos outros apps.
 *
 * É um `TYPE_APPLICATION_OVERLAY` desenhado por `WindowManager` — o único
 * jeito de aparecer sobre outro app no Android. Três coisas guiam o desenho:
 *
 * 1. **Nunca bloqueia.** A janela é `WRAP_CONTENT` num canto e não pega o
 *    toque fora dela (`FLAG_NOT_TOUCH_MODAL`): quem quiser continuar no outro
 *    app continua. Um overlay que trava a tela é malware, não companhia.
 * 2. **Some sozinho.** Sem interação, sai em [SEGUNDOS_ATE_SUMIR].
 * 3. **Sem culpa.** A fala vem do Dart já traduzida; este arquivo não escreve
 *    texto de produto nenhum.
 */
class OverlayDoBaru : Service() {

    companion object {
        const val EXTRA_FALA = "fala"
        const val EXTRA_PELO = "pelo"
        const val EXTRA_ESPECIE = "especie"
        const val EXTRA_ACAO_FECHAR = "acaoFechar"
        const val EXTRA_ACAO_MAIS = "acaoMais"
        const val ACAO_MOSTRAR = "com.lhcx.baru_app.MOSTRAR_OVERLAY"
        const val ACAO_ESCONDER = "com.lhcx.baru_app.ESCONDER_OVERLAY"

        /** Tempo até sumir sozinho. Um lembrete que fica é um estorvo. */
        const val SEGUNDOS_ATE_SUMIR = 12L

        fun temPermissao(ctx: Context): Boolean =
            Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                Settings.canDrawOverlays(ctx)

        fun intentDePermissao(ctx: Context): Intent =
            Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:${ctx.packageName}"),
            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }

    private var janela: WindowManager? = null
    private var vista: View? = null
    private val sumir = Runnable { esconde() }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACAO_ESCONDER -> esconde()
            else -> mostra(intent)
        }
        return START_NOT_STICKY
    }

    private fun mostra(intent: Intent?) {
        if (!temPermissao(this)) {
            stopSelf()
            return
        }
        esconde()

        val fala = intent?.getStringExtra(EXTRA_FALA).orEmpty()
        val pelo = intent?.getIntExtra(EXTRA_PELO, 0xFFB07A4E.toInt())
            ?: 0xFFB07A4E.toInt()
        val especie = intent?.getStringExtra(EXTRA_ESPECIE) ?: "capybara"
        val rotuloFechar = intent?.getStringExtra(EXTRA_ACAO_FECHAR).orEmpty()
        val rotuloMais = intent?.getStringExtra(EXTRA_ACAO_MAIS).orEmpty()

        val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val v = BalaoDoBaru(
            this,
            fala = fala,
            pelo = pelo,
            especie = especie,
            rotuloFechar = rotuloFechar,
            rotuloMais = rotuloMais,
            aoFechar = {
                esconde()
                // Manda o usuário para a home do sistema: sair do app que o
                // prendeu é o pedido, e não temos como fechá-lo.
                startActivity(
                    Intent(Intent.ACTION_MAIN)
                        .addCategory(Intent.CATEGORY_HOME)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
            },
            aoAdiar = { esconde() },
        )

        val tipo =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }

        val lp = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            tipo,
            // NOT_FOCUSABLE + NOT_TOUCH_MODAL: o toque fora do balão continua
            // indo para o app de baixo. Sem isto, o overlay sequestra a tela.
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.BOTTOM or Gravity.END
            x = dp(12)
            y = dp(96)
        }

        wm.addView(v, lp)
        janela = wm
        vista = v
        v.entra()
        v.postDelayed(sumir, SEGUNDOS_ATE_SUMIR * 1000)
    }

    private fun esconde() {
        val v = vista ?: return
        v.removeCallbacks(sumir)
        try {
            janela?.removeView(v)
        } catch (_: IllegalArgumentException) {
            // Já removida — nada a fazer.
        }
        vista = null
    }

    override fun onDestroy() {
        esconde()
        super.onDestroy()
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()
}

/**
 * O balão com o bicho.
 *
 * Desenhado à mão em `Canvas` de propósito: um overlay não pode depender do
 * motor do Flutter estar vivo — ele aparece justamente quando o usuário está
 * **noutro app**.
 */
private class BalaoDoBaru(
    ctx: Context,
    private val fala: String,
    private val pelo: Int,
    private val especie: String,
    private val rotuloFechar: String,
    private val rotuloMais: String,
    private val aoFechar: () -> Unit,
    private val aoAdiar: () -> Unit,
) : View(ctx) {

    private val d = resources.displayMetrics.density
    private fun dp(v: Float) = v * d

    private val larguraBalao = dp(232f)
    private val alturaPet = dp(96f)

    private val tinta = Paint(Paint.ANTI_ALIAS_FLAG)
    private val texto = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = 0xFF3E2F23.toInt()
        textSize = dp(13.5f)
        typeface = Typeface.create("sans-serif", Typeface.BOLD)
    }
    private val textoBotao = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textSize = dp(12.5f)
        typeface = Typeface.create("sans-serif", Typeface.BOLD)
        textAlign = Paint.Align.CENTER
    }

    private var escala = 0f
    private var linhas: List<String> = emptyList()
    private val rFechar = RectF()
    private val rMais = RectF()

    fun entra() {
        ValueAnimator.ofFloat(0f, 1f).apply {
            duration = 420
            interpolator = OvershootInterpolator(1.6f)
            addUpdateListener {
                escala = it.animatedValue as Float
                invalidate()
            }
        }.start()
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        linhas = quebra(fala, larguraBalao - dp(28f))
        val alturaTexto = linhas.size * dp(19f)
        val alturaBalao = alturaTexto + dp(66f)
        setMeasuredDimension(
            (larguraBalao + dp(16f)).toInt(),
            (alturaBalao + alturaPet).toInt(),
        )
    }

    override fun onDraw(canvas: Canvas) {
        val e = 0.6f + escala * 0.4f
        canvas.save()
        canvas.scale(e, e, width.toFloat(), height.toFloat())
        canvas.translate(0f, (1f - escala) * dp(18f))

        val alturaBalao = height - alturaPet
        val r = RectF(dp(8f), 0f, dp(8f) + larguraBalao, alturaBalao - dp(10f))

        // Sombra e corpo do balão.
        tinta.color = 0x22000000
        canvas.drawRoundRect(
            RectF(r.left, r.top + dp(3f), r.right, r.bottom + dp(3f)),
            dp(20f), dp(20f), tinta,
        )
        tinta.color = 0xFFFAF1E3.toInt()
        canvas.drawRoundRect(r, dp(20f), dp(20f), tinta)

        // Rabicho apontando para o bicho.
        val rabo = Path().apply {
            moveTo(r.right - dp(58f), r.bottom - dp(1f))
            lineTo(r.right - dp(34f), r.bottom + dp(13f))
            lineTo(r.right - dp(30f), r.bottom - dp(1f))
            close()
        }
        canvas.drawPath(rabo, tinta)

        var y = r.top + dp(24f)
        for (linha in linhas) {
            canvas.drawText(linha, r.left + dp(14f), y, texto)
            y += dp(19f)
        }

        // Dois botões: sair do app, ou mais um pouco. Nada de "OK".
        val alturaBotao = dp(32f)
        val topoBotoes = r.bottom - alturaBotao - dp(10f)
        val meio = (r.left + r.right) / 2f
        rFechar.set(r.left + dp(12f), topoBotoes, meio - dp(4f), topoBotoes + alturaBotao)
        rMais.set(meio + dp(4f), topoBotoes, r.right - dp(12f), topoBotoes + alturaBotao)

        tinta.color = 0xFF5C8A4E.toInt()
        canvas.drawRoundRect(rFechar, dp(16f), dp(16f), tinta)
        textoBotao.color = Color.WHITE
        canvas.drawText(
            rotuloFechar,
            rFechar.centerX(),
            rFechar.centerY() + dp(4.5f),
            textoBotao,
        )

        tinta.color = 0x143E2F23
        canvas.drawRoundRect(rMais, dp(16f), dp(16f), tinta)
        textoBotao.color = 0xFF3E2F23.toInt()
        canvas.drawText(
            rotuloMais,
            rMais.centerX(),
            rMais.centerY() + dp(4.5f),
            textoBotao,
        )

        desenhaBicho(canvas, r.right - dp(58f), alturaBalao + dp(6f))
        canvas.restore()
    }

    /**
     * Uma silhueta reconhecível do companheiro.
     *
     * Não é o `_PetPainter` do Flutter — aqui não há Flutter. É a mesma
     * gramática reduzida ao essencial: corpo, barriga, cabeça, orelhas,
     * focinho e olhos, com a paleta derivada da mesma cor de pelagem.
     */
    private fun desenhaBicho(canvas: Canvas, cx: Float, topo: Float) {
        val s = alturaPet / dp(96f)
        fun px(v: Float) = dp(v) * s

        val sombra = mistura(pelo, 0xFF3E2F23.toInt(), 0.30f)
        val barriga = mistura(pelo, 0xFFFAF1E3.toInt(), 0.26f)
        val claro = mistura(pelo, 0xFFFAF1E3.toInt(), 0.30f)

        val baseY = topo + px(90f)

        // Sombra no chão.
        tinta.color = 0x1A000000
        canvas.drawOval(
            RectF(cx - px(30f), baseY - px(7f), cx + px(30f), baseY + px(4f)),
            tinta,
        )

        // Corpo.
        tinta.color = pelo
        canvas.drawOval(
            RectF(cx - px(28f), topo + px(38f), cx + px(28f), baseY),
            tinta,
        )
        tinta.color = barriga
        canvas.drawOval(
            RectF(cx - px(18f), topo + px(50f), cx + px(18f), baseY - px(4f)),
            tinta,
        )

        // Orelhas antes da cabeça: a base some sob o contorno.
        tinta.color = sombra
        val orelhaY = topo + px(14f)
        if (especie == "owl") {
            // Tufos: base larga e ponta.
            for (lado in intArrayOf(-1, 1)) {
                val p = Path().apply {
                    moveTo(cx + lado * px(6f), topo + px(18f))
                    lineTo(cx + lado * px(22f), topo)
                    lineTo(cx + lado * px(24f), topo + px(20f))
                    close()
                }
                canvas.drawPath(p, tinta)
            }
        } else {
            for (lado in intArrayOf(-1, 1)) {
                canvas.drawCircle(cx + lado * px(21f), orelhaY, px(9f), tinta)
            }
        }

        // Cabeça.
        tinta.color = pelo
        canvas.drawOval(
            RectF(cx - px(26f), topo + px(2f), cx + px(26f), topo + px(48f)),
            tinta,
        )

        // Focinho claro.
        tinta.color = claro
        canvas.drawOval(
            RectF(cx - px(15f), topo + px(26f), cx + px(15f), topo + px(46f)),
            tinta,
        )

        // Olhos: esclera, pupila e um brilho.
        for (lado in intArrayOf(-1, 1)) {
            val ox = cx + lado * px(11f)
            val oy = topo + px(21f)
            tinta.color = 0xFFFAF1E3.toInt()
            canvas.drawCircle(ox, oy, px(7f), tinta)
            tinta.color = 0xFF3E2F23.toInt()
            canvas.drawCircle(ox, oy + px(1f), px(4f), tinta)
            tinta.color = Color.WHITE
            canvas.drawCircle(ox - px(1.6f), oy - px(1.4f), px(1.6f), tinta)
        }

        // Focinheira.
        tinta.color = mistura(pelo, 0xFF3E2F23.toInt(), 0.46f)
        canvas.drawOval(
            RectF(cx - px(5f), topo + px(30f), cx + px(5f), topo + px(37f)),
            tinta,
        )
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (event.action != MotionEvent.ACTION_UP) return true
        val x = event.x
        val y = event.y
        return when {
            rFechar.contains(x, y) -> { aoFechar(); true }
            rMais.contains(x, y) -> { aoAdiar(); true }
            else -> true
        }
    }

    private fun quebra(t: String, largura: Float): List<String> {
        if (t.isEmpty()) return emptyList()
        val out = mutableListOf<String>()
        var atual = StringBuilder()
        for (palavra in t.split(' ')) {
            val tentativa = if (atual.isEmpty()) palavra else "$atual $palavra"
            if (texto.measureText(tentativa) <= largura) {
                atual = StringBuilder(tentativa)
            } else {
                if (atual.isNotEmpty()) out.add(atual.toString())
                atual = StringBuilder(palavra)
            }
        }
        if (atual.isNotEmpty()) out.add(atual.toString())
        return out.take(4)
    }

    private fun mistura(a: Int, b: Int, t: Float): Int {
        val f = min(1f, t)
        fun c(sa: Int, sb: Int) = (sa + (sb - sa) * f).toInt()
        return Color.argb(
            255,
            c(Color.red(a), Color.red(b)),
            c(Color.green(a), Color.green(b)),
            c(Color.blue(a), Color.blue(b)),
        )
    }
}
