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

/// Um critério medido: um contador e o valor a atingir.
///
/// Existe como classe em vez de dois campos soltos no marco porque um degrau
/// pode ter **dois** caminhos até a mesma porta, e o par `tipoAlternativo` +
/// `alvoAlternativo` deixaria "tipo sem alvo" representável.
class Criterio {
  const Criterio(this.tipo, this.alvo);

  final TipoDeMarco tipo;

  /// Valor a atingir: nível 5, 10 sessões, 7 dias seguidos...
  final int alvo;
}

/// Um degrau da trilha.
class Marco {
  const Marco({
    required this.id,
    required this.tipo,
    required this.alvo,
    required this.recompensa,
    this.alternativa,
  });

  final String id;
  final TipoDeMarco tipo;

  /// Valor a atingir: nível 5, 10 sessões, 7 dias seguidos...
  final int alvo;

  final RecompensaDeMarco recompensa;

  /// Segundo caminho até o mesmo degrau.
  ///
  /// Só os marcos de [TipoDeMarco.diasAbaixoDaMeta] têm um, e o motivo é
  /// estrutural: `diasAbaixoDaMeta` só anda com a permissão de uso concedida,
  /// e recusar a permissão é caminho suportado, não degradado (contrato §8).
  /// Enquanto os marcos eram independentes, um contador parado só travava os
  /// marcos dele. Numa corrente ele vira **muro**: a trilha inteira pararia
  /// no primeiro degrau desse tipo e nunca mais andaria, para todo mundo que
  /// disse não à permissão. É o mesmo defeito que o §8C proíbe nas missões —
  /// "nunca missão impossível".
  ///
  /// A alternativa mede a mesma intenção pelo que o app enxerga sozinho —
  /// dias de presença seguidos — e é de propósito **mais cara** que o critério
  /// principal, para quem concedeu a permissão continuar fechando o passo pelo
  /// caminho curto em vez de pelo desvio.
  final Criterio? alternativa;

  /// O critério principal, na mesma forma da alternativa.
  Criterio get criterio => Criterio(tipo, alvo);
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

/// A posição de cada marco, por id. Calculado uma vez.
///
/// A busca linear que morava em [passoDoMarco] custava nada enquanto era
/// chamada de vez em quando. Agora a posição é o que decide se um degrau está
/// conquistado, então ela é consultada para cada um dos 22 nós a cada quadro
/// da tela — busca dentro de busca. O mapa tira o quadrado da conta.
final Map<String, int> _passoPorId = {
  for (var i = 0; i < trilha.length; i++) trilha[i].id: i + 1,
};

/// Onde um marco está na trilha, contando de 1. Zero se não estiver nela.
int passoDoMarco(Marco m) => _passoPorId[m.id] ?? 0;

/// Como um degrau se apresenta na trilha.
///
/// Existe porque a tela mostrava só dois estados — feito ou não feito — e
/// desenhava todo "não feito" com anel de progresso. Quem estava no passo 3
/// via os passos 8, 11 e 13 com barra pela metade, como se estivessem
/// carregando. Um caminho tem uma frente só.
enum EstadoNaTrilha {
  /// Atrás da frente. Só se chega aqui passando pelo degrau anterior.
  conquistado,

  /// A frente da trilha: o único degrau em aberto.
  atual,

  /// Ainda não é a vez dele — com ou sem o critério dele cumprido.
  travado,
}

/// A trilha: a corrente ordenada e visível que responde "por que eu volto
/// amanhã".
///
/// **Ordem é a regra, não a decoração.** O passo N+1 não é conquistável antes
/// do N, aconteça o que acontecer com o critério dele — ver
/// [ProgressoDaTrilha.passosConquistados]. Isto obriga a lista a estar em
/// ordem de esforço crescente: se um degrau caro ficar na frente de um barato,
/// a corrente para nele e o barato lá atrás vira uma promessa que não abre.
///
/// A ordem anterior não obedecia a isso — era legível como "um de cada tipo,
/// rodando", e nesse rodízio o passo 12 (5 dias abaixo da meta, ~5 dias) vinha
/// depois do passo 11 (nível 6, ~8 dias) e o passo 19 (nível 15, ~53 dias)
/// vinha antes do passo 20 (30 dias seguidos, ~30 dias). Enquanto cada marco
/// era independente isso não aparecia; numa corrente, cada inversão é uma
/// parada seca no meio do caminho.
///
/// A estimativa que ordena a lista é "quantos dias de uso engajado até bater",
/// com ~70 XP/dia (duas sessões, presença, missões e o dia abaixo da meta):
/// 0,7 · 1 · 1,6 · 2 · 3 · 3 · 3,3 · 5 · 5,3 · 6,7 · 7 · 7,9 · 13 · 14 · 14,5
/// · 15 · 23 · 30 · 30 · 33 · 53 · 67.
///
/// **Os ids nunca mudam.** Eles são a chave de `marcosResgatados`, que é o que
/// impede um marco de pagar duas vezes e é de onde a carteira lê o histórico:
/// renomear um id imprimiria folhas e apagaria uma linha do extrato. Reordenar
/// move a *posição* e, com ela, a folha da escada de recompensas — o conjunto
/// dos 22 valores é o mesmo de antes, só trocou de dono.
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
    alternativa: Criterio(TipoDeMarco.sequencia, 4),
    recompensa: RecompensaDeMarco(folhas: 25),
  ),
  Marco(
    id: 'nivel_3',
    tipo: TipoDeMarco.nivel,
    alvo: 3,
    recompensa: RecompensaDeMarco(folhas: 30, estagioDeHabitat: 2),
  ),
  Marco(
    id: 'tres_focos',
    tipo: TipoDeMarco.sessoes,
    alvo: 3,
    recompensa: RecompensaDeMarco(folhas: 40),
  ),
  Marco(
    id: 'tres_dias',
    tipo: TipoDeMarco.sequencia,
    alvo: 3,
    recompensa: RecompensaDeMarco(folhas: 50),
  ),
  Marco(
    id: 'tres_dias_abaixo',
    tipo: TipoDeMarco.diasAbaixoDaMeta,
    alvo: 3,
    alternativa: Criterio(TipoDeMarco.sequencia, 8),
    recompensa: RecompensaDeMarco(folhas: 60),
  ),
  Marco(
    id: 'cinco_focos',
    tipo: TipoDeMarco.sessoes,
    alvo: 5,
    recompensa: RecompensaDeMarco(folhas: 70, especie: Species.otter),
  ),
  Marco(
    id: 'cinco_dias_abaixo',
    tipo: TipoDeMarco.diasAbaixoDaMeta,
    alvo: 5,
    alternativa: Criterio(TipoDeMarco.sequencia, 12),
    recompensa: RecompensaDeMarco(folhas: 80, especie: Species.tortoise),
  ),
  Marco(
    id: 'nivel_5',
    tipo: TipoDeMarco.nivel,
    alvo: 5,
    recompensa: RecompensaDeMarco(folhas: 90),
  ),
  Marco(
    id: 'dez_focos',
    tipo: TipoDeMarco.sessoes,
    alvo: 10,
    recompensa: RecompensaDeMarco(folhas: 100),
  ),
  Marco(
    id: 'semana_inteira',
    tipo: TipoDeMarco.sequencia,
    alvo: 7,
    recompensa: RecompensaDeMarco(folhas: 110, estagioDeHabitat: 3),
  ),
  Marco(
    id: 'nivel_6',
    tipo: TipoDeMarco.nivel,
    alvo: 6,
    recompensa: RecompensaDeMarco(folhas: 120),
  ),
  Marco(
    id: 'vinte_focos',
    tipo: TipoDeMarco.sessoes,
    alvo: 20,
    recompensa: RecompensaDeMarco(
      folhas: 140,
      estagioDeHabitat: 4,
      especie: Species.axolotl,
    ),
  ),
  Marco(
    id: 'duas_semanas',
    tipo: TipoDeMarco.sequencia,
    alvo: 14,
    recompensa: RecompensaDeMarco(folhas: 160),
  ),
  Marco(
    id: 'nivel_8',
    tipo: TipoDeMarco.nivel,
    alvo: 8,
    recompensa: RecompensaDeMarco(folhas: 180),
  ),
  Marco(
    id: 'quinze_dias_abaixo',
    tipo: TipoDeMarco.diasAbaixoDaMeta,
    alvo: 15,
    alternativa: Criterio(TipoDeMarco.sequencia, 25),
    recompensa: RecompensaDeMarco(folhas: 200, especie: Species.penguin),
  ),
  Marco(
    id: 'nivel_10',
    tipo: TipoDeMarco.nivel,
    alvo: 10,
    recompensa: RecompensaDeMarco(folhas: 220, especie: Species.owl),
  ),
  Marco(
    id: 'trinta_dias',
    tipo: TipoDeMarco.sequencia,
    alvo: 30,
    recompensa: RecompensaDeMarco(
      folhas: 260,
      estagioDeHabitat: 5,
      especie: Species.cat,
    ),
  ),
  Marco(
    id: 'trinta_dias_abaixo',
    tipo: TipoDeMarco.diasAbaixoDaMeta,
    alvo: 30,
    alternativa: Criterio(TipoDeMarco.sequencia, 45),
    recompensa: RecompensaDeMarco(folhas: 300),
  ),
  // O buldogue francês entra **num degrau que já existia**, e não num degrau
  // novo.
  //
  // A trilha é uma corrente ordenada por esforço, com 22 posições, uma escada
  // de folhas que a soma inteira preserva e ids que são chave de resgate
  // (`marcosResgatados`). Um vigésimo terceiro degrau empurraria a folha de
  // todos os degraus a partir dele, e mexer na escada de recompensa por causa
  // de uma espécie nova é pagar caro por nada: `cinquenta_focos` não
  // entregava espécie nenhuma e as espécies estavam nos passos 7, 8, 13, 16,
  // 17, 18 e 22 — o vão entre a gata e a raposa era justamente aqui.
  //
  // E o degrau diz a coisa certa. O buldogue francês é a única raça do elenco
  // criada só para fazer companhia: não caça, não pastoreia, não nada. Ele é
  // o prêmio de cinquenta sessões **acompanhadas**, que é o que ele faz.
  Marco(
    id: 'cinquenta_focos',
    tipo: TipoDeMarco.sessoes,
    alvo: 50,
    recompensa: RecompensaDeMarco(folhas: 340, especie: Species.frenchie),
  ),
  Marco(
    id: 'nivel_15',
    tipo: TipoDeMarco.nivel,
    alvo: 15,
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
    this.entregues = const <String>{},
  });

  final int xp;
  final int sessoesConcluidas;

  /// A **melhor** sequência já feita, não a atual: um marco conquistado nunca
  /// é retirado (§ "o usuário nunca perde nada").
  final int melhorSequencia;

  final int diasAbaixoDaMeta;

  /// Ids de marcos que **já entregaram** o que prometiam, em algum momento.
  ///
  /// Piso de migração. O modelo anterior pagava o marco no instante em que o
  /// critério dele batia, fora de ordem — quem tem `marcosResgatados` com
  /// buracos ganhou espécie e habitat que a corrente ainda não alcançou.
  /// Folhas e XP não correm risco (moram em contadores que só sobem, e a
  /// carteira lê `marcosResgatados`, não a trilha), mas espécie e habitat são
  /// **derivados** — sem este piso, virar a chave tiraria de volta um bicho e
  /// um cenário que a pessoa já tinha, e o §1 do contrato não permite tirar
  /// nada.
  ///
  /// Não entra em [alcancados]: o ✓ segue a corrente, senão a trilha voltaria
  /// a ter buraco. O piso é sobre **posse**, não sobre posição.
  final Set<String> entregues;

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

  /// O contador bateu o alvo deste critério.
  bool bateu(Criterio c) => valorDe(c.tipo) >= c.alvo;

  /// O critério do marco está cumprido — **sem olhar a posição dele**.
  ///
  /// Continua existindo e continua valendo: é ele que abre o degrau atual. O
  /// que ele não faz mais é conquistar um degrau fora da vez.
  bool cumpriuOCriterio(Marco m) {
    if (bateu(m.criterio)) return true;
    final alt = m.alternativa;
    return alt != null && bateu(alt);
  }

  /// Quantos degraus a corrente já entregou: o maior **prefixo** em que todos
  /// os critérios bateram.
  ///
  /// É a regra inteira em quatro linhas. Como os contadores só sobem (XP,
  /// sessões, melhor sequência, dias abaixo da meta), o prefixo também só
  /// cresce — a corrente nunca anda para trás, e nenhum degrau precisa ser
  /// gravado como "já foi".
  int get passosConquistados {
    var n = 0;
    for (final m in trilha) {
      if (!cumpriuOCriterio(m)) break;
      n += 1;
    }
    return n;
  }

  /// Este degrau é seu.
  ///
  /// **Ordem obrigatória**: não basta o critério bater, é preciso que todos os
  /// de trás tenham batido. Antes bastava o critério, e como os quatro
  /// contadores correm em paralelo e medem coisas de naturezas diferentes,
  /// alguém fechava o passo 13 (20 sessões) sem nunca ter fechado o passo 11
  /// (7 dias seguidos) — a trilha mostrava ✓ salteado, e conquistar o passo 13
  /// sem ter passado pelo 11 não é uma trilha, é uma lista.
  bool alcancou(Marco m) {
    final passo = passoDoMarco(m);
    return passo > 0 && passo <= passosConquistados;
  }

  /// Progresso de 0 a 1 dentro de um marco.
  ///
  /// O piso de cada tipo importa: sessões, sequência e dias abaixo da meta
  /// começam em 0, mas **o nível começa em 1**. Medindo o nível a partir de
  /// zero, "chegar ao nível 3" nascia com um terço da barra cheia numa conta
  /// recém-criada — e passava à frente de "faça sua primeira sessão" na hora
  /// de escolher o próximo passo.
  ///
  /// Com dois caminhos, vale o mais adiantado: é o que a pessoa vai fechar.
  double fracaoDe(Marco m) {
    var f = fracaoDoCriterio(m.criterio);
    final alt = m.alternativa;
    if (alt != null) {
      final fa = fracaoDoCriterio(alt);
      if (fa > f) f = fa;
    }
    return f;
  }

  double fracaoDoCriterio(Criterio c) {
    final piso = c.tipo == TipoDeMarco.nivel ? 1 : 0;
    final alvo = c.alvo - piso;
    if (alvo <= 0) return 1;
    return ((valorDe(c.tipo) - piso) / alvo).clamp(0.0, 1.0);
  }

  /// Dos caminhos deste marco, o que está mais perto de fechar.
  ///
  /// A tela mostra **um** critério por degrau (T-02: "o que falta para este
  /// passo" em uma frase). Mostrar os dois lado a lado devolveria o problema
  /// que a frase existe para resolver.
  Criterio criterioMaisPerto(Marco m) {
    final alt = m.alternativa;
    if (alt == null) return m.criterio;
    return fracaoDoCriterio(alt) > fracaoDoCriterio(m.criterio)
        ? alt
        : m.criterio;
  }

  /// Onde você está na trilha: o degrau logo depois do último conquistado.
  ///
  /// Um caminho tem ordem. Apontar para o "mais perto de acontecer" mandava o
  /// "VOCÊ ESTÁ AQUI" para o fim da trilha enquanto os primeiros passos
  /// seguiam apagados — que foi o que o usuário viu e não fez sentido nenhum.
  Marco? get proximoMarco {
    final feitos = passosConquistados;
    return feitos >= trilha.length ? null : trilha[feitos];
  }

  /// O marco não alcançado com o critério mais perto de fechar.
  ///
  /// Responde outra pergunta: não "onde estou", e sim "que critério está
  /// quase batendo". Mede critério, não conquista — a trilha **nunca** aponta
  /// para ele, senão o "VOCÊ ESTÁ AQUI" voltaria a saltar degrau.
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
  /// Decidido pela **posição** contra a frente da corrente, e só por ela. É
  /// isto que garante, por construção, o que a tela precisa mostrar: tudo
  /// antes conquistado, exatamente um atual, tudo depois travado, sem buraco
  /// no meio. Não há estado que produza duas frentes nem um ✓ solto adiante.
  EstadoNaTrilha estadoDe(Marco m) {
    final passo = passoDoMarco(m);
    if (passo == 0) return EstadoNaTrilha.travado;
    final feitos = passosConquistados;
    if (passo <= feitos) return EstadoNaTrilha.conquistado;
    if (passo == feitos + 1) return EstadoNaTrilha.atual;
    return EstadoNaTrilha.travado;
  }

  /// O critério deste degrau já bateu, mas ainda não é a vez dele.
  ///
  /// É o que acontece com quem juntou 30 sessões sem nunca fechar um dia
  /// abaixo da meta. Sem nome próprio, a tela dizia "faltam 0 sessões" — o
  /// número certo para a pergunta errada.
  bool esperandoAVez(Marco m) => !alcancou(m) && cumpriuOCriterio(m);

  /// Em que passo a pessoa está, contando de 1.
  ///
  /// É a resposta literal a "em que momento eu tô, em que passo": a posição
  /// do primeiro degrau em aberto. Com a trilha inteira feita, vale o total.
  int get passoAtual {
    final feitos = passosConquistados;
    return feitos >= trilha.length ? trilha.length : feitos + 1;
  }

  int get totalDePassos => trilha.length;

  /// Quanto falta no critério mais perto, na unidade dele. Zero quando bateu.
  ///
  /// Nível é a exceção: "faltam 2 níveis" não diz o que fazer hoje, e o que
  /// a pessoa junta de fato é XP. Ver [xpQueFaltaPara].
  int quantoFalta(Marco m) => quantoFaltaNo(criterioMaisPerto(m));

  int quantoFaltaNo(Criterio c) {
    final falta = c.alvo - valorDe(c.tipo);
    return falta < 0 ? 0 : falta;
  }

  /// XP que falta para um marco de nível. Zero para os outros tipos.
  int xpQueFaltaPara(Marco m) {
    if (m.tipo != TipoDeMarco.nivel) return 0;
    final falta = Balanco.xpAcumuladoPara(m.alvo) - xp;
    return falta < 0 ? 0 : falta;
  }

  /// Quantos marcos já foram conquistados. Igual a [passosConquistados] — a
  /// corrente não tem furo, então contar é o mesmo que medir a frente.
  int get conquistados => passosConquistados;

  List<Marco> get alcancados => trilha.take(passosConquistados).toList();

  /// O que a conta já **tem**: o que a corrente entregou, mais o que o modelo
  /// antigo entregou antes de a corrente existir. Ver [entregues].
  Iterable<Marco> get _comPosse =>
      trilha.where((m) => alcancou(m) || entregues.contains(m.id));

  /// Espécies liberadas por marco, mais a que veio do quiz.
  /// As quatro que o quiz pode devolver.
  ///
  /// Elas **não** ficam todas abertas: a trilha entrega lontra, tartaruga e
  /// coruja como recompensa, e abrir as quatro de saída esvaziaria três
  /// degraus. O que vale é o momento — no onboarding a pessoa escolhe entre
  /// as quatro, porque o quiz sugere e não sentencia; depois disso a porta
  /// da trilha vale para todas as oito que ela entrega.
  static const deOrigem = {
    Species.capybara,
    Species.otter,
    Species.tortoise,
    Species.owl,
  };

  /// Em que passo da trilha a espécie abre, ou `null` se ela é de origem.
  ///
  /// A tela precisa disto para dizer **onde** a espécie abre, e não só que
  /// está travada: cadeado sem destino é frustração, cadeado com número é
  /// motivo para subir.
  static int? passoQueAbre(Species e) {
    for (var i = 0; i < trilha.length; i++) {
      if (trilha[i].recompensa.especie == e) return i + 1;
    }
    return null;
  }

  Set<Species> especiesLiberadas(Species doQuiz) {
    final out = <Species>{doQuiz};
    for (final m in _comPosse) {
      final e = m.recompensa.especie;
      if (e != null) out.add(e);
    }
    return out;
  }

  /// Estágio da cena: sobe com os marcos e nunca desce.
  int get estagioDoHabitat {
    var estagio = 1;
    for (final m in _comPosse) {
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
