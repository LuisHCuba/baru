/// Ponte entre os tokens e o `ThemeData` do Material.
///
/// Os nomes antigos (`AppColors`, `AppRadii`, `AppShadows`) continuam
/// existindo como fachada sobre [Cores], [Raio] e [Elevacao] para que as telas
/// já escritas não precisassem ser reescritas de uma vez — mas **código novo
/// usa os tokens diretamente**.
library;

import 'package:flutter/material.dart';

import 'design/tokens.dart';

export 'design/motion.dart';
export 'design/tokens.dart';

/// Nunito empacotada. `fontFamily` aponta para a família declarada no
/// pubspec; nada é baixado em runtime.
const String kFonte = 'Nunito';

TextStyle nunito({
  required double size,
  FontWeight weight = FontWeight.w400,
  Color? color,
  double? height,
  double? letterSpacing,
  bool tabular = false,
}) {
  return TextStyle(
    fontFamily: kFonte,
    fontSize: size,
    fontWeight: weight,
    color: color ?? Cores.tinta,
    height: height,
    letterSpacing: letterSpacing,
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
  );
}

/// Estilo a partir da escala tipográfica. Preferir isto a [nunito] em código
/// novo: o tamanho, o peso e a altura de linha vêm juntos do token.
TextStyle estilo(
  EstiloTipo token, {
  Color? color,
  bool tabular = false,
  FontWeight? weight,
}) {
  return TextStyle(
    fontFamily: kFonte,
    fontSize: token.size,
    fontWeight: weight ?? token.weight,
    height: token.height,
    letterSpacing: token.letterSpacing == 0 ? null : token.letterSpacing,
    color: color ?? Cores.tinta,
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
  );
}

/// Fachada histórica sobre [Cores].
class AppColors {
  static const cream = Cores.superficie;
  static const canvas = Cores.canvas;
  static const ink = Cores.tinta;
  static const green = Cores.primaria;
  static const greenHover = Cores.primariaHover;
  static const greenDeep = Cores.primariaEscura;
  static const greenSoft = Cores.primariaClara;
  static const orange = Cores.acento;
  static const orangeText = Cores.acentoTexto;
  static const orangeDeep = Cores.acentoForte;
  static const card = Cores.superficieElevada;
  static const habitat = Cores.habitat;
  static const sessionBg = Cores.foco;
  static const shareSheet = Cores.folha;
  static const shareThumb = Color(0xFFF1E0C2);
  static const sand = Cores.areia;
  static const wood = Cores.madeira;
  static const woodDark = Cores.madeiraEscura;
  static const boat = Cores.barco;
  static const rock = Cores.pedra;
  static const rockLight = Cores.pedraClara;
  static const rockDark = Cores.pedraEscura;
  static const coat = Cores.pelagem;

  static Color inkA(double a) => Cores.tintaA(a);
  static Color greenA(double a) => Cores.primariaA(a);
  static Color orangeA(double a) => Cores.acentoA(a);
  static Color sandA(double a) => Cores.areiaA(a);
}

class AppWeight {
  static const regular = FontWeight.w400;
  static const semibold = FontWeight.w600;
  static const bold = FontWeight.w700;
  static const extra = FontWeight.w800;
}

/// Fachada histórica sobre [Raio].
class AppRadii {
  static const debug = 9.0;
  static const tab = 7.0;
  static const chip = Raio.chip;
  static const input = Raio.campo;
  static const button = Raio.botao;
  static const card = Raio.cartao;
  static const report = 24.0;
  static const share = Raio.cartaoGrande;
  static const habitat = Raio.cena;
  static const sheet = Raio.folha;
  static const device = Raio.aparelho;
  static const pill = 99.0;
}

/// Fachada histórica sobre [Elevacao].
class AppShadows {
  static List<BoxShadow> get card => Elevacao.cartao;
  static List<BoxShadow> get habitat => Elevacao.cena;
  static List<BoxShadow> get cta => Elevacao.acaoPrimaria;
  static List<BoxShadow> get device => Elevacao.aparelho;
}

class AppTheme {
  static TextStyle _n({
    required double size,
    required FontWeight weight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: kFonte,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? Cores.tinta,
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
      scaffoldBackgroundColor: Cores.superficie,
      canvasColor: Cores.canvas,
      dividerColor: Cores.tintaA(0.08),
      colorScheme: const ColorScheme.light(
        primary: Cores.primaria,
        onPrimary: Cores.tintaClara,
        surface: Cores.superficie,
        onSurface: Cores.tinta,
        secondary: Cores.acento,
        onSecondary: Colors.white,
        tertiary: Cores.primariaEscura,
      ),
      textTheme: text,
      primaryTextTheme: text,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Cores.tintaA(0.06),
      hoverColor: Cores.tintaA(0.05),
      // Nunito só no textTheme. Sem fontFamily no ThemeData — senão
      // IconTheme herda a família de texto e Material Icons viram quadrados.
      iconTheme: const IconThemeData(
        color: Cores.tinta,
        size: 22,
        applyTextScaling: false,
      ),
      actionIconTheme: const ActionIconThemeData(),
      dividerTheme: DividerThemeData(color: Cores.tintaA(0.08), thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Cores.superficie,
        shape: RoundedRectangleBorder(borderRadius: Raio.topo(Raio.cartao)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Cores.tintaA(0.06),
        border: OutlineInputBorder(
          borderRadius: Raio.todos(Raio.campo),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Espaco.lg,
          vertical: Espaco.md,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Cores.tinta,
        foregroundColor: Cores.tintaClara,
        elevation: 0,
      ),
    );
  }
}

/// O HTML esconde a scrollbar (`::-webkit-scrollbar{width:0}`).
class BaruScrollBehavior extends MaterialScrollBehavior {
  const BaruScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
