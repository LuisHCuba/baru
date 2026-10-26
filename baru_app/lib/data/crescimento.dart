/// O crescimento do bicho: de ovo (ou recém-nascido no ninho) a pleno.
///
/// **A régua são as sessões de foco concluídas com aquela espécie** — as
/// "sessões juntos". Os laudos 05–08 discutiram três réguas (trilha, XP,
/// sessões); a síntese (`docs/pesquisa/00-SINTESE.md`) ficou com esta porque
/// é a que a pessoa entende sem explicação: "ele cresceu porque eu foquei".
/// XP mistura fontes (carinho, missão, marco), e a trilha abre a raposa no
/// passo 22 — ela nasceria adulta.
///
/// Três regras de produto que este arquivo trava:
///
/// - **Nunca regride.** O contador só sobe; o estágio é função dele.
/// - **Nunca se compra.** Nada na loja mexe aqui.
/// - **Só bota ovo quem bota ovo.** Coruja, pinguim, tartaruga e axolote
///   começam no ovo; capivara, lontra, gata, raposa e buldogue começam
///   recém-nascidos, de olho fechado, no ninho. O pedido do dono ("a coruja
///   começa em um ovo") e a biologia, juntos.
library;

import '../models.dart';

/// Os cinco estágios de vida, na ordem.
///
/// O último é "pleno" — o adulto no auge —, nunca idoso: um bicho
/// visivelmente velho conversaria com a morte, e aqui ninguém morre.
enum EstagioDoBicho { inicio, filhote, jovem, adulto, pleno }

class Crescimento {
  const Crescimento._();

  /// Quantas sessões juntos abrem cada estágio.
  ///
  /// A primeira sessão concluída choca o ovo: o primeiro foco da vida da
  /// pessoa termina com o bicho nascendo, que é o "aha" do começo. Os
  /// demais limiares dão um crescimento por semana de uso no começo e
  /// espaçam depois. Calibrar com dados reais quando houver.
  static const limiares = <int>[0, 1, 5, 15, 40];

  static EstagioDoBicho estagioPara(int sessoesJuntos) {
    var e = EstagioDoBicho.inicio;
    for (var i = 0; i < limiares.length; i++) {
      if (sessoesJuntos >= limiares[i]) e = EstagioDoBicho.values[i];
    }
    return e;
  }

  /// Quantas sessões faltam para o próximo estágio. `null` no pleno.
  static int? faltamPara(int sessoesJuntos) {
    final atual = estagioPara(sessoesJuntos);
    if (atual == EstagioDoBicho.pleno) return null;
    return limiares[atual.index + 1] - sessoesJuntos;
  }

  /// 0 a 1, quanto já andou dentro do estágio atual. 1 no pleno.
  static double progressoNoEstagio(int sessoesJuntos) {
    final atual = estagioPara(sessoesJuntos);
    if (atual == EstagioDoBicho.pleno) return 1;
    final de = limiares[atual.index];
    final ate = limiares[atual.index + 1];
    return ((sessoesJuntos - de) / (ate - de)).clamp(0.0, 1.0);
  }

  /// Bota ovo (e por isso começa num).
  static bool botaOvo(Species s) => switch (s) {
        Species.owl ||
        Species.penguin ||
        Species.tortoise ||
        Species.axolotl =>
          true,
        Species.capybara ||
        Species.otter ||
        Species.cat ||
        Species.fox ||
        Species.frenchie =>
          false,
      };

  /// A migração das contas que existiam antes do crescimento.
  ///
  /// Cada espécie já liberada recebe o total de sessões concluídas da conta.
  /// O app está em teste fechado, sem público: ninguém perde um adulto que
  /// tinha (o bicho de antes era desenhado adulto), e quem já usa vê o
  /// estágio real do bicho. Espécie liberada depois disso começa do zero —
  /// ela nunca foi vista crescida. Ver ADR-024.
  static Map<String, int> semeia({
    required Map<String, int> atual,
    required int sessoesDaConta,
    required Iterable<Species> liberadas,
  }) {
    if (atual.isNotEmpty || sessoesDaConta <= 0) return atual;
    return {for (final s in liberadas) s.name: sessoesDaConta};
  }

  /// Funde dois mapas de contador que só sobe: o maior de cada chave.
  static Map<String, int> fundeMaior(Map<String, int> a, Map<String, int> b) {
    final out = Map<String, int>.of(a);
    b.forEach((k, v) {
      final atual = out[k];
      if (atual == null || v > atual) out[k] = v;
    });
    return out;
  }
}
