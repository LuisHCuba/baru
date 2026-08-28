import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

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

    // 1. A luz. Foco acima do centro, onde o bicho fica.
    canvas.drawRect(
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.35),
          radius: 1.05,
          colors: const [
            Color(0xFF8FB87C),
            Cores.primariaClara,
            Color(0xFF4E7342),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(r),
    );

    // 2. A folhagem. Tom próximo do fundo: a diferença é de brilho, não de
    // matiz — folhas de outra cor virariam manchas competindo com o bicho.
    final sorte = math.Random(semente * 104729 + 17);
    final folha = Paint()..color = const Color(0x1AFFFFFF);
    final sombra = Paint()..color = const Color(0x14000000);
    // Menores e em volta: no primeiro desenho eram grandes e no meio, e
    // viravam manchas pálidas disputando espaço com o bicho. Folhagem tem
    // de emoldurar, não ocupar.
    for (var i = 0; i < 11; i++) {
      final aoRedor = i / 11 * math.pi * 2;
      final raio = size.width * (0.36 + sorte.nextDouble() * 0.10);
      final cx = size.width / 2 + math.cos(aoRedor) * raio;
      final cy = size.height / 2 + math.sin(aoRedor) * raio;
      final comp = size.width * (0.09 + sorte.nextDouble() * 0.07);
      final ang = aoRedor + math.pi / 2;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(ang);
      // Folha como duas curvas espelhadas: um oval seria bolha, e bolha não
      // lê como mato.
      final p = Path()
        ..moveTo(0, -comp / 2)
        ..quadraticBezierTo(comp * 0.38, 0, 0, comp / 2)
        ..quadraticBezierTo(-comp * 0.38, 0, 0, -comp / 2)
        ..close();
      canvas.drawPath(p, i.isEven ? folha : sombra);
      canvas.restore();
    }

    // 3. A vinheta. A máscara do launcher corta as bordas; escurecê-las faz
    // o corte parecer intenção.
    canvas.drawRect(
      r,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.78,
          colors: const [Color(0x00000000), Color(0x33000000)],
          stops: const [0.62, 1.0],
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
