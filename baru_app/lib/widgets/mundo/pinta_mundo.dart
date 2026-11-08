/// O desenho do mundo da home, em camadas com paralaxe.
///
/// Do fundo para a frente: céu (com sol ou lua, nuvens, estrelas), as
/// chapadas do Cerrado em três fiadas, as árvores de baru com a sua faixa
/// de chão, o campo com a toca, o canto dos brinquedos e a lagoa — e, por
/// cima de tudo, o capim do primeiro plano, que passa mais rápido que o
/// resto. Cada camada anda a uma fração da câmera: é isso que dá
/// profundidade a um mundo plano.
///
/// A luz vem de [LuzDaCena], por período: o sol nasce do lado da terra, se
/// põe atrás das chapadas, a lua fica sobre a lagoa e se reflete nela. Tudo
/// o que se mexe lê o mesmo campo de [vento] (laudo 35, R9).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../habitat.dart';
import 'mundo.dart';

Paint _p(Color c) => Paint()
  ..color = c
  ..isAntiAlias = true;

Color _lerp(Color a, Color b, double k) => Color.lerp(a, b, k)!;
Color _claro(Color c, double k) => _lerp(c, const Color(0xFFFFFFFF), k);
Color _escuro(Color c, double k) => _lerp(c, const Color(0xFF1C1A14), k);

/// Uma camada que anda a [fator] da câmera; devolve o deslocamento em px.
double _desloca(double camera, double fator) => -camera * fator;

/// O campo de vento do mundo, em [t] segundos e [x] px do mundo.
///
/// Uma brisa fraca e, a cada 9 s, uma rajada que entra pela esquerda e
/// atravessa o mundo a 300 px/s (ataque de 1,5 s, decaimento de ~4 s).
/// Capim, tufos, juncos e copas leem o mesmo campo com amplitudes próprias:
/// setenta senos independentes liam como gelatina, não como vento.
double vento(double t, double x) {
  const periodo = 9.0;
  final f = ((t - x / 300) % periodo + periodo) % periodo;
  final rajada = f < 1.5 ? f / 1.5 : math.exp(-(f - 1.5) / 1.3);
  return 0.06 * math.sin(t * 1.1 + x / 220) + rajada;
}

/// Uma lâmina de capim: dois lados que afunilam até a ponta, curvada por
/// [curva] px para o lado do vento.
Path _lamina(Offset pe, double altura, double larguraBase, double curva) {
  final ponta = Offset(pe.dx + curva, pe.dy - altura);
  final cx = pe.dx + curva * 0.35, cy = pe.dy - altura * 0.55;
  return Path()
    ..moveTo(pe.dx - larguraBase / 2, pe.dy)
    ..quadraticBezierTo(cx - larguraBase / 4, cy, ponta.dx, ponta.dy)
    ..quadraticBezierTo(
      cx + larguraBase / 4,
      cy,
      pe.dx + larguraBase / 2,
      pe.dy,
    )
    ..close();
}

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

  /// A altura de referência do céu: o horizonte fica a 56% dela.
  double get _hCeu => g.horizonte / 0.56;

  /// Onde o campo (camada 1,0) começa: um pouco abaixo do horizonte, para
  /// deixar à vista a faixa de chão das árvores (CEN-23).
  double get _topoDoCampo => g.horizonte + _hCeu * 0.045;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = _hCeu;
    final cam = math.max(0.0, camera.value);
    final t = tempo.value;
    final noite = luz.noite;
    // A crista das chapadas: o sol baixo se põe atrás dela.
    final crista = h * 0.53;
    final astro = Offset(
      w * luz.astroX + _desloca(cam, 0.03),
      crista - luz.astroAlto * 0.5 * h,
    );

    // --- céu: três paradas (zênite, meio, horizonte) ---------------------
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [luz.ceuAlto, luz.ceuMeio, luz.ceuBaixo, luz.ceuBaixo],
          stops: const [0, 0.3, 0.56, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    if (noite) {
      _estrelas(canvas, w, h, cam, t);
    } else {
      _passaro(canvas, w, h, cam, t);
    }
    _astro(canvas, astro, noite);
    _nuvens(canvas, w, h, cam, t, astro, noite);

    // --- chapadas (o horizonte do Cerrado), em três fiadas -----------------
    final colina = cenario.colinaCom(luz.colina);
    final longe = _lerp(colina, luz.ceuBaixo, 0.4);
    final media = _lerp(colina, luz.ceuBaixo, 0.2);
    final perto = _lerp(colina, luz.ceuBaixo, 0.04);
    canvas.save();
    canvas.translate(_desloca(cam, 0.15), 0);
    _chapadas(
      canvas,
      de: -200,
      ate: g.largura * 0.15 + w + 200,
      base: crista,
      altura: h * 0.07,
      pico: cenario.pico,
      cor: longe,
      semente: 5,
    );
    canvas.restore();
    canvas.save();
    canvas.translate(_desloca(cam, 0.3), 0);
    _chapadas(
      canvas,
      de: -200,
      ate: g.largura * 0.3 + w + 200,
      base: g.horizonte + h * 0.015,
      altura: h * 0.05,
      pico: cenario.pico,
      cor: media,
      semente: 9,
    );
    canvas.restore();

    // --- colinas: elipses achatadas, assimétricas ------------------------
    canvas.save();
    canvas.translate(_desloca(cam, 0.45), 0);
    final rc = math.Random(23);
    for (
      var x = -400.0;
      x < g.largura * 0.45 + w + 400;
      x += 220 + rc.nextDouble() * 260
    ) {
      final larg = 300 + rc.nextDouble() * 400;
      final alt = h * (0.05 + rc.nextDouble() * 0.045);
      canvas.drawPath(
        cenario.pico > 0.5
            ? silhuetaDeColina(
                esquerda: x,
                base: g.horizonte + h * 0.02,
                largura: larg,
                altura: alt * 1.6,
                pico: cenario.pico,
              )
            : _colina(
                x,
                g.horizonte + h * 0.02,
                larg,
                alt,
                (rc.nextDouble() - 0.5) * 0.3,
              ),
        _p(perto),
      );
    }
    canvas.restore();

    // Névoa rente ao horizonte: a camada de ar entre as colinas e o campo.
    final nevoa = noite ? luz.ceuBaixo : const Color(0xFFFFFFFF);
    final faixaDeNevoa = Rect.fromLTWH(0, g.horizonte - 60, w, 70);
    canvas.drawRect(
      faixaDeNevoa,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            nevoa.withValues(alpha: 0),
            nevoa.withValues(alpha: noite ? 0.12 : 0.25),
          ],
        ).createShader(faixaDeNevoa),
    );

    // --- árvores de baru, na sua própria faixa de chão -------------------
    final copa = _lerp(
      const Color(0xFF5F8A4C),
      luz.ceuAlto,
      noite ? 0.5 : (luz.acendeLuzes ? 0.25 : 0.12),
    );
    final tronco = _lerp(
      const Color(0xFF7A5A3C),
      luz.ceuAlto,
      noite ? 0.45 : 0.1,
    );
    final grama = _lerp(luz.grama, cenario.colina, cenario.forca * 0.6);
    canvas.save();
    canvas.translate(_desloca(cam, 0.72), 0);
    final fimDaFaixa = g.largura * 0.72 + w + 300;
    final faixa = Path()..moveTo(-300, size.height);
    for (var x = -300.0; x <= fimDaFaixa; x += 30) {
      faixa.lineTo(x, g.horizonte - 4 + math.sin(x / 210) * 5);
    }
    faixa
      ..lineTo(fimDaFaixa, size.height)
      ..close();
    canvas.drawPath(faixa, _p(_lerp(grama, colina, 0.3)));
    final peDasArvores = g.horizonte + h * 0.03;
    const arvores = [
      (0.04, 1.2),
      (0.2, 0.8),
      (0.33, 1.5),
      (0.5, 0.9),
      (0.62, 2.05),
      (0.86, 1.4),
    ];
    for (var i = 0; i < arvores.length; i++) {
      final (fx, tamanho) = arvores[i];
      _arvoreDeBaru(
        canvas,
        Offset(fx * (g.largura * 0.72 + w), peDasArvores),
        tamanho * 150 * g.escala,
        copa,
        tronco,
        t,
        semente: 50 + i,
      );
    }
    _folhaCaindo(
      canvas,
      t,
      arvores[4].$1 * (g.largura * 0.72 + w),
      peDasArvores,
      2.05 * 150 * g.escala,
      copa,
    );
    canvas.restore();

    // --- o chão do mundo (anda com a câmera) ------------------------------
    canvas.save();
    canvas.translate(-cam, 0);
    _chao(canvas, size, t, cam, astro);
    canvas.restore();
  }

  // ------------------------------------------------------------------ céu

  /// Três classes de estrelas, pintadas depois de tudo o que é céu: oito
  /// grandes com cruz (as únicas que cintilam), quarenta médias e uma faixa
  /// leitosa diagonal de pequenas (CEN-15).
  void _estrelas(Canvas canvas, double w, double h, double cam, double t) {
    final r = math.Random(7);
    final ciclo = w * 1.1;
    double xDe(double u) => (u * ciclo + _desloca(cam, 0.04)) % ciclo;
    final branco = Paint()..color = const Color(0xFFFFFFFF);
    for (var i = 0; i < 14; i++) {
      final o = Offset(xDe(r.nextDouble()), r.nextDouble() * h * 0.42);
      final raio = 2.5 + r.nextDouble();
      final cintila = 0.9 + 0.1 * math.sin(t * (0.6 + r.nextDouble()) + i);
      canvas.drawCircle(o, raio, _p(Colors.white.withValues(alpha: cintila)));
      final cruz = Paint()
        ..color = Colors.white.withValues(alpha: 0.5 * cintila)
        ..strokeWidth = 1;
      canvas.drawLine(o - Offset(raio * 3, 0), o + Offset(raio * 3, 0), cruz);
      canvas.drawLine(o - Offset(0, raio * 3), o + Offset(0, raio * 3), cruz);
    }
    for (var i = 0; i < 110; i++) {
      final o = Offset(xDe(r.nextDouble()), r.nextDouble() * h * 0.5);
      canvas.drawCircle(
        o,
        1.2 + r.nextDouble() * 0.8,
        branco..color = Colors.white.withValues(alpha: 0.85),
      );
    }
    for (var i = 0; i < 150; i++) {
      final x = xDe(r.nextDouble());
      final centro = h * (0.08 + 0.32 * x / ciclo);
      final y = centro + (r.nextDouble() + r.nextDouble() - 1) * h * 0.1;
      if (y > h * 0.5) continue;
      canvas.drawCircle(
        Offset(x, y),
        0.6 + r.nextDouble() * 0.4,
        _p(Colors.white.withValues(alpha: 0.3 + r.nextDouble() * 0.2)),
      );
    }
  }

  /// Um pássaro cruza o céu a cada 32 s, por 4 s (laudo 35, R9).
  void _passaro(Canvas canvas, double w, double h, double cam, double t) {
    final u = (t % 32) / 4;
    if (u >= 1) return;
    final x = -60 + u * (w + 120) + _desloca(cam, 0.1);
    final y = h * 0.2 + math.sin(u * 6) * 14;
    final bate = math.sin(t * 14) * 5;
    final asa = Paint()
      ..color = _escuro(luz.ceuAlto, 0.5).withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(x - 11, y - 4 - bate)
        ..quadraticBezierTo(x - 4, y + 1, x, y)
        ..quadraticBezierTo(x + 4, y + 1, x + 11, y - 4 - bate),
      asa,
    );
  }

  /// Sol com halo em degradê, ou lua com luar e crateras (CEN-08, CEN-14).
  void _astro(Canvas canvas, Offset o, bool noite) {
    if (luz.astro.a == 0) return;
    if (noite) {
      canvas.drawCircle(
        o,
        180,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFDDE6FF).withValues(alpha: 0.18),
              const Color(0xFFDDE6FF).withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: o, radius: 180)),
      );
      canvas.drawCircle(o, 30, _p(luz.astro));
      for (final (dx, dy, r) in const [
        (-9.0, -6.0, 6.0),
        (8.0, 4.0, 4.0),
        (-3.0, 12.0, 3.0),
      ]) {
        canvas.drawCircle(
          o + Offset(dx, dy),
          r,
          _p(const Color(0xFF6C6A88).withValues(alpha: 0.08)),
        );
      }
      return;
    }
    final baixo = luz.astroAlto < 0.3;
    final raio = baixo ? 44.0 : 27.0;
    final halo = baixo ? 150.0 : 110.0;
    canvas.drawCircle(
      o,
      halo,
      Paint()
        ..shader = RadialGradient(
          colors: [
            luz.haloAstro.withValues(alpha: 0.55),
            luz.haloAstro.withValues(alpha: 0.18),
            luz.haloAstro.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: o, radius: halo)),
    );
    canvas.drawCircle(
      o,
      raio,
      Paint()
        ..shader = RadialGradient(
          colors: [
            baixo ? _claro(luz.astro, 0.35) : const Color(0xFFFFF2C2),
            luz.astro,
          ],
          stops: const [0.2, 1],
        ).createShader(Rect.fromCircle(center: o, radius: raio)),
    );
  }

  /// Seis nuvens de três silhuetas, em dois tamanhos: as grandes andam
  /// longe e devagar, as pequenas perto e mais rápido. Perto do astro elas
  /// se dissolvem, para nada empilhar no sol ou na lua (CEN-13).
  void _nuvens(
    Canvas canvas,
    double w,
    double h,
    double cam,
    double t,
    Offset astro,
    bool noite,
  ) {
    final Color topo, base;
    if (noite) {
      topo = _claro(luz.ceuAlto, 0.08);
      base = _escuro(luz.ceuAlto, 0.2);
    } else {
      topo = _lerp(const Color(0xFFFFFFFF), luz.ceuBaixo, 0.08);
      base = _lerp(const Color(0xFFFFFFFF), luz.ceuMeio, 0.4);
    }
    final altas = luz.astroAlto < 0.3;
    final rn = math.Random(11);
    for (var i = 0; i < 6; i++) {
      final grande = i.isEven;
      final largura = grande
          ? 170 + rn.nextDouble() * 90
          : 80 + rn.nextDouble() * 50;
      final ciclo = w * 1.6 + largura;
      final inicio = rn.nextDouble() * ciclo;
      final y = h * (altas ? 0.07 : 0.2) + rn.nextDouble() * h * 0.16;
      final x =
          ((inicio +
                  t * (grande ? 3 : 7) +
                  _desloca(cam, grande ? 0.1 : 0.15)) %
              ciclo) -
          largura;
      final dx = (x - astro.dx).abs(), dy = (y - astro.dy).abs();
      final alfa = dy < 230 ? ((dx - 210) / 120).clamp(0.0, 1.0) : 1.0;
      if (alfa <= 0) continue;
      _nuvem(
        canvas,
        Offset(x, y),
        largura,
        i % 3,
        topo.withValues(alpha: (noite ? 0.9 : 0.95) * alfa),
        base.withValues(alpha: (noite ? 0.9 : 0.95) * alfa),
      );
    }
  }

  /// Uma nuvem: 3–5 bolhas de raios sorteados pela [forma], base reta, o
  /// lado de baixo um tom mais escuro.
  void _nuvem(
    Canvas canvas,
    Offset o,
    double largura,
    int forma,
    Color topo,
    Color base,
  ) {
    final r = math.Random(100 + forma);
    final n = 3 + r.nextInt(3);
    final bolhas = Path();
    for (var i = 0; i < n; i++) {
      final raio = largura * (0.14 + r.nextDouble() * 0.14);
      final cx = o.dx + (i / (n - 1) - 0.5) * largura * 0.8;
      final cy = o.dy - raio * (0.5 + r.nextDouble() * 0.5);
      bolhas.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: raio));
    }
    bolhas.addRect(
      Rect.fromLTWH(
        o.dx - largura * 0.42,
        o.dy - largura * 0.1,
        largura * 0.84,
        largura * 0.1,
      ),
    );
    final corte = Path()
      ..addRect(
        Rect.fromLTWH(o.dx - largura, o.dy - largura, largura * 2, largura),
      );
    final nuvem = Path.combine(PathOperation.intersect, bolhas, corte);
    canvas.drawPath(nuvem, _p(base));
    canvas.save();
    canvas.clipPath(nuvem);
    canvas.drawPath(nuvem.shift(Offset(0, -largura * 0.08)), _p(topo));
    canvas.restore();
  }

  // ------------------------------------------------------------- relevo

  /// Chapadas: topo quase reto, levemente inclinado, e o paredão da encosta
  /// dois tons mais escuro (ou picos, na serra). Em coordenadas do mundo:
  /// o deslocamento é do `translate` de fora (CEN-F2).
  void _chapadas(
    Canvas canvas, {
    required double de,
    required double ate,
    required double base,
    required double altura,
    required double pico,
    required Color cor,
    required int semente,
  }) {
    final r = math.Random(semente);
    final path = Path()..moveTo(de, base + 40);
    final paredoes = Path();
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
        final inclina = (r.nextDouble() - 0.5) * alto * 0.3;
        final xr = x + subida + topo;
        path.lineTo(x + subida, base - alto);
        path.lineTo(xr, base - alto + inclina);
        x += subida * 2 + topo;
        final fim = base - r.nextDouble() * altura * 0.15;
        path.lineTo(x, fim);
        paredoes
          ..moveTo(xr, base - alto + inclina)
          ..lineTo(x, fim)
          ..lineTo(x, base + 40)
          ..lineTo(xr - alto * 0.35, base + 40)
          ..close();
      }
      x += r.nextDouble() * 60;
      path.lineTo(x, base);
    }
    path
      ..lineTo(ate, base + 40)
      ..close();
    canvas.drawPath(path, _p(cor));
    canvas.save();
    canvas.clipPath(path);
    canvas.drawPath(paredoes, _p(_escuro(cor, 0.12)));
    canvas.restore();
  }

  /// Uma colina baixa: elipse achatada (altura ≤ 0,35 da largura) com o
  /// ápice fora do meio (CEN-09).
  Path _colina(
    double esquerda,
    double base,
    double largura,
    double altura,
    double assimetria,
  ) {
    final direita = esquerda + largura;
    final ax = esquerda + largura * (0.5 + assimetria);
    return Path()
      ..moveTo(esquerda, base)
      ..cubicTo(
        esquerda + (ax - esquerda) * 0.5,
        base,
        ax - (ax - esquerda) * 0.3,
        base - altura,
        ax,
        base - altura,
      )
      ..cubicTo(
        ax + (direita - ax) * 0.3,
        base - altura,
        direita - (direita - ax) * 0.5,
        base,
        direita,
        base,
      )
      ..close();
  }

  /// O baru (Dipteryx alata): fuste reto e alto, copa larga, densa e
  /// arredondada, em lóbulos de dois tons com vazios de céu (CEN-10).
  void _arvoreDeBaru(
    Canvas canvas,
    Offset pe,
    double altura,
    Color copa,
    Color tronco,
    double t, {
    required int semente,
  }) {
    final r = math.Random(semente);
    final balanco = vento(t, pe.dx) * altura * 0.035;
    final lt = altura * 0.08;
    final fuste = altura * 0.45;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(pe.dx + altura * 0.04, pe.dy + 2),
        width: altura * 0.55,
        height: altura * 0.07,
      ),
      _p(const Color(0xFF000000).withValues(alpha: 0.12)),
    );
    final tr = Rect.fromLTWH(
      pe.dx - lt / 2,
      pe.dy - fuste - altura * 0.12,
      lt,
      fuste + altura * 0.12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tr, Radius.circular(lt * 0.3)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_claro(tronco, 0.12), tronco, _escuro(tronco, 0.3)],
          stops: const [0, 0.45, 1],
        ).createShader(tr),
    );
    // O pé alargado.
    canvas.drawPath(
      Path()
        ..moveTo(pe.dx - lt * 0.9, pe.dy)
        ..quadraticBezierTo(
          pe.dx - lt * 0.5,
          pe.dy - altura * 0.03,
          pe.dx - lt / 2,
          pe.dy - altura * 0.06,
        )
        ..lineTo(pe.dx + lt / 2, pe.dy - altura * 0.06)
        ..quadraticBezierTo(
          pe.dx + lt * 0.5,
          pe.dy - altura * 0.03,
          pe.dx + lt * 0.9,
          pe.dy,
        )
        ..close(),
      _p(tronco),
    );
    // Dois galhos curtos, para dentro da copa.
    final galho = Paint()
      ..color = _escuro(tronco, 0.1)
      ..strokeWidth = lt * 0.45
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final topoDoFuste = Offset(pe.dx, pe.dy - fuste);
    canvas.drawLine(
      topoDoFuste + Offset(0, altura * 0.02),
      topoDoFuste + Offset(-altura * 0.2 + balanco * 0.5, -altura * 0.2),
      galho,
    );
    canvas.drawLine(
      topoDoFuste,
      topoDoFuste + Offset(altura * 0.22 + balanco * 0.5, -altura * 0.18),
      galho,
    );
    // A copa.
    final cc = Offset(pe.dx + balanco, pe.dy - fuste - altura * 0.28);
    final lw = altura * 0.95, lh = altura * 0.55;
    final n = 6 + r.nextInt(3);
    final lobos = Path();
    final lista = <(Offset, double)>[];
    for (var i = 0; i < n; i++) {
      final a = (i / n) * 2 * math.pi + r.nextDouble() * 0.5;
      final raio = lh * (0.28 + r.nextDouble() * 0.14);
      final c =
          cc +
          Offset(
            math.cos(a) * (lw / 2 - raio) * 0.95,
            math.sin(a) * (lh / 2 - raio) * 0.9,
          );
      lista.add((c, raio));
      lobos.addOval(Rect.fromCircle(center: c, radius: raio));
    }
    lobos.addOval(
      Rect.fromCenter(center: cc, width: lw * 0.7, height: lh * 0.75),
    );
    final furos = Path();
    final nFuros = 2 + r.nextInt(2);
    for (var i = 0; i < nFuros; i++) {
      final a = r.nextDouble() * 2 * math.pi;
      furos.addOval(
        Rect.fromCircle(
          center: cc + Offset(math.cos(a) * lw * 0.3, math.sin(a) * lh * 0.3),
          radius: lh * (0.05 + r.nextDouble() * 0.04),
        ),
      );
    }
    final forma = Path.combine(PathOperation.difference, lobos, furos);
    canvas.drawPath(forma, _p(_escuro(copa, 0.15)));
    canvas.save();
    canvas.clipPath(forma);
    canvas.drawPath(lobos.shift(Offset(-lw * 0.04, -lh * 0.14)), _p(copa));
    final brilho = Path();
    for (final (c, raio) in lista) {
      if (c.dy < cc.dy) {
        brilho.addOval(
          Rect.fromCircle(
            center: c + Offset(-raio * 0.2, -raio * 0.3),
            radius: raio * 0.7,
          ),
        );
      }
    }
    canvas.drawPath(brilho, _p(_claro(copa, 0.12)));
    canvas.restore();
  }

  /// Uma folha cai da maior árvore a cada 15 s, em zigue-zague por 4 s.
  void _folhaCaindo(
    Canvas canvas,
    double t,
    double x0,
    double pe,
    double altura,
    Color copa,
  ) {
    final u = (t % 15) / 4;
    if (u >= 1) return;
    final y = pe - altura * 0.8 + u * altura * 0.8;
    final x = x0 + 60 + math.sin(u * math.pi * 4) * 30 + u * 40;
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(u * 10);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 10, height: 5),
      _p(_claro(copa, 0.2)),
    );
    canvas.restore();
  }

  // ---------------------------------------------------------------- chão

  void _chao(Canvas canvas, Size size, double t, double cam, Offset astro) {
    final h = size.height;
    final largura = g.largura;
    final beira = g.x(ZonasDoMundo.beira);
    final e = g.escala;
    final noite = luz.noite;
    final grama = _lerp(luz.grama, cenario.colina, cenario.forca * 0.6);
    final gramaFunda = _lerp(
      luz.gramaFunda,
      cenario.colina,
      cenario.forca * 0.6,
    );
    final areia = cenario.areiaCom(luz.areia);
    final topo = _topoDoCampo;

    // O campo em três bandas de valor: a do fundo mais clara (ar), a do meio
    // onde o bicho pisa, e a da frente mais funda (CEN-11, CEN-19).
    Path banda(double de, double ate, double onda) {
      final p = Path()..moveTo(0, ate);
      for (var x = 0.0; x <= largura; x += 24) {
        p.lineTo(x, de + math.sin(x / 260 + onda) * 8 + math.sin(x / 90) * 3);
      }
      p
        ..lineTo(largura, ate)
        ..close();
      return p;
    }

    canvas.drawPath(banda(topo, h, 0), _p(_lerp(grama, luz.ceuBaixo, 0.22)));
    canvas.drawPath(banda(g.chao - 40, h, 1.7), _p(grama));
    canvas.drawPath(banda(g.linhaDagua + 12, h, 3.1), _p(gramaFunda));

    // Hachura leve, mais densa perto da câmera.
    final hachura = Path();
    final rh = math.Random(13);
    for (var y = topo + 14; y < h; y += 30 - (y - topo) / (h - topo) * 16) {
      for (
        var x = rh.nextDouble() * 40;
        x < beira - 20;
        x += 50 + rh.nextDouble() * 70
      ) {
        final l = 8 + rh.nextDouble() * 16;
        hachura
          ..moveTo(x, y)
          ..lineTo(x + l, y + (rh.nextDouble() - 0.5) * 2);
      }
    }
    canvas.drawPath(
      hachura,
      Paint()
        ..color = const Color(0xFF000000).withValues(alpha: 0.05)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );

    // Sombra de uma nuvem passeando pelo campo.
    if (!noite) {
      final sx = (largura * 0.2 + t * 4) % (largura + 600) - 300;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(sx, g.chao - 20),
          width: 400,
          height: 50,
        ),
        _p(const Color(0xFF000000).withValues(alpha: 0.06)),
      );
    }

    _trilha(canvas, areia, grama);
    _toca(canvas, areia, gramaFunda, t);
    _cantoDosBrinquedos(canvas, areia, grama);
    _lagoa(
      canvas,
      h,
      largura,
      beira,
      e,
      t,
      cam,
      astro,
      areia,
      grama,
      gramaFunda,
    );
    _tufos(canvas, beira, e, t, grama, gramaFunda);
  }

  /// A trilha de terra batida, da toca à margem: largura variável, bordas
  /// em ruído, afinando em ponta nas duas extremidades (CEN-05).
  void _trilha(Canvas canvas, Color areia, Color grama) {
    final r = math.Random(29);
    final x0 = g.x(0.06), x1 = g.x(0.66);
    final cima = <Offset>[], baixo = <Offset>[];
    for (var x = x0; x <= x1; x += 24) {
      final s = (x - x0) / (x1 - x0);
      final y = g.chao + 14 + math.sin(s * math.pi * 2) * 10;
      final meia =
          math.pow(math.sin(s * math.pi), 0.5) *
          (6 + 7 * (0.5 + 0.5 * math.sin(s * 13 + 1)));
      cima.add(Offset(x, y - meia + (r.nextDouble() - 0.5) * 6));
      baixo.add(Offset(x, y + meia + (r.nextDouble() - 0.5) * 6));
    }
    final trilha = Path()..moveTo(cima.first.dx, cima.first.dy);
    for (final o in cima.skip(1)) {
      trilha.lineTo(o.dx, o.dy);
    }
    for (final o in baixo.reversed) {
      trilha.lineTo(o.dx, o.dy);
    }
    trilha.close();
    canvas.drawPath(
      trilha,
      _p(_lerp(areia, grama, 0.5).withValues(alpha: 0.7)),
    );
    final terra = _p(_escuro(areia, 0.35).withValues(alpha: 0.5));
    for (var i = 0; i < 26; i++) {
      final s = r.nextDouble();
      final x = x0 + s * (x1 - x0);
      final y =
          g.chao +
          14 +
          math.sin(s * math.pi * 2) * 10 +
          (r.nextDouble() - 0.5) * 10;
      canvas.drawCircle(Offset(x, y), 1 + r.nextDouble(), terra);
    }
  }

  /// A toca: um monte de terra de 330 × 110 unidades do bicho, com dois
  /// tons, tufos por cima e raízes expostas; a boca é um arco de 105
  /// unidades que nasce na base (CEN-17).
  void _toca(Canvas canvas, Color areia, Color gramaFunda, double t) {
    final e = g.escala;
    final tx = g.x(0.09), base = g.chao + 6;
    final terra = _lerp(areia, const Color(0xFF8A6A48), 0.35);
    final monte = Path()
      ..moveTo(tx - 165 * e, base)
      ..cubicTo(
        tx - 125 * e,
        base - 147 * e,
        tx + 70 * e,
        base - 150 * e,
        tx + 165 * e,
        base,
      )
      ..close();
    canvas.drawPath(
      monte,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_claro(terra, 0.14), terra, _escuro(terra, 0.2)],
              stops: const [0, 0.5, 1],
            ).createShader(
              Rect.fromLTWH(tx - 165 * e, base - 110 * e, 330 * e, 110 * e),
            ),
    );
    // Raízes expostas na encosta da esquerda.
    final raiz = Paint()
      ..color = _escuro(terra, 0.35)
      ..strokeWidth = 2.2 * e * 0.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final (dx, dy, l) in const [
      (-120.0, -30.0, 36.0),
      (-95.0, -58.0, 28.0),
      (105.0, -40.0, 30.0),
    ]) {
      final o = Offset(tx + dx * e, base + dy * e);
      canvas.drawPath(
        Path()
          ..moveTo(o.dx, o.dy)
          ..quadraticBezierTo(
            o.dx + l * e * 0.4,
            o.dy + l * e * 0.5,
            o.dx + l * e * 0.9,
            o.dy + l * e * 0.4,
          ),
        raiz,
      );
    }
    // Tufos por cima do monte.
    final tufo = Path();
    final r = math.Random(19);
    for (var i = 0; i < 9; i++) {
      final s = -0.8 + i * 0.2;
      final x = tx + s * 150 * e;
      final y = base - (1 - s * s) * 105 * e + 6 * e;
      final v = vento(t, x) * 0.6;
      for (var k = 0; k < 5; k++) {
        tufo.addPath(
          _lamina(
            Offset(x + (k - 2) * 3 * e * 0.6, y),
            (8 + r.nextDouble() * 8) * e * 0.6,
            2.2 * e * 0.6,
            (k - 2) * 2 + v * 6,
          ),
          Offset.zero,
        );
      }
    }
    canvas.drawPath(tufo, _p(gramaFunda));
    // A boca: arco que nasce na base e sobe 105 unidades; dentro, escuro.
    final boca = Path()
      ..moveTo(tx - 62 * e, base)
      ..cubicTo(
        tx - 62 * e,
        base - 146 * e,
        tx + 62 * e,
        base - 146 * e,
        tx + 62 * e,
        base,
      )
      ..close();
    canvas.drawPath(
      boca,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [Color(0xFF1A110C), Color(0xFF3B2A1E)],
            ).createShader(
              Rect.fromLTWH(tx - 62 * e, base - 110 * e, 124 * e, 110 * e),
            ),
    );
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(tx - 80 * e, base - 120 * e, 160 * e, 120 * e),
    );
    canvas.drawPath(
      boca,
      Paint()
        ..color = _lerp(areia, const Color(0xFF6B5A4A), 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * e * 0.6,
    );
    canvas.restore();
    for (final (dx, raio) in const [
      (-78.0, 5.0),
      (-70.0, 3.0),
      (72.0, 4.5),
      (84.0, 3.0),
    ]) {
      canvas.drawCircle(
        Offset(tx + dx * e, base - 2 * e),
        raio * e * 0.6,
        _p(_lerp(areia, const Color(0xFF6B5A4A), 0.5)),
      );
    }
  }

  /// O canto dos brinquedos: terra batida de borda irregular, pedrinhas e
  /// um toco — marcas de uso, não uma elipse (CEN-24).
  void _cantoDosBrinquedos(Canvas canvas, Color areia, Color grama) {
    final e = g.escala;
    final c = Offset(g.x(0.27), g.chao + 12);
    final rx = g.x(0.08), ry = 20 * e;
    final r = math.Random(43);
    final terra = Path();
    for (var i = 0; i < 28; i++) {
      final a = i / 28 * 2 * math.pi;
      final k = 0.82 + r.nextDouble() * 0.3;
      final o = c + Offset(math.cos(a) * rx * k, math.sin(a) * ry * k);
      if (i == 0) {
        terra.moveTo(o.dx, o.dy);
      } else {
        terra.lineTo(o.dx, o.dy);
      }
    }
    terra.close();
    canvas.drawPath(
      terra,
      _p(_lerp(areia, grama, 0.35).withValues(alpha: 0.75)),
    );
    // Pedrinhas.
    for (final (dx, dy, raio) in const [
      (-0.7, 0.5, 5.0),
      (-0.55, 0.75, 3.5),
      (0.6, 0.55, 4.5),
      (0.3, 0.9, 3.0),
    ]) {
      final o = c + Offset(dx * rx, dy * ry);
      canvas.drawOval(
        Rect.fromCenter(
          center: o,
          width: raio * 2 * e * 0.6,
          height: raio * 1.4 * e * 0.6,
        ),
        _p(const Color(0xFF8E8A82)),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: o + Offset(-raio * 0.2, -raio * 0.3),
          width: raio * 1.1 * e * 0.6,
          height: raio * 0.7 * e * 0.6,
        ),
        _p(const Color(0xFFB3AFA6)),
      );
    }
    // Um toco de árvore no canto direito.
    final toco = Rect.fromLTWH(
      c.dx + rx * 0.85,
      c.dy - 22 * e * 0.6,
      22 * e * 0.6,
      24 * e * 0.6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(toco, Radius.circular(3 * e * 0.6)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [Color(0xFF8C6B4A), Color(0xFF5E4630)],
        ).createShader(toco),
    );
    final tampo = Rect.fromCenter(
      center: toco.topCenter,
      width: toco.width + 2,
      height: toco.width * 0.5,
    );
    canvas.drawOval(tampo, _p(const Color(0xFFC9A77A)));
    canvas.drawOval(
      tampo.deflate(toco.width * 0.18),
      Paint()
        ..color = const Color(0xFFA8865C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: toco.bottomCenter + Offset(4, 0),
        width: toco.width * 1.8,
        height: toco.width * 0.4,
      ),
      _p(const Color(0xFF000000).withValues(alpha: 0.12)),
    );
  }

  /// A lagoa: margem de lá em lóbulos, faixa de areia contínua, raso claro,
  /// água em três paradas, reflexos com causa (astro, juncos, buritis),
  /// ondulação leve e um peixe de vez em quando (CEN-03, CEN-04, CEN-08).
  void _lagoa(
    Canvas canvas,
    double h,
    double largura,
    double beira,
    double e,
    double t,
    double cam,
    Offset astro,
    Color areia,
    Color grama,
    Color gramaFunda,
  ) {
    final noite = luz.noite;
    final agua = cenario.aguaCom(luz.agua);
    final funda = cenario.aguaFundaCom(luz.aguaFunda);
    final topoDaAgua = g.linhaDagua - 40 * e;
    final lagoa = Path()
      ..moveTo(beira - 40, h)
      ..lineTo(beira - 30, g.chao + 30)
      ..quadraticBezierTo(beira - 10, topoDaAgua + 8, beira + 50, topoDaAgua);
    final rl = math.Random(37);
    final lobulos = <Offset>[Offset(beira + 50, topoDaAgua)];
    var x = beira + 50.0, y = topoDaAgua;
    while (x < largura) {
      final nx = math.min(largura, x + 260 + rl.nextDouble() * 220);
      final ny = topoDaAgua + (rl.nextDouble() - 0.5) * 44;
      lagoa.quadraticBezierTo(
        (x + nx) / 2 + (rl.nextDouble() - 0.5) * 60,
        (y + ny) / 2 + (rl.nextDouble() - 0.5) * 50,
        nx,
        ny,
      );
      lobulos.add(Offset(nx, ny));
      x = nx;
      y = ny;
    }
    lagoa
      ..lineTo(largura, h)
      ..close();

    // Buritis na margem de lá, atrás da água.
    final copa = _lerp(
      _lerp(const Color(0xFF4F7A42), luz.ceuAlto, noite ? 0.5 : 0.15),
      luz.ceuBaixo,
      0.2,
    );
    final rb = math.Random(53);
    final buritis = <(Offset, double)>[];
    for (var i = 1; i < lobulos.length - 1; i++) {
      if (rb.nextDouble() < 0.4) continue;
      final o = lobulos[i] + Offset((rb.nextDouble() - 0.5) * 120, 2);
      buritis.add((o, (0.22 + rb.nextDouble() * 0.14) * _hCeu));
    }
    for (final (o, alt) in buritis) {
      _buriti(canvas, o, alt, copa, t);
    }

    // A faixa de areia em toda a volta, e a água.
    canvas.drawPath(
      lagoa,
      Paint()
        ..color = areia
        ..style = PaintingStyle.stroke
        ..strokeWidth = 34
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      lagoa,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_lerp(luz.ceuBaixo, agua, 0.5), agua, funda],
              stops: const [0, 0.3, 1],
            ).createShader(
              Rect.fromLTWH(
                beira,
                topoDaAgua - 22,
                largura - beira,
                h - topoDaAgua + 22,
              ),
            ),
    );
    canvas.save();
    canvas.clipPath(lagoa);
    // O raso junto às margens, e a linha de sombra da margem na água.
    canvas.drawPath(
      lagoa,
      Paint()
        ..color = _lerp(agua, areia, 0.35).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18,
    );
    canvas.drawPath(
      lagoa,
      Paint()
        ..color = _escuro(areia, 0.3).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    // Reflexos invertidos dos buritis e dos juncos, partidos por ondas.
    for (final (o, alt) in buritis) {
      canvas.save();
      canvas.translate(0, o.dy * 2);
      canvas.scale(1, -0.6);
      canvas.saveLayer(
        null,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.3),
      );
      _buriti(canvas, o, alt, _escuro(copa, 0.2), t);
      canvas.restore();
      canvas.restore();
    }
    // A trilha do astro na água, quando ele está sobre a lagoa.
    final ax = astro.dx + cam;
    if (ax > beira + 60 &&
        ax < largura - 40 &&
        (noite || luz.astroAlto < 0.3)) {
      final cor = noite ? const Color(0xFFDDE6FF) : _claro(luz.astro, 0.3);
      final n = 9;
      for (var i = 0; i < n; i++) {
        final yy = topoDaAgua + 24 + i * (h - topoDaAgua - 50) / n;
        final larg = 90 * (1 - i * 0.06);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(ax + math.sin(t * 0.9 + i * 1.3) * 10, yy),
            width: larg,
            height: 5,
          ),
          _p(cor.withValues(alpha: noite ? 0.55 : 0.4)),
        );
      }
    }
    // Ondulação leve: elipses de 1 px que andam com o vento.
    final rr = math.Random(31);
    final ondula = _lerp(luz.ceuBaixo, const Color(0xFFFFFFFF), 0.5);
    for (var i = 0; i < 26; i++) {
      final x = beira + 60 + rr.nextDouble() * (largura - beira - 100);
      final y = topoDaAgua + 20 + rr.nextDouble() * (h - topoDaAgua - 50);
      final l = 12 + rr.nextDouble() * 20;
      final d = math.sin(t * 0.6 + i) * 9;
      final v = (0.25 + 0.75 * vento(t, x)).clamp(0.0, 1.0);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x + d, y), width: l, height: 1.2),
        _p(ondula.withValues(alpha: 0.35 * v)),
      );
    }
    _peixe(
      canvas,
      t,
      Offset(
        beira + (largura - beira) * 0.5,
        topoDaAgua + (h - topoDaAgua) * 0.45,
      ),
      ondula,
    );
    canvas.restore();

    // Juncos em touceiras nos lóbulos da margem de lá, com reflexo.
    final rj = math.Random(47);
    for (var i = 1; i < lobulos.length; i++) {
      final o = lobulos[i] + Offset((rj.nextDouble() - 0.5) * 160, 0);
      if (o.dx > largura - 40) continue;
      _touceiraDeJunco(canvas, o, e, t, rj.nextInt(1000), gramaFunda, lagoa);
    }

    // Névoa da manhã sobre a lagoa.
    if (!noite && luz.astroAlto < 0.3 && luz.astroX < 0.5) {
      final faixa = Rect.fromLTWH(beira, topoDaAgua - 80, largura - beira, 80);
      canvas.drawRect(
        faixa,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Color(0x00FFFFFF), Color(0x4DFFFFFF)],
          ).createShader(faixa),
      );
    }
  }

  /// Um buriti (Mauritia flexuosa): fuste fino e reto, leque de 7–9 folhas
  /// rígidas no ápice — a palmeira da vereda (laudo 35, R7).
  void _buriti(Canvas canvas, Offset pe, double altura, Color cor, double t) {
    final apice = Offset(pe.dx, pe.dy - altura);
    canvas.drawPath(
      Path()
        ..moveTo(pe.dx - altura * 0.025, pe.dy)
        ..lineTo(apice.dx - altura * 0.012, apice.dy)
        ..lineTo(apice.dx + altura * 0.012, apice.dy)
        ..lineTo(pe.dx + altura * 0.025, pe.dy)
        ..close(),
      _p(_escuro(cor, 0.25)),
    );
    final v = vento(t, pe.dx) * 0.4;
    final folha = Paint()
      ..color = cor
      ..strokeWidth = altura * 0.03
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 8; i++) {
      final a = -math.pi * 0.95 + i / 7 * math.pi * 0.9 + v * 0.15;
      final l = altura * (0.16 + (i % 3) * 0.03);
      final ponta = apice + Offset(math.cos(a) * l, math.sin(a) * l + l * 0.25);
      canvas.drawLine(apice, ponta, folha);
      canvas.drawOval(
        Rect.fromCenter(center: ponta, width: l * 0.55, height: l * 0.35),
        _p(cor),
      );
    }
  }

  /// Uma touceira de junco: 3–5 lâminas curvas de larguras e alturas
  /// diferentes, dois tons, uma em três com espiga de taboa; o reflexo
  /// invertido na água (CEN-04, CEN-22 — o mesmo desenho do item `juncos`).
  void _touceiraDeJunco(
    Canvas canvas,
    Offset pe,
    double e,
    double t,
    int semente,
    Color base,
    Path lagoa,
  ) {
    final r = math.Random(semente);
    final n = 3 + r.nextInt(3);
    final v = vento(t, pe.dx) * 0.8;
    final tons = [base, _claro(base, 0.15)];
    final espigaCor = _lerp(
      const Color(0xFF6B4A2E),
      luz.ceuAlto,
      luz.noite ? 0.4 : 0,
    );
    // As lâminas, sorteadas uma vez: o reflexo é a mesma touceira.
    final laminas = [
      for (var k = 0; k < n; k++)
        (
          alto: (30 + r.nextDouble() * 60) * e * 0.6,
          larg: 2 + r.nextDouble() * 2,
          x: pe.dx + (k - n / 2) * 6 * e * 0.5,
          curva: (k - n / 2) * 4 + (r.nextDouble() - 0.5) * 8 + v * 10,
        ),
    ];
    void desenha() {
      for (var k = 0; k < n; k++) {
        final l = laminas[k];
        final haste = Path()
          ..moveTo(l.x, pe.dy)
          ..quadraticBezierTo(
            l.x + l.curva * 0.3,
            pe.dy - l.alto * 0.55,
            l.x + l.curva,
            pe.dy - l.alto,
          );
        canvas.drawPath(
          haste,
          Paint()
            ..color = tons[k % 2]
            ..strokeWidth = l.larg
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );
        if (k % 3 == 1) {
          final espiga = Rect.fromCenter(
            center: Offset(l.x + l.curva, pe.dy - l.alto + 6 * e * 0.6),
            width: 6 * e * 0.5,
            height: 18 * e * 0.5,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(espiga, Radius.circular(espiga.width / 2)),
            _p(espigaCor),
          );
        }
      }
    }

    desenha();
    // O reflexo: a mesma touceira, invertida e encurtada, só dentro da água.
    canvas.save();
    canvas.clipPath(lagoa);
    canvas.translate(0, pe.dy * 2);
    canvas.scale(1, -0.5);
    canvas.saveLayer(
      null,
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.22),
    );
    desenha();
    canvas.restore();
    canvas.restore();
  }

  /// Um peixe pula na lagoa a cada 47 s: o arco e os anéis que ficam.
  void _peixe(Canvas canvas, double t, Offset o, Color brilho) {
    final u = t % 47;
    if (u < 0.7) {
      final k = u / 0.7;
      final pos = o + Offset((k - 0.5) * 60, -math.sin(k * math.pi) * 40);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate((0.5 - k) * 1.6);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 16, height: 7),
        _p(_lerp(brilho, const Color(0xFF7A8A96), 0.4)),
      );
      canvas.drawPath(
        Path()
          ..moveTo(-8, 0)
          ..lineTo(-13, -4)
          ..lineTo(-13, 4)
          ..close(),
        _p(_lerp(brilho, const Color(0xFF7A8A96), 0.4)),
      );
      canvas.restore();
    }
    if (u > 0.5 && u < 2.6) {
      final k = (u - 0.5) / 2.1;
      for (final d in [0.0, 0.3]) {
        final kk = (k - d).clamp(0.0, 1.0);
        if (kk <= 0) continue;
        canvas.drawOval(
          Rect.fromCenter(center: o, width: 20 + kk * 90, height: 6 + kk * 26),
          Paint()
            ..color = brilho.withValues(alpha: 0.5 * (1 - kk))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
    }
  }

  /// Tufos de 5–7 lâminas curvas em dois tons, e flores de pétalas com
  /// caule, pelo campo; o pé mais largo que a ponta (CEN-11).
  void _tufos(
    Canvas canvas,
    double beira,
    double e,
    double t,
    Color grama,
    Color gramaFunda,
  ) {
    final rt = math.Random(17);
    final escuro = Path(), claro = Path();
    final claroCor = luz.noite
        ? _claro(grama, 0.12)
        : _lerp(grama, const Color(0xFFB9D48A), 0.5);
    final petalas = [
      const Color(0xFFE9A0C4),
      const Color(0xFFFFF4C9),
      const Color(0xFFF2C14E),
    ];
    final topo = _topoDoCampo;
    for (var i = 0; i < 70; i++) {
      final x = rt.nextDouble() * beira;
      final y = topo + 16 + rt.nextDouble() * (g.visivel - topo - 30);
      final s = 0.6 + (y - g.horizonte) / g.visivel * 1.6;
      final v = vento(t, x) * 0.6;
      final n = 5 + rt.nextInt(3);
      for (var k = 0; k < n; k++) {
        final alto = (6 + rt.nextDouble() * 10) * s;
        final curva = (k - n / 2) * 2.2 * s + v * 6 * s;
        final lamina = _lamina(
          Offset(x + (k - n / 2) * 2.4 * s, y),
          alto,
          2.4 * s,
          curva,
        );
        (k.isEven ? escuro : claro).addPath(lamina, Offset.zero);
      }
      if (i % 5 == 0) {
        final cor = luz.noite
            ? _lerp(petalas[i % 3], grama, 0.6)
            : petalas[i % 3];
        final topoFlor = Offset(x + v * 4 * s, y - 14 * s);
        canvas.drawLine(
          Offset(x, y),
          topoFlor,
          Paint()
            ..color = gramaFunda
            ..strokeWidth = 1.2 * s,
        );
        final np = 4 + i % 2;
        for (var p = 0; p < np; p++) {
          final a = p / np * 2 * math.pi;
          canvas.drawCircle(
            topoFlor + Offset(math.cos(a), math.sin(a)) * 2.6 * s,
            2 * s,
            _p(cor),
          );
        }
        canvas.drawCircle(topoFlor, 1.3 * s, _p(const Color(0xFFF2C14E)));
      }
    }
    canvas.drawPath(escuro, _p(gramaFunda));
    canvas.drawPath(claro, _p(claroCor));
  }

  @override
  bool shouldRepaint(FundoDoMundo old) =>
      old.g.tela != g.tela || old.luz != luz || old.cenario != cenario;
}

/// O capim do primeiro plano, por cima do bicho e dos brinquedos: passa
/// mais rápido que o chão (fator 1,25) e emoldura a cena embaixo.
///
/// Touceiras de 4–9 lâminas curvas em três tons, com lacunas, folhas
/// largas e flores silvestres, balançando por touceira com o [vento]; o
/// corte na beira é feito em coordenadas de tela, para o capim não crescer
/// dentro da lagoa (CEN-02, CEN-12).
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
    final w = size.width;
    final cam = math.max(0.0, camera.value);
    final t = tempo.value;
    final noite = luz.noite;
    final base = _lerp(luz.gramaFunda, cenario.colina, cenario.forca * 0.6);
    final escuro = _lerp(_escuro(base, 0.25), luz.ceuAlto, noite ? 0.35 : 0);
    final tons = [
      escuro,
      _claro(escuro, 0.08),
      _lerp(
        escuro,
        const Color(0xFFC8D86A),
        noite ? 0.12 : 0.4,
      ).withValues(alpha: 0.78),
    ];
    final petalas = [
      const Color(0xFFFFF4C9),
      const Color(0xFFE9A0C4),
      const Color(0xFFFFFFFF),
    ];
    final beiraNaTela = g.x(ZonasDoMundo.beira) - cam;
    canvas.save();
    canvas.translate(-cam * 1.25, 0);
    final r = math.Random(41);
    final fim = g.largura * 1.25 + w;
    var x = -20.0;
    var molhados = false;
    while (x < fim) {
      // Os sorteios da touceira saem sempre, visível ou não: o desenho tem
      // de ser o mesmo em qualquer câmera.
      final n = 4 + r.nextInt(6);
      final lacuna = 20 + r.nextDouble() * 40;
      final sementes = List.generate(
        n,
        (_) => (r.nextDouble(), r.nextDouble(), r.nextDouble()),
      );
      final extra = r.nextDouble();
      final larguraDaTouceira = n * 7.0;
      final xTela = x - cam * 1.25;
      if (xTela > -120 && xTela < w + 120) {
        // Medido pela ponta direita da touceira: nenhuma lâmina passa da beira.
        final ateABeira = beiraNaTela - 30 - (xTela + larguraDaTouceira);
        if (ateABeira > 0) {
          // Perto da beira o capim abaixa e rareia: a transição não é um muro.
          final perto = ateABeira < 60;
          final fator = perto ? 0.5 : 1.0;
          final v = vento(t, x / 1.25);
          final balanco = v * 12 + math.sin(t * 1.3 + x / 120) * 2;
          final caminhos = [Path(), Path(), Path()];
          for (var k = 0; k < n; k++) {
            if (perto && k.isOdd) continue;
            final (s1, s2, s3) = sementes[k];
            final alto = h * (0.035 + s1 * 0.06) * fator;
            final larg = 2 + s2 * 4;
            final curva = (s3 - 0.5) * 14 + balanco;
            caminhos[k % 3].addPath(
              _lamina(
                Offset(x + k * 7 + (s2 - 0.5) * 4, h + 4),
                alto,
                larg,
                curva,
              ),
              Offset.zero,
            );
          }
          if (extra > 0.7 && !perto) {
            // Uma folha larga.
            caminhos[2].addPath(
              _lamina(
                Offset(x + n * 3.5, h + 4),
                h * 0.04,
                8 + extra * 4,
                balanco * 0.6 - 6,
              ),
              Offset.zero,
            );
          }
          for (var k = 0; k < 3; k++) {
            canvas.drawPath(caminhos[k], _p(tons[k]));
          }
          if (extra > 0.86 && !perto) {
            final topo = Offset(x + n * 3.5 + balanco * 0.8, h - h * 0.075);
            canvas.drawLine(
              Offset(x + n * 3.5, h + 4),
              topo,
              Paint()
                ..color = tons[1]
                ..strokeWidth = 1.5,
            );
            final cor = noite
                ? _lerp(petalas[n % 3], escuro, 0.5)
                : petalas[n % 3];
            for (var p = 0; p < 5; p++) {
              final a = p / 5 * 2 * math.pi;
              canvas.drawCircle(
                topo + Offset(math.cos(a), math.sin(a)) * 3.2,
                2.4,
                _p(cor),
              );
            }
            canvas.drawCircle(topo, 1.6, _p(const Color(0xFFF2C14E)));
          }
        } else if (!molhados && xTela < beiraNaTela + 40) {
          // A primeira touceira depois do corte vira dois ou três juncos
          // molhados, já dentro d'água, a 30 px da beira.
          molhados = true;
          final v = vento(t, x / 1.25) * 0.8;
          for (var k = 0; k < 2 + n % 2; k++) {
            final (s1, _, s3) = sementes[k];
            final xx = beiraNaTela + cam * 1.25 + 30 + k * 10;
            final alto = h * (0.05 + s1 * 0.04);
            final curva = (s3 - 0.5) * 8 + v * 8;
            canvas.drawPath(
              Path()
                ..moveTo(xx, h + 4)
                ..quadraticBezierTo(
                  xx + curva * 0.3,
                  h - alto * 0.5,
                  xx + curva,
                  h - alto,
                ),
              Paint()
                ..color = tons[k % 2]
                ..strokeWidth = 2.5
                ..strokeCap = StrokeCap.round
                ..style = PaintingStyle.stroke,
            );
          }
        }
      }
      x += larguraDaTouceira + lacuna;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FrenteDoMundo old) => false;
}
