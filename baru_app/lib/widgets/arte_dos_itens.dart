/// A arte dos objetos do habitat.
///
/// Os 22 objetos da loja eram desenhados como retângulos de canto redondo —
/// um "barco" era uma pílula marrom com um palito e um quadrado creme. Ao
/// lado de um bicho desenhado com cuidado, o cenário parecia rascunho, e o
/// dono do produto disse isso com todas as letras.
///
/// Aqui cada objeto tem um desenho próprio, no mesmo traço do bicho: forma
/// chapada, um tom mais claro onde bate a luz, um mais escuro embaixo, contorno
/// discreto. As peças de `ShopItemDef.parts` continuam sendo a verdade sobre
/// **onde** o objeto fica e de que cor ele é; esta arte desenha **dentro** da
/// caixa delas, em coordenadas da cena (`HabitatScene.design`, 372×296).
///
/// Quem desenha: o habitat, a miniatura da loja e a amostra da home. Os três
/// passam pelo mesmo [pintaItem], então o que se compra é o que aparece.
library;

import 'dart:math' as math;
import 'dart:ui';

import '../models.dart' show ShapePart;

/// A caixa do objeto na cena: a união das peças.
Rect caixaDasPecas(List<ShapePart> pecas) {
  var e = double.infinity, t = double.infinity;
  var d = -double.infinity, b = -double.infinity;
  for (final p in pecas) {
    e = math.min(e, p.x);
    t = math.min(t, p.y);
    d = math.max(d, p.x + p.w);
    b = math.max(b, p.y + p.h);
  }
  return Rect.fromLTRB(e, t, d, b);
}

/// A caixa que a arte ocupa: a das peças com folga para o que passa delas
/// (o corrimão da ponte, a bandeira do barco).
Rect caixaDaArte(String id, List<ShapePart> pecas) {
  final r = caixaDasPecas(pecas).inflate(6);
  return switch (id) {
    'bridge' => Rect.fromLTRB(r.left, r.top - 16, r.right, r.bottom),
    'boat' => Rect.fromLTRB(r.left, r.top - 6, r.right, r.bottom),
    'fogueira' => Rect.fromLTRB(r.left, r.top - 10, r.right, r.bottom),
    _ => r,
  };
}

/// Desenha o objeto [id] em coordenadas da cena.
///
/// [fase] vai de 0 a 1 e volta (a deriva de 14 s do habitat): o fogo
/// tremula, os peixes nadam, os vaga-lumes piscam. Parado, fica em 0.
/// Objeto sem arte própria cai nas peças, como antes — nunca some.
void pintaItem(
  Canvas canvas,
  String id,
  List<ShapePart> pecas, {
  double fase = 0,
}) {
  if (pecas.isEmpty) return;
  final arte = _artes[id];
  if (arte == null) {
    _pecasCruas(canvas, pecas);
    return;
  }
  arte(_Pincel(canvas, pecas, fase));
}

typedef _Arte = void Function(_Pincel p);

final Map<String, _Arte> _artes = {
  'lily': _vitoriaRegia,
  'bamboo': _bambu,
  'rock': _pedra,
  'dock': _deque,
  'lantern': _lampiao,
  'tree': _arvore,
  'boat': _barco,
  'bridge': _ponte,
  'juncos': _juncos,
  'cogumelos': _cogumelos,
  'samambaia': _samambaia,
  'folhas_de_outono': _folhasDeOutono,
  'pedras_do_riacho': _pedrasDoRiacho,
  'cardume': _cardume,
  'nuvens': _nuvens,
  'tronco_caido': _troncoCaido,
  'casa_de_passaro': _casaDePassaro,
  'vagalumes': _vagalumes,
  'neve': _neve,
  'varal_de_luzes': _varalDeLuzes,
  'fogueira': _fogueira,
  'cerejeira': _cerejeira,
};

void _pecasCruas(Canvas canvas, List<ShapePart> pecas) {
  for (final p in pecas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(p.x, p.y, p.w, p.h),
        Radius.circular(p.r),
      ),
      Paint()..color = p.c,
    );
  }
}

/// O que toda arte usa: o canvas, as peças, a fase e os tons.
class _Pincel {
  _Pincel(this.c, this.pecas, this.fase) : caixa = caixaDasPecas(pecas);

  final Canvas c;
  final List<ShapePart> pecas;
  final double fase;
  final Rect caixa;

  ShapePart operator [](int i) => pecas[math.min(i, pecas.length - 1)];

  /// Uma onda de 0 a 1 que dá [voltas] voltas na deriva.
  double onda(double voltas, [double defasagem = 0]) =>
      0.5 + 0.5 * math.sin((fase * voltas + defasagem) * 2 * math.pi);

  Paint cor(Color c) => Paint()
    ..color = c
    ..isAntiAlias = true;

  Paint traco(Color c, double largura) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = largura
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint gradV(Rect r, Color topo, Color base) => Paint()
    ..shader = Gradient.linear(r.topCenter, r.bottomCenter, [topo, base]);

  Paint brilho(Offset centro, double raio, Color cor) => Paint()
    ..shader = Gradient.radial(centro, raio, [cor, cor.withValues(alpha: 0)]);

  /// Sombra de contato no chão.
  void sombra(double cx, double y, double largura, [double alfa = 0.16]) {
    c.drawOval(
      Rect.fromCenter(center: Offset(cx, y), width: largura, height: largura * 0.18),
      Paint()
        ..color = const Color(0xFF3E2F23).withValues(alpha: alfa)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
  }

  /// Anel de água em volta do que está na lagoa.
  void anel(double cx, double y, double largura) {
    final r = Rect.fromCenter(
      center: Offset(cx, y),
      width: largura,
      height: largura * 0.22,
    );
    c.drawOval(r, traco(const Color(0x66FFFFFF), 1.4));
    c.drawOval(
      r.inflate(4 + 2 * onda(3)),
      traco(const Color(0x33FFFFFF), 1),
    );
  }
}

Color _claro(Color c, double k) =>
    Color.lerp(c, const Color(0xFFFFFFFF), k)!.withValues(alpha: c.a);
Color _escuro(Color c, double k) =>
    Color.lerp(c, const Color(0xFF2B2018), k)!.withValues(alpha: c.a);

/// Contorno discreto: o mesmo tom, mais escuro e meio transparente.
Paint _contorno(Color base, [double largura = 1.2]) => Paint()
  ..color = _escuro(base, 0.45).withValues(alpha: 0.55)
  ..style = PaintingStyle.stroke
  ..strokeWidth = largura
  ..strokeJoin = StrokeJoin.round;

/// Uma folha pontuda, do pé [de] à ponta [ate], com largura [l].
Path _folha(Offset de, Offset ate, double l) {
  final m = Offset.lerp(de, ate, 0.45)!;
  final dir = ate - de;
  final n = Offset(-dir.dy, dir.dx) / dir.distance * l / 2;
  return Path()
    ..moveTo(de.dx, de.dy)
    ..quadraticBezierTo(m.dx + n.dx, m.dy + n.dy, ate.dx, ate.dy)
    ..quadraticBezierTo(m.dx - n.dx, m.dy - n.dy, de.dx, de.dy)
    ..close();
}

// ---------------------------------------------------------------- água

void _vitoriaRegia(_Pincel p) {
  final c = p.c;
  void folha(Offset centro, double rx, double ry, Color cor, double corte) {
    final r = Rect.fromCenter(center: centro, width: rx * 2, height: ry * 2);
    p.anel(centro.dx, centro.dy + 1, rx * 2.2);
    final borda = Path()
      ..moveTo(centro.dx, centro.dy)
      ..arcTo(r, corte + 0.28, 2 * math.pi - 0.56, false)
      ..close();
    // A borda levantada, um tom abaixo, dá espessura.
    c.drawPath(borda.shift(const Offset(0, 1.6)), p.cor(_escuro(cor, 0.3)));
    c.drawPath(borda, p.gradV(r, _claro(cor, 0.18), cor));
    for (var i = 1; i < 6; i++) {
      final a = corte + 0.28 + i * (2 * math.pi - 0.56) / 6;
      c.drawLine(
        centro,
        centro + Offset(math.cos(a) * rx * 0.8, math.sin(a) * ry * 0.8),
        p.traco(_escuro(cor, 0.25).withValues(alpha: 0.5), 0.8),
      );
    }
  }

  final a = p[0], b = p[1];
  folha(Offset(a.x + a.w / 2, a.y + a.h / 2), a.w / 2, a.h / 2 + 1, a.c, -0.6);
  folha(Offset(b.x + b.w / 2, b.y + b.h / 2), b.w / 2, b.h / 2 + 1, b.c, 2.4);

  // A flor, rosa, em cima da folha maior.
  final f = Offset(a.x + a.w * 0.62, a.y + a.h * 0.25);
  c.drawCircle(f, 10, p.brilho(f, 10, const Color(0x55FFF3E0)));
  const petala = Color(0xFFF2A7B8);
  for (var i = 0; i < 6; i++) {
    final ang = -math.pi / 2 + (i - 2.5) * 0.42;
    final ponta = f + Offset(math.cos(ang) * 7.5, math.sin(ang) * 6.5);
    c.drawPath(_folha(f, ponta, 4.4), p.cor(i.isEven ? petala : _claro(petala, 0.35)));
  }
  c.drawCircle(f + const Offset(0, -1), 2, p.cor(const Color(0xFFF2C14E)));
}

void _pedra(_Pincel p) {
  final c = p.c;
  final base = p[0].c, luz = p[1].c;
  final r = p.caixa;
  p.anel(r.center.dx, r.bottom - 4, r.width * 1.05);
  final corpo = Path()
    ..moveTo(r.left + 2, r.bottom - 5)
    ..cubicTo(r.left - 2, r.top + 18, r.left + 14, r.top + 2, r.left + 30, r.top + 1)
    ..cubicTo(r.left + 46, r.top - 1, r.right - 4, r.top + 10, r.right - 1, r.bottom - 9)
    ..quadraticBezierTo(r.right, r.bottom - 2, r.right - 10, r.bottom - 2)
    ..lineTo(r.left + 8, r.bottom - 1)
    ..quadraticBezierTo(r.left + 2, r.bottom - 1, r.left + 2, r.bottom - 5)
    ..close();
  c.drawPath(corpo, p.gradV(r, luz, _escuro(base, 0.18)));
  // A face de cima, onde bate a luz.
  final face = Path()
    ..moveTo(r.left + 12, r.top + 12)
    ..cubicTo(r.left + 18, r.top + 4, r.left + 40, r.top + 2, r.right - 14, r.top + 9)
    ..quadraticBezierTo(r.left + 36, r.top + 16, r.left + 12, r.top + 12)
    ..close();
  c.drawPath(face, p.cor(_claro(luz, 0.35)));
  // Musgo e uma rachadura: pedra de lagoa, não de pedreira.
  c.drawOval(
    Rect.fromLTWH(r.left + 18, r.top + 1, 20, 7),
    p.cor(const Color(0xFF8DAA6B)),
  );
  c.drawOval(
    Rect.fromLTWH(r.left + 30, r.top - 1, 11, 5),
    p.cor(const Color(0xFFA5C083)),
  );
  c.drawPath(
    Path()
      ..moveTo(r.right - 20, r.top + 14)
      ..lineTo(r.right - 24, r.top + 21)
      ..lineTo(r.right - 21, r.top + 27),
    p.traco(_escuro(base, 0.4).withValues(alpha: 0.5), 1),
  );
  c.drawPath(corpo, _contorno(base));
}

void _deque(_Pincel p) {
  final c = p.c;
  final tabua = p[0], poste = p[1], poste2 = p[2];
  final madeira = tabua.c;
  // Os postes primeiro: a água passa por eles.
  for (final q in [poste, poste2]) {
    final r = Rect.fromLTWH(q.x, q.y - 2, q.w, q.h + 2);
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(3)),
      p.gradV(r, q.c, _escuro(q.c, 0.25)),
    );
    p.anel(r.center.dx, r.bottom - 3, q.w * 2.6);
  }
  final topo = Rect.fromLTWH(tabua.x, tabua.y, tabua.w, tabua.h);
  // A espessura da prancha.
  c.drawRRect(
    RRect.fromRectAndRadius(topo.shift(const Offset(0, 3)), const Radius.circular(3)),
    p.cor(_escuro(madeira, 0.35)),
  );
  c.drawRRect(
    RRect.fromRectAndRadius(topo, const Radius.circular(3)),
    p.gradV(topo, _claro(madeira, 0.18), madeira),
  );
  for (var x = topo.left + 11; x < topo.right - 4; x += 11) {
    c.drawLine(
      Offset(x, topo.top + 1),
      Offset(x, topo.bottom - 1),
      p.traco(_escuro(madeira, 0.35).withValues(alpha: 0.55), 1),
    );
    c.drawCircle(Offset(x - 3, topo.center.dy), 0.9, p.cor(_escuro(madeira, 0.5)));
  }
  c.drawRRect(
    RRect.fromRectAndRadius(topo, const Radius.circular(3)),
    _contorno(madeira),
  );
}

void _barco(_Pincel p) {
  final c = p.c;
  final casco = p[0], mastro = p[1], vela = p[2];
  final r = Rect.fromLTWH(casco.x, casco.y, casco.w, casco.h);
  final balanco = (p.onda(2) - 0.5) * 2.2;
  c.save();
  c.translate(0, balanco);
  p.anel(r.center.dx, r.bottom - 2, r.width * 1.1);
  // O mastro e a vela, atrás do casco.
  c.drawLine(
    Offset(mastro.x + mastro.w / 2, mastro.y - 4),
    Offset(mastro.x + mastro.w / 2, r.top + 4),
    p.traco(mastro.c, 2.6),
  );
  final vx = mastro.x + mastro.w / 2 + 2;
  final velaP = Path()
    ..moveTo(vx, mastro.y - 2)
    ..quadraticBezierTo(vx + vela.w + 6, vela.y + vela.h * 0.5, vx + 1, r.top + 1)
    ..close();
  c.drawPath(velaP, p.cor(_claro(vela.c, 0.3)));
  c.drawPath(velaP, _contorno(vela.c));
  // A bandeirinha no topo.
  c.drawPath(
    Path()
      ..moveTo(vx - 2, mastro.y - 4)
      ..lineTo(vx - 10, mastro.y - 1.5)
      ..lineTo(vx - 2, mastro.y + 1)
      ..close(),
    p.cor(const Color(0xFFE07A5F)),
  );
  // O casco: proa e popa levantadas, fundo curvo.
  final corpo = Path()
    ..moveTo(r.left - 3, r.top)
    ..lineTo(r.right + 3, r.top)
    ..quadraticBezierTo(r.right - 6, r.bottom + 1, r.center.dx, r.bottom)
    ..quadraticBezierTo(r.left + 6, r.bottom + 1, r.left - 3, r.top)
    ..close();
  c.drawPath(corpo, p.gradV(r, casco.c, _escuro(casco.c, 0.3)));
  c.drawLine(
    Offset(r.left + 1, r.top + 4),
    Offset(r.right - 1, r.top + 4),
    p.traco(_claro(casco.c, 0.5), 2.2),
  );
  c.drawPath(corpo, _contorno(casco.c));
  c.restore();
}

void _ponte(_Pincel p) {
  final c = p.c;
  final deck = p[0];
  final pedra = deck.c, escura = p[1].c;
  final e = deck.x, d = deck.x + deck.w, base = deck.y + 30;
  final meio = (e + d) / 2;
  // O arco, de pedra, com o vão escuro embaixo.
  final arco = Path()
    ..moveTo(e, deck.y + 8)
    ..quadraticBezierTo(meio, deck.y - 16, d, deck.y + 8)
    ..lineTo(d, base)
    ..lineTo(d - 16, base)
    ..quadraticBezierTo(meio, deck.y + 2, e + 16, base)
    ..lineTo(e, base)
    ..close();
  final rArco = Rect.fromLTRB(e, deck.y - 6, d, base);
  c.drawPath(arco, p.gradV(rArco, _claro(pedra, 0.12), _escuro(pedra, 0.1)));
  // Os blocos do arco.
  for (var i = 1; i < 9; i++) {
    final t = i / 9;
    final x = e + 16 + (d - e - 32) * t;
    final yArco = _quad(base, deck.y + 2, base, t);
    final yTopo = _quad(deck.y + 8, deck.y - 16, deck.y + 8, (x - e) / (d - e));
    c.drawLine(
      Offset(x, yArco - 1),
      Offset(x + (t - 0.5) * 6, yTopo + 3),
      p.traco(_escuro(pedra, 0.3).withValues(alpha: 0.35), 1),
    );
  }
  p.anel(meio, base - 2, (d - e) * 0.55);
  c.drawPath(arco, _contorno(pedra));
  // O tabuleiro de madeira e o corrimão.
  const madeira = Color(0xFFA9774E);
  final caminho = Path()
    ..moveTo(e - 2, deck.y + 7)
    ..quadraticBezierTo(meio, deck.y - 18, d + 2, deck.y + 7);
  c.drawPath(caminho, p.traco(_escuro(madeira, 0.25), 6));
  c.drawPath(caminho.shift(const Offset(0, -1.5)), p.traco(madeira, 3.4));
  final corrimao = Path()
    ..moveTo(e + 4, deck.y - 6)
    ..quadraticBezierTo(meio, deck.y - 31, d - 4, deck.y - 6);
  for (var i = 0; i <= 6; i++) {
    final t = i / 6;
    final x = e + 4 + (d - e - 8) * t;
    final y0 = _quad(deck.y + 6, deck.y - 18, deck.y + 6, (x - e) / (d - e));
    final y1 = _quad(deck.y - 6, deck.y - 31, deck.y - 6, t);
    c.drawLine(Offset(x, y0), Offset(x, y1), p.traco(escura, 2.4));
  }
  c.drawPath(corrimao, p.traco(_escuro(madeira, 0.15), 2.6));
}

double _quad(double a, double b, double c, double t) =>
    (1 - t) * (1 - t) * a + 2 * (1 - t) * t * b + t * t * c;

void _pedrasDoRiacho(_Pincel p) {
  final c = p.c;
  final r = p.caixa;
  p.anel(r.center.dx, r.bottom - 2, r.width * 1.3);
  // De baixo para cima: o monte de pedras equilibradas.
  for (final q in p.pecas) {
    final o = Rect.fromLTWH(q.x, q.y, q.w, q.h + 1);
    c.drawOval(o.shift(const Offset(0, 1.5)), p.cor(_escuro(q.c, 0.3)));
    c.drawOval(o, p.gradV(o, _claro(q.c, 0.25), q.c));
    c.drawOval(
      Rect.fromLTWH(o.left + o.width * 0.2, o.top + 1.5, o.width * 0.35, o.height * 0.3),
      p.cor(const Color(0x55FFFFFF)),
    );
    c.drawOval(o, _contorno(q.c, 1));
  }
}

void _cardume(_Pincel p) {
  final c = p.c;
  // Os corpos grandes são os peixes; as peças menores eram caudas.
  final peixes = p.pecas.where((q) => q.w >= 14).toList();
  for (var i = 0; i < peixes.length; i++) {
    final q = peixes[i];
    final nado = (p.onda(3, i * 0.3) - 0.5) * 6;
    final centro = Offset(q.x + q.w / 2 + nado, q.y + q.h / 2);
    final cor = q.c.withValues(alpha: 0.85);
    final corpo = Rect.fromCenter(center: centro, width: q.w, height: q.h + 1);
    // Sob a água: um pouco apagados, com a cauda para a direita.
    final cauda = Path()
      ..moveTo(corpo.right - 2, centro.dy)
      ..lineTo(corpo.right + q.h * 0.8, centro.dy - q.h * 0.55)
      ..lineTo(corpo.right + q.h * 0.6, centro.dy)
      ..lineTo(corpo.right + q.h * 0.8, centro.dy + q.h * 0.55)
      ..close();
    c.drawPath(cauda, p.cor(_escuro(cor, 0.15)));
    c.drawOval(corpo, p.gradV(corpo, _claro(cor, 0.25), cor));
    c.drawCircle(
      Offset(corpo.left + q.h * 0.45, centro.dy - 0.6),
      math.max(0.9, q.h * 0.13),
      p.cor(const Color(0xCC2B2018)),
    );
  }
  // Duas bolhas subindo.
  final s = p.caixa;
  final sobe = p.onda(2);
  c.drawCircle(Offset(s.left + 6, s.top - 4 - sobe * 6), 1.6, p.traco(const Color(0x88FFFFFF), 0.9));
  c.drawCircle(Offset(s.left + 12, s.top - 9 - sobe * 4), 1.1, p.traco(const Color(0x77FFFFFF), 0.8));
}

void _folhasDeOutono(_Pincel p) {
  final c = p.c;
  for (var i = 0; i < p.pecas.length; i++) {
    final q = p.pecas[i];
    final centro = Offset(q.x + q.w / 2, q.y + q.h / 2);
    final giro = -0.6 + i * 0.9 + (p.onda(1, i * 0.25) - 0.5) * 0.3;
    final meio = Offset(math.cos(giro), math.sin(giro)) * q.w * 0.55;
    final de = centro - meio, ate = centro + meio;
    p.anel(centro.dx, centro.dy + 2, q.w * 1.3);
    final folha = _folha(de, ate, q.h * 1.3);
    c.drawPath(folha, p.cor(q.c));
    c.drawLine(de, ate, p.traco(_escuro(q.c, 0.35).withValues(alpha: 0.6), 0.8));
    c.drawPath(folha, _contorno(q.c, 0.8));
  }
}

// ---------------------------------------------------------------- mata

void _bambu(_Pincel p) {
  final c = p.c;
  final chao = p.caixa.bottom;
  p.sombra(p.caixa.center.dx, chao, p.caixa.width + 14);
  for (var i = 0; i < p.pecas.length; i++) {
    final q = p.pecas[i];
    final ginga = (p.onda(1, i * 0.2) - 0.5) * 2.4;
    final r = Rect.fromLTWH(q.x, q.y, q.w, q.h);
    final caule = Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left + ginga, r.top + 2)
      ..quadraticBezierTo(r.center.dx + ginga, r.top - 2, r.right + ginga, r.top + 2)
      ..lineTo(r.right, r.bottom)
      ..close();
    c.drawPath(
      caule,
      Paint()
        ..shader = Gradient.linear(
          r.centerLeft,
          r.centerRight,
          [_claro(q.c, 0.25), q.c, _escuro(q.c, 0.2)],
          const [0, 0.5, 1],
        ),
    );
    // Os nós do bambu.
    for (var y = r.bottom - 14; y > r.top + 6; y -= 15) {
      final k = (r.bottom - y) / r.height;
      c.drawLine(
        Offset(r.left - 0.6 + ginga * k, y),
        Offset(r.right + 0.6 + ginga * k, y),
        p.traco(_escuro(q.c, 0.4), 1.5),
      );
    }
    // Folhas finas saindo dos nós de cima.
    final topo = Offset(r.center.dx + ginga, r.top + 10);
    final lado = i.isEven ? 1.0 : -1.0;
    c.drawPath(
      _folha(topo, topo + Offset(15 * lado, -5), 4.5),
      p.cor(_claro(q.c, 0.15)),
    );
    c.drawPath(
      _folha(topo + const Offset(0, 14), topo + Offset(-13 * lado, 8), 4),
      p.cor(q.c),
    );
    c.drawPath(caule, _contorno(q.c, 0.9));
  }
}

void _arvore(_Pincel p) {
  final c = p.c;
  final tronco = p[0], copa = p[1], fruta = p[2];
  final chao = tronco.y + tronco.h;
  final cx = tronco.x + tronco.w / 2;
  p.sombra(cx, chao, copa.w * 0.9, 0.18);
  // Tronco que alarga no pé, com duas raízes.
  final t = Path()
    ..moveTo(cx - tronco.w * 0.4, copa.y + copa.h * 0.7)
    ..quadraticBezierTo(cx - tronco.w * 0.45, chao - 12, cx - tronco.w * 1.1, chao)
    ..lineTo(cx + tronco.w * 1.1, chao)
    ..quadraticBezierTo(cx + tronco.w * 0.45, chao - 12, cx + tronco.w * 0.4, copa.y + copa.h * 0.7)
    ..close();
  final rt = Rect.fromLTWH(tronco.x - 6, tronco.y, tronco.w + 12, tronco.h);
  c.drawPath(
    t,
    Paint()
      ..shader = Gradient.linear(
        rt.centerLeft,
        rt.centerRight,
        [_claro(tronco.c, 0.2), _escuro(tronco.c, 0.15)],
      ),
  );
  c.drawLine(
    Offset(cx + 1, chao - 22),
    Offset(cx + 2, chao - 34),
    p.traco(_escuro(tronco.c, 0.35), 1),
  );
  c.drawPath(t, _contorno(tronco.c));
  // A copa: bolas sobrepostas, a de trás mais escura.
  final ginga = (p.onda(1) - 0.5) * 1.6;
  final o = Offset(copa.x + ginga, copa.y);
  final w = copa.w, h = copa.h;
  final bolas = [
    (Offset(w * 0.28, h * 0.62), w * 0.27, _escuro(copa.c, 0.18)),
    (Offset(w * 0.74, h * 0.6), w * 0.27, _escuro(copa.c, 0.18)),
    (Offset(w * 0.5, h * 0.42), w * 0.34, copa.c),
    (Offset(w * 0.24, h * 0.42), w * 0.22, copa.c),
    (Offset(w * 0.76, h * 0.38), w * 0.23, copa.c),
    (Offset(w * 0.5, h * 0.66), w * 0.3, copa.c),
  ];
  for (final (pos, raio, cor) in bolas) {
    c.drawCircle(o + pos + const Offset(0, 2), raio, p.cor(_escuro(cor, 0.25)));
  }
  for (final (pos, raio, cor) in bolas) {
    c.drawCircle(o + pos, raio, p.cor(cor));
  }
  c.drawCircle(o + Offset(w * 0.4, h * 0.26), w * 0.14, p.cor(_claro(copa.c, 0.22)));
  c.drawCircle(o + Offset(w * 0.68, h * 0.28), w * 0.08, p.cor(_claro(copa.c, 0.18)));
  // As frutas.
  for (final f in [
    Offset(fruta.x + fruta.w / 2, fruta.y + fruta.h / 2),
    o + Offset(w * 0.72, h * 0.56),
    o + Offset(w * 0.2, h * 0.5),
  ]) {
    c.drawCircle(f + Offset(ginga, 0), fruta.w * 0.45, p.cor(fruta.c));
    c.drawCircle(f + Offset(ginga - 1.2, -1.2), fruta.w * 0.14, p.cor(const Color(0x88FFFFFF)));
  }
}

void _juncos(_Pincel p) {
  final c = p.c;
  final chao = p.caixa.bottom;
  p.sombra(p.caixa.center.dx, chao, p.caixa.width + 10);
  final cabeca = p.pecas.last;
  final hastes = p.pecas.take(p.pecas.length - 1).toList();
  for (var i = 0; i < hastes.length; i++) {
    final q = hastes[i];
    final ginga = (p.onda(1.5, i * 0.33) - 0.5) * 4;
    final pe = Offset(q.x + q.w / 2, chao);
    final ponta = Offset(q.x + q.w / 2 + ginga + (i - 1) * 3, q.y - 2);
    final haste = Path()
      ..moveTo(pe.dx, pe.dy)
      ..quadraticBezierTo(pe.dx + (i - 1) * 2, (pe.dy + ponta.dy) / 2, ponta.dx, ponta.dy);
    c.drawPath(haste, p.traco(_escuro(q.c, 0.1), 2));
    // A taboa: a espiga marrom no alto.
    final espiga = Rect.fromCenter(
      center: ponta + const Offset(0, 9),
      width: cabeca.w * 0.7,
      height: cabeca.h,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(espiga, Radius.circular(espiga.width / 2)),
      p.gradV(espiga, _claro(cabeca.c, 0.15), _escuro(cabeca.c, 0.15)),
    );
    c.drawLine(ponta, ponta + const Offset(0, -4), p.traco(_escuro(q.c, 0.2), 1));
    // Uma lâmina de folha de cada lado.
    c.drawPath(
      _folha(pe, pe + Offset((i - 1) * 9 - 4, -(chao - q.y) * 0.65), 3.5),
      p.cor(q.c),
    );
  }
}

void _cogumelos(_Pincel p) {
  final c = p.c;
  final chao = p.caixa.bottom;
  p.sombra(p.caixa.center.dx, chao, p.caixa.width + 6);
  // Peças 0/1: o grande; 2/3: o pequeno.
  for (final (pe, chapeu) in [(p[0], p[1]), (p[2], p[3])]) {
    final caule = Rect.fromLTRB(pe.x, chapeu.y + chapeu.h * 0.6, pe.x + pe.w, chao);
    c.drawRRect(
      RRect.fromRectAndCorners(
        caule,
        bottomLeft: const Radius.circular(2),
        bottomRight: const Radius.circular(2),
      ),
      p.gradV(caule, _claro(pe.c, 0.3), pe.c),
    );
    final r = Rect.fromLTWH(chapeu.x, chapeu.y, chapeu.w, chapeu.h * 1.5);
    final cupula = Path()
      ..moveTo(r.left, chapeu.y + chapeu.h)
      ..quadraticBezierTo(r.left, r.top - 2, r.center.dx, r.top)
      ..quadraticBezierTo(r.right, r.top - 2, r.right, chapeu.y + chapeu.h)
      ..quadraticBezierTo(r.center.dx, chapeu.y + chapeu.h + 2.4, r.left, chapeu.y + chapeu.h)
      ..close();
    c.drawPath(cupula, p.gradV(r, _claro(chapeu.c, 0.15), chapeu.c));
    // As pintas brancas.
    final w = chapeu.w;
    for (final (dx, dy, raio) in [(0.3, 0.45, 0.1), (0.62, 0.3, 0.08), (0.75, 0.65, 0.06)]) {
      c.drawCircle(
        Offset(r.left + w * dx, chapeu.y + chapeu.h * dy),
        math.max(0.8, w * raio),
        p.cor(const Color(0xEEFFF8EE)),
      );
    }
    c.drawPath(cupula, _contorno(chapeu.c, 0.9));
  }
}

void _samambaia(_Pincel p) {
  final c = p.c;
  final r = p.caixa;
  final chao = r.bottom;
  p.sombra(r.center.dx, chao, r.width * 0.9);
  final pe = Offset(r.center.dx, chao);
  // Cinco frondes em leque, cada uma com folíolos dos dois lados.
  const angulos = [-2.55, -2.05, -1.57, -1.09, -0.6];
  for (var i = 0; i < angulos.length; i++) {
    final cor = p[i % p.pecas.length].c;
    final ginga = (p.onda(1.2, i * 0.2) - 0.5) * 0.08;
    final a = angulos[i] + ginga;
    final comp = (i == 2 ? 30.0 : 24.0) * (r.height / 29);
    final ponta = pe + Offset(math.cos(a), math.sin(a)) * comp;
    final dobra = pe + Offset(math.cos(a), math.sin(a)) * comp * 0.55 + const Offset(0, -4);
    final eixo = Path()
      ..moveTo(pe.dx, pe.dy)
      ..quadraticBezierTo(dobra.dx, dobra.dy, ponta.dx, ponta.dy);
    for (var k = 1; k <= 6; k++) {
      final t = k / 7;
      final x = _quad(pe.dx, dobra.dx, ponta.dx, t);
      final y = _quad(pe.dy, dobra.dy, ponta.dy, t);
      final tam = 6.5 * (1 - t * 0.7);
      final n = Offset(-math.sin(a), math.cos(a));
      final base = Offset(x, y);
      c.drawPath(_folha(base, base + n * tam + Offset(0, -tam * 0.3), 2.8), p.cor(cor));
      c.drawPath(_folha(base, base - n * tam + Offset(0, -tam * 0.3), 2.8), p.cor(_claro(cor, 0.12)));
    }
    c.drawPath(eixo, p.traco(_escuro(cor, 0.25), 1.1));
  }
}

void _troncoCaido(_Pincel p) {
  final c = p.c;
  final corpo = p[0], topo = p[1], ponta = p[2];
  final r = Rect.fromLTWH(corpo.x, corpo.y, corpo.w, corpo.h);
  p.sombra(r.center.dx, r.bottom, r.width * 1.05, 0.18);
  c.drawRRect(
    RRect.fromRectAndRadius(r, Radius.circular(r.height / 2)),
    p.gradV(r, topo.c, _escuro(corpo.c, 0.2)),
  );
  // A casca: riscos compridos.
  for (var i = 0; i < 6; i++) {
    final x = r.left + 16 + i * 11.0;
    c.drawLine(
      Offset(x, r.top + 3 + (i % 2) * 2),
      Offset(x + 8, r.top + 3 + (i % 2) * 2),
      p.traco(_escuro(corpo.c, 0.35).withValues(alpha: 0.6), 1),
    );
  }
  // O corte, com os anéis.
  final corte = Rect.fromLTWH(ponta.x, r.top - 0.5, ponta.w, r.height + 1);
  c.drawOval(corte, p.cor(const Color(0xFFE6C79A)));
  c.drawOval(corte.deflate(2.2), p.traco(const Color(0xFFB98C5A), 0.9));
  c.drawOval(corte.deflate(4.2), p.traco(const Color(0xFFB98C5A), 0.8));
  c.drawOval(corte, _contorno(ponta.c, 1));
  // Musgo e um broto: o tronco virou casa.
  c.drawOval(Rect.fromLTWH(r.left + 40, r.top - 2.5, 18, 5.5), p.cor(const Color(0xFF8DAA6B)));
  final broto = Offset(r.left + 64, r.top + 1);
  c.drawLine(broto, broto + const Offset(0, -6), p.traco(const Color(0xFF6E9150), 1.2));
  c.drawPath(_folha(broto + const Offset(0, -5), broto + const Offset(5, -9), 3), p.cor(const Color(0xFF8DAA6B)));
  c.drawRRect(
    RRect.fromRectAndRadius(r, Radius.circular(r.height / 2)),
    _contorno(corpo.c),
  );
}

void _casaDePassaro(_Pincel p) {
  final c = p.c;
  final poste = p[0], caixa = p[1], telhado = p[2], furo = p[3];
  final chao = poste.y + poste.h;
  p.sombra(poste.x + poste.w / 2, chao, 26);
  final rp = Rect.fromLTWH(poste.x, caixa.y + caixa.h - 4, poste.w, chao - caixa.y - caixa.h + 4);
  c.drawRect(rp, p.gradV(rp, _escuro(poste.c, 0.1), poste.c));
  // A casinha: parede com empena.
  final r = Rect.fromLTWH(caixa.x, caixa.y, caixa.w, caixa.h);
  final casa = Path()
    ..moveTo(r.left, r.bottom)
    ..lineTo(r.left, r.top + 6)
    ..lineTo(r.center.dx, r.top - 6)
    ..lineTo(r.right, r.top + 6)
    ..lineTo(r.right, r.bottom)
    ..close();
  c.drawPath(casa, p.gradV(r, _claro(caixa.c, 0.12), caixa.c));
  c.drawPath(casa, _contorno(caixa.c));
  // O telhado, saindo além da parede.
  final tl = Path()
    ..moveTo(telhado.x - 1, r.top + 9)
    ..lineTo(r.center.dx, r.top - 10)
    ..lineTo(telhado.x + telhado.w + 1, r.top + 9);
  c.drawPath(
    tl,
    p.traco(telhado.c, 5)..strokeCap = StrokeCap.round,
  );
  c.drawPath(tl, p.traco(_escuro(telhado.c, 0.3).withValues(alpha: 0.5), 1));
  // O furo e o poleiro.
  final f = Offset(furo.x + furo.w / 2, furo.y + furo.h / 2 + 2);
  c.drawCircle(f, furo.w / 2, p.cor(const Color(0xFF3A2A1E)));
  c.drawLine(
    f + Offset(0, furo.w / 2 + 3),
    f + Offset(0, furo.w / 2 + 3) + const Offset(-7, 0),
    p.traco(_escuro(poste.c, 0.1), 1.8),
  );
}

// ---------------------------------------------------------------- noite

void _lampiao(_Pincel p) {
  final c = p.c;
  final corpo = p[0], fio = p[1];
  final balanco = (p.onda(1.5) - 0.5) * 0.08;
  final topo = Offset(fio.x + fio.w / 2, 0);
  c.save();
  c.translate(topo.dx, topo.dy);
  c.rotate(balanco);
  c.translate(-topo.dx, -topo.dy);
  c.drawLine(topo, Offset(topo.dx, corpo.y + 2), p.traco(const Color(0x993E2F23), 1.2));
  final r = Rect.fromLTWH(corpo.x, corpo.y, corpo.w, corpo.h);
  final pulso = 0.85 + 0.15 * p.onda(5);
  c.drawCircle(r.center, r.width * 1.5, p.brilho(r.center, r.width * 1.5, Color.fromRGBO(255, 190, 110, 0.45 * pulso)));
  // Lanterna de papel: um balão com gomos.
  final balao = Rect.fromLTWH(r.left, r.top + 4, r.width, r.height - 8);
  c.drawOval(
    balao,
    Paint()
      ..shader = Gradient.radial(
        balao.center,
        balao.width * 0.7,
        [const Color(0xFFFFD27A), corpo.c, _escuro(corpo.c, 0.15)],
        const [0, 0.6, 1],
      ),
  );
  for (final k in [0.3, 0.5, 0.7]) {
    final x = balao.left + balao.width * k;
    final curva = Path()
      ..moveTo(balao.center.dx, balao.top)
      ..quadraticBezierTo(x + (k - 0.5) * balao.width * 0.9, balao.center.dy, balao.center.dx, balao.bottom);
    c.drawPath(curva, p.traco(_escuro(corpo.c, 0.3).withValues(alpha: 0.45), 0.9));
  }
  const tampa = Color(0xFF5A4030);
  c.drawRRect(
    RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(r.center.dx, r.top + 4), width: r.width * 0.5, height: 5), const Radius.circular(2)),
    p.cor(tampa),
  );
  c.drawRRect(
    RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(r.center.dx, r.bottom - 4), width: r.width * 0.5, height: 5), const Radius.circular(2)),
    p.cor(tampa),
  );
  c.drawLine(Offset(r.center.dx, r.bottom - 2), Offset(r.center.dx, r.bottom + 5), p.traco(const Color(0xFFE07A5F), 1.4));
  c.restore();
}

void _vagalumes(_Pincel p) {
  final c = p.c;
  for (var i = 0; i < p.pecas.length; i++) {
    final q = p.pecas[i];
    final pisca = p.onda(4, i * 0.37);
    final voo = Offset(math.sin((p.fase * 3 + i * 0.4) * 2 * math.pi) * 5, math.cos((p.fase * 2 + i * 0.3) * 2 * math.pi) * 4);
    final o = Offset(q.x + q.w / 2, q.y + q.h / 2) + voo;
    c.drawCircle(o, q.w * 1.8, p.brilho(o, q.w * 1.8, q.c.withValues(alpha: 0.35 + 0.45 * pisca)));
    c.drawCircle(o, q.w * 0.32, p.cor(_claro(q.c, 0.5).withValues(alpha: 0.6 + 0.4 * pisca)));
  }
}

void _neve(_Pincel p) {
  final c = p.c;
  for (var i = 0; i < p.pecas.length; i++) {
    final q = p.pecas[i];
    final cai = (p.fase * 14 + i * 2.3) % 14;
    final o = Offset(q.x + q.w / 2 + math.sin((p.fase * 2 + i * 0.2) * 2 * math.pi) * 4, q.y + q.h / 2 + cai);
    if (q.w >= 7) {
      // Os grandes são flocos de seis pontas.
      for (var k = 0; k < 3; k++) {
        final a = k * math.pi / 3 + p.fase;
        final d = Offset(math.cos(a), math.sin(a)) * q.w * 0.7;
        c.drawLine(o - d, o + d, p.traco(const Color(0xEEFFFFFF), 1.1));
      }
      c.drawCircle(o, 1.2, p.cor(const Color(0xFFFFFFFF)));
    } else {
      c.drawCircle(o, q.w * 0.75, p.brilho(o, q.w * 0.75, const Color(0xEEFFFFFF)));
      c.drawCircle(o, q.w * 0.32, p.cor(const Color(0xFFFFFFFF)));
    }
  }
}

void _varalDeLuzes(_Pincel p) {
  final c = p.c;
  final fio = p[0];
  final e = fio.x, d = fio.x + fio.w, y = fio.y + 1;
  double curva(double x) {
    final t = (x - e) / (d - e);
    return y + math.sin(t * math.pi) * 14;
  }

  final caminho = Path()..moveTo(e, y);
  for (var x = e; x <= d; x += 4) {
    caminho.lineTo(x, curva(x));
  }
  c.drawPath(caminho, p.traco(const Color(0x995A4636), 1.2));
  for (var i = 1; i < p.pecas.length; i++) {
    final q = p.pecas[i];
    final x = q.x + q.w / 2;
    final topo = Offset(x, curva(x));
    final pisca = p.onda(3, i * 0.21);
    final lampada = topo + const Offset(0, 6);
    c.drawCircle(lampada, q.w * 1.3, p.brilho(lampada, q.w * 1.3, q.c.withValues(alpha: 0.35 + 0.3 * pisca)));
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: topo + const Offset(0, 1.5), width: 3.4, height: 3), const Radius.circular(1)),
      p.cor(const Color(0xFF5A4636)),
    );
    final gota = Path()
      ..moveTo(topo.dx - q.w * 0.3, topo.dy + 3)
      ..quadraticBezierTo(topo.dx - q.w * 0.5, topo.dy + 9, topo.dx, topo.dy + 11)
      ..quadraticBezierTo(topo.dx + q.w * 0.5, topo.dy + 9, topo.dx + q.w * 0.3, topo.dy + 3)
      ..close();
    c.drawPath(gota, p.cor(_claro(q.c, 0.2 + 0.2 * pisca)));
    c.drawCircle(topo + const Offset(-1, 6), 0.9, p.cor(const Color(0xAAFFFFFF)));
  }
}

void _fogueira(_Pincel p) {
  final c = p.c;
  final lenha = p[0], fogo = p[2], brasa = p[3];
  final base = lenha.y + lenha.h;
  final cx = lenha.x + lenha.w / 2;
  c.drawCircle(Offset(cx, base - 14), 26, p.brilho(Offset(cx, base - 14), 26, Color.fromRGBO(255, 170, 90, 0.28 + 0.12 * p.onda(9))));
  // As pedras em roda.
  for (var i = 0; i < 6; i++) {
    final x = lenha.x - 2 + i * (lenha.w + 4) / 5;
    final o = Rect.fromCenter(center: Offset(x, base - 1), width: 8, height: 5.5);
    c.drawOval(o, p.gradV(o, const Color(0xFFB8B0A3), const Color(0xFF8C8478)));
  }
  // Duas toras cruzadas.
  for (final s in [-1.0, 1.0]) {
    c.save();
    c.translate(cx, base - 4);
    c.rotate(0.32 * s);
    final r = Rect.fromCenter(center: Offset.zero, width: lenha.w * 0.9, height: 5.5);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2.7)), p.gradV(r, _claro(lenha.c, 0.2), lenha.c));
    c.drawOval(Rect.fromCenter(center: Offset(r.right - 1.5 * s * s, 0), width: 3.5, height: 5), p.cor(const Color(0xFFD9B184)));
    c.restore();
  }
  // As chamas, em três camadas que tremulam fora de fase.
  Path chama(double largura, double altura, double inclina) => Path()
    ..moveTo(cx - largura / 2, base - 6)
    ..quadraticBezierTo(cx - largura * 0.6, base - 6 - altura * 0.55, cx + inclina, base - 6 - altura)
    ..quadraticBezierTo(cx + largura * 0.6, base - 6 - altura * 0.5, cx + largura / 2, base - 6)
    ..close();
  final t1 = p.onda(11), t2 = p.onda(13, 0.3), t3 = p.onda(17, 0.6);
  c.drawPath(chama(fogo.w * 1.1, fogo.h + 4 + 3 * t1, (t2 - 0.5) * 4), p.cor(const Color(0xFFE76F51)));
  c.drawPath(chama(fogo.w * 0.8, fogo.h - 1 + 3 * t2, (t3 - 0.5) * 3), p.cor(fogo.c));
  c.drawPath(chama(fogo.w * 0.45, fogo.h * 0.6 + 2 * t3, (t1 - 0.5) * 2), p.cor(const Color(0xFFFFE08A)));
  // Fagulhas subindo.
  for (var i = 0; i < 3; i++) {
    final sobe = (p.fase * 9 + i / 3) % 1;
    final o = Offset(cx + math.sin((sobe + i) * 6) * 5, base - 22 - sobe * 18);
    c.drawCircle(o, 1.2 * (1 - sobe) + 0.3, p.cor(brasa.c.withValues(alpha: 1 - sobe)));
  }
}

void _cerejeira(_Pincel p) {
  final c = p.c;
  final tronco = p[0], copa = p[1], copa2 = p[2];
  final chao = tronco.y + tronco.h;
  final cx = tronco.x + tronco.w / 2;
  p.sombra(cx, chao, copa.w * 0.9, 0.16);
  // Tronco torto com um galho.
  final t = Path()
    ..moveTo(cx - tronco.w * 0.9, chao)
    ..quadraticBezierTo(cx - 2, chao - tronco.h * 0.5, cx - tronco.w * 0.3, copa.y + copa.h * 0.6)
    ..lineTo(cx + tronco.w * 0.4, copa.y + copa.h * 0.6)
    ..quadraticBezierTo(cx + 3, chao - tronco.h * 0.45, cx + tronco.w * 0.9, chao)
    ..close();
  c.drawPath(t, p.cor(tronco.c));
  c.drawLine(
    Offset(cx, chao - tronco.h * 0.55),
    Offset(cx - 13, copa.y + copa.h * 0.75),
    p.traco(tronco.c, 2.6),
  );
  c.drawPath(t, _contorno(tronco.c, 1));
  // A copa: flores em cachos, dois rosas.
  final ginga = (p.onda(1) - 0.5) * 1.4;
  final o = Offset(copa.x + ginga, copa.y);
  final w = copa.w, h = copa.h;
  final cachos = [
    (Offset(w * 0.2, h * 0.65), w * 0.22, copa.c),
    (Offset(w * 0.82, h * 0.62), w * 0.2, copa.c),
    (Offset(w * 0.5, h * 0.5), w * 0.3, copa.c),
    (Offset(w * 0.34, h * 0.28), w * 0.22, copa2.c),
    (Offset(w * 0.66, h * 0.22), w * 0.22, copa2.c),
    (Offset(w * 0.5, h * 0.78), w * 0.22, copa2.c),
  ];
  for (final (pos, raio, cor) in cachos) {
    c.drawCircle(o + pos + const Offset(0, 1.6), raio, p.cor(_escuro(cor, 0.12)));
  }
  for (final (pos, raio, cor) in cachos) {
    c.drawCircle(o + pos, raio, p.cor(cor));
  }
  // Florzinhas brancas pontuando a copa.
  for (final (dx, dy) in [(0.28, 0.4), (0.58, 0.32), (0.72, 0.6), (0.42, 0.66), (0.86, 0.48), (0.16, 0.6)]) {
    final f = o + Offset(w * dx, h * dy);
    c.drawCircle(f, 1.5, p.cor(const Color(0xF0FFF6F8)));
    c.drawCircle(f, 0.6, p.cor(const Color(0xFFE38FA6)));
  }
  // Pétalas caindo.
  for (var i = 0; i < 3; i++) {
    final q = p[3 + (i % 2)];
    final cai = (p.fase * 3 + i * 0.33) % 1;
    final x = q.x + q.w / 2 - i * 8 + math.sin((cai + i) * 6) * 3;
    final y = q.y + q.h / 2 + cai * 26;
    c.drawPath(_folha(Offset(x, y), Offset(x + 3.5, y + 1.5), 2.6), p.cor(q.c.withValues(alpha: 1 - cai * 0.6)));
  }
}

// ---------------------------------------------------------------- céu

void _nuvens(_Pincel p) {
  final c = p.c;
  final deriva = (p.fase - 0.5) * 10;
  for (var i = 0; i < p.pecas.length; i++) {
    final q = p.pecas[i];
    final r = Rect.fromLTWH(q.x + deriva * (i.isEven ? 1 : 0.6), q.y, q.w, q.h);
    final nuvem = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(r.left, r.top + r.height * 0.45, r.width, r.height * 0.55),
        Radius.circular(r.height * 0.3),
      ))
      ..addOval(Rect.fromCircle(center: Offset(r.left + r.width * 0.32, r.top + r.height * 0.5), radius: r.height * 0.42))
      ..addOval(Rect.fromCircle(center: Offset(r.left + r.width * 0.6, r.top + r.height * 0.36), radius: r.height * 0.52))
      ..addOval(Rect.fromCircle(center: Offset(r.left + r.width * 0.82, r.top + r.height * 0.58), radius: r.height * 0.32));
    c.drawPath(nuvem.shift(const Offset(0, 2)), p.cor(_escuro(q.c, 0.12).withValues(alpha: 0.45)));
    c.drawPath(nuvem, p.gradV(r.inflate(r.height * 0.5), _claro(q.c, 0.6), q.c));
  }
}
