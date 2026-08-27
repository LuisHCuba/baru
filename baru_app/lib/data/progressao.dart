/// Progressão do Baru: XP, nível e trilha de marcos.
///
/// **Todos os números de balanceamento do jogo vivem neste arquivo.** Espalhar
/// constantes de economia pelo código é como o app chegou a ter "+15" escrito
/// em duas telas sem nada creditando: ninguém consegue ver o sistema inteiro
/// de uma vez para saber se ele fecha.
library;

import '../models.dart' show Species;

/// A tabela de balanceamento. Mexa aqui, não nas telas.
class Balanco {
  const Balanco._();

  // --- XP por ação -------------------------------------------------------

  /// XP de uma sessão concluída, por duração.
  ///
  /// Cresce mais que linearmente: 90 min valem mais que três de 25, porque
  /// foco longo é mais difícil e é o comportamento que o produto quer.
  static int xpDeSessao(int minutos) {
    if (minutos >= 90) return 60;
    if (minutos >= 50) return 30;
    if (minutos >= 25) return 12;
    return (minutos * 0.4).floor();
  }

  /// Fechar o dia abaixo da meta.
  static const xpDiaAbaixoDaMeta = 20;

  /// Missões.
  static const xpMissaoDiaria = 10;
  static const xpMissaoSemanal = 40;

  /// Cada dia de sequência mantida.
  static const xpPorDiaDeSequencia = 5;

  // --- Curva de nível ----------------------------------------------------

  /// XP para sair do nível [nivel] e chegar no seguinte.
  ///
  /// Os primeiros níveis são rápidos de propósito: o usuário precisa sentir
  /// progresso no primeiro dia, ou não volta no segundo. Depois a curva abre.
  static int xpParaSubirDe(int nivel) {
    if (nivel < 1) return 0;
    return 40 + (nivel - 1) * 35;
  }

  /// XP acumulado necessário para **atingir** [nivel].
  static int xpAcumuladoPara(int nivel) {
    var total = 0;
    for (var n = 1; n < nivel; n++) {
      total += xpParaSubirDe(n);
    }
    return total;
  }

  /// Nível para um XP acumulado. Nunca cai: o XP só sobe.
  static int nivelPara(int xp) {
    var nivel = 1;
    var restante = xp;
    while (restante >= xpParaSubirDe(nivel) && nivel < nivelMaximo) {
      restante -= xpParaSubirDe(nivel);
      nivel += 1;
    }
    return nivel;
  }

  /// Teto para a curva não crescer sem fim. Ao chegar aqui a barra fica cheia.
  static const nivelMaximo = 40;

  /// Progresso dentro do nível atual, de 0 a 1.
  static double progressoNoNivel(int xp) {
    final nivel = nivelPara(xp);
    if (nivel >= nivelMaximo) return 1;
    final base = xpAcumuladoPara(nivel);
    final precisa = xpParaSubirDe(nivel);
    if (precisa <= 0) return 1;
    return ((xp - base) / precisa).clamp(0.0, 1.0);
  }

  /// Quanto falta de XP para o próximo nível.
  static int faltaParaProximoNivel(int xp) {
    final nivel = nivelPara(xp);
    if (nivel >= nivelMaximo) return 0;
    return xpAcumuladoPara(nivel + 1) - xp;
  }
}

/// O que um marco exige.
enum TipoDeMarco {
  /// Chegar a um nível.
  nivel,

  /// Somar N sessões de foco concluídas.
  sessoes,

  /// Manter N dias de presença seguidos.
  sequencia,

  /// Fechar N dias abaixo da meta.
  diasAbaixoDaMeta,
}

/// O que um marco entrega.
class RecompensaDeMarco {
  const RecompensaDeMarco({
    this.folhas = 0,
    this.especie,
    this.estagioDeHabitat,
  });

  /// Folhas creditadas ao alcançar.
  final int folhas;

  /// Espécie que passa a poder ser escolhida nos ajustes.
  ///
  /// Espécie se desbloqueia por marco, nunca por dinheiro (§4).
  final Species? especie;

  /// Estágio de habitat que a cena passa a mostrar.
  final int? estagioDeHabitat;

  bool get vazia => folhas == 0 && especie == null && estagioDeHabitat == null;
}

/// Um degrau da trilha.
class Marco {
  const Marco({
    required this.id,
    required this.tipo,
    required this.alvo,
    required this.recompensa,
  });

  final String id;
  final TipoDeMarco tipo;

  /// Valor a atingir: nível 5, 10 sessões, 7 dias seguidos...
  final int alvo;

  final RecompensaDeMarco recompensa;
}

/// A trilha: a sequência ordenada e visível que responde "por que eu volto
/// amanhã".
///
/// Ordem importa. O usuário precisa sempre saber qual é o próximo passo e o
/// que ganha nele.
const trilha = <Marco>[
  Marco(
    id: 'primeiro_foco',
    tipo: TipoDeMarco.sessoes,
    alvo: 1,
    recompensa: RecompensaDeMarco(folhas: 20),
  ),
  Marco(
    id: 'primeiro_dia_abaixo',
    tipo: TipoDeMarco.diasAbaixoDaMeta,
    alvo: 1,
    recompensa: RecompensaDeMarco(folhas: 25),
  ),
  Marco(
    id: 'nivel_3',
    tipo: TipoDeMarco.nivel,
    alvo: 3,
    recompensa: RecompensaDeMarco(folhas: 40, estagioDeHabitat: 2),
  ),
  Marco(
    id: 'tres_dias',
    tipo: TipoDeMarco.sequencia,
    alvo: 3,
    recompensa: RecompensaDeMarco(folhas: 50),
  ),
  Marco(
    id: 'cinco_focos',
    tipo: TipoDeMarco.sessoes,
    alvo: 5,
    recompensa: RecompensaDeMarco(folhas: 60, especie: Species.otter),
  ),
  Marco(
    id: 'semana_inteira',
    tipo: TipoDeMarco.sequencia,
    alvo: 7,
    recompensa: RecompensaDeMarco(folhas: 90, estagioDeHabitat: 3),
  ),
  Marco(
    id: 'nivel_6',
    tipo: TipoDeMarco.nivel,
    alvo: 6,
    recompensa: RecompensaDeMarco(folhas: 100),
  ),
  Marco(
    id: 'cinco_dias_abaixo',
    tipo: TipoDeMarco.diasAbaixoDaMeta,
    alvo: 5,
    recompensa: RecompensaDeMarco(folhas: 110, especie: Species.tortoise),
  ),
  Marco(
    id: 'vinte_focos',
    tipo: TipoDeMarco.sessoes,
    alvo: 20,
    recompensa: RecompensaDeMarco(folhas: 150, estagioDeHabitat: 4),
  ),
  Marco(
    id: 'nivel_10',
    tipo: TipoDeMarco.nivel,
    alvo: 10,
    recompensa: RecompensaDeMarco(folhas: 180, especie: Species.owl),
  ),
  Marco(
    id: 'trinta_dias',
    tipo: TipoDeMarco.sequencia,
    alvo: 30,
    recompensa: RecompensaDeMarco(folhas: 300, estagioDeHabitat: 5),
  ),
  Marco(
    id: 'cem_focos',
    tipo: TipoDeMarco.sessoes,
    alvo: 100,
    recompensa: RecompensaDeMarco(folhas: 500),
  ),
];

/// Os contadores que a trilha lê.
class ProgressoDaTrilha {
  const ProgressoDaTrilha({
    required this.xp,
    required this.sessoesConcluidas,
    required this.melhorSequencia,
    required this.diasAbaixoDaMeta,
  });

  final int xp;
  final int sessoesConcluidas;

  /// A **melhor** sequência já feita, não a atual: um marco conquistado nunca
  /// é retirado (§ "o usuário nunca perde nada").
  final int melhorSequencia;

  final int diasAbaixoDaMeta;

  int get nivel => Balanco.nivelPara(xp);

  int valorDe(TipoDeMarco tipo) {
    switch (tipo) {
      case TipoDeMarco.nivel:
        return nivel;
      case TipoDeMarco.sessoes:
        return sessoesConcluidas;
      case TipoDeMarco.sequencia:
        return melhorSequencia;
      case TipoDeMarco.diasAbaixoDaMeta:
        return diasAbaixoDaMeta;
    }
  }

  bool alcancou(Marco m) => valorDe(m.tipo) >= m.alvo;

  /// Progresso de 0 a 1 dentro de um marco.
  double fracaoDe(Marco m) {
    if (m.alvo <= 0) return 1;
    return (valorDe(m.tipo) / m.alvo).clamp(0.0, 1.0);
  }

  /// O próximo marco não alcançado — o que a home destaca.
  Marco? get proximoMarco {
    for (final m in trilha) {
      if (!alcancou(m)) return m;
    }
    return null;
  }

  List<Marco> get alcancados => trilha.where(alcancou).toList();

  /// Espécies liberadas por marco, mais a que veio do quiz.
  Set<Species> especiesLiberadas(Species doQuiz) {
    final out = <Species>{doQuiz};
    for (final m in alcancados) {
      final e = m.recompensa.especie;
      if (e != null) out.add(e);
    }
    return out;
  }

  /// Estágio da cena: sobe com os marcos e nunca desce.
  int get estagioDoHabitat {
    var estagio = 1;
    for (final m in alcancados) {
      final e = m.recompensa.estagioDeHabitat;
      if (e != null && e > estagio) estagio = e;
    }
    return estagio;
  }
}
