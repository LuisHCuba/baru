import 'package:flutter/painting.dart';

/// As cores que a loja precisou e a paleta ainda não tinha.
///
/// O lugar certo destas cores é `lib/design/tokens.dart` — a regra do projeto
/// é que nenhum valor de cor se escreva fora de lá. Elas estão aqui por um
/// motivo de coordenação, não de estilo: a loja cresceu numa frente paralela
/// e `tokens.dart` é arquivo de outra. Colocá-las em `models.dart` cru, como
/// já acontece com as roupas, espalharia hexadecimal pelo catálogo; um
/// arquivo só, com nome, deixa a mudança de paleta a um `Ctrl+H` de
/// distância e a mudança para `tokens.dart` a um recorta-e-cola.
///
/// Toda cor daqui é escolhida para conviver com a luz do habitat: nada de
/// saturação alta, que numa cena de aquarela vira adesivo.
class CoresDaLoja {
  const CoresDaLoja._();

  // --- cogumelo ----------------------------------------------------------
  /// Chapéu: vermelho apagado, na família do acento, não vermelho de alerta.
  static const cogumelo = Color(0xFFC65F4A);
  static const cogumeloTalo = Color(0xFFF0E2CB);

  // --- peixe -------------------------------------------------------------
  /// O cardume é visto **através da água**: azul dessaturado, senão parece
  /// boiando por cima dela.
  static const peixe = Color(0xFF6F86A8);
  static const peixeClaro = Color(0xFF93A9C6);

  // --- madeira -----------------------------------------------------------
  /// O topo do tronco caído, um passo mais claro que `Cores.madeira`: é a
  /// única coisa que faz um retângulo deitado parecer cilíndrico.
  static const madeiraClara = Color(0xFFB98D62);

  // --- fogo e luz --------------------------------------------------------
  static const brasa = Color(0xFFFFC46B);
  static const vagalume = Color(0xFFF2D98A);
  static const vagalumeForte = Color(0xFFFFEEB4);

  /// O fio do varal. Translúcido de propósito: fio opaco no céu vira risco.
  static const fioDeVaral = Color(0x553E2F23);
  static const lampada = Color(0xFFFFD79A);

  // --- estações ----------------------------------------------------------
  static const cereja = Color(0xFFE8A6BD);
  static const cerejaClara = Color(0xFFF6CEDC);
  static const outono = Color(0xFFD98A4A);

  /// Neve e nuvem não são branco puro: branco puro sobre creme parece furo
  /// na tela.
  static const neve = Color(0xFFFDFBF6);
  static const nuvem = Color(0xFFF6F0E4);
  static const nuvemClara = Color(0xFFFFFCF4);
}
