import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/rendering.dart' show Matrix4;

/// Um campo de deformação no espaço do corpo: recebe um ponto do desenho e
/// devolve para onde ele vai neste quadro.
typedef CampoDeDeformacao = Offset Function(Offset ponto);

/// Um [Canvas] que dobra cada contorno antes de desenhar.
///
/// É o que faz o personagem do Duolingo parecer de borracha boa, e não um
/// recorte rígido: no Rive, cada vértice do contorno vetorial fica preso a
/// ossos, e quando os ossos se movem o contorno inteiro se curva, incha e
/// afina junto (pesquisa 25). Aqui o desenho do bicho já é vetorial; este
/// canvas amostra cada contorno em pontos, passa cada ponto pelo campo de
/// deformação do quadro (no espaço do corpo) e redesenha o contorno pelos
/// pontos movidos. As formas deixam de ser peças fixas: o corpo verga para
/// onde vai, a barriga respira, o quadril balança com o passo.
class CanvasDeformavel implements Canvas {
  /// Só para medir o custo: desliga o deformador.
  static bool ligado = true;

  CanvasDeformavel(this._c, this._campo)
    : _corpo = Matrix4.fromFloat64List(_c.getTransform()) {
    _doCorpo = Matrix4.inverted(_corpo);
  }

  final Canvas _c;
  final CampoDeDeformacao _campo;

  /// O espaço do corpo: a transformação do canvas quando o desenho do bicho
  /// começa. O campo é definido nele (pés em y = 60, +x para onde ele vai).
  final Matrix4 _corpo;
  late final Matrix4 _doCorpo;

  /// Distância entre amostras do contorno, em unidades locais. As amostras
  /// são ligadas por curvas (pelos pontos médios), então 4 já é liso.
  static const _passo = 4.0;

  /// Abaixo disto (em unidades do corpo) a peça é um detalhe — olho, narina,
  /// bigode: ela acompanha o corpo sem se dobrar, e o olho segue redondo.
  static const _detalhe = 16.0;

  /// A transformação afim local -> corpo deste instante, como 6 números.
  (double, double, double, double, double, double) _afim() {
    final m = _doCorpo.multiplied(Matrix4.fromFloat64List(_c.getTransform()));
    final s = m.storage;
    return (s[0], s[1], s[4], s[5], s[12], s[13]);
  }

  Path _dobra(Path p) {
    final (a, b, c, d, tx, ty) = _afim();
    final det = a * d - b * c;
    if (det.abs() < 1e-9) return p;
    // corpo -> local
    final ia = d / det, ib = -b / det, ic = -c / det, id = a / det;
    Offset paraCorpo(Offset q) =>
        Offset(a * q.dx + c * q.dy + tx, b * q.dx + d * q.dy + ty);
    Offset paraLocal(Offset q) {
      final x = q.dx - tx, y = q.dy - ty;
      return Offset(ia * x + ic * y, ib * x + id * y);
    }

    final caixa = p.getBounds();
    final escala = math.sqrt(det.abs());
    if (math.max(caixa.width, caixa.height) * escala < _detalhe) {
      // Detalhe: desloca inteiro pelo campo no centro dele.
      final centro = paraCorpo(caixa.center);
      final ida = paraLocal(_campo(centro)) - caixa.center;
      return p.shift(ida);
    }

    final saida = Path()..fillType = p.fillType;
    for (final m in p.computeMetrics()) {
      final n = math.max(8, (m.length * escala / _passo).ceil());
      final pts = <Offset>[];
      final total = m.isClosed ? n : n + 1;
      for (var i = 0; i < total; i++) {
        final t = m.getTangentForOffset(m.length * i / n);
        if (t == null) continue;
        pts.add(paraLocal(_campo(paraCorpo(t.position))));
      }
      if (pts.length < 2) continue;
      if (m.isClosed) {
        // Fechado: curva suave pelos pontos médios, dando a volta.
        final k = pts.length;
        Offset meio(int i) => (pts[i % k] + pts[(i + 1) % k]) / 2;
        final ini = meio(0);
        saida.moveTo(ini.dx, ini.dy);
        for (var i = 1; i <= k; i++) {
          final cp = pts[i % k];
          final fim = meio(i);
          saida.quadraticBezierTo(cp.dx, cp.dy, fim.dx, fim.dy);
        }
        saida.close();
      } else {
        saida.moveTo(pts.first.dx, pts.first.dy);
        for (var i = 1; i < pts.length - 1; i++) {
          final fim = (pts[i] + pts[i + 1]) / 2;
          saida.quadraticBezierTo(pts[i].dx, pts[i].dy, fim.dx, fim.dy);
        }
        saida.lineTo(pts.last.dx, pts.last.dy);
      }
    }
    return saida;
  }

  Offset _ponto(Offset q) {
    final (a, b, c, d, tx, ty) = _afim();
    final det = a * d - b * c;
    if (det.abs() < 1e-9) return q;
    final corpo = Offset(a * q.dx + c * q.dy + tx, b * q.dx + d * q.dy + ty);
    final r = _campo(corpo);
    final x = r.dx - tx, y = r.dy - ty;
    return Offset((d * x - c * y) / det, (-b * x + a * y) / det);
  }

  // --- desenho: tudo vira contorno dobrado ---------------------------------

  @override
  void drawPath(Path path, Paint paint) => _c.drawPath(_dobra(path), paint);

  @override
  void drawOval(Rect rect, Paint paint) =>
      drawPath(Path()..addOval(rect), paint);

  @override
  void drawCircle(Offset c, double radius, Paint paint) => drawPath(
    Path()..addOval(Rect.fromCircle(center: c, radius: radius)),
    paint,
  );

  @override
  void drawRect(Rect rect, Paint paint) =>
      drawPath(Path()..addRect(rect), paint);

  @override
  void drawRRect(RRect rrect, Paint paint) =>
      drawPath(Path()..addRRect(rrect), paint);

  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) => drawPath(
    Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(outer)
      ..addRRect(inner),
    paint,
  );

  @override
  void drawArc(
    Rect rect,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    Paint paint,
  ) {
    final p = Path();
    if (useCenter) {
      p.moveTo(rect.center.dx, rect.center.dy);
      p.arcTo(rect, startAngle, sweepAngle, false);
      p.close();
    } else {
      p.addArc(rect, startAngle, sweepAngle);
    }
    drawPath(p, paint);
  }

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) =>
      _c.drawLine(_ponto(p1), _ponto(p2), paint);

  @override
  void drawPoints(PointMode pointMode, List<Offset> points, Paint paint) =>
      _c.drawPoints(pointMode, [for (final p in points) _ponto(p)], paint);

  @override
  void drawRawPoints(PointMode pointMode, Float32List points, Paint paint) {
    final lista = <Offset>[
      for (var i = 0; i + 1 < points.length; i += 2)
        Offset(points[i], points[i + 1]),
    ];
    drawPoints(pointMode, lista, paint);
  }

  @override
  void drawRSuperellipse(RSuperellipse rsuperellipse, Paint paint) =>
      _c.drawRSuperellipse(rsuperellipse, paint);

  @override
  void drawShadow(
    Path path,
    Color color,
    double elevation,
    bool transparentOccluder,
  ) => _c.drawShadow(_dobra(path), color, elevation, transparentOccluder);

  // --- recorte: dobra junto, para o que está recortado acompanhar ----------

  @override
  void clipPath(Path path, {bool doAntiAlias = true}) =>
      _c.clipPath(_dobra(path), doAntiAlias: doAntiAlias);

  @override
  void clipRect(
    Rect rect, {
    ClipOp clipOp = ClipOp.intersect,
    bool doAntiAlias = true,
  }) {
    // Recorte de exclusão ou retângulo enorme (folga de camada): direto.
    if (clipOp != ClipOp.intersect || rect.width > 600 || rect.height > 600) {
      _c.clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias);
      return;
    }
    _c.clipPath(_dobra(Path()..addRect(rect)), doAntiAlias: doAntiAlias);
  }

  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) =>
      _c.clipPath(_dobra(Path()..addRRect(rrect)), doAntiAlias: doAntiAlias);

  @override
  void clipRSuperellipse(
    RSuperellipse rsuperellipse, {
    bool doAntiAlias = true,
  }) => _c.clipRSuperellipse(rsuperellipse, doAntiAlias: doAntiAlias);

  // --- o resto passa direto -----------------------------------------------

  @override
  void save() => _c.save();

  @override
  void saveLayer(Rect? bounds, Paint paint) => _c.saveLayer(bounds, paint);

  @override
  void restore() => _c.restore();

  @override
  void restoreToCount(int count) => _c.restoreToCount(count);

  @override
  int getSaveCount() => _c.getSaveCount();

  @override
  void translate(double dx, double dy) => _c.translate(dx, dy);

  @override
  void scale(double sx, [double? sy]) => _c.scale(sx, sy);

  @override
  void rotate(double radians) => _c.rotate(radians);

  @override
  void skew(double sx, double sy) => _c.skew(sx, sy);

  @override
  void transform(Float64List matrix4) => _c.transform(matrix4);

  @override
  Float64List getTransform() => _c.getTransform();

  @override
  Rect getLocalClipBounds() => _c.getLocalClipBounds();

  @override
  Rect getDestinationClipBounds() => _c.getDestinationClipBounds();

  @override
  void drawColor(Color color, BlendMode blendMode) =>
      _c.drawColor(color, blendMode);

  @override
  void drawPaint(Paint paint) => _c.drawPaint(paint);

  @override
  void drawImage(Image image, Offset offset, Paint paint) =>
      _c.drawImage(image, offset, paint);

  @override
  void drawImageRect(Image image, Rect src, Rect dst, Paint paint) =>
      _c.drawImageRect(image, src, dst, paint);

  @override
  void drawImageNine(Image image, Rect center, Rect dst, Paint paint) =>
      _c.drawImageNine(image, center, dst, paint);

  @override
  void drawPicture(Picture picture) => _c.drawPicture(picture);

  @override
  void drawParagraph(Paragraph paragraph, Offset offset) =>
      _c.drawParagraph(paragraph, offset);

  @override
  void drawVertices(Vertices vertices, BlendMode blendMode, Paint paint) =>
      _c.drawVertices(vertices, blendMode, paint);

  @override
  void drawAtlas(
    Image atlas,
    List<RSTransform> transforms,
    List<Rect> rects,
    List<Color>? colors,
    BlendMode? blendMode,
    Rect? cullRect,
    Paint paint,
  ) => _c.drawAtlas(
    atlas,
    transforms,
    rects,
    colors,
    blendMode,
    cullRect,
    paint,
  );

  @override
  void drawRawAtlas(
    Image atlas,
    Float32List rstTransforms,
    Float32List rects,
    Int32List? colors,
    BlendMode? blendMode,
    Rect? cullRect,
    Paint paint,
  ) => _c.drawRawAtlas(
    atlas,
    rstTransforms,
    rects,
    colors,
    blendMode,
    cullRect,
    paint,
  );
}

/// Os "ossos" do corpo neste quadro, já como números: quanto ele verga,
/// achata, respira, balança o quadril e levanta cada lado.
class OssosDoCorpo {
  const OssosDoCorpo({
    this.verga = 0,
    this.achata = 0,
    this.folego = 0,
    this.quadril = 0,
    this.ladoEsquerdo = 0,
    this.ladoDireito = 0,
    this.pes = 60,
    this.altura = 140,
    this.ondula = 0,
    this.faseDaOnda = 0,
  });

  /// 0..1: nadando, o corpo ondula de lado numa onda que sobe do quadril
  /// para a cabeça (é como o axolote e a lontra nadam).
  final double ondula;
  final double faseDaOnda;

  /// -1..1: o tronco verga para +x (para onde ele vai), a base fica.
  final double verga;

  /// -1..1: positivo achata (pouso), negativo estica (no ar). A base fica;
  /// a cintura incha e o alto desce — volume, não escala.
  final double achata;

  /// -1..1: o peito enche e esvazia.
  final double folego;

  /// -1..1: o quadril vai para um lado e outro no passo.
  final double quadril;

  /// 0..1: o lado da pata que está no ar sobe junto.
  final double ladoEsquerdo;
  final double ladoDireito;

  /// A linha dos pés e a altura do corpo, em unidades do desenho.
  final double pes;
  final double altura;

  bool get parado =>
      verga.abs() < 0.002 &&
      achata.abs() < 0.002 &&
      folego.abs() < 0.002 &&
      quadril.abs() < 0.002 &&
      ladoEsquerdo < 0.002 &&
      ladoDireito < 0.002 &&
      ondula < 0.002;

  /// O campo de deformação destes ossos.
  Offset deforma(Offset p) {
    // 0 nos pés, 1 no alto da cabeça.
    final h = ((pes - p.dy) / altura).clamp(0.0, 1.3);
    var x = p.dx;
    var y = p.dy;

    // Verga: o alto vai mais que a base, numa curva (h²): o tronco dobra,
    // não tomba inteiro.
    // Acima do alto da cabeça (orelhas) não verga mais: com h passando de
    // 1, a cabeça alta do buldogue tombava 27 unidades.
    final hv = math.min(h, 1.0);
    x += verga * hv * hv * 11;
    y += verga.abs() * hv * hv * 2;

    // Achata/estica com volume: o alto desce (ou sobe) proporcional à
    // altura; a cintura (meio de baixo) incha (ou afina) para os lados.
    final cintura = math.sin(math.pi * h.clamp(0.0, 1.0)) * (1.2 - h * 0.6);
    y += achata * h * 14;
    x *= 1 + achata * 0.11 * cintura;

    // Fôlego: o peito (centro em ~35% da altura) enche para fora.
    final dyPeito = (h - 0.35) / 0.22;
    final peito = math.exp(-dyPeito * dyPeito);
    x *= 1 + folego * 0.035 * peito;
    y -= folego * 1.4 * peito;

    // Quadril: a base vai para o lado do passo, o alto fica (1-h)².
    final base = (1 - h).clamp(0.0, 1.0);
    x += quadril * base * base * 4;

    // A onda do nado: cada altura atrasada em relação à de baixo, então a
    // ondulação sobe pelo corpo; a cabeça vai menos que o tronco.
    if (ondula > 0) {
      final amplitude = 6 * ondula * (0.35 + 0.65 * (1 - (h - 0.5).abs()));
      x += amplitude * math.sin(faseDaOnda - h * math.pi * 1.6);
    }

    // O lado da pata no ar sobe um pouco: a barriga daquele lado acompanha.
    final lado = x < 0 ? ladoEsquerdo : ladoDireito;
    final borda = (x.abs() / 40).clamp(0.0, 1.0);
    y -= lado * math.pow(base, 3) * borda * 5;

    return Offset(x, y);
  }
}
