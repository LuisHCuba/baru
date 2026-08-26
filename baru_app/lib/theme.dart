import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const cream = Color(0xFFFAF1E3);
  static const canvas = Color(0xFFEDE3D2);
  static const ink = Color(0xFF3E2F23);
  static const green = Color(0xFF5C8A4E);
  static const greenHover = Color(0xFF4E7842);
  static const greenDeep = Color(0xFF3E6B32);
  static const greenSoft = Color(0xFF6E9C5E);
  static const orange = Color(0xFFEF8354);
  static const orangeText = Color(0xFFB8502A);
  static const orangeDeep = Color(0xFFC25A26);
  static const card = Color(0xFFFFFBF2);
  static const habitat = Color(0xFFF4E6CB);
  static const sessionBg = Color(0xFFF5E9D3);
  static const shareSheet = Color(0xFFF2EFEA);
  static const shareThumb = Color(0xFFF1E0C2);
  static const sand = Color(0xFFC98A5B);
  static const wood = Color(0xFFA0764C);
  static const woodDark = Color(0xFF8A6440);
  static const boat = Color(0xFFB3764A);
  static const rock = Color(0xFFA79A8C);
  static const rockLight = Color(0xFFB6AA9D);
  static const rockDark = Color(0xFF948877);

  static const coat = [
    Color(0xFFC98A5B),
    Color(0xFFA9733F),
    Color(0xFFDBA478),
    Color(0xFF8A6247),
  ];

  static Color inkA(double a) => ink.withValues(alpha: a);
  static Color greenA(double a) => green.withValues(alpha: a);
  static Color orangeA(double a) => orange.withValues(alpha: a);
  static Color sandA(double a) => sand.withValues(alpha: a);
}

/// Nunito 400 / 600 / 700 / 800 — iguais ao HTML.
class AppWeight {
  static const regular = FontWeight.w400;
  static const semibold = FontWeight.w600;
  static const bold = FontWeight.w700;
  static const extra = FontWeight.w800;
}

/// Raios do markup (chip 14, botão 20, card 22, habitat 28, sheet 30).
class AppRadii {
  static const debug = 9.0;
  static const tab = 7.0;
  static const chip = 14.0;
  static const input = 18.0;
  static const button = 20.0;
  static const card = 22.0;
  static const report = 24.0;
  static const share = 26.0;
  static const habitat = 28.0;
  static const sheet = 30.0;
  static const device = 44.0;
  static const pill = 99.0;
}

class AppTheme {
  static TextStyle _n({
    required double size,
    required FontWeight weight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.nunito(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? AppColors.ink,
    );
  }

  static ThemeData get data {
    final text = TextTheme(
      displayLarge: _n(size: 30, weight: AppWeight.extra, height: 1.15, letterSpacing: -0.6),
      displayMedium: _n(size: 27, weight: AppWeight.extra, height: 1.2, letterSpacing: -0.5),
      displaySmall: _n(size: 23, weight: AppWeight.extra, height: 1.25, letterSpacing: -0.3),
      headlineMedium: _n(size: 26, weight: AppWeight.extra, height: 1.2, letterSpacing: -0.4),
      headlineSmall: _n(size: 18, weight: AppWeight.extra),
      titleLarge: _n(size: 17, weight: AppWeight.bold),
      titleMedium: _n(size: 15, weight: AppWeight.bold),
      titleSmall: _n(size: 13.5, weight: AppWeight.bold),
      bodyLarge: _n(size: 15.5, weight: AppWeight.regular, height: 1.5),
      bodyMedium: _n(size: 14.5, weight: AppWeight.regular, height: 1.5),
      bodySmall: _n(size: 12.5, weight: AppWeight.regular, height: 1.5),
      labelLarge: _n(size: 17, weight: AppWeight.bold),
      labelMedium: _n(size: 13, weight: AppWeight.semibold),
      labelSmall: _n(size: 11.5, weight: AppWeight.semibold, letterSpacing: 0.8),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.cream,
      canvasColor: AppColors.canvas,
      dividerColor: AppColors.inkA(0.08),
      colorScheme: const ColorScheme.light(
        primary: AppColors.green,
        onPrimary: AppColors.cream,
        surface: AppColors.cream,
        onSurface: AppColors.ink,
        secondary: AppColors.orange,
        onSecondary: Colors.white,
        tertiary: AppColors.greenDeep,
      ),
      textTheme: text,
      primaryTextTheme: text,
      splashFactory: NoSplash.splashFactory,
      highlightColor: AppColors.inkA(0.06),
      hoverColor: AppColors.inkA(0.05),
      // Nunito só no textTheme. Sem fontFamily no ThemeData — senão
      // IconTheme herda a família de texto e Material Icons viram quadrados.
      iconTheme: const IconThemeData(
        color: AppColors.ink,
        size: 22,
        applyTextScaling: false,
      ),
      actionIconTheme: const ActionIconThemeData(),
      dividerTheme: DividerThemeData(color: AppColors.inkA(0.08), thickness: 1, space: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inkA(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.cream,
        elevation: 0,
      ),
    );
  }
}

class AppShadows {
  static final card = [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.055),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];
  static final habitat = [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.10),
      blurRadius: 22,
      offset: const Offset(0, 6),
    ),
  ];
  static final cta = [
    BoxShadow(
      color: AppColors.green.withValues(alpha: 0.32),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
  static final device = [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.16),
      blurRadius: 40,
      offset: const Offset(0, 18),
    ),
  ];
}

/// HTML esconde a scrollbar (`::-webkit-scrollbar{width:0}`).
/// O outro agente pode passar isto no `MaterialApp.scrollBehavior`.
class BaruScrollBehavior extends MaterialScrollBehavior {
  const BaruScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
