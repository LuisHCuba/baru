/// Os glifos das três coisas que a pessoa junta: folha, raiz e XP.
///
/// **Um desenho e uma cor cada, em todo lugar** (laudo 03, R-V2). A folha
/// era uma gota verde na home, uma gota cor de ferrugem nas missões, a
/// folha do Material na loja e uma gota laranja no fim da sessão; a raiz
/// era laranja no app e verde no cartão. Quatro desenhos da mesma moeda
/// dizem que são quatro moedas.
///
/// Pintados à mão numa grade de 24 × 24, com a luz vindo de cima-esquerda
/// como no bicho: o lado de cima da folha é um tom mais claro. Abaixo de
/// 14 px a nervura sai — a meio pixel ela vira sujeira, não detalhe.
///
/// `test/glifos_test.dart` falha se `Icons.eco` ou um desenho de folha
/// paralelo voltar a aparecer em `lib/`.
library;

import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// A folha, a moeda do app.
class GlifoFolha extends StatelessWidget {
  const GlifoFolha({super.key, this.tamanho = 16, this.cor = Cores.folha600});

  final double tamanho;

  /// [Cores.folha600] em toda superfície clara. Outra cor só sobre a face de
  /// um botão (creme) ou apagada, quando não dá para pagar.
  final Color cor;

  @override
  Widget build(BuildContext context) => _Glifo(
        tamanho: tamanho,
        pintor: _PintorDaFolha(cor, nervura: tamanho >= 14),
      );
}

/// A raiz, a sequência de dias: um broto num montinho de terra, com a raiz
/// embaixo.
class GlifoRaiz extends StatelessWidget {
  const GlifoRaiz({super.key, this.tamanho = 16, this.cor = Cores.raiz600});

  final double tamanho;
  final Color cor;

  @override
  Widget build(BuildContext context) =>
      _Glifo(tamanho: tamanho, pintor: _PintorDaRaiz(cor));
}

/// O XP: uma semente-estrela de quatro pontas, cor de mel.
class GlifoXp extends StatelessWidget {
  const GlifoXp({super.key, this.tamanho = 16});

  final double tamanho;

  @override
  Widget build(BuildContext context) =>
      _Glifo(tamanho: tamanho, pintor: const _PintorDoXp());
}

class _Glifo extends StatelessWidget {
  const _Glifo({required this.tamanho, required this.pintor});

  final double tamanho;
  final CustomPainter pintor;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox.square(
          dimension: tamanho,
          child: CustomPaint(painter: pintor),
        ),
      );
}

/// Contorno da folha na grade de 24: gota assimétrica com a ponta para
/// cima-direita e o cabo saindo embaixo-esquerda.
Path _contornoDaFolha() => Path()
  ..moveTo(6.2, 18.2)
  ..cubicTo(3.4, 11.6, 8.6, 3.6, 20.6, 3.4)
  ..cubicTo(20.8, 13.4, 14.6, 20.4, 6.2, 18.2)
  ..close();

class _PintorDaFolha extends CustomPainter {
  const _PintorDaFolha(this.cor, {required this.nervura});

  final Color cor;
  final bool nervura;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final folha = _contornoDaFolha();
    canvas.drawPath(folha, Paint()..color = cor);
    // A metade de cima, acima da nervura, pega a luz.
    canvas.save();
    canvas.clipPath(folha);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(24, 0)
        ..lineTo(20.6, 3.4)
        ..quadraticBezierTo(11.4, 9.6, 6.2, 18.2)
        ..lineTo(0, 24)
        ..close(),
      Paint()..color = Color.lerp(cor, const Color(0xFFFFFFFF), 0.16)!,
    );
    canvas.restore();
    final traco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // O cabo.
    canvas.drawLine(
      const Offset(6.6, 17.8),
      const Offset(3.4, 21),
      traco
        ..color = cor
        ..strokeWidth = 2.2,
    );
    if (nervura) {
      canvas.drawPath(
        Path()
          ..moveTo(7.6, 16.6)
          ..quadraticBezierTo(11.6, 10.8, 17.4, 6.8),
        traco
          // Clara sobre a folha verde; escura sobre a folha creme do
          // botão, onde clarear não se veria.
          ..color = cor.computeLuminance() > 0.5
              ? Color.lerp(cor, Cores.folha600, 0.30)!
              : Color.lerp(cor, const Color(0xFFFFFBF2), 0.62)!
          ..strokeWidth = 1.3,
      );
    }
  }

  @override
  bool shouldRepaint(_PintorDaFolha old) =>
      old.cor != cor || old.nervura != nervura;
}

class _PintorDaRaiz extends CustomPainter {
  const _PintorDaRaiz(this.cor);

  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final traco = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.1;
    final cheio = Paint()..color = cor;
    // A raiz por baixo: três fios saindo da base do montinho, o do meio
    // mais fundo. Desenhada antes, para a terra cobrir a emenda.
    canvas.drawPath(
      Path()
        ..moveTo(12, 13)
        ..cubicTo(12.6, 16, 11.2, 18.6, 12, 21.8),
      traco,
    );
    canvas.drawPath(
      Path()
        ..moveTo(10.4, 13)
        ..cubicTo(9.4, 15.6, 7, 16.4, 5.6, 19.6),
      traco,
    );
    canvas.drawPath(
      Path()
        ..moveTo(13.6, 13)
        ..cubicTo(14.6, 15.6, 17, 16.4, 18.4, 19.6),
      traco,
    );
    // O montinho de terra: uma cúpula cheia, não um traço — uma linha de
    // chão cruzando o caule fazia o glifo ler como um bonequinho
    // (auditoria do item 10, 4).
    canvas.drawPath(
      Path()
        ..moveTo(3.4, 13.6)
        ..cubicTo(5, 9.2, 19, 9.2, 20.6, 13.6)
        ..close(),
      Paint()..color = Color.lerp(cor, const Color(0xFFFFFBF2), 0.45)!,
    );
    // O broto em cima da terra: caule curto e duas folhas em V.
    canvas.drawLine(const Offset(12, 10.4), const Offset(12, 6.6), traco);
    canvas.drawPath(
      Path()
        ..moveTo(11.6, 7.4)
        ..quadraticBezierTo(6.6, 7.4, 5.4, 2.6)
        ..quadraticBezierTo(10.6, 2.6, 11.6, 7.4)
        ..close(),
      cheio,
    );
    canvas.drawPath(
      Path()
        ..moveTo(12.4, 7.4)
        ..quadraticBezierTo(17.4, 7.4, 18.6, 2.6)
        ..quadraticBezierTo(13.4, 2.6, 12.4, 7.4)
        ..close(),
      cheio,
    );
  }

  @override
  bool shouldRepaint(_PintorDaRaiz old) => old.cor != cor;
}

class _PintorDoXp extends CustomPainter {
  const _PintorDoXp();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    const c = 12.0;
    const cintura = 3.0;
    final estrela = Path()
      ..moveTo(c, 2.2)
      ..quadraticBezierTo(c + cintura, c - cintura, 21.8, c)
      ..quadraticBezierTo(c + cintura, c + cintura, c, 21.8)
      ..quadraticBezierTo(c - cintura, c + cintura, 2.2, c)
      ..quadraticBezierTo(c - cintura, c - cintura, c, 2.2)
      ..close();
    canvas.drawPath(estrela, Paint()..color = Cores.mel400);
    canvas.drawPath(
      estrela,
      Paint()
        ..color = Cores.mel700
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 1.7,
    );
    // O brilho de cima-esquerda.
    canvas.drawCircle(
      const Offset(9.8, 9.8),
      1.3,
      Paint()..color = const Color(0xFFFFF4D6),
    );
  }

  @override
  bool shouldRepaint(_PintorDoXp old) => false;
}
