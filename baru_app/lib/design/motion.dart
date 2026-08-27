/// Sistema de movimento do Baru. **Nenhuma duração ou curva de animação deve
/// ser escrita fora daqui.**
///
/// Movimento com número mágico espalhado vira um app onde cada elemento tem
/// um tempo diferente pelo mesmo motivo — e o conjunto parece desconjuntado
/// mesmo quando cada peça isolada está boa.
library;

import 'package:flutter/widgets.dart';

class Tempo {
  const Tempo._();

  /// Resposta ao dedo: escala de botão, brilho de chip.
  static const microFeedback = Duration(milliseconds: 120);

  /// Componente mudando de estado: cartão, barra, chip selecionado.
  static const componente = Duration(milliseconds: 260);

  /// Transição entre telas.
  static const tela = Duration(milliseconds: 380);

  /// Celebração: nível, marco, missão concluída.
  static const celebracao = Duration(milliseconds: 900);

  /// Contador subindo. Longo o bastante para o olho seguir o número.
  static const contador = Duration(milliseconds: 700);

  /// Respiração do companheiro — um ciclo completo.
  static const respiracao = Duration(milliseconds: 3400);
}

/// Curvas. Entrada com mola, saída com desaceleração. Nada de linear.
class Curvas {
  const Curvas._();

  /// Entrada de elemento: passa um pouco e volta.
  static const entrada = Curves.easeOutBack;

  /// Saída: some rápido, sem chamar atenção.
  static const saida = Curves.easeInCubic;

  /// Transição padrão entre estados.
  static const padrao = Curves.easeOutCubic;

  /// Enfática — para o que o usuário conquistou.
  static const enfatica = Curves.easeOutQuint;

  /// Movimento contínuo e orgânico (respirar, boiar).
  static const organica = Curves.easeInOut;
}

/// Molas para feedback físico.
class Molas {
  const Molas._();

  /// Toque: responde e volta rápido, sem oscilar demais.
  static const toque = SpringDescription(mass: 1, stiffness: 500, damping: 26);

  /// Entrada de elemento na tela: um pouco mais solta.
  static const entrada = SpringDescription(mass: 1, stiffness: 320, damping: 22);

  /// Celebração: oscila de propósito.
  static const festa = SpringDescription(mass: 1, stiffness: 220, damping: 12);
}

/// Distâncias de deslocamento em transições.
class Desloca {
  const Desloca._();

  /// Irmãos deslizam lateralmente.
  static const irmao = 0.06;

  /// Filho entra em profundidade.
  static const profundidade = 0.04;
}

/// Respeita "reduzir movimento" do sistema.
///
/// A regra do §7 é reduzir amplitude, **nunca remover o feedback**: quem pediu
/// menos movimento ainda precisa saber que o toque foi registrado.
class Movimento {
  const Movimento._();

  static bool reduzido(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Amplitude efetiva de um deslocamento ou escala.
  static double amplitude(BuildContext context, double cheia) =>
      reduzido(context) ? cheia * 0.25 : cheia;

  /// Duração efetiva. Encurta, não zera.
  static Duration duracao(BuildContext context, Duration cheia) =>
      reduzido(context)
          ? Duration(milliseconds: (cheia.inMilliseconds * 0.4).round())
          : cheia;
}
