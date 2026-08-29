/// Missões diárias e semanais.
///
/// O que existia antes eram duas linhas de texto com "+10" e "+15" ao lado e
/// um visto binário. Não havia progresso numérico, prazo, estado de resgate,
/// nem código creditando as recompensas. Missão que anuncia prêmio e não paga
/// é dívida de confiança.
library;

import 'descanso_do_dia.dart';
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

  /// Somar mais minutos de foco do que de apps dispersivos, no mesmo dia.
  ///
  /// **O que ela mede que nenhuma outra mede.** `minutosHoje` premia fazer,
  /// `dispersivoAbaixoDe` premia não gastar — e as duas convivem com um dia
  /// em que a pessoa focou uma hora e rolou quatro. Esta é a única que olha
  /// a **razão** entre as duas medidas, que é a tese do produto inteira:
  /// não é sobre focar muito nem sobre rolar pouco, é sobre qual dos dois
  /// ganhou o dia. O alvo é binário de propósito — "ganhou" não tem meio
  /// termo, e uma barra fracionada aqui sugeriria um crédito parcial que
  /// não existe.
  focoAcimaDoDispersivo,

  /// Um foco **e** o dia abaixo da meta — as duas metades do mesmo dia.
  ///
  /// Não é `sessoesHoje` com `abaixoDaMeta` grudadas para render duas
  /// missões pelo preço de uma. É a coincidência que nenhuma das duas
  /// sozinha consegue exigir: dá para fechar `um_foco` num dia de seis
  /// horas de tela, e dá para fechar `abaixo_hoje` num dia em que o
  /// telefone só ficou na gaveta. O produto quer o dia em que as duas
  /// aconteceram, e é esse dia que esta missão paga.
  diaCompleto,

  /// Colher o descanso em N dias da semana.
  ///
  /// A missão do descanso é a principal do dia (D-01) e some à meia-noite.
  /// Nada no app dizia "de novo amanhã" — e constância é justamente o que
  /// uma missão diária, sozinha, não consegue pedir. Esta é a única que
  /// enxerga mais de um dia da mesma coisa.
  descansoNaSemana,

  /// Média de minutos por sessão na semana.
  ///
  /// `minutosNaSemana` e `sessoesNaSemana` premiam volume, e volume se faz
  /// com dez sessões de dez minutos. Esta pergunta outra coisa —
  /// profundidade — e é a única em que fazer **mais** sessões curtas
  /// atrapalha em vez de ajudar.
  focoProfundoNaSemana,

  /// Fazer carinho no companheiro N vezes hoje.
  ///
  /// A única do quadro que não pede foco nem menos tela. O app é um bicho
  /// que reage, e todas as outras missões falam de produtividade — o que
  /// transformava o companheiro em enfeite de um app de disciplina. Esta
  /// pede presença com ele, e é a única que se cumpre sem nenhum sacrifício.
  carinhoHoje,

  /// Focar em N períodos diferentes do dia (manhã, tarde, noite).
  ///
  /// Todas as outras de foco somam: mais sessões, mais minutos, sessão mais
  /// longa. Uma manhã heroica fecha todas elas e o resto do dia não existe.
  /// Esta é a única que **não** se cumpre numa sessão só, por mais longa que
  /// seja — o que ela mede é a distribuição, não o total.
  faixasDeFocoHoje,

  /// Somar N minutos em apps produtivos.
  ///
  /// A primeira missão do app que pede para **usar** o telefone. Todo o
  /// resto do quadro trata tela como coisa a reduzir, e o §5 do contrato já
  /// diz que produtivo não entra na meta — mas até aqui "não entra na meta"
  /// era só ausência de castigo, nunca um prêmio. Ler no telefone é uma boa
  /// hora de telefone, e nada no app dizia isso.
  minutosProdutivos,

  /// Manter o dispersivo abaixo de N% do tempo de tela do dia.
  ///
  /// A única que olha **proporção**. `dispersivoAbaixoDe` e `abaixoDaMeta`
  /// olham totais, e um total pune igual quem passou quatro horas lendo e
  /// quem passou quatro horas rolando. Esta sabe a diferença, e é a única
  /// que melhora quando a pessoa troca um app pelo outro sem largar o
  /// telefone — que é a mudança realista.
  fatiaDoDispersivo,

  /// Voltar ao foco no dia em que se volta depois de faltar.
  ///
  /// **Não entra em pool nenhum** — ver [defDaRetomada].
  retomadaHoje,
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
///
/// Crescer o pool muda o sorteio de todos os dias, passados inclusive — é a
/// consequência que a ADR-010 já aceitou por escrito: missão expirada não é
/// recuperável, então reabrir uma data antiga com outro sorteio não tira
/// nada de ninguém.
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
  // As duas mais caras do pool diário, e ainda assim abaixo das 30 do
  // descanso: a missão principal do dia não pode ser a segunda melhor
  // troca de esforço por folha, ou vira a que se pula.
  DefinicaoDeMissao(
    id: 'foco_ganha_do_rolar',
    tipo: TipoDeMissao.focoAcimaDoDispersivo,
    ritmo: RitmoDaMissao.diaria,
    alvo: 1,
    folhas: 25,
    xp: Balanco.xpMissaoDiaria,
    precisaDeUso: true,
  ),
  DefinicaoDeMissao(
    id: 'dia_completo',
    tipo: TipoDeMissao.diaCompleto,
    ritmo: RitmoDaMissao.diaria,
    alvo: 2,
    folhas: 24,
    xp: Balanco.xpMissaoDiaria,
    precisaDeUso: true,
  ),
  // Três de cinco, e não cinco de cinco: `Balanco.carinhosPorDia` é o teto
  // do XP de afago, e pedir o teto inteiro transformaria a missão mais leve
  // do quadro na que exige mais toques. O teste trava o alvo abaixo do teto
  // — acima dele a missão seria literalmente impossível.
  DefinicaoDeMissao(
    id: 'carinho_no_bicho',
    tipo: TipoDeMissao.carinhoHoje,
    ritmo: RitmoDaMissao.diaria,
    alvo: 3,
    folhas: 14,
    xp: Balanco.xpMissaoDiaria,
  ),
  // Dois períodos e não três: três obrigaria a focar de manhã, à tarde e à
  // noite no mesmo dia, o que é agenda de quem não trabalha.
  DefinicaoDeMissao(
    id: 'foco_em_dois_periodos',
    tipo: TipoDeMissao.faixasDeFocoHoje,
    ritmo: RitmoDaMissao.diaria,
    alvo: 2,
    folhas: 22,
    xp: Balanco.xpMissaoDiaria,
  ),
  DefinicaoDeMissao(
    id: 'tela_que_constroi',
    tipo: TipoDeMissao.minutosProdutivos,
    ritmo: RitmoDaMissao.diaria,
    alvo: 30,
    folhas: 20,
    xp: Balanco.xpMissaoDiaria,
    precisaDeUso: true,
  ),
  // Metade: é o ponto em que a frase fica dizível sem porcentagem na boca
  // ("menos da metade do seu tempo de tela foi rolagem") e ainda é exigente
  // para quem hoje passa o dia em dois apps de vídeo.
  DefinicaoDeMissao(
    id: 'fatia_da_rolagem',
    tipo: TipoDeMissao.fatiaDoDispersivo,
    ritmo: RitmoDaMissao.diaria,
    alvo: 50,
    folhas: 23,
    xp: Balanco.xpMissaoDiaria,
    precisaDeUso: true,
  ),
];

/// A missão da retomada — a do dia em que a pessoa volta depois de faltar.
///
/// **Por que fica fora dos pools.** Ela só existe em alguns dias, e o sorteio
/// da ADR-010 é cego: no pool, ela sairia em dias comuns e ficaria parada em
/// `0/1` para sempre, porque a condição dela não é algo que se faça — é algo
/// que já aconteceu. O contrato de produto §8C proíbe exatamente isso ("nunca
/// missão impossível"), e a saída é a mesma que o descanso já usa: viver ao
/// lado do sorteio, aparecendo quando faz sentido.
///
/// **Por que é uma [DefinicaoDeMissao] e não uma classe própria como o
/// descanso.** O descanso precisou de classe porque é um ciclo com relógio,
/// fuga e ruptura. Esta é uma leitura de contador como qualquer outra do
/// `switch` — o que ela tem de diferente é só *quando aparece*. Uma classe
/// nova traria um segundo caminho de crédito para manter em pé, e o caminho
/// que já existe (`resgataMissao`, com a chave `retomada@<dia>`) é o mesmo
/// que os testes de idempotência já protegem.
///
/// Paga menos que o descanso e mais que `um_foco`: é uma sessão de foco
/// comum, no dia em que ela custa mais caro.
const defDaRetomada = DefinicaoDeMissao(
  id: 'retomada',
  tipo: TipoDeMissao.retomadaHoje,
  ritmo: RitmoDaMissao.diaria,
  alvo: 1,
  folhas: 22,
  xp: Balanco.xpMissaoDiaria,
);

/// Toda definição que existe: as sorteadas e as fixas.
///
/// Existe para o teste que trava a regra "todo tipo tem uma definição". Um
/// valor de [TipoDeMissao] sem definição nenhuma é conteúdo que o app nunca
/// entrega, e some sem ninguém notar.
const todasAsDefinicoes = <DefinicaoDeMissao>[
  ...poolDiario,
  ...poolSemanal,
  defDaRetomada,
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
  // Três dias, e não cinco: constância se aprende com um alvo que se
  // alcança. Cinco de sete transformaria a semana em obrigação, e o
  // contrato de produto §1 não admite missão que puna quem falhou terça.
  DefinicaoDeMissao(
    id: 'semana_descanso',
    tipo: TipoDeMissao.descansoNaSemana,
    ritmo: RitmoDaMissao.semanal,
    alvo: 3,
    folhas: 90,
    xp: Balanco.xpMissaoSemanal,
    precisaDeUso: true,
  ),
  // 45 min de média: acima da sessão de 25 e abaixo da de 50, então nem
  // sai de graça de quem só faz curtas nem exige a longa todo dia.
  DefinicaoDeMissao(
    id: 'semana_foco_profundo',
    tipo: TipoDeMissao.focoProfundoNaSemana,
    ritmo: RitmoDaMissao.semanal,
    alvo: 45,
    folhas: 85,
    xp: Balanco.xpMissaoSemanal,
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
    this.carinhosHoje = 0,
    this.neutroHoje,
    this.produtivoHoje,
    this.faixasDeFocoHoje = 0,
    this.voltouDepoisDeFaltar = false,
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

  /// Afagos de hoje, já limitados pelo teto de `Balanco.carinhosPorDia`.
  final int carinhosHoje;

  /// Minutos por categoria de app. `null` pelo mesmo motivo de
  /// [dispersivoHoje]: sem medição, a missão fica indisponível em vez de
  /// aparecer com progresso inventado (ADR-009).
  final int? neutroHoje;
  final int? produtivoHoje;

  /// Em quantos períodos do dia (manhã, tarde, noite) houve foco concluído.
  final int faixasDeFocoHoje;

  /// A pessoa passou pelo menos um dia inteiro sem abrir o app e voltou hoje.
  final bool voltouDepoisDeFaltar;
}

/// Os períodos do dia que a missão de variedade de horário conta.
///
/// Três e não vinte e quatro: a missão pergunta se o foco se espalhou pelo
/// dia, e "às 9 e às 10" não é foco espalhado. Também não são faixas iguais —
/// a noite é maior porque é onde a madrugada cabe sem virar uma quarta faixa
/// que quase ninguém alcançaria.
enum PeriodoDoDia {
  /// 05:00–11:59.
  manha,

  /// 12:00–17:59.
  tarde,

  /// 18:00–04:59.
  noite,
}

PeriodoDoDia periodoDe(DateTime quando) {
  final h = quando.hour;
  if (h >= 5 && h < 12) return PeriodoDoDia.manha;
  if (h >= 12 && h < 18) return PeriodoDoDia.tarde;
  return PeriodoDoDia.noite;
}

/// Em quantos períodos de [dia] houve foco, a partir dos instantes [inicios].
///
/// Recebe `DateTime` cru, e não os registros de sessão, para que este arquivo
/// não precise conhecer o formato do histórico — é o mesmo desenho de
/// `horarioDoHabito`, que já lê `sessions.map((s) => s.at)`.
///
/// O instante que interessa é o **começo** da sessão: é quando a pessoa
/// decidiu focar. Uma sessão de 90 minutos começada às 11h50 é foco da manhã,
/// não da tarde, e contar pelo fim faria a missão depender da duração
/// escolhida em vez do horário.
int faixasDeFoco(Iterable<DateTime> inicios, {required DateTime dia}) {
  final vistos = <PeriodoDoDia>{};
  for (final quando in inicios) {
    if (quando.year != dia.year ||
        quando.month != dia.month ||
        quando.day != dia.day) {
      continue;
    }
    vistos.add(periodoDe(quando));
  }
  return vistos.length;
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

  /// Uma chave `id@dia`, para o que é diário e não sai do pool.
  ///
  /// Existe para que haja um único lugar decidindo o formato da chave. Duas
  /// gramáticas dentro do mesmo conjunto de resgates seria o tipo de
  /// divergência que ninguém nota até um resgate deixar de ser idempotente.
  static String chaveDoDia(String id, DateTime dia) => '$id@${_diaEm(dia)}';

  /// A chave de resgate da missão do descanso.
  static String chaveDoDescanso(DateTime dia) => chaveDoDia(Descanso.id, dia);

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
          progresso: progressoDe(d, contadores, dia: dia, resgatadas: resgatadas),
          resgatada: resgatadas.contains(chaveDeResgate(d, dia)),
          disponivel: !d.precisaDeUso || contadores.temPermissaoDeUso,
        ),
    ];
  }

  /// O progresso de uma missão.
  ///
  /// [dia] e [resgatadas] entram **opcionais** e não como campos de
  /// [ContadoresDeMissao] por dois motivos. O primeiro é que não são
  /// contadores: são o calendário e o histórico de resgates, que já chegam
  /// prontos em [doDia] e cujo dono é este quadro. O segundo é que qualquer
  /// tipo que ignore os dois — os oito originais — continua chamável sem
  /// eles, e nenhuma chamada existente precisou mudar de forma.
  int progressoDe(
    DefinicaoDeMissao d,
    ContadoresDeMissao c, {
    DateTime? dia,
    Set<String> resgatadas = const {},
  }) {
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
      case TipoDeMissao.focoAcimaDoDispersivo:
        final disp = c.dispersivoHoje;
        // Sem medição, zero — a mesma regra de `dispersivoAbaixoDe`: o app
        // não estima tempo de tela (ADR-009).
        if (disp == null) return 0;
        // O `> 0` não é zelo. À meia-noite o dia tem zero de foco e zero de
        // rolagem, e `0 >= 0` pagaria a missão inteira antes de a pessoa
        // fazer qualquer coisa — recompensa por existir, que é o oposto do
        // que o cartão promete.
        return c.minutosHoje > 0 && c.minutosHoje >= disp ? d.alvo : 0;
      case TipoDeMissao.diaCompleto:
        // Meio a meio, para a barra dizer qual metade falta em vez de só
        // acender no fim.
        var feito = 0;
        if (c.sessoesHoje >= 1) feito += 1;
        if (c.fechouAbaixoHoje) feito += 1;
        return feito.clamp(0, d.alvo);
      case TipoDeMissao.descansoNaSemana:
        if (dia == null) return 0;
        return _descansosColhidosNaSemana(dia, resgatadas).clamp(0, d.alvo);
      case TipoDeMissao.focoProfundoNaSemana:
        // Zero sessões não é média zero, é média indefinida — e dividir por
        // zero aqui derrubaria a tela inteira.
        if (c.sessoesNaSemana <= 0) return 0;
        return (c.minutosNaSemana ~/ c.sessoesNaSemana).clamp(0, d.alvo);
      case TipoDeMissao.carinhoHoje:
        return c.carinhosHoje.clamp(0, d.alvo);
      case TipoDeMissao.faixasDeFocoHoje:
        return c.faixasDeFocoHoje.clamp(0, d.alvo);
      case TipoDeMissao.minutosProdutivos:
        final prod = c.produtivoHoje;
        if (prod == null) return 0;
        return prod.clamp(0, d.alvo);
      case TipoDeMissao.fatiaDoDispersivo:
        final disp = c.dispersivoHoje;
        final neutro = c.neutroHoje;
        final prod = c.produtivoHoje;
        if (disp == null || neutro == null || prod == null) return 0;
        final total = disp + neutro + prod;
        // Proporção de dez minutos de tela não descreve dia nenhum: às sete
        // da manhã, dois minutos num app de leitura dariam 100% fora da
        // rolagem e fechariam a missão antes de o dia começar. Abaixo do
        // piso o app diz que ainda não sabe, que é a verdade.
        if (total < minutosParaHaverProporcao) return 0;
        return (((total - disp) * 100) ~/ total).clamp(0, d.alvo);
      case TipoDeMissao.retomadaHoje:
        return c.sessoesHoje.clamp(0, d.alvo);
    }
  }

  /// Abaixo disto não há proporção que signifique alguma coisa.
  static const minutosParaHaverProporcao = 30;

  /// A missão da retomada de hoje, ou `null` no dia em que ela não cabe.
  ///
  /// **Por que a condição é só ter faltado, e não "a raiz caiu".** A segunda
  /// leitura seria mais precisa — quem tinha congelamento não falhou de
  /// verdade — mas `streak` sobe dentro de `_concluiSessao`, na primeira
  /// sessão do dia. Usá-la como porta faria o cartão **sumir no instante
  /// exato em que vira resgatável**: a missão anunciaria o prêmio e nunca o
  /// pagaria. `voltouDepoisDeFaltar` sai de `daysAway`, que não se mexe
  /// durante o dia.
  Missao? aRetomada({
    required DateTime dia,
    required ContadoresDeMissao contadores,
    required Set<String> resgatadas,
  }) {
    if (!contadores.voltouDepoisDeFaltar) return null;
    return Missao(
      definicao: defDaRetomada,
      progresso: progressoDe(defDaRetomada, contadores),
      resgatada: resgatadas.contains(chaveDeResgate(defDaRetomada, dia)),
      disponivel: true,
    );
  }

  /// Quantos dias desta semana já tiveram o descanso **colhido**.
  ///
  /// Lê o conjunto de resgates, que é o único registro do descanso que
  /// atravessa a meia-noite: `melhorDescansoHoje` é apagado na virada do
  /// dia de propósito (o contador de tela zera junto e a subtração passaria
  /// a descrever outra coisa). Guardar um histórico próprio de descansos
  /// exigiria campo novo no estado do app — e o campo que já existe,
  /// sincronizado e à prova de resgate duplo, é este.
  ///
  /// A consequência está dita no cartão, não escondida: o dia entra quando
  /// a toca é aberta, não quando o relógio bate quarenta minutos.
  static int _descansosColhidosNaSemana(
    DateTime dia,
    Set<String> resgatadas,
  ) {
    var n = 0;
    for (var i = 0; i < 7; i++) {
      // Aritmética no construtor, e não `add(Duration(days: i))`: somar 24h
      // sobre um horário de verão cai no dia anterior às 23h, e a semana
      // passaria a contar um dia duas vezes e outro nenhuma.
      final d = DateTime(dia.year, dia.month, dia.day - (dia.weekday - 1) + i);
      if (resgatadas.contains(chaveDoDescanso(d))) n += 1;
    }
    return n;
  }
}

/// A missão do descanso — a principal do dia.
///
/// **Por que não é um valor de [TipoDeMissao].** As de lá são leituras
/// de contador: o quadro sorteia, lê um número que o dia já produziu e
/// desenha a barra. O descanso não é leitura — é um ciclo, com começo
/// declarado, pausa, ruptura e recomeço, e a conta dele precisa do instante
/// em que começou e de quanto de tela houve desde então. Entrar no `switch`
/// de [QuadroDeMissoes.progressoDe] obrigaria [ContadoresDeMissao] a
/// carregar relógio e o quadro a ter estado.
///
/// E, principalmente: ela é **fixa**. O sorteio determinístico (ADR-010)
/// escolhe três do pool diário todo dia — a missão principal do dia não pode
/// depender de sair no sorteio. Ela fica ao lado, sempre presente, com a
/// mesma anatomia visível do §5: alvo, folhas, XP, prazo, estado e resgate
/// idempotente.
class DefinicaoDoDescanso {
  const DefinicaoDoDescanso({
    this.alvo = Descanso.alvo,
    this.folhas = Descanso.folhas,
    this.xp = Balanco.xpMissaoDiaria,
  });

  final Duration alvo;
  final int folhas;
  final int xp;

  String get id => Descanso.id;
  RitmoDaMissao get ritmo => RitmoDaMissao.diaria;
  int get alvoEmMinutos => alvo.inMinutes;

  /// Depende da permissão de tempo de tela.
  ///
  /// Sem ela o app não sabe se o telefone ficou parado ou se a pessoa passou
  /// quarenta minutos no TikTok — e ADR-009 é explícito em não estimar. A
  /// missão vira convite para conceder a permissão, como `abaixo_hoje`,
  /// nunca uma barra que anda sozinha por falta de evidência.
  bool get precisaDeUso => true;
}

/// A missão do descanso com progresso — o que a tela desenha.
class MissaoDoDescanso {
  const MissaoDoDescanso({
    this.definicao = const DefinicaoDoDescanso(),
    this.melhorDoDia = Duration.zero,
    this.emCurso,
    this.resgatada = false,
    this.temPermissaoDeUso = false,
  });

  final DefinicaoDoDescanso definicao;

  /// O melhor descanso já conseguido hoje. **Nunca diminui** — ver
  /// [melhorDescanso].
  final Duration melhorDoDia;

  /// A tentativa em curso, se houver alguma. `null` = ninguém descansando.
  final LeituraDoDescanso? emCurso;

  final bool resgatada;
  final bool temPermissaoDeUso;

  String get id => definicao.id;
  int get alvo => definicao.alvoEmMinutos;
  int get folhas => definicao.folhas;
  int get xp => definicao.xp;
  RitmoDaMissao get ritmo => definicao.ritmo;

  bool get disponivel => !definicao.precisaDeUso || temPermissaoDeUso;

  /// O progresso mostrado é o melhor do dia, não o da tentativa atual.
  ///
  /// Se fosse o da tentativa, sair para o WhatsApp e voltar faria a barra
  /// recuar — decaimento de progresso, que o contrato de produto §1 proíbe.
  /// A perda continua visível ([LeituraDoDescanso.fuga] e a distância até o
  /// alvo), só não é cobrada em cima do que já foi feito.
  int get progresso => melhorDoDia.inMinutes.clamp(0, alvo);

  bool get concluida => melhorDoDia >= definicao.alvo;

  double get fracao => alvo <= 0 ? 1 : (progresso / alvo).clamp(0.0, 1.0);

  /// Há alguém descansando agora?
  bool get correndo => emCurso?.emAndamento ?? false;

  EstadoDaMissao get estado {
    if (!disponivel) return EstadoDaMissao.precisaPermissao;
    if (resgatada) return EstadoDaMissao.resgatada;
    if (concluida) return EstadoDaMissao.concluida;
    return EstadoDaMissao.emProgresso;
  }

  bool get resgatavel => disponivel && concluida && !resgatada;

  /// A chave que torna o resgate idempotente, com o dia dentro.
  static String chaveDeResgate(DateTime dia) =>
      QuadroDeMissoes.chaveDoDescanso(dia);
}
