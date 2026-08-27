import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../theme.dart';

/// O companheiro. **Nunca está parado.**
///
/// Um bicho estático mata o conceito de habitat: vira wallpaper. Aqui ele
/// respira continuamente, pisca em intervalos irregulares, reage ao toque e
/// tem movimento próprio por atividade — boiar na água, cochilar, pastar.
///
/// Quando o sistema pede movimento reduzido, as animações contínuas param e
/// a pose fica neutra, mas o toque **continua respondendo**: quem pediu menos
/// movimento ainda precisa saber que o dedo foi registrado.
class PetView extends StatefulWidget {
  const PetView({
    super.key,
    required this.species,
    required this.mood,
    required this.activity,
    required this.coat,
    this.scale = 1,
    this.width = 200,
    this.height = 150,
    this.alignment = Alignment.center,
    this.interativo = true,
  });

  final Species species;
  final Mood mood;
  final Activity activity;
  final int coat;
  final double scale;
  final double width;
  final double height;
  final Alignment alignment;

  /// Responde ao toque. Desligado em miniaturas e capturas.
  final bool interativo;

  /// Chave da camada que o teste captura para provar que o desenho mudou.
  static const cenaKey = Key('pet-cena');

  @override
  State<PetView> createState() => _PetViewState();
}

class _PetViewState extends State<PetView> with TickerProviderStateMixin {
  late final AnimationController _respiro = AnimationController(
    vsync: this,
    duration: Tempo.respiracao,
  );

  /// Período diferente do da respiração de propósito: se os dois ciclos
  /// batessem, o movimento pareceria mecânico.
  late final AnimationController _flutua = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4700),
  );

  late final AnimationController _pisca = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 170),
  );

  /// `preserve` de propósito: com "reduzir movimento" ligado, o Flutter
  /// encurta a duração de um controller para 5% — a quicada do toque acabaria
  /// antes de ser vista. Amplitude a gente reduz; o feedback fica.
  late final AnimationController _toque = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    animationBehavior: AnimationBehavior.preserve,
  );

  final _sorte = math.Random();
  Timer? _proximoPiscar;
  bool _continuoLigado = false;

  @override
  void initState() {
    super.initState();
    _toque.value = 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduzido = Movimento.reduzido(context);
    if (reduzido) {
      _paraContinuo();
    } else {
      _iniciaContinuo();
    }
  }

  void _iniciaContinuo() {
    if (_continuoLigado) return;
    _continuoLigado = true;
    _respiro.repeat(reverse: true);
    _flutua.repeat(reverse: true);
    _agendaPiscar();
  }

  void _paraContinuo() {
    _continuoLigado = false;
    _proximoPiscar?.cancel();
    _respiro
      ..stop()
      ..value = 0.5;
    _flutua
      ..stop()
      ..value = 0.5;
    _pisca
      ..stop()
      ..value = 0;
  }

  /// Piscada em intervalo irregular. Cadência fixa parece relógio, não bicho.
  void _agendaPiscar() {
    _proximoPiscar?.cancel();
    final espera = Duration(milliseconds: 2200 + _sorte.nextInt(4200));
    _proximoPiscar = Timer(espera, () async {
      if (!mounted || !_continuoLigado) return;
      await _pisca.forward(from: 0);
      if (!mounted) return;
      await _pisca.reverse();
      if (!mounted) return;
      _agendaPiscar();
    });
  }

  void _reageAoToque() {
    if (!widget.interativo) return;
    HapticFeedback.lightImpact();
    _toque.forward(from: 0);
    // Uma piscada junto do toque: o bicho "olha" para quem tocou.
    if (_continuoLigado && !_pisca.isAnimating) {
      _pisca.forward(from: 0).then((_) {
        if (mounted) _pisca.reverse();
      });
    }
  }

  @override
  void dispose() {
    _proximoPiscar?.cancel();
    _respiro.dispose();
    _flutua.dispose();
    _pisca.dispose();
    _toque.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amplitude = Movimento.reduzido(context) ? 0.25 : 1.0;
    final cena = RepaintBoundary(
      key: PetView.cenaKey,
      child: AnimatedBuilder(
        animation: Listenable.merge([_respiro, _flutua, _pisca, _toque]),
        builder: (context, _) {
          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _PetPainter(
              species: widget.species,
              mood: widget.mood,
              activity: widget.activity,
              coat: AppColors.coat[
                  widget.coat.clamp(0, AppColors.coat.length - 1)],
              respiro: Curvas.organica.transform(_respiro.value),
              flutua: Curvas.organica.transform(_flutua.value),
              pisca: _pisca.value,
              toque: _toque.value,
              amplitude: amplitude,
            ),
          );
        },
      ),
    );

    final corpo = Transform.scale(
      scale: widget.scale,
      alignment: widget.alignment,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: cena,
      ),
    );

    if (!widget.interativo) return corpo;
    // `opaque`, não `deferToChild`: um CustomPaint sem filho não responde a
    // hit-test, então deferir ao filho deixaria o toque no bicho sem efeito.
    return GestureDetector(
      onTap: _reageAoToque,
      behavior: HitTestBehavior.opaque,
      child: corpo,
    );
  }
}

class _PetPainter extends CustomPainter {
  _PetPainter({
    required this.species,
    required this.mood,
    required this.activity,
    required this.coat,
    required this.respiro,
    required this.flutua,
    required this.pisca,
    required this.toque,
    required this.amplitude,
  });

  final Species species;
  final Mood mood;
  final Activity activity;
  final Color coat;

  /// 0..1, ida e volta contínua. Comprime e estica o corpo.
  final double respiro;

  /// 0..1, ida e volta contínua, período diferente do respiro.
  final double flutua;

  /// 0..1, onde 1 é olho fechado.
  final double pisca;

  /// 0..1, um pulso disparado pelo toque.
  final double toque;

  /// Fator global de movimento (menor quando o sistema pede movimento
  /// reduzido).
  final double amplitude;

  /// Amplitude do toque.
  ///
  /// Tem piso próprio: o §7 manda **reduzir** amplitude quando o sistema pede
  /// menos movimento, não remover o feedback. Com o fator global de 0.25 a
  /// quicada ficava abaixo de um pixel — feedback invisível é feedback que
  /// não existe.
  double get _amplitudeToque => math.max(amplitude, 0.55);

  /// Quicada do toque: sobe rápido e volta oscilando.
  double get _quique {
    if (toque == 0) return 0;
    final t = toque;
    return math.sin(t * math.pi * 3) * math.exp(-t * 4);
  }

  bool get asleep => activity == Activity.nap || mood == Mood.sleepy;
  bool get droop =>
      mood == Mood.missingYou || mood == Mood.sleepy || activity == Activity.nap;

  Color get fur {
    switch (mood) {
      case Mood.radiant:
        return Color.lerp(coat, AppColors.cream, 0.10)!;
      case Mood.sleepy:
        return Color.lerp(coat, AppColors.ink, 0.10)!;
      case Mood.missingYou:
        return Color.lerp(coat, AppColors.ink, 0.14)!;
      case Mood.neutral:
        return Color.lerp(coat, AppColors.ink, 0.05)!;
      case Mood.content:
        return coat;
    }
  }

  Color get dark => Color.lerp(fur, AppColors.ink, 0.36)!;
  Color get light => Color.lerp(fur, AppColors.cream, 0.32)!;

  Paint fill(Color c) => Paint()..color = c..isAntiAlias = true;

  void rr(Canvas canvas, Rect r, double rad, Color c) {
    canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(rad)), fill(c));
  }

  void ov(Canvas canvas, Rect r, Color c) => canvas.drawOval(r, fill(c));

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 8;

    // Sopro: -1..1. Peito enche e esvazia.
    final sopro = (respiro * 2 - 1) * amplitude;
    // Boia: -1..1, para o corpo subir e descer na água ou no sono.
    final boia = (flutua * 2 - 1) * amplitude;

    final balancoPorAtividade = switch (activity) {
      Activity.swim => boia * 3.4,
      Activity.nap => sopro * 1.6,
      Activity.graze => boia * 1.8,
      Activity.idle => boia * 1.1,
    };

    canvas.save();
    canvas.translate(
      cx,
      cy + balancoPorAtividade + _quique * 7 * _amplitudeToque,
    );

    // Respiração como leve squash/stretch: o corpo alarga ao encher.
    final respiraX = 1 + sopro * 0.016 + _quique * 0.07 * _amplitudeToque;
    final respiraY = 1 - sopro * 0.012 - _quique * 0.07 * _amplitudeToque;
    canvas.scale(respiraX, respiraY);

    if (activity == Activity.graze) {
      // Pastar é abaixar e levantar a cabeça: uma inclinação que respira.
      canvas.rotate(boia * 0.05 * amplitude);
    }

    switch (activity) {
      case Activity.nap:
        canvas.rotate(-0.24);
        canvas.translate(0, 12);
      case Activity.swim:
        canvas.rotate(-0.10);
        canvas.translate(0, 8);
      case Activity.graze:
        canvas.rotate(0.08);
        canvas.translate(2, 6);
      case Activity.idle:
        if (mood == Mood.sleepy) {
          canvas.rotate(-0.08);
          canvas.translate(0, 4);
        } else if (mood == Mood.missingYou) {
          canvas.translate(0, 3);
        }
    }
    switch (species) {
      case Species.capybara:
        _capybara(canvas);
      case Species.otter:
        _otter(canvas);
      case Species.tortoise:
        _tortoise(canvas);
      case Species.owl:
        _owl(canvas);
    }
    _moodFx(canvas);
    canvas.restore();
    if (activity == Activity.swim) _ripples(canvas, size);
  }

  void _capybara(Canvas canvas) {
    rr(canvas, const Rect.fromLTWH(22, 18, 16, 20), 7, dark);
    rr(canvas, const Rect.fromLTWH(40, 16, 15, 22), 7, dark);
    rr(canvas, const Rect.fromLTWH(-52, -22, 120, 54), 27, fur);
    ov(canvas, const Rect.fromLTWH(-18, -2, 72, 26), light);
    ov(canvas, const Rect.fromLTWH(8, -18, 42, 18), Color.lerp(fur, AppColors.cream, 0.18)!);
    rr(canvas, const Rect.fromLTWH(-38, 20, 15, 18), 7, dark);
    rr(canvas, const Rect.fromLTWH(-18, 22, 14, 16), 7, dark);
    rr(canvas, const Rect.fromLTWH(-80, -40, 62, 50), 23, fur);
    if (droop) {
      ov(canvas, const Rect.fromLTWH(-72, -46, 17, 12), fur);
      ov(canvas, const Rect.fromLTWH(-50, -48, 15, 11), fur);
    } else {
      ov(canvas, const Rect.fromLTWH(-74, -54, 15, 18), fur);
      ov(canvas, const Rect.fromLTWH(-52, -56, 14, 17), fur);
      ov(canvas, const Rect.fromLTWH(-71, -50, 8, 9), light);
    }
    ov(canvas, const Rect.fromLTWH(-84, -16, 34, 20), light);
    rr(canvas, const Rect.fromLTWH(-80, -8, 13, 6), 3, dark);
    _eyes(canvas, const Offset(-66, -22), const Offset(-48, -24));
    _blush(canvas, const Offset(-74, -6), const Offset(-42, -8), rx: 5.5, ry: 3);
    _mouth(canvas, const Offset(-68, 2), w: 11);
    _tear(canvas, const Offset(-44, -10));
  }

  void _otter(Canvas canvas) {
    final tail = Path()
      ..moveTo(44, 0)
      ..quadraticBezierTo(92, 8, 78, 38)
      ..quadraticBezierTo(62, 22, 40, 16)
      ..close();
    canvas.drawPath(tail, fill(dark));
    rr(canvas, const Rect.fromLTWH(-50, -18, 108, 40), 20, fur);
    ov(canvas, const Rect.fromLTWH(-24, -6, 64, 22), light);
    rr(canvas, const Rect.fromLTWH(-80, -36, 52, 42), 20, fur);
    if (droop) {
      ov(canvas, const Rect.fromLTWH(-74, -40, 13, 10), fur);
      ov(canvas, const Rect.fromLTWH(-56, -42, 13, 10), fur);
    } else {
      ov(canvas, const Rect.fromLTWH(-74, -46, 12, 14), fur);
      ov(canvas, const Rect.fromLTWH(-56, -48, 12, 14), fur);
    }
    ov(canvas, const Rect.fromLTWH(-82, -12, 28, 16), light);
    ov(canvas, const Rect.fromLTWH(-80, -4, 9, 7), dark);
    final w = Paint()
      ..color = AppColors.inkA(0.28)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-80, -2), const Offset(-98, -6), w);
    canvas.drawLine(const Offset(-80, 2), const Offset(-98, 2), w);
    canvas.drawLine(const Offset(-80, 6), const Offset(-96, 10), w);
    _eyes(canvas, const Offset(-66, -18), const Offset(-50, -20), r: 3.8);
    _blush(canvas, const Offset(-72, -4), const Offset(-44, -6), rx: 5, ry: 2.8);
    _mouth(canvas, const Offset(-68, 4), w: 9);
    _tear(canvas, const Offset(-46, -8));
  }

  void _tortoise(Canvas canvas) {
    for (final x in [-42.0, -14.0, 16.0, 42.0]) {
      ov(canvas, Rect.fromLTWH(x, 26, 18, 14), dark);
    }
    ov(canvas, const Rect.fromLTWH(-56, -30, 114, 74), dark);
    ov(canvas, const Rect.fromLTWH(-46, -22, 94, 58), fur);
    ov(canvas, const Rect.fromLTWH(-28, -14, 30, 22), light);
    ov(canvas, const Rect.fromLTWH(6, -10, 26, 18), light);
    ov(canvas, Rect.fromLTWH(-8, 6, 22, 14), Color.lerp(fur, dark, 0.22)!);
    rr(canvas, const Rect.fromLTWH(-80, -10, 36, 28), 14, fur);
    ov(canvas, const Rect.fromLTWH(-82, -18, 14, 12), fur);
    _eye(canvas, const Offset(-70, -2), 3.5);
    _blush(canvas, const Offset(-76, 8), const Offset(-58, 10), rx: 4, ry: 2.4);
    _mouth(canvas, const Offset(-74, 10), w: 8);
    _tear(canvas, const Offset(-64, 8));
  }

  void _owl(Canvas canvas) {
    rr(canvas, const Rect.fromLTWH(-42, -38, 84, 88), 40, fur);
    ov(canvas, const Rect.fromLTWH(-44, -8, 22, 48), dark);
    ov(canvas, const Rect.fromLTWH(22, -8, 22, 48), dark);
    ov(canvas, const Rect.fromLTWH(-18, 4, 36, 40), light);
    final tuftY = droop ? -46.0 : -60.0;
    canvas.drawPath(
      Path()
        ..moveTo(-26, -34)
        ..lineTo(-40, tuftY)
        ..lineTo(-10, -38)
        ..close(),
      fill(dark),
    );
    canvas.drawPath(
      Path()
        ..moveTo(26, -34)
        ..lineTo(40, tuftY)
        ..lineTo(10, -38)
        ..close(),
      fill(dark),
    );
    canvas.drawCircle(const Offset(-16, -8), 17, fill(AppColors.cream));
    canvas.drawCircle(const Offset(16, -8), 17, fill(AppColors.cream));
    _eyes(canvas, const Offset(-16, -8), const Offset(16, -8), r: 6.4);
    canvas.drawPath(
      Path()
        ..moveTo(0, 2)
        ..lineTo(-7, 13)
        ..lineTo(7, 13)
        ..close(),
      fill(AppColors.orange),
    );
    ov(canvas, const Rect.fromLTWH(-18, 40, 16, 16), dark);
    ov(canvas, const Rect.fromLTWH(2, 40, 16, 16), dark);
    _blush(canvas, const Offset(-28, 8), const Offset(28, 8), rx: 6, ry: 3.2);
    _tear(canvas, const Offset(26, 4));
  }

  void _eyes(Canvas canvas, Offset a, Offset b, {double r = 4.2}) {
    _eye(canvas, a, r);
    _eye(canvas, b, r);
  }

  void _eye(Canvas canvas, Offset o, double r) {
    if (pisca > 0.02 && !asleep) {
      // Fecha o olho comprimindo verticalmente e desenha a pálpebra ao final.
      canvas.save();
      canvas.translate(o.dx, o.dy);
      canvas.scale(1, (1 - pisca).clamp(0.0, 1.0));
      canvas.translate(-o.dx, -o.dy);
      _olhoAberto(canvas, o, r);
      canvas.restore();
      if (pisca > 0.6) {
        canvas.drawLine(
          o + Offset(-r * 0.9, 0),
          o + Offset(r * 0.9, 0),
          Paint()
            ..color = AppColors.ink
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
      return;
    }
    _olhoAberto(canvas, o, r);
  }

  void _olhoAberto(Canvas canvas, Offset o, double r) {
    final ink = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (asleep) {
      canvas.drawArc(Rect.fromCircle(center: o, radius: r * 0.95), 0.28, math.pi - 0.56, false, ink);
      return;
    }
    if (mood == Mood.neutral) {
      canvas.drawLine(o + Offset(-r, 0.4), o + Offset(r, 0.4), ink..strokeWidth = 2.2);
      return;
    }
    final look = mood == Mood.missingYou
        ? Offset(r * 0.20, r * 0.36)
        : Offset(r * 0.10, r * 0.08);
    canvas.drawCircle(o, r, fill(AppColors.cream));
    canvas.drawCircle(o + look, mood == Mood.radiant ? r * 0.56 : r * 0.50, fill(AppColors.ink));
    if (mood == Mood.radiant) {
      canvas.drawCircle(o + Offset(-r * 0.32, -r * 0.30), r * 0.20, fill(Colors.white));
      canvas.drawCircle(o + Offset(r * 0.18, r * 0.12), r * 0.10, fill(Colors.white70));
    } else if (mood == Mood.content) {
      canvas.drawCircle(o + Offset(-r * 0.28, -r * 0.26), r * 0.14, fill(Colors.white));
    }
    if (mood == Mood.missingYou) {
      canvas.drawLine(
        o + Offset(-r * 0.85, -r * 1.15),
        o + Offset(r * 0.45, -r * 0.82),
        ink..strokeWidth = 1.6,
      );
    }
  }

  void _mouth(Canvas canvas, Offset o, {double w = 12}) {
    final paint = Paint()
      ..color = dark
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    switch (mood) {
      case Mood.radiant:
        canvas.drawArc(
          Rect.fromCenter(center: o, width: w, height: w * 0.72),
          0.15,
          math.pi - 0.3,
          false,
          paint,
        );
      case Mood.content:
        canvas.drawArc(
          Rect.fromCenter(center: o, width: w * 0.8, height: w * 0.48),
          0.22,
          math.pi - 0.44,
          false,
          paint,
        );
      case Mood.neutral:
        canvas.drawLine(o + Offset(-w * 0.2, 0), o + Offset(w * 0.2, 0), paint..strokeWidth = 1.5);
      case Mood.sleepy:
        ov(canvas, Rect.fromCenter(center: o, width: 5, height: 4), dark);
      case Mood.missingYou:
        canvas.drawArc(
          Rect.fromCenter(center: o + const Offset(0, 2), width: w * 0.7, height: w * 0.5),
          math.pi + 0.25,
          math.pi - 0.5,
          false,
          paint,
        );
    }
  }

  void _blush(Canvas canvas, Offset a, Offset b, {double rx = 6, double ry = 3.5}) {
    if (mood != Mood.radiant && mood != Mood.content) return;
    final c = AppColors.orange.withValues(alpha: mood == Mood.radiant ? 0.42 : 0.22);
    ov(canvas, Rect.fromCenter(center: a, width: rx * 2, height: ry * 2), c);
    ov(canvas, Rect.fromCenter(center: b, width: rx * 2, height: ry * 2), c);
  }

  void _tear(Canvas canvas, Offset o) {
    if (mood != Mood.missingYou) return;
    final path = Path()
      ..moveTo(o.dx, o.dy - 5)
      ..quadraticBezierTo(o.dx + 4, o.dy + 1, o.dx, o.dy + 7)
      ..quadraticBezierTo(o.dx - 4, o.dy + 1, o.dx, o.dy - 5)
      ..close();
    canvas.drawPath(path, fill(const Color(0x996B8FA8)));
  }

  void _moodFx(Canvas canvas) {
    if (mood == Mood.radiant) {
      _star(canvas, const Offset(56, -48), 6, AppColors.orange);
      _star(canvas, const Offset(-78, -56), 4.5, AppColors.green);
      if (activity != Activity.nap) {
        _star(canvas, const Offset(34, -68), 3.4, AppColors.orange.withValues(alpha: 0.8));
      }
    }
    if (asleep && mood != Mood.radiant) _zzz(canvas);
  }

  void _star(Canvas canvas, Offset o, double s, Color c) {
    final path = Path()
      ..moveTo(o.dx, o.dy - s)
      ..lineTo(o.dx + s * 0.26, o.dy - s * 0.26)
      ..lineTo(o.dx + s, o.dy)
      ..lineTo(o.dx + s * 0.26, o.dy + s * 0.26)
      ..lineTo(o.dx, o.dy + s)
      ..lineTo(o.dx - s * 0.26, o.dy + s * 0.26)
      ..lineTo(o.dx - s, o.dy)
      ..lineTo(o.dx - s * 0.26, o.dy - s * 0.26)
      ..close();
    canvas.drawPath(path, fill(c));
  }

  void _zzz(Canvas canvas) {
    _z(canvas, const Offset(46, -40), 8);
    _z(canvas, const Offset(58, -54), 6);
    _z(canvas, const Offset(68, -66), 5);
  }

  void _z(Canvas canvas, Offset o, double s) {
    final path = Path()
      ..moveTo(o.dx, o.dy)
      ..lineTo(o.dx + s, o.dy)
      ..lineTo(o.dx, o.dy + s * 0.85)
      ..lineTo(o.dx + s, o.dy + s * 0.85);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.inkA(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Ondas que abrem a partir do bicho, cada anel numa fase diferente.
  void _ripples(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height - 12);
    const rings = [(130.0, 16.0, 0.22), (96.0, 11.0, 0.14), (64.0, 7.0, 0.10)];
    for (var i = 0; i < rings.length; i++) {
      final (w, h, a) = rings[i];
      // Cada anel adianta a fase: a água anda em vez de pulsar em bloco.
      final fase = (flutua + i * 0.33) % 1.0;
      final cresce = 1 + fase * 0.16 * amplitude;
      final some = (1 - fase * 0.55).clamp(0.25, 1.0);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: w * cresce, height: h * cresce),
        Paint()
          ..color = AppColors.green.withValues(alpha: a * some)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PetPainter old) {
    return old.species != species ||
        old.mood != mood ||
        old.activity != activity ||
        old.coat != coat ||
        old.respiro != respiro ||
        old.flutua != flutua ||
        old.pisca != pisca ||
        old.toque != toque ||
        old.amplitude != amplitude;
  }
}
