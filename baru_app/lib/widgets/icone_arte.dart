import 'dart:math' as math;

import 'package:flutter/material.dart';


/// O fundo do ícone do app.
///
/// **O que estava errado.** O ícone era o bicho chapado sobre um retângulo
/// de cor chapada. Num launcher cheio de ícones com profundidade, isso lê
/// como placeholder — foi exatamente a reação: "está simplório demais".
///
/// **O que dá profundidade sem virar ilustração.** Três camadas, e nenhuma
/// delas é enfeite:
///
/// 1. **Luz vinda de cima.** Gradiente radial com o foco acima do centro,
///    onde o bicho fica. É o que faz o olho ir para ele.
/// 2. **Folhagem atrás.** Silhuetas em tom próximo do fundo — a diferença é
///    de brilho, não de matiz, senão viram manchas e competem com o bicho.
/// 3. **Vinheta na borda.** A máscara do launcher corta as bordas; escurecê-
///    las faz o corte parecer intencional em vez de acidental.
///
/// Desenhado, e não um PNG de editor, pelo mesmo motivo do bicho: um asset
/// pintado à mão envelhece em silêncio quando a paleta do app muda.
class FundoDoIcone extends StatelessWidget {
  const FundoDoIcone({super.key, required this.lado, this.semente = 0});

  final double lado;

  /// Varia a folhagem por espécie sem perder determinismo: o mesmo valor
  /// desenha sempre o mesmo fundo.
  final int semente;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: lado,
      height: lado,
      child: CustomPaint(painter: _PintorDoFundo(semente: semente)),
    );
  }
}

class _PintorDoFundo extends CustomPainter {
  _PintorDoFundo({required this.semente});

  final int semente;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. O verde profundo do fundo.
    //
    // Escuro de propósito: o bicho é castanho, e castanho sobre verde médio
    // fica lamacento no tamanho de um ícone. O que faz um ícone ler de longe
    // é separação entre figura e fundo, não riqueza de detalhe.
    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5C8A4C), Color(0xFF31502A)],
        ).createShader(r),
    );

    // 2. O halo atrás do bicho.
    //
    // É esta camada que faz o contraste. Sem ela, o corpo escuro do bicho
    // encosta num fundo escuro e some; com ela, ele sempre nasce sobre uma
    // área clara, qualquer que seja a pelagem.
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.46),
      size.width * 0.40,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFA9CF93).withValues(alpha: 0.95),
            const Color(0xFFA9CF93).withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width / 2, size.height * 0.46),
            radius: size.width * 0.40,
          ),
        ),
    );

    // 3. Três folhas grandes nos cantos.
    //
    // Grandes e poucas. A versão anterior espalhava onze pequenas em volta,
    // e no tamanho real elas viravam sujeira clara em vez de mato — num
    // ícone de 48dp, detalhe fino é ruído.
    final sorte = math.Random(semente * 104729 + 17);
    final folha = Paint()..color = const Color(0x26000000);
    for (var i = 0; i < 3; i++) {
      final ang = -0.6 + i * 2.2 + sorte.nextDouble() * 0.4;
      final raio = size.width * 0.46;
      final cx = size.width / 2 + math.cos(ang) * raio;
      final cy = size.height / 2 + math.sin(ang) * raio;
      final comp = size.width * (0.34 + sorte.nextDouble() * 0.10);

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(ang + math.pi / 2);
      final p = Path()
        ..moveTo(0, -comp / 2)
        ..quadraticBezierTo(comp * 0.34, 0, 0, comp / 2)
        ..quadraticBezierTo(-comp * 0.34, 0, 0, -comp / 2)
        ..close();
      canvas.drawPath(p, folha);
      canvas.restore();
    }

    // 4. A vinheta. A máscara corta as bordas de qualquer jeito; escurecê-
    // las faz o corte parecer intenção.
    canvas.drawRect(
      r,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.80,
          colors: const [Color(0x00000000), Color(0x3D000000)],
          stops: const [0.58, 1.0],
        ).createShader(r),
    );
  }

  @override
  bool shouldRepaint(_PintorDoFundo old) => old.semente != semente;
}

/// A sombra que assenta o bicho no chão do ícone.
///
/// Sem ela o bicho flutua, e flutuar é o que faz um ícone parecer recortado
/// e colado.
class SombraDoIcone extends StatelessWidget {
  const SombraDoIcone({super.key, required this.largura});

  final double largura;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: largura,
      height: largura * 0.16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.elliptical(largura, 20)),
          gradient: const RadialGradient(
            colors: [Color(0x55000000), Color(0x00000000)],
          ),
        ),
      ),
    );
  }
}
