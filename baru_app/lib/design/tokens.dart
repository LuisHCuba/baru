/// Tokens do Baru. **Nenhum valor de cor, espaço, raio, sombra ou tipografia
/// deve ser escrito fora daqui.**
///
/// A regra existe porque a alternativa já foi tentada: dezenas de
/// `EdgeInsets.fromLTRB(26, 20, 26, 34)` e `Radius.circular(18)` espalhados
/// pelas telas, cada um com um número diferente pelo mesmo motivo. Densidade
/// inconsistente é o que faz uma tela parecer amadora mesmo com bons
/// componentes.
library;

import 'package:flutter/widgets.dart';

class Cores {
  const Cores._();

  // --- superfícies -------------------------------------------------------
  /// Fundo da moldura, atrás de tudo.
  static const canvas = Color(0xFFEDE3D2);

  /// Fundo das telas.
  static const superficie = Color(0xFFFAF1E3);

  /// Cartão sobre a superfície.
  static const superficieElevada = Color(0xFFFFFBF2);

  /// Fundo da cena do habitat.
  static const habitat = Color(0xFFF4E6CB);

  /// Fundo da sessão de foco — mais quente, para a tela toda mudar de clima.
  static const foco = Color(0xFFF5E9D3);

  static const folha = Color(0xFFF2EFEA);

  // --- tintas ------------------------------------------------------------
  static const tinta = Color(0xFF3E2F23);
  static const tintaClara = Color(0xFFFAF1E3);

  // --- primária ----------------------------------------------------------
  static const primaria = Color(0xFF5C8A4E);
  static const primariaPressionada = Color(0xFF486D3D);
  static const primariaHover = Color(0xFF4E7842);
  static const primariaClara = Color(0xFF6E9C5E);
  static const primariaEscura = Color(0xFF3E6B32);

  // --- acento ------------------------------------------------------------
  static const acento = Color(0xFFEF8354);
  static const acentoTexto = Color(0xFFB8502A);
  static const acentoForte = Color(0xFFC25A26);

  // --- cenário -----------------------------------------------------------
  static const areia = Color(0xFFC98A5B);
  static const madeira = Color(0xFFA0764C);
  static const madeiraEscura = Color(0xFF8A6440);
  static const barco = Color(0xFFB3764A);
  static const pedra = Color(0xFFA79A8C);
  static const pedraClara = Color(0xFFB6AA9D);
  static const pedraEscura = Color(0xFF948877);

  /// Pelagens do companheiro.
  static const pelagem = [
    Color(0xFFC98A5B),
    Color(0xFFA9733F),
    Color(0xFFDBA478),
    Color(0xFF8A6247),
  ];

  // --- categorias de tempo de tela ---------------------------------------
  // Cores próprias: o usuário precisa reconhecer a categoria pela cor em
  // qualquer tela, sem ler o rótulo.
  static const dispersivo = Color(0xFFE0714B);
  static const neutro = Color(0xFF7C93B8);
  static const produtivo = Color(0xFF5C8A4E);
  static const passivo = Color(0xFFB39BC8);

  static Color tintaA(double a) => tinta.withValues(alpha: a);
  static Color primariaA(double a) => primaria.withValues(alpha: a);
  static Color acentoA(double a) => acento.withValues(alpha: a);
  static Color areiaA(double a) => areia.withValues(alpha: a);
}

/// Escala de espaçamento em passos fixos, base 4.
///
/// Só use estes valores em padding, margin e gap. Um `SizedBox(height: 13)`
/// é sempre um erro de alguém que não olhou a escala.
class Espaco {
  const Espaco._();

  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 26.0;
  static const xxl = 34.0;
  static const xxxl = 48.0;

  /// Margem lateral padrão de tela.
  static const margemTela = lg;

  /// Margem lateral de telas de conteúdo denso (onboarding, paywall).
  static const margemLarga = xl;
}

/// Escala de raio. Superfície de destaque nunca tem canto vivo.
class Raio {
  const Raio._();

  static const chip = 14.0;
  static const campo = 18.0;
  static const botao = 20.0;
  static const cartao = 22.0;
  static const cartaoGrande = 26.0;
  static const cena = 28.0;
  static const folha = 30.0;
  static const aparelho = 44.0;
  static const pilula = 999.0;

  static BorderRadius todos(double r) => BorderRadius.circular(r);
  static BorderRadius topo(double r) => BorderRadius.vertical(top: Radius.circular(r));
}

/// Escala de elevação. Sombra suave e difusa, nunca dura.
class Elevacao {
  const Elevacao._();

  /// Cartão em repouso.
  static List<BoxShadow> get cartao => [
        BoxShadow(
          color: Cores.tintaA(0.055),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];

  /// Cartão sob o dedo ou em foco.
  static List<BoxShadow> get cartaoElevado => [
        BoxShadow(
          color: Cores.tintaA(0.10),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  /// A cena do habitat.
  static List<BoxShadow> get cena => [
        BoxShadow(
          color: Cores.tintaA(0.10),
          blurRadius: 22,
          offset: const Offset(0, 6),
        ),
      ];

  /// Ação primária — a sombra é colorida para o botão parecer aceso.
  static List<BoxShadow> get acaoPrimaria => [
        BoxShadow(
          color: Cores.primaria.withValues(alpha: 0.32),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  /// Folha modal subindo sobre a tela.
  static List<BoxShadow> get folha => [
        BoxShadow(
          color: Cores.tintaA(0.18),
          blurRadius: 30,
          offset: const Offset(0, -6),
        ),
      ];

  /// Moldura de aparelho no desktop.
  static List<BoxShadow> get aparelho => [
        BoxShadow(
          color: Cores.tintaA(0.16),
          blurRadius: 40,
          offset: const Offset(0, 18),
        ),
      ];
}

/// Escala tipográfica: tamanho, peso e altura de linha andam juntos.
///
/// Números que mudam ao vivo usam [tabular] para o contador não tremer.
class Tipo {
  const Tipo._();

  static const displayGrande = EstiloTipo(30, FontWeight.w800, 1.15, -0.6);
  static const display = EstiloTipo(27, FontWeight.w800, 1.2, -0.5);
  static const tituloGrande = EstiloTipo(23, FontWeight.w800, 1.25, -0.3);
  static const titulo = EstiloTipo(18, FontWeight.w800, 1.3, 0);
  static const subtitulo = EstiloTipo(16, FontWeight.w700, 1.3, 0);
  static const corpoGrande = EstiloTipo(15.5, FontWeight.w400, 1.5, 0);
  static const corpo = EstiloTipo(14.5, FontWeight.w400, 1.5, 0);
  static const corpoForte = EstiloTipo(14.5, FontWeight.w700, 1.4, 0);
  static const corpoPequeno = EstiloTipo(12.5, FontWeight.w400, 1.5, 0);
  static const rotulo = EstiloTipo(13, FontWeight.w600, 1.3, 0);
  static const rotuloPequeno = EstiloTipo(11.5, FontWeight.w600, 1.3, 0.8);

  /// Número grande de destaque — o contador da sessão, o total do dia.
  static const numeroHeroi = EstiloTipo(66, FontWeight.w800, 1, -2);
  static const numeroGrande = EstiloTipo(38, FontWeight.w800, 1.1, -1);
  static const numero = EstiloTipo(24, FontWeight.w800, 1.15, 0);
}

class EstiloTipo {
  const EstiloTipo(this.size, this.weight, this.height, this.letterSpacing);
  final double size;
  final FontWeight weight;
  final double height;
  final double letterSpacing;
}

/// Alvo mínimo de toque. Abaixo disso o dedo erra.
class Toque {
  const Toque._();
  static const minimo = 48.0;
  static const confortavel = 56.0;
}
