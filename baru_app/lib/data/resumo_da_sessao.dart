/// O retrato de uma sessão concluída: o que havia antes e o que ela trouxe.
///
/// A tela de resultado anima **a partir disto**, e não lendo o estado de
/// agora: quando ela aparece, folhas, XP e missões já mudaram, e animar do
/// valor atual para ele mesmo é não animar nada. Era o defeito de agosto —
/// a home contava por baixo de uma tela que ninguém via (laudo 01, §6).
library;

import 'package:flutter/foundation.dart';

import 'missoes.dart';

/// Uma missão que esta sessão fez andar.
@immutable
class MissaoTocada {
  const MissaoTocada({required this.antes, required this.depois});

  final Missao antes;
  final Missao depois;

  /// Fechou agora (estava aberta e ficou pronta para colher).
  bool get fechou => !antes.concluida && depois.concluida;
}

@immutable
class ResumoDaSessao {
  const ResumoDaSessao({
    required this.minutos,
    required this.folhasAntes,
    required this.folhasDaSessao,
    required this.xpAntes,
    required this.xpDaSessao,
    required this.xpDaRaiz,
    this.missoes = const [],
  });

  final int minutos;
  final int folhasAntes;
  final int folhasDaSessao;
  final int xpAntes;
  final int xpDaSessao;

  /// O bônus da raiz: só na primeira sessão do dia.
  final int xpDaRaiz;

  /// As missões que andaram, na ordem do quadro.
  final List<MissaoTocada> missoes;

  /// Compara o quadro de antes com o de depois e fica com quem andou.
  ///
  /// Missão já colhida fica de fora: andar o contador de quem já foi paga
  /// não é novidade para ninguém.
  static List<MissaoTocada> tocadas(List<Missao> antes, List<Missao> depois) {
    final porId = {for (final m in antes) m.id: m};
    return [
      for (final d in depois)
        if (porId[d.id] case final a?)
          if (!d.resgatada && d.progresso != a.progresso)
            MissaoTocada(antes: a, depois: d),
    ];
  }
}
