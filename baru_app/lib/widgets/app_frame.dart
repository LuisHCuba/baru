import 'package:flutter/material.dart';

import '../theme.dart';

/// Coluna 412px no Chrome/desktop — o HTML vive num frame 412×892.
/// Em largura de telefone o filho ocupa a tela inteira.
/// O outro agente pode envolver o `_Shell` com isto.
class AppFrame extends StatelessWidget {
  const AppFrame({
    super.key,
    required this.child,
    this.width = 412,
    this.maxHeight = 892,
    this.breakpoint = 520,
  });

  final Widget child;
  final double width;
  final double maxHeight;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final scaled = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.25),
          ),
          child: child,
        );
        if (c.maxWidth <= breakpoint) return scaled;
        final h = c.maxHeight.isFinite ? c.maxHeight.clamp(480.0, maxHeight) : maxHeight;
        return ColoredBox(
          color: AppColors.canvas,
          child: Center(
            child: Container(
              width: width + 20,
              height: h + 20,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(AppRadii.device),
                boxShadow: AppShadows.device,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.device - 8),
                child: ColoredBox(color: AppColors.cream, child: scaled),
              ),
            ),
          ),
        );
      },
    );
  }
}
