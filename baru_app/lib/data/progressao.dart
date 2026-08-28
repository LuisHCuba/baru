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

  // --- Vínculo -----------------------------------------------------------

  /// Afagos que rendem XP por dia.
  ///
  /// Existe teto porque sem ele o carinho vira a forma mais barata de subir
  /// de nível, e o app passa a recompensar esfregar a tela em vez de foco.
  /// Depois do teto o bicho continua reagindo — só não paga mais.
  static const carinhosPorDia = 5;

  /// XP de um afago completo, dentro do teto do dia.
  static const xpPorCarinho = 3;

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

/// Um lugar onde o companheiro mora — a "arena" do Baru.
///
/// O habitat não tinha relação nenhuma com a trilha: subir marco não abria
/// cenário nenhum, e `estagioDeHabitat` era um número que ninguém lia. Agora
/// cada estágio é um lugar com nome, e a trilha é o que abre a porta.
///
/// Só o id e o estágio moram aqui. Cor e terreno são desenho e vivem em
/// `widgets/habitat.dart`: esta camada não conhece `Color`, e misturar as
/// duas obrigaria a importar Flutter dentro do balanceamento.
class HabitatDaTrilha {
  const HabitatDaTrilha({required this.id, required this.estagio});

  final String id;

  /// Ordem na escada. 1 é o de partida, e nunca se perde.
  final int estagio;
}

/// A escada de habitats, na ordem em que se abre.
///
/// O estágio bate com `RecompensaDeMarco.estagioDeHabitat`: o marco diz o
/// número, esta lista diz que lugar é aquele.
const habitatsDaTrilha = <HabitatDaTrilha>[
  HabitatDaTrilha(id: 'lagoa', estagio: 1),
  HabitatDaTrilha(id: 'igarape', estagio: 2),
  HabitatDaTrilha(id: 'manguezal', estagio: 3),
  HabitatDaTrilha(id: 'serra', estagio: 4),
  HabitatDaTrilha(id: 'praia', estagio: 5),
  HabitatDaTrilha(id: 'ilha', estagio: 6),
];

/// O habitat de um estágio. O primeiro é o piso: estágio desconhecido cai
/// nele em vez de devolver nulo e obrigar toda a UI a tratar cena vazia.
HabitatDaTrilha habitatDoEstagio(int estagio) {
  for (final h in habitatsDaTrilha) {
    if (h.estagio == estagio) return h;
  }
  return habitatsDaTrilha.first;
}

HabitatDaTrilha? habitatPorId(String? id) {
  if (id == null) return null;
  for (final h in habitatsDaTrilha) {
    if (h.id == id) return h;
  }
  return null;
}

/// Em que passo da trilha um habitat se abre — 1 para o de partida.
///
/// A tela do habitat travado precisa dizer *quando* ele abre, e a única
/// resposta honesta é a posição do marco que o entrega.
int passoQueAbreOHabitat(HabitatDaTrilha h) {
  if (h.estagio <= 1) return 1;
  for (var i = 0; i < trilha.length; i++) {
    if (trilha[i].recompensa.estagioDeHabitat == h.estagio) return i + 1;
  }
  return trilha.length;
}

/// Onde um marco está na trilha, contando de 1. Zero se não estiver nela.
int passoDoMarco(Marco m) {
  for (var i = 0; i < trilha.length; i++) {
    if (trilha[i].id == m.id) return i + 1;
  }
  return 0;
}

/// Como um degrau se apresenta na trilha.
///
/// Existe porque a tela mostrava só dois estados — feito ou não feito — e
/// desenhava todo "não feito" com anel de progresso. Quem estava no passo 3
/// via os passos 8, 11 e 13 com barra pela metade, como se estivessem
/// carregando. Um caminho tem uma frente só.
enum EstadoNaTrilha {
  /// Alcançado. Nunca volta atrás, mesmo fora de ordem.
  conquistado,

  /// A frente da trilha: o primeiro degrau em aberto.
  atual,

  /// Ainda não é a vez dele.
  travado,
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
    id: 'tres_focos',
    tipo: TipoDeMarco.sessoes,
    alvo: 3,
    recompensa: RecompensaDeMarco(folhas: 30),
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
    id: 'tres_dias_abaixo',
    tipo: TipoDeMarco.diasAbaixoDaMeta,
    alvo: 3,
    recompensa: RecompensaDeMarco(folhas: 70),
  ),
  Marco(
    id: 'nivel_5',
    tipo: TipoDeMarco.nivel,
    alvo: 5,
    recompensa: RecompensaDeMarco(folhas: 80),
  ),
  Marco(
    id: 'semana_inteira',
    tipo: TipoDeMarco.sequencia,
    alvo: 7,
    recompensa: RecompensaDeMarco(folhas: 90, estagioDeHabitat: 3),
  ),
  Marco(
    id: 'dez_focos',
    tipo: TipoDeMarco.sessoes,
    alvo: 10,
    recompensa: RecompensaDeMarco(folhas: 100),
  ),
  Marco(
    id: 'nivel_6',
    tipo: TipoDeMarco.nivel,
    alvo: 6,
    recompensa: RecompensaDeMarco(folhas: 110),
  ),
  Marco(
    id: 'cinco_dias_abaixo',
    tipo: TipoDeMarco.diasAbaixoDaMeta,
    alvo: 5,
    recompensa: RecompensaDeMarco(folhas: 120, especie: Species.tortoise),
  ),
  Marco(
    id: 'nivel_8',
    tipo: TipoDeMarco.nivel,
    alvo: 8,
    recompensa: RecompensaDeMarco(folhas: 140),
  ),
  Marco(
    id: 'duas_semanas',
    tipo: TipoDeMarco.sequencia,
    alvo: 14,
    recompensa: RecompensaDeMarco(folhas: 160),
  ),
  Marco(
    id: 'vinte_focos',
    tipo: TipoDeMarco.sessoes,
    alvo: 20,
    recompensa: RecompensaDeMarco(
      folhas: 180,
      estagioDeHabitat: 4,
      especie: Species.axolotl,
    ),
  ),
  Marco(
    id: 'nivel_10',
    tipo: TipoDeMarco.nivel,
    alvo: 10,
    recompensa: RecompensaDeMarco(folhas: 200, especie: Species.owl),
  ),
  Marco(
    id: 'quinze_dias_abaixo',
    tipo: TipoDeMarco.diasAbaixoDaMeta,
    alvo: 15,
    recompensa: RecompensaDeMarco(folhas: 220, especie: Species.penguin),
  ),
  Marco(
    id: 'cinquenta_focos',
    tipo: TipoDeMarco.sessoes,
    alvo: 50,
    recompensa: RecompensaDeMarco(folhas: 260),
  ),
  Marco(
    id: 'nivel_15',
    tipo: TipoDeMarco.nivel,
    alvo: 15,
    recompensa: RecompensaDeMarco(folhas: 300),
  ),
  Marco(
    id: 'trinta_dias',
    tipo: TipoDeMarco.sequencia,
    alvo: 30,
    recompensa: RecompensaDeMarco(
      folhas: 340,
      estagioDeHabitat: 5,
      especie: Species.cat,
    ),
  ),
  Marco(
    id: 'trinta_dias_abaixo',
    tipo: TipoDeMarco.diasAbaixoDaMeta,
    alvo: 30,
    recompensa: RecompensaDeMarco(folhas: 400),
  ),
  Marco(
    id: 'cem_focos',
    tipo: TipoDeMarco.sessoes,
    alvo: 100,
    recompensa: RecompensaDeMarco(
      folhas: 500,
      estagioDeHabitat: 6,
      especie: Species.fox,
    ),
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
  ///
  /// O piso de cada tipo importa: sessões, sequência e dias abaixo da meta
  /// começam em 0, mas **o nível começa em 1**. Medindo o nível a partir de
  /// zero, "chegar ao nível 3" nascia com um terço da barra cheia numa conta
  /// recém-criada — e passava à frente de "faça sua primeira sessão" na hora
  /// de escolher o próximo passo.
  double fracaoDe(Marco m) {
    final piso = m.tipo == TipoDeMarco.nivel ? 1 : 0;
    final alvo = m.alvo - piso;
    if (alvo <= 0) return 1;
    return ((valorDe(m.tipo) - piso) / alvo).clamp(0.0, 1.0);
  }

  /// Onde você está na trilha: o **primeiro** marco ainda não alcançado.
  ///
  /// Um caminho tem ordem. Apontar para o "mais perto de acontecer" mandava o
  /// "VOCÊ ESTÁ AQUI" para o fim da trilha enquanto os primeiros passos
  /// seguiam apagados — que foi o que o usuário viu e não fez sentido nenhum.
  ///
  /// Os marcos continuam independentes: quem alcançar um lá embaixo antes da
  /// hora fica com o ✓ dele, e isso lê como bônus. O que não pode é a
  /// **frente** da trilha pular para trás de um degrau apagado.
  Marco? get proximoMarco {
    for (final m in trilha) {
      if (!alcancou(m)) return m;
    }
    return null;
  }

  /// O marco não alcançado mais perto de fechar.
  ///
  /// Responde outra pergunta: não "onde estou", e sim "o que dá para fechar
  /// hoje". A trilha usa [proximoMarco]; quem quiser sugerir ação usa este.
  Marco? get marcoMaisPerto {
    Marco? melhor;
    var melhorFracao = -1.0;
    for (final m in trilha) {
      if (alcancou(m)) continue;
      final f = fracaoDe(m);
      if (f > melhorFracao) {
        melhorFracao = f;
        melhor = m;
      }
    }
    return melhor;
  }

  /// Como o degrau se apresenta na trilha.
  ///
  /// Alcançado ganha de posição: quem fechou um marco lá embaixo antes da
  /// hora fica com o ✓ dele. O que não pode acontecer — e acontecia — é um
  /// degrau que ninguém alcançou aparecer com anel de progresso pela metade,
  /// como se estivesse a caminho de sozinho.
  EstadoNaTrilha estadoDe(Marco m) {
    if (alcancou(m)) return EstadoNaTrilha.conquistado;
    if (proximoMarco?.id == m.id) return EstadoNaTrilha.atual;
    return EstadoNaTrilha.travado;
  }

  /// Em que passo a pessoa está, contando de 1.
  ///
  /// É a resposta literal a "em que momento eu tô, em que passo": a posição
  /// do primeiro degrau em aberto. Com a trilha inteira feita, vale o total.
  int get passoAtual {
    final p = proximoMarco;
    return p == null ? trilha.length : passoDoMarco(p);
  }

  int get totalDePassos => trilha.length;

  /// Quanto falta para o marco, na unidade dele. Zero quando já é seu.
  ///
  /// Nível é a exceção: "faltam 2 níveis" não diz o que fazer hoje, e o que
  /// a pessoa junta de fato é XP. Ver [xpQueFaltaPara].
  int quantoFalta(Marco m) {
    final falta = m.alvo - valorDe(m.tipo);
    return falta < 0 ? 0 : falta;
  }

  /// XP que falta para um marco de nível. Zero para os outros tipos.
  int xpQueFaltaPara(Marco m) {
    if (m.tipo != TipoDeMarco.nivel) return 0;
    final falta = Balanco.xpAcumuladoPara(m.alvo) - xp;
    return falta < 0 ? 0 : falta;
  }

  /// Quantos marcos já foram conquistados.
  int get conquistados => trilha.where(alcancou).length;

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

  /// Os lugares que a trilha já abriu, do primeiro ao último.
  List<HabitatDaTrilha> get habitatsLiberados =>
      habitatsDaTrilha.where((h) => h.estagio <= estagioDoHabitat).toList();

  bool habitatLiberado(String id) {
    final h = habitatPorId(id);
    return h != null && h.estagio <= estagioDoHabitat;
  }

  /// O habitat mais alto já aberto — para onde a pessoa se muda sozinha
  /// quando sobe de marco, do jeito que a arena do Clash Royale troca.
  HabitatDaTrilha get habitatDoTopo => habitatDoEstagio(estagioDoHabitat);
}
