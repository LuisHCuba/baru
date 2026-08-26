import 'package:flutter/material.dart';

import '../theme.dart';

/// Ícone Material com glifo da fonte padrão.
/// Não herda Nunito do [TextTheme] — [IconData] já aponta para `MaterialIcons`.
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size = 20, this.color});

  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: size, color: color);
  }
}

class Chevron extends StatelessWidget {
  const Chevron({super.key, this.size = 20, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return AppIcon(
      Icons.chevron_right_rounded,
      size: size,
      color: color ?? AppColors.inkA(0.3),
    );
  }
}

class QuestMark extends StatelessWidget {
  const QuestMark({super.key, required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 21,
      height: 21,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: done ? AppColors.green : null,
          shape: BoxShape.circle,
          border: done ? null : Border.all(color: AppColors.inkA(0.16), width: 2),
        ),
        child: done
            ? const Center(
                child: AppIcon(Icons.check_rounded, size: 14, color: AppColors.card),
              )
            : null,
      ),
    );
  }
}

class TabGlyph {
  const TabGlyph(this.off, this.on);
  final IconData off;
  final IconData on;
}

/// O HTML só tinha um quadrado 19×19. Estes são os glifos reais das tabs.
const tabGlyphs = [
  TabGlyph(Icons.home_outlined, Icons.home_rounded),
  TabGlyph(Icons.storefront_outlined, Icons.storefront_rounded),
  TabGlyph(Icons.insights_outlined, Icons.insights),
  TabGlyph(Icons.settings_outlined, Icons.settings_rounded),
];
