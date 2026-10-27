/// O desenho do mundo da home, em camadas com paralaxe.
///
/// Do fundo para a frente: céu (com sol ou lua, nuvens, estrelas), as
/// chapadas do Cerrado, as colinas, as árvores de baru, o chão com a toca,
/// o canto dos brinquedos e a lagoa — e, por cima de tudo, o capim do
/// primeiro plano, que passa mais rápido que o resto. Cada camada anda a uma
/// fração da câmera: é isso que dá profundidade a um mundo plano.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../habitat.dart';
import 'mundo.dart';

Paint _p(Color c) => Paint()
  ..color = c
  ..isAntiAlias = true;

bool _noite(LuzDaCena l) => l.ceuAlto.computeLuminance() < 0.15;

/// Uma camada que anda a [fator] da câmera; devolve o deslocamento em px.
double _desloca(double camera, double fator) => -camera * fator;

class FundoDoMundo extends CustomPainter {
  FundoDoMundo({
    required this.g,
    required this.luz,
    required this.cenario,
    required this.camera,
    required this.tempo,
  }) : super(repaint: Listenable.merge([camera, tempo]));

  final GeometriaDoMundo g;
  final LuzDaCena luz;
  final CenarioDoHabitat cenario;
  final ValueNotifier<double> camera;
  final ValueNotifier<double> tempo;

  @override
  void paint(Canvas canvas, Size size) {
    // As alturas do cenário seguem o horizonte (que segue a parte visível,
    // acima do painel), não a tela inteira.
    final w = size.width, h = g.horizonte / 0.56;
    final cam = math.max(0.0, camera.value);
    final t = tempo.value;
    final noite = _noite(luz);

    // --- céu -----------------------------------------------------------
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [luz.ceuAlto, luz.ceuBaixo, luz.ceuBaixo],
          stops: const [0, 0.5, 1],
        ).createShader(Offset.zero & size),
    );

    if (noite) {
      final r = math.Random(7);
      for (var i = 0; i < 60; i++) {
        final x = (r.nextDouble() * w * 1.4 + _desloca(cam, 0.04)) % (w * 1.4);
        final y = r.nextDouble() * h * 0.42;
        final brilho = 0.35 + 0.35 * math.sin(t * (0.8 + r.nextDouble()) + i);
        canvas.drawCircle(
          Offset(x, y),
          0.6 + r.nextDouble() * 1.2,
          _p(Colors.white.withValues(alpha: brilho.clamp(0.0, 1.0))),
        );
      }
    }

    // --- astro ---------------------------------------------------------
    final astro = Offset(
      w * 0.78 + _desloca(cam, 0.03),
      h * (0.09 + (1 - luz.astroAlto) * 0.16),
    );
    canvas.drawCircle(astro, 64, _p(luz.haloAstro));
    canvas.drawCircle(astro, 30, _p(luz.astro));

    // --- nuvens --------------------------------------------------------
    final nuvem = noite
        ? Colors.white.withValues(alpha: 0.10)
        : Color.lerp(Colors.white, luz.ceuBaixo, 0.25)!.withValues(alpha: 0.8);
    final rn = math.Random(11);
    for (var i = 0; i < 6; i++) {
      final largura = 90 + rn.nextDouble() * 110;
      final ciclo = w * 1.6 + largura;
      final base = rn.nextDouble() * ciclo;
      final x = ((base + t * (4 + i) + _desloca(cam, 0.1)) % ciclo) - largura;
      final y = h * (0.1 + rn.nextDouble() * 0.22);
      _nuvem(canvas, Offset(x, y), largura, nuvem);
    }

    // --- chapadas (o horizonte do Cerrado) -----------------------------
    final distante = Color.lerp(
      cenario.colinaCom(luz.colina),
      luz.ceuBaixo,
      0.55,
    )!;
    canvas.save();
    canvas.translate(_desloca(cam, 0.2), 0);
    _chapadas(
      canvas,
      de: cam * 0.2 - 200,
      ate: cam * 0.2 + w + 200,
      base: h * 0.53,
      altura: h * 0.09,
      pico: cenario.pico,
      cor: distante,
    );
    canvas.restore();

    // --- colinas -------------------------------------------------------
    final colina = Color.lerp(
      cenario.colinaCom(luz.colina),
      luz.ceuBaixo,
      0.18,
    )!;
    canvas.save();
    canvas.translate(_desloca(cam, 0.45), 0);
    final rc = math.Random(23);
    for (
      var x = -300.0;
      x < g.largura * 0.45 + w + 300;
      x += 150 + rc.nextDouble() * 120
    ) {
      final larg = 200 + rc.nextDouble() * 180;
      canvas.drawPath(
        silhuetaDeColina(
          esquerda: x,
          base: g.horizonte + h * 0.04,
          largura: larg,
          altura: h * (0.06 + rc.nextDouble() * 0.06),
          pico: cenario.pico * 0.6,
        ),
        _p(colina),
      );
    }
    canvas.restore();

    // --- árvores de baru --------------------------------------------------
    final copa = Color.lerp(
      const Color(0xFF5F8A4C),
      luz.ceuAlto,
      noite ? 0.45 : 0.12,
    )!;
    final tronco = Color.lerp(
      const Color(0xFF7A5A3C),
      luz.ceuAlto,
      noite ? 0.4 : 0.1,
    )!;
    canvas.save();
    canvas.translate(_desloca(cam, 0.72), 0);
    for (final (fx, tamanho) in const [
      (0.04, 1.0),
      (0.2, 0.7),
      (0.33, 1.25),
      (0.5, 0.8),
      (0.62, 1.05),
      (0.86, 0.75),
    ]) {
      _arvoreDeBaru(
        canvas,
        Offset(fx * (g.largura * 0.72 + w), g.horizonte + h * 0.05),
        tamanho * h * 0.15,
        copa,
        tronco,
        t,
      );
    }
    canvas.restore();

    // --- o chão do mundo (anda com a câmera) ------------------------------
    canvas.save();
    canvas.translate(-cam, 0);
    _chao(canvas, size, t);
    canvas.restore();

    if (luz.sombraAmbiente.a > 0) {
      canvas.drawRect(Offset.zero & size, _p(luz.sombraAmbiente));
    }
  }

  /// Uma nuvem só, num caminho só: com três formas translúcidas por cima
  /// uma da outra, as sobreposições escureciam e a nuvem virava mancha.
  void _nuvem(Canvas canvas, Offset o, double largura, Color cor) {
    final forma = Path()
      ..addOval(
        Rect.fromCenter(center: o, width: largura, height: largura * 0.32),
      )
      ..addOval(
        Rect.fromCircle(
          center: o + Offset(-largura * 0.15, -largura * 0.12),
          radius: largura * 0.2,
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: o + Offset(largura * 0.12, -largura * 0.16),
          radius: largura * 0.24,
        ),
      );
    canvas.drawPath(forma, _p(cor));
  }

  /// Chapadas: topo reto e encosta inclinada (ou picos, na serra).
  void _chapadas(
    Canvas canvas, {
    required double de,
    required double ate,
    required double base,
    required double altura,
    required double pico,
    required Color cor,
  }) {
    final r = math.Random(5);
    final path = Path()..moveTo(de, base + 40);
    var x = de;
    path.lineTo(x, base);
    while (x < ate) {
      final subida = 30 + r.nextDouble() * 50;
      final topo = 60 + r.nextDouble() * 160;
      final alto = altura * (0.45 + r.nextDouble() * 0.55);
      if (pico > 0.5) {
        path.lineTo(x + subida, base - alto * 1.3);
        x += subida * 2;
        path.lineTo(x, base - alto * 0.3);
      } else {
        path.lineTo(x + subida, base - alto);
        path.lineTo(x + subida + topo, base - alto);
        x += subida * 2 + topo;
        path.lineTo(x, base - r.nextDouble() * altura * 0.15);
      }
      x += r.nextDouble() * 60;
      path.lineTo(x, base);
    }
    path
      ..lineTo(ate, base + 40)
      ..close();
    canvas.drawPath(path, _p(cor));
  }

  /// O baru (Dipteryx alata): tronco torto e copa larga, em tufos.
  void _arvoreDeBaru(
    Canvas canvas,
    Offset pe,
    double altura,
    Color copa,
    Color tronco,
    double t,
  ) {
    final balanco = math.sin(t * 0.6 + pe.dx) * altura * 0.01;
    canvas.drawPath(
      Path()
        ..moveTo(pe.dx - altura * 0.05, pe.dy)
        ..quadraticBezierTo(
          pe.dx - altura * 0.12,
          pe.dy - altura * 0.45,
          pe.dx + balanco,
          pe.dy - altura * 0.75,
        )
        ..lineTo(pe.dx + altura * 0.06 + balanco, pe.dy - altura * 0.72)
        ..quadraticBezierTo(
          pe.dx - altura * 0.02,
          pe.dy - altura * 0.4,
          pe.dx + altura * 0.06,
          pe.dy,
        )
        ..close(),
      _p(tronco),
    );
    final centro = Offset(pe.dx + balanco, pe.dy - altura * 0.85);
    final claro = Color.lerp(copa, Colors.white, 0.12)!;
    for (final (dx, dy, r, c) in [
      (-0.32, 0.05, 0.3, copa),
      (0.3, 0.06, 0.32, copa),
      (0.0, -0.12, 0.38, copa),
      (-0.12, -0.18, 0.2, claro),
      (0.18, -0.08, 0.16, claro),
    ]) {
      canvas.drawCircle(
        centro + Offset(dx * altura, dy * altura),
        r * altura,
        _p(c),
      );
    }
  }

  void _chao(Canvas canvas, Size size, double t) {
    final h = size.height;
    final largura = g.largura;
    final beira = g.x(ZonasDoMundo.beira);
    final grama = Color.lerp(
      cenario.colinaCom(luz.colina),
      const Color(0xFF8DB06A),
      0.55,
    )!;
    final gramaFunda = Color.lerp(grama, const Color(0xFF3F6B33), 0.35)!;
    final areia = cenario.areiaCom(luz.areia);

    // O campo, de ponta a ponta, com ondulação suave.
    final campo = Path()..moveTo(0, h);
    for (var x = 0.0; x <= largura; x += 24) {
      final y = g.horizonte + math.sin(x / 260) * 8 + math.sin(x / 90) * 3;
      campo.lineTo(x, y);
    }
    campo
      ..lineTo(largura, h)
      ..close();
    canvas.drawPath(
      campo,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [grama, gramaFunda],
        ).createShader(Rect.fromLTWH(0, g.horizonte, largura, h - g.horizonte)),
    );

    // A trilha de terra batida, da toca à margem.
    final trilha = Path()
      ..moveTo(g.x(0.06), g.chao + 10)
      ..quadraticBezierTo(g.x(0.25), g.chao - 4, g.x(0.45), g.chao + 14)
      ..quadraticBezierTo(g.x(0.58), g.chao + 22, g.x(0.66), g.chao + 12)
      ..lineTo(g.x(0.66), g.chao + 30)
      ..quadraticBezierTo(g.x(0.58), g.chao + 40, g.x(0.45), g.chao + 32)
      ..quadraticBezierTo(g.x(0.25), g.chao + 16, g.x(0.06), g.chao + 28)
      ..close();
    canvas.drawPath(trilha, _p(areia.withValues(alpha: 0.55)));

    // --- a toca -----------------------------------------------------------
    final e = g.escala;
    final toca = Offset(g.x(0.09), g.chao + 6);
    canvas.drawPath(
      Path()
        ..moveTo(toca.dx - 120 * e, toca.dy)
        ..cubicTo(
          toca.dx - 90 * e,
          toca.dy - 70 * e,
          toca.dx + 90 * e,
          toca.dy - 70 * e,
          toca.dx + 120 * e,
          toca.dy,
        )
        ..close(),
      _p(Color.lerp(areia, const Color(0xFF8A6A48), 0.35)!),
    );
    // A boca da toca, escura, e a borda de terra solta.
    canvas.drawOval(
      Rect.fromCenter(
        center: toca + Offset(0, -18 * e),
        width: 74 * e,
        height: 44 * e,
      ),
      _p(const Color(0xFF3B2A1E).withValues(alpha: 0.85)),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: toca + Offset(0, -14 * e),
        width: 60 * e,
        height: 30 * e,
      ),
      _p(const Color(0xFF241812).withValues(alpha: 0.9)),
    );
    for (final (dx, r) in const [
      (-70.0, 6.0),
      (-50.0, 4.0),
      (62.0, 5.0),
      (80.0, 3.5),
    ]) {
      canvas.drawCircle(
        toca + Offset(dx * e, -2 * e),
        r * e,
        _p(Color.lerp(areia, const Color(0xFF6B5A4A), 0.5)!),
      );
    }

    // --- o canto dos brinquedos: um círculo de grama gasta --------------
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(g.x(0.27), g.chao + 12),
        width: g.x(0.16),
        height: 40 * e,
      ),
      _p(areia.withValues(alpha: 0.35)),
    );

    // --- a lagoa ----------------------------------------------------------
    final agua = cenario.aguaCom(luz.agua);
    final funda = cenario.aguaFundaCom(luz.aguaFunda);
    final topoDaAgua = g.linhaDagua - 40 * e;
    final lagoa = Path()
      ..moveTo(beira - 40, h)
      ..lineTo(beira - 30, g.chao + 30)
      ..quadraticBezierTo(beira - 10, topoDaAgua + 8, beira + 50, topoDaAgua)
      ..lineTo(largura, topoDaAgua - 6)
      ..lineTo(largura, h)
      ..close();
    // A margem de areia em volta.
    canvas.drawPath(lagoa.shift(const Offset(-10, -6)), _p(areia));
    canvas.drawPath(
      lagoa,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [agua, funda],
            ).createShader(
              Rect.fromLTWH(beira, topoDaAgua, largura - beira, h - topoDaAgua),
            ),
    );
    // Reflexos que andam devagar.
    final rr = math.Random(31);
    final brilho = Paint()
      ..color = luz.brilho
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 16; i++) {
      final x = beira + 40 + rr.nextDouble() * (largura - beira - 60);
      final y = topoDaAgua + 14 + rr.nextDouble() * (h - topoDaAgua - 40);
      final d = math.sin(t * 0.8 + i) * 6;
      final l = 10 + rr.nextDouble() * 18;
      canvas.drawLine(Offset(x + d, y), Offset(x + d + l, y), brilho);
    }
    // Juncos na margem de lá.
    final junco = Paint()
      ..color = Color.lerp(gramaFunda, const Color(0xFF2F5C27), 0.4)!
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 18; i++) {
      final x = beira + 70 + i * (largura - beira - 90) / 18;
      final alto = 18 + (i * 37 % 17).toDouble();
      final v = math.sin(t * 1.1 + i) * 2;
      canvas.drawLine(
        Offset(x, topoDaAgua + 2),
        Offset(x + v, topoDaAgua + 2 - alto * e * 0.6),
        junco,
      );
    }

    // --- tufos e flores pelo campo, balançando ---------------------------
    final rt = math.Random(17);
    final tufo = Paint()
      ..color = gramaFunda
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 70; i++) {
      final x = rt.nextDouble() * beira;
      final y =
          g.horizonte + 16 + rt.nextDouble() * (g.visivel - g.horizonte - 30);
      final s = 0.6 + (y - g.horizonte) / g.visivel * 1.6;
      final v = math.sin(t * 1.4 + x / 40) * 2 * s;
      for (final d in const [-1.0, 0.0, 1.0]) {
        canvas.drawLine(
          Offset(x + d * 3 * s, y),
          Offset(x + d * 5 * s + v, y - 9 * s),
          tufo,
        );
      }
      if (i % 5 == 0) {
        canvas.drawCircle(
          Offset(x + v, y - 10 * s),
          2.6 * s,
          _p(i % 10 == 0 ? const Color(0xFFE9A0C4) : const Color(0xFFFFF4C9)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(FundoDoMundo old) =>
      old.g.tela != g.tela || old.luz != luz || old.cenario != cenario;
}

/// O capim do primeiro plano, por cima do bicho e dos brinquedos: passa
/// mais rápido que o chão (fator 1,25) e emoldura a cena embaixo.
class FrenteDoMundo extends CustomPainter {
  FrenteDoMundo({
    required this.g,
    required this.luz,
    required this.cenario,
    required this.camera,
    required this.tempo,
  }) : super(repaint: Listenable.merge([camera, tempo]));

  final GeometriaDoMundo g;
  final LuzDaCena luz;
  final CenarioDoHabitat cenario;
  final ValueNotifier<double> camera;
  final ValueNotifier<double> tempo;

  @override
  void paint(Canvas canvas, Size size) {
    // O capim da frente nasce no pé do que se vê, logo acima do painel.
    final h = g.visivel;
    final cam = math.max(0.0, camera.value);
    final t = tempo.value;
    final escuro = Color.lerp(
      Color.lerp(cenario.colinaCom(luz.colina), const Color(0xFF3F6B33), 0.6)!,
      luz.ceuAlto,
      _noite(luz) ? 0.35 : 0,
    )!;
    canvas.save();
    canvas.translate(-cam * 1.25, 0);
    final r = math.Random(41);
    final talo = Paint()
      ..color = escuro
      ..strokeCap = StrokeCap.round;
    final fim = g.largura * 1.25 + size.width;
    for (var x = -20.0; x < fim; x += 9 + r.nextDouble() * 14) {
      // A lagoa não tem capim na frente: só a terra.
      if (x / 1.25 > g.x(ZonasDoMundo.beira) - 30) {
        r.nextDouble();
        continue;
      }
      final alto = h * (0.035 + r.nextDouble() * 0.05);
      final v = math.sin(t * 1.3 + x / 50) * 4;
      talo.strokeWidth = 3 + r.nextDouble() * 2.5;
      canvas.drawLine(
        Offset(x, h + 4),
        Offset(x + v + (r.nextDouble() - 0.5) * 8, h - alto),
        talo,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FrenteDoMundo old) => false;
}
