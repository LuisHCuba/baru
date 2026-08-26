import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

/// Estudo de formas 200×150 — o HTML importa um Pet que não veio na pasta.
/// Humores: sleepy, neutral, content, radiant, missing_you.
class PetView extends StatelessWidget {
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
  });

  final Species species;
  final Mood mood;
  final Activity activity;
  final int coat;
  final double scale;
  final double width;
  final double height;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      alignment: alignment,
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _PetPainter(
            species: species,
            mood: mood,
            activity: activity,
            coat: AppColors.coat[coat.clamp(0, AppColors.coat.length - 1)],
          ),
        ),
      ),
    );
  }
}

class _PetPainter extends CustomPainter {
  _PetPainter({
    required this.species,
    required this.mood,
    required this.activity,
    required this.coat,
  });

  final Species species;
  final Mood mood;
  final Activity activity;
  final Color coat;

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
    canvas.save();
    canvas.translate(cx, cy);
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

  void _ripples(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height - 12);
    const rings = [(130.0, 16.0, 0.22), (96.0, 11.0, 0.14), (64.0, 7.0, 0.10)];
    for (final e in rings) {
      canvas.drawOval(
        Rect.fromCenter(center: c, width: e.$1, height: e.$2),
        Paint()
          ..color = AppColors.green.withValues(alpha: e.$3)
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
        old.coat != coat;
  }
}
