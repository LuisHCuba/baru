/// Missões diárias e semanais.
///
/// O que existia antes eram duas linhas de texto com "+10" e "+15" ao lado e
/// um visto binário. Não havia progresso numérico, prazo, estado de resgate,
/// nem código creditando as recompensas. Missão que anuncia prêmio e não paga
/// é dívida de confiança.
library;

import 'progressao.dart';

/// O que a missão mede.
enum TipoDeMissao {
  /// Concluir N sessões de foco hoje.
  sessoesHoje,

  /// Somar N minutos de foco hoje.
  minutosHoje,

  /// Concluir uma sessão de pelo menos N minutos.
  sessaoLonga,

  /// Fechar o dia abaixo da meta de tempo de tela.
  abaixoDaMeta,

  /// Manter o tempo dispersivo do dia abaixo de N minutos.
  dispersivoAbaixoDe,

  /// Concluir N sessões na semana.
  sessoesNaSemana,

  /// Somar N minutos de foco na semana.
  minutosNaSemana,

  /// Fechar N dias abaixo da meta na semana.
  diasAbaixoNaSemana,
}

/// Quanto tempo a missão dura.
enum RitmoDaMissao {
  /// Expira à meia-noite local. Dá ritmo ao dia.
  diaria,

  /// Expira no fim da semana. Dá amplitude.
  semanal,
}

/// A definição de uma missão — o molde, sem progresso.
class DefinicaoDeMissao {
  const DefinicaoDeMissao({
    required this.id,
    required this.tipo,
    required this.ritmo,
    required this.alvo,
    required this.folhas,
    required this.xp,
    this.precisaDeUso = false,
  });

  final String id;
  final TipoDeMissao tipo;
  final RitmoDaMissao ritmo;
  final int alvo;
  final int folhas;
  final int xp;

  /// Depende da permissão de tempo de tela.
  ///
  /// Missão impossível nunca é mostrada como missão: vira convite para
  /// conceder a permissão (§5).
  final bool precisaDeUso;
}

/// O sorteio das diárias sai daqui. Três por dia, do mesmo pool.
const poolDiario = <DefinicaoDeMissao>[
  DefinicaoDeMissao(
    id: 'um_foco',
    tipo: TipoDeMissao.sessoesHoje,
    ritmo: RitmoDaMissao.diaria,
    alvo: 1,
    folhas: 10,
    xp: Balanco.xpMissaoDiaria,
  ),
  DefinicaoDeMissao(
    id: 'dois_focos',
    tipo: TipoDeMissao.sessoesHoje,
    ritmo: RitmoDaMissao.diaria,
    alvo: 2,
    folhas: 18,
    xp: Balanco.xpMissaoDiaria,
  ),
  DefinicaoDeMissao(
    id: 'meia_hora',
    tipo: TipoDeMissao.minutosHoje,
    ritmo: RitmoDaMissao.diaria,
    alvo: 30,
    folhas: 12,
    xp: Balanco.xpMissaoDiaria,
  ),
  DefinicaoDeMissao(
    id: 'uma_hora',
    tipo: TipoDeMissao.minutosHoje,
    ritmo: RitmoDaMissao.diaria,
    alvo: 60,
    folhas: 22,
    xp: Balanco.xpMissaoDiaria,
  ),
  DefinicaoDeMissao(
    id: 'foco_longo',
    tipo: TipoDeMissao.sessaoLonga,
    ritmo: RitmoDaMissao.diaria,
    alvo: 50,
    folhas: 20,
    xp: Balanco.xpMissaoDiaria,
  ),
  DefinicaoDeMissao(
    id: 'abaixo_hoje',
    tipo: TipoDeMissao.abaixoDaMeta,
    ritmo: RitmoDaMissao.diaria,
    alvo: 1,
    folhas: 15,
    xp: Balanco.xpMissaoDiaria,
    precisaDeUso: true,
  ),
  DefinicaoDeMissao(
    id: 'pouco_dispersivo',
    tipo: TipoDeMissao.dispersivoAbaixoDe,
    ritmo: RitmoDaMissao.diaria,
    alvo: 60,
    folhas: 18,
    xp: Balanco.xpMissaoDiaria,
    precisaDeUso: true,
  ),
];

/// As semanais. Duas por semana, também sorteadas.
const poolSemanal = <DefinicaoDeMissao>[
  DefinicaoDeMissao(
    id: 'semana_cinco_focos',
    tipo: TipoDeMissao.sessoesNaSemana,
    ritmo: RitmoDaMissao.semanal,
    alvo: 5,
    folhas: 60,
    xp: Balanco.xpMissaoSemanal,
  ),
  DefinicaoDeMissao(
    id: 'semana_dez_focos',
    tipo: TipoDeMissao.sessoesNaSemana,
    ritmo: RitmoDaMissao.semanal,
    alvo: 10,
    folhas: 110,
    xp: Balanco.xpMissaoSemanal,
  ),
  DefinicaoDeMissao(
    id: 'semana_300_min',
    tipo: TipoDeMissao.minutosNaSemana,
    ritmo: RitmoDaMissao.semanal,
    alvo: 300,
    folhas: 80,
    xp: Balanco.xpMissaoSemanal,
  ),
  DefinicaoDeMissao(
    id: 'semana_tres_abaixo',
    tipo: TipoDeMissao.diasAbaixoNaSemana,
    ritmo: RitmoDaMissao.semanal,
    alvo: 3,
    folhas: 70,
    xp: Balanco.xpMissaoSemanal,
    precisaDeUso: true,
  ),
];

/// Os contadores que as missões leem.
class ContadoresDeMissao {
  const ContadoresDeMissao({
    this.sessoesHoje = 0,
    this.minutosHoje = 0,
    this.maiorSessaoHoje = 0,
    this.fechouAbaixoHoje = false,
    this.dispersivoHoje,
    this.sessoesNaSemana = 0,
    this.minutosNaSemana = 0,
    this.diasAbaixoNaSemana = 0,
    this.temPermissaoDeUso = false,
  });

  final int sessoesHoje;
  final int minutosHoje;
  final int maiorSessaoHoje;
  final bool fechouAbaixoHoje;

  /// `null` quando não há medição — a missão fica indisponível em vez de
  /// aparecer com progresso inventado.
  final int? dispersivoHoje;

  final int sessoesNaSemana;
  final int minutosNaSemana;
  final int diasAbaixoNaSemana;
  final bool temPermissaoDeUso;
}

/// Estado de uma missão para a tela.
enum EstadoDaMissao {
  /// Depende de permissão que o usuário não deu.
  precisaPermissao,

  /// Em andamento.
  emProgresso,

  /// Alvo batido, prêmio ainda não recolhido.
  concluida,

  /// Prêmio já creditado.
  resgatada,
}

/// Uma missão com progresso — o que a tela desenha.
class Missao {
  const Missao({
    required this.definicao,
    required this.progresso,
    required this.resgatada,
    required this.disponivel,
  });

  final DefinicaoDeMissao definicao;

  /// Quanto já foi feito, na mesma unidade do alvo.
  final int progresso;

  final bool resgatada;

  /// Falso quando falta a permissão de uso.
  final bool disponivel;

  String get id => definicao.id;
  int get alvo => definicao.alvo;
  int get folhas => definicao.folhas;
  int get xp => definicao.xp;
  RitmoDaMissao get ritmo => definicao.ritmo;

  bool get concluida => progresso >= alvo;

  double get fracao => alvo <= 0 ? 1 : (progresso / alvo).clamp(0.0, 1.0);

  EstadoDaMissao get estado {
    if (!disponivel) return EstadoDaMissao.precisaPermissao;
    if (resgatada) return EstadoDaMissao.resgatada;
    if (concluida) return EstadoDaMissao.concluida;
    return EstadoDaMissao.emProgresso;
  }

  /// Pode virar folhas agora?
  bool get resgatavel => disponivel && concluida && !resgatada;
}

/// Sorteia e avalia as missões.
class QuadroDeMissoes {
  const QuadroDeMissoes();

  static const quantasDiarias = 3;
  static const quantasSemanais = 2;

  /// Chave de resgate: inclui o período, então a mesma missão em dias
  /// diferentes é outra missão, e resgatar ontem não resgata hoje.
  static String chaveDeResgate(DefinicaoDeMissao d, DateTime dia) {
    final periodo = d.ritmo == RitmoDaMissao.diaria
        ? _diaEm(dia)
        : _semanaEm(dia);
    return '${d.id}@$periodo';
  }

  static String _diaEm(DateTime d) =>
      '${d.year}-${_dois(d.month)}-${_dois(d.day)}';

  /// Semana ISO ancorada na segunda-feira, igual à faixa da home.
  static String _semanaEm(DateTime d) {
    final segunda = DateTime(d.year, d.month, d.day)
        .subtract(Duration(days: d.weekday - 1));
    return 'w${segunda.year}-${_dois(segunda.month)}-${_dois(segunda.day)}';
  }

  static String _dois(int n) => n.toString().padLeft(2, '0');

  /// Sorteio **determinístico**: o mesmo dia e a mesma conta dão sempre as
  /// mesmas missões, em qualquer aparelho, sem precisar sincronizar a escolha.
  List<DefinicaoDeMissao> _sorteia(
    List<DefinicaoDeMissao> pool,
    int quantas,
    String semente,
  ) {
    final indices = List<int>.generate(pool.length, (i) => i);
    // Embaralhamento de Fisher-Yates com um gerador simples e estável.
    var h = _hash(semente);
    for (var i = indices.length - 1; i > 0; i--) {
      h = (h * 1103515245 + 12345) & 0x7fffffff;
      final j = h % (i + 1);
      final tmp = indices[i];
      indices[i] = indices[j];
      indices[j] = tmp;
    }
    return indices.take(quantas).map((i) => pool[i]).toList();
  }

  static int _hash(String s) {
    var h = 2166136261;
    for (final c in s.codeUnits) {
      h = ((h ^ c) * 16777619) & 0x7fffffff;
    }
    return h;
  }

  /// As missões de hoje.
  List<Missao> doDia({
    required DateTime dia,
    required String conta,
    required ContadoresDeMissao contadores,
    required Set<String> resgatadas,
  }) {
    final diarias = _sorteia(
      poolDiario,
      quantasDiarias,
      '$conta|${_diaEm(dia)}',
    );
    final semanais = _sorteia(
      poolSemanal,
      quantasSemanais,
      '$conta|${_semanaEm(dia)}',
    );
    return [
      for (final d in [...diarias, ...semanais])
        Missao(
          definicao: d,
          progresso: progressoDe(d, contadores),
          resgatada: resgatadas.contains(chaveDeResgate(d, dia)),
          disponivel: !d.precisaDeUso || contadores.temPermissaoDeUso,
        ),
    ];
  }

  int progressoDe(DefinicaoDeMissao d, ContadoresDeMissao c) {
    switch (d.tipo) {
      case TipoDeMissao.sessoesHoje:
        return c.sessoesHoje;
      case TipoDeMissao.minutosHoje:
        return c.minutosHoje;
      case TipoDeMissao.sessaoLonga:
        // Progresso é o maior foco do dia, para a barra andar em vez de
        // ficar em zero até o fim.
        return c.maiorSessaoHoje.clamp(0, d.alvo);
      case TipoDeMissao.abaixoDaMeta:
        return c.fechouAbaixoHoje ? d.alvo : 0;
      case TipoDeMissao.dispersivoAbaixoDe:
        final disp = c.dispersivoHoje;
        if (disp == null) return 0;
        // Quanto mais longe do teto, mais completa: a barra enche enquanto o
        // usuário **não** gasta.
        final folga = (d.alvo - disp).clamp(0, d.alvo);
        return folga;
      case TipoDeMissao.sessoesNaSemana:
        return c.sessoesNaSemana;
      case TipoDeMissao.minutosNaSemana:
        return c.minutosNaSemana;
      case TipoDeMissao.diasAbaixoNaSemana:
        return c.diasAbaixoNaSemana;
    }
  }
}
