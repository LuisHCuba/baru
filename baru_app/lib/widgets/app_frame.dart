import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// Coluna 412px no Chrome/desktop — o HTML vive num frame 412×892.
/// Em telefone o filho ocupa a tela inteira, em qualquer orientação.
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

  /// Chave da moldura de aparelho — o teste a usa para provar que ela não
  /// aparece dentro de um telefone.
  static const molduraKey = Key('app-frame-device');

  /// A moldura simula um aparelho: mostrá-la *dentro* de um aparelho é o bug.
  ///
  /// Decidir só pela largura não basta — um celular deitado passa dos 520 px e
  /// passava a desenhar o bezel falso em volta do próprio app.
  static bool molduraFazSentido() {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return false;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return true;
    }
  }

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
        if (!molduraFazSentido() || c.maxWidth <= breakpoint) return scaled;
        final h = c.maxHeight.isFinite ? c.maxHeight.clamp(480.0, maxHeight) : maxHeight;
        return ColoredBox(
          color: AppColors.canvas,
          child: Center(
            child: Container(
              key: molduraKey,
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
