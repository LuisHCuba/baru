/// O que cada bicho come, desenhado.
///
/// Era um talo verde para os nove: a coruja e o pinguim "petiscavam" folha.
/// Cada espécie come o que come de verdade (pesquisa 22): capivara pasta,
/// tartaruga come folha, lontra, pinguim e gata pegam peixe, coruja caça
/// grilo, axolote suga minhoca, raposa come amora, buldogue ganha biscoito.
/// O mesmo desenho serve na boca, enquanto ele come, e no potinho de
/// petiscos do habitat.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';

enum Comida {
  capim,
  folha,
  peixe,
  grilo,
  minhoca,
  amora,
  biscoito,
  castanha,
  melancia,
  lagostim,
  lula,
}

/// O que ele come no dia a dia (pastando, petiscando).
Comida comidaDe(Species s) => switch (s) {
  Species.capybara => Comida.capim,
  Species.tortoise => Comida.folha,
  Species.otter || Species.penguin || Species.cat => Comida.peixe,
  Species.owl => Comida.grilo,
  Species.axolotl => Comida.minhoca,
  Species.fox => Comida.amora,
  Species.frenchie => Comida.biscoito,
};

/// O petisco que a pessoa dá: o agrado de cada um (pesquisa 22, dieta).
/// Capivara: fruta (melão, melancia); lontra: lagostim; pinguim: lula;
/// tartaruga: minhoca (adulta come planta, filhote é carnívoro).
Comida petiscoDe(Species s) => switch (s) {
  Species.capybara => Comida.melancia,
  Species.otter => Comida.lagostim,
  Species.penguin => Comida.lula,
  Species.tortoise => Comida.minhoca,
  _ => comidaDe(s),
};

Paint _p(Color c) => Paint()
  ..color = c
  ..isAntiAlias = true;

/// Desenha [c] centrada em [o], com [r] de "raio" (meia largura), girada
/// [angulo] radianos.
void pintaComida(
  Canvas canvas,
  Comida c,
  Offset o,
  double r, {
  double angulo = 0,
}) {
  canvas.save();
  canvas.translate(o.dx, o.dy);
  if (angulo != 0) canvas.rotate(angulo);
  switch (c) {
    case Comida.capim:
      final talo = Paint()
        ..color = const Color(0xFF6E9C5E)
        ..strokeWidth = r * 0.28
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (final (dx, curva) in const [(-0.5, -0.5), (0.0, 0.2), (0.5, 0.6)]) {
        canvas.drawPath(
          Path()
            ..moveTo(dx * r * 0.4, r * 0.4)
            ..quadraticBezierTo(
              dx * r + curva * r * 0.4,
              -r * 0.2,
              dx * r * 1.3 + curva * r * 0.6,
              -r,
            ),
          talo,
        );
      }
    case Comida.folha:
      final folha = Path()
        ..moveTo(-r, 0)
        ..quadraticBezierTo(-r * 0.2, -r * 0.9, r, 0)
        ..quadraticBezierTo(-r * 0.2, r * 0.9, -r, 0)
        ..close();
      canvas.drawPath(folha, _p(const Color(0xFF8CC26A)));
      canvas.drawLine(
        Offset(-r * 0.9, 0),
        Offset(r * 0.8, 0),
        Paint()
          ..color = const Color(0xFF5C8A4E)
          ..strokeWidth = r * 0.12,
      );
    case Comida.peixe:
      final corpo = Path()
        ..moveTo(-r * 0.9, 0)
        ..quadraticBezierTo(-r * 0.2, -r * 0.6, r * 0.55, 0)
        ..quadraticBezierTo(-r * 0.2, r * 0.6, -r * 0.9, 0)
        ..close();
      final cauda = Path()
        ..moveTo(r * 0.45, 0)
        ..lineTo(r, -r * 0.45)
        ..lineTo(r, r * 0.45)
        ..close();
      canvas.drawPath(cauda, _p(const Color(0xFF7F95A6)));
      canvas.drawPath(corpo, _p(const Color(0xFFA9BBC8)));
      canvas.drawCircle(
        Offset(-r * 0.55, -r * 0.08),
        r * 0.1,
        _p(const Color(0xFF3E2F23)),
      );
    case Comida.grilo:
      final perna = Paint()
        ..color = const Color(0xFF4A5A2A)
        ..strokeWidth = r * 0.12
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(r * 0.1, 0), Offset(r * 0.6, -r * 0.6), perna);
      canvas.drawLine(
        Offset(r * 0.6, -r * 0.6),
        Offset(r * 0.9, r * 0.2),
        perna,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 1.6, height: r * 0.7),
        _p(const Color(0xFF6B7A35)),
      );
      canvas.drawCircle(
        Offset(-r * 0.75, -r * 0.05),
        r * 0.28,
        _p(const Color(0xFF55632A)),
      );
      final antena = Paint()
        ..color = const Color(0xFF4A5A2A)
        ..strokeWidth = r * 0.06
        ..style = PaintingStyle.stroke;
      canvas.drawPath(
        Path()
          ..moveTo(-r * 0.9, -r * 0.15)
          ..quadraticBezierTo(-r * 1.3, -r * 0.8, -r * 0.6, -r * 1.0),
        antena,
      );
    case Comida.minhoca:
      canvas.drawPath(
        Path()
          ..moveTo(-r, r * 0.2)
          ..cubicTo(-r * 0.5, -r * 0.6, 0, r * 0.6, r * 0.5, -r * 0.1)
          ..quadraticBezierTo(r * 0.8, -r * 0.4, r, -r * 0.1),
        Paint()
          ..color = const Color(0xFFD98C8C)
          ..strokeWidth = r * 0.38
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    case Comida.amora:
      for (var i = 0; i < 7; i++) {
        final a = i / 7 * math.pi * 2;
        canvas.drawCircle(
          Offset(math.cos(a), math.sin(a)) * r * 0.42,
          r * 0.32,
          _p(const Color(0xFF5B2A4E)),
        );
      }
      canvas.drawCircle(Offset.zero, r * 0.34, _p(const Color(0xFF6E3560)));
      canvas.drawCircle(
        Offset(-r * 0.2, -r * 0.25),
        r * 0.12,
        _p(Colors.white.withValues(alpha: 0.5)),
      );
      canvas.drawLine(
        Offset(0, -r * 0.6),
        Offset(r * 0.15, -r * 1.0),
        Paint()
          ..color = const Color(0xFF5C8A4E)
          ..strokeWidth = r * 0.14
          ..strokeCap = StrokeCap.round,
      );
    case Comida.biscoito:
      final cor = _p(const Color(0xFFD9A066));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: r * 1.4, height: r * 0.5),
          Radius.circular(r * 0.2),
        ),
        cor,
      );
      for (final x in [-1.0, 1.0]) {
        for (final y in [-1.0, 1.0]) {
          canvas.drawCircle(Offset(x * r * 0.7, y * r * 0.22), r * 0.3, cor);
        }
      }
    case Comida.melancia:
      final fatia = Path()
        ..moveTo(-r, -r * 0.2)
        ..arcToPoint(
          Offset(r, -r * 0.2),
          radius: Radius.circular(r),
          clockwise: false,
        )
        ..close();
      canvas.drawPath(fatia, _p(const Color(0xFF5C8A4E)));
      canvas.save();
      canvas.translate(0, -r * 0.1);
      canvas.scale(0.86);
      canvas.drawPath(fatia, _p(const Color(0xFFF3E7D3)));
      canvas.scale(0.9);
      canvas.drawPath(fatia, _p(const Color(0xFFE5555E)));
      canvas.restore();
      for (final x in [-0.4, 0.0, 0.4]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x * r, r * 0.22),
            width: r * 0.14,
            height: r * 0.24,
          ),
          _p(const Color(0xFF3E2F23)),
        );
      }
    case Comida.lagostim:
      final casca = _p(const Color(0xFFC75B3A));
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 1.5, height: r * 0.6),
        casca,
      );
      final cauda = Path()
        ..moveTo(r * 0.6, 0)
        ..lineTo(r, -r * 0.35)
        ..lineTo(r, r * 0.35)
        ..close();
      canvas.drawPath(cauda, casca);
      for (final lado in [-1.0, 1.0]) {
        canvas.drawLine(
          Offset(-r * 0.6, lado * r * 0.15),
          Offset(-r * 1.0, lado * r * 0.45),
          Paint()
            ..color = const Color(0xFFC75B3A)
            ..strokeWidth = r * 0.12,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(-r * 1.05, lado * r * 0.5),
            width: r * 0.4,
            height: r * 0.26,
          ),
          casca,
        );
      }
    case Comida.lula:
      final manto = Path()
        ..moveTo(r, 0)
        ..quadraticBezierTo(r * 0.2, -r * 0.5, -r * 0.2, -r * 0.3)
        ..lineTo(-r * 0.2, r * 0.3)
        ..quadraticBezierTo(r * 0.2, r * 0.5, r, 0)
        ..close();
      canvas.drawPath(manto, _p(const Color(0xFFE8B7B0)));
      final tentaculo = Paint()
        ..color = const Color(0xFFDDA39B)
        ..strokeWidth = r * 0.1
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (final y in [-0.2, 0.0, 0.2]) {
        canvas.drawPath(
          Path()
            ..moveTo(-r * 0.2, y * r)
            ..quadraticBezierTo(-r * 0.6, y * r * 2.2, -r, y * r * 1.4),
          tentaculo,
        );
      }
      canvas.drawCircle(
        Offset(r * 0.05, -r * 0.08),
        r * 0.08,
        _p(const Color(0xFF3E2F23)),
      );
    case Comida.castanha:
      canvas.rotate(-0.35);
      final forma = Rect.fromCenter(
        center: Offset.zero,
        width: r * 2.5,
        height: r * 1.6,
      );
      canvas.drawOval(
        forma,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB98552), Color(0xFF7A4A26)],
          ).createShader(forma),
      );
      canvas.drawLine(
        Offset(-r * 0.95, r * 0.05),
        Offset(r * 0.95, -r * 0.05),
        Paint()
          ..color = const Color(0xFF5A3418).withValues(alpha: 0.6)
          ..strokeWidth = 1.1
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-r * 0.35, -r * 0.4),
          width: r * 0.9,
          height: r * 0.32,
        ),
        _p(Colors.white.withValues(alpha: 0.35)),
      );
  }
  canvas.restore();
}
