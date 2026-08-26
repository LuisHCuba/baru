import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import 'pet.dart';

class HabitatScene extends StatelessWidget {
  const HabitatScene({super.key, this.height = 296});

  final double height;

  /// Largura útil do HTML: frame 412 − padding 20+20.
  static const design = Size(372, 296);

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Semantics(
      image: true,
      label: app.t.fill(app.t.moodCap(app.moodKey), {'n': app.displayName}),
      child: Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.habitat,
        borderRadius: BorderRadius.circular(AppRadii.habitat),
        boxShadow: AppShadows.habitat,
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, c) {
          final sx = c.maxWidth / design.width;
          final sy = height / design.height;
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _HabitatBackdrop(sx: sx, sy: sy)),
              ),
              for (final item in shopItems.where((i) => app.owned.contains(i.id)))
                for (final p in item.parts)
                  Positioned(
                    left: p.x * sx,
                    top: p.y * sy,
                    child: Container(
                      width: p.w * sx,
                      height: p.h * sy,
                      decoration: BoxDecoration(
                        color: p.c,
                        borderRadius: BorderRadius.circular(p.r * sx),
                      ),
                    ),
                  ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 50 * sy,
                child: Center(
                  child: Container(
                    width: 152 * sx,
                    height: 16 * sy,
                    decoration: BoxDecoration(
                      color: AppColors.inkA(0.11),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 56 * sy,
                child: Center(
                  child: PetView(
                    species: app.species,
                    mood: app.mood,
                    activity: app.activity,
                    coat: app.color,
                    scale: 1.05,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
              ),
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _InsetVignette()),
                ),
              ),
            ],
          );
        },
      ),
    ),
    );
  }
}

/// Sol, colinas, faixa de areia, água e reflexos — iguais ao markup da home.
class _HabitatBackdrop extends CustomPainter {
  const _HabitatBackdrop({required this.sx, required this.sy});

  final double sx;
  final double sy;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width - 26 * sx - 28 * sx, 20 * sy + 28 * sx),
      28 * sx,
      Paint()..color = AppColors.orangeA(0.2),
    );

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(-34 * sx, 104 * sy, 224 * sx, 130 * sy),
        topLeft: Radius.circular(112 * sx),
        topRight: Radius.circular(112 * sx),
      ),
      Paint()..color = AppColors.greenA(0.14),
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(size.width - 206 * sx + 44 * sx, 92 * sy, 206 * sx, 140 * sy),
        topLeft: Radius.circular(104 * sx),
        topRight: Radius.circular(104 * sx),
      ),
      Paint()..color = AppColors.greenA(0.10),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 150 * sy, size.width, 34 * sy),
      Paint()..color = AppColors.sandA(0.17),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 120 * sy, size.width, 120 * sy),
      Paint()..color = AppColors.greenA(0.17),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 112 * sy, size.width, 2),
      Paint()..color = AppColors.greenA(0.26),
    );

    final glint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(38 * sx, size.height - 76 * sy - 4, 62 * sx, 4),
        const Radius.circular(AppRadii.pill),
      ),
      glint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 56 * sx - 46 * sx, size.height - 44 * sy - 4, 46 * sx, 4),
        const Radius.circular(AppRadii.pill),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.3),
    );
  }

  @override
  bool shouldRepaint(covariant _HabitatBackdrop old) => old.sx != sx || old.sy != sy;
}

/// `box-shadow: inset 0 0 46px rgba(62,47,35,.09)`
class _InsetVignette extends CustomPainter {
  const _InsetVignette();

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppRadii.habitat),
    );
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = AppColors.ink.withValues(alpha: 0.09)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 52
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
