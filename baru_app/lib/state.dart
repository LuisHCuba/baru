import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import 'data/app_snapshot.dart';
import 'data/cofre.dart';
import 'data/descanso_do_dia.dart';
import 'data/descanso_retencao.dart';
import 'data/auth_errors.dart';
import 'data/baru_env.dart';
import 'data/repositories.dart';
import 'data/missoes.dart';
import 'data/progressao.dart';
import 'data/quiz.dart';
import 'data/supabase_gateway.dart';
import 'data/tempo_de_tela.dart';
import 'l10n.dart';
import 'l10n_descanso.dart';
import 'l10n_humor.dart';
import 'l10n_sobreposicao.dart';
import 'theme.dart';
import 'models.dart';
import 'navegacao.dart';
import 'services/notification_service.dart';
import 'services/overlay_service.dart';
import 'services/som_service.dart';
import 'services/vigia_service.dart';
import 'services/widget_service.dart';
import 'widgets/raiz.dart';
import 'services/usage_service.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class AppState extends ChangeNotifier {
  AppState({
    this.repos,
    AppSnapshot? snapshot,
    this.onSyncError,
    this.onUserMessage,
  }) {
    if (snapshot != null) {
      _applySnapshot(snapshot);
    }
    final agora = DateTime.now();
    // Antes do calendário: uma sessão que terminou ontem tem de contar como
    // presença de ontem, e é o avanço de calendário que fecha aquele dia.
    _restauraSessao(agora);
    applyCalendar(agora, persist: false);
  }

  final BaruRepositories? repos;
  final void Function(String message)? onSyncError;
  final void Function(String message)? onUserMessage;

  bool _pendingOnbUsageAdvance = false;
  bool _usageTogglePending = false;

  /// Bônus de +15 folhas por fechar o dia abaixo da meta (contrato de produto §5).
  static const underGoalBonus = 15;

  // --- progressao --------------------------------------------------------

  /// XP acumulado. **Nunca diminui.**
  int xp = 0;

  /// Total de sessoes de foco concluidas na vida da conta.
  int sessoesConcluidas = 0;

  /// A melhor sequencia ja feita. Guardada a parte de [streak] porque marco
  /// conquistado nao se perde quando a sequencia atual cai.
  int melhorSequencia = 0;

  /// Dias fechados abaixo da meta, no total.
  int diasAbaixoDaMeta = 0;

  /// Marcos cujo premio ja foi creditado. Resgate e idempotente: um marco
  /// pago duas vezes seria dinheiro impresso.
  Set<String> marcosResgatados = {};

  /// Marcos alcancados que ainda nao viraram celebracao na tela.
  List<Marco> marcosACelebrar = [];

  /// Nivel ja comemorado, para saber se houve subida nova.
  int nivelCelebrado = 1;

  ProgressoDaTrilha get progresso => ProgressoDaTrilha(
        xp: xp,
        sessoesConcluidas: sessoesConcluidas,
        melhorSequencia: melhorSequencia,
        diasAbaixoDaMeta: diasAbaixoDaMeta,
        // Piso de posse para quem já recebeu.
        //
        // Espécie e habitat são **derivados** da trilha, não gravados. Ao
        // virar a chave para a corrente linear, uma conta que ganhou o
        // axolote e a Serra por fora de ordem perderia os dois — punição
        // retroativa por uma mudança nossa, que o contrato proíbe.
        //
        // `entregues` é piso: não devolve o ✓ nem recria buraco na
        // corrente, só impede que o que já foi entregue seja tomado de
        // volta.
        entregues: marcosResgatados,
      );

  int get nivel => progresso.nivel;
  double get progressoNoNivel => Balanco.progressoNoNivel(xp);
  int get xpParaProximoNivel => Balanco.faltaParaProximoNivel(xp);
  Marco? get proximoMarco => progresso.proximoMarco;
  Set<Species> get especiesLiberadas => progresso.especiesLiberadas(species);

  /// A pessoa pode trocar para esta espécie agora.
  ///
  /// Duas regras, e o que separa as duas é **o momento**:
  ///
  /// - **No onboarding**, as quatro de origem estão abertas. O quiz sugere
  ///   um bicho; a tela de revelação existe justamente para a pessoa dizer
  ///   "não, quero a coruja". Gatear ali transformaria a sugestão em
  ///   sentença.
  /// - **Depois**, vale a trilha. A lontra, a tartaruga e a coruja são
  ///   recompensa de degrau — abrir as quatro para sempre esvaziaria três
  ///   deles, e o axolote, o pinguim, a gata, a raposa e o buldogue só
  ///   chegam subindo.
  /// As espécies que a tela deve oferecer agora.
  ///
  /// Derivada de [podeEscolher] de propósito. A primeira versão passava
  /// `especiesLiberadas` para o seletor e `podeEscolher` para a guarda —
  /// os dois discordavam no onboarding, a lontra aparecia com cadeado e o
  /// toque não fazia nada. Porta e vitrine têm de vir da mesma regra.
  Set<Species> get especiesEscolhiveis =>
      Species.values.where(podeEscolher).toSet();

  bool podeEscolher(Species s) {
    if (!companionshipStarted) {
      return ProgressoDaTrilha.deOrigem.contains(s);
    }
    return especiesLiberadas.contains(s);
  }
  int get estagioDoHabitat => progresso.estagioDoHabitat;
  List<HabitatDaTrilha> get habitatsLiberados => progresso.habitatsLiberados;

  // --- habitat da trilha -------------------------------------------------

  /// Prefixo do habitat dentro de [equipados] e [owned].
  ///
  /// **Não há campo próprio no snapshot de propósito**: `AppSnapshot` é
  /// território compartilhado e mexer nele agora colide com outra frente. O
  /// par `owned` + `equipados` já carrega exatamente a semântica que falta —
  /// "isto é da conta" e "isto está em uso" —, já é gravado no aparelho e já
  /// sobe para `baru_inventory_items`, cujo `check` de ids fechados foi
  /// removido na migration 11. O prefixo garante que nada colida com id de
  /// item da loja, e `itemPorId` devolve nulo para ele, então cena, loja e
  /// guarda-roupa ignoram a linha inteira.
  static const _prefixoDeHabitat = 'habitat:';

  /// O habitat escolhido à mão, se a pessoa escolheu algum.
  String? get habitatEscolhido {
    for (final id in equipados) {
      if (id.startsWith(_prefixoDeHabitat)) {
        return id.substring(_prefixoDeHabitat.length);
      }
    }
    return null;
  }

  /// Onde o companheiro mora agora.
  ///
  /// Sem escolha, vale o mais alto já aberto: subir de marco **muda o lugar
  /// sozinho**, que é como a arena do Clash Royale troca. Uma escolha
  /// explícita ganha — mas só enquanto continuar liberada, para um snapshot
  /// de outro aparelho (ou uma trilha que ainda não chegou lá) não conseguir
  /// mostrar um cenário que esta conta não conquistou.
  HabitatDaTrilha get habitatAtivo {
    final escolhido = habitatEscolhido;
    if (escolhido != null && progresso.habitatLiberado(escolhido)) {
      return habitatPorId(escolhido)!;
    }
    return progresso.habitatDoTopo;
  }

  /// Muda de habitat. Silencioso quando o lugar ainda não foi aberto: a UI
  /// não oferece o toque, e uma chamada fora de hora não pode virar cenário.
  void escolheHabitat(String id) {
    if (!progresso.habitatLiberado(id)) return;
    final chave = '$_prefixoDeHabitat$id';
    // Um habitat por vez, como o cenário da loja: guardar os antigos só
    // encheria o inventário remoto de linha morta.
    equipados = {...equipados}
      ..removeWhere((e) => e.startsWith(_prefixoDeHabitat))
      ..add(chave);
    owned = [
      ...owned.where((e) => !e.startsWith(_prefixoDeHabitat)),
      chave,
    ];
    _markSync(_syncShop);
    notifyListeners();
  }

  /// Houve subida de nivel ainda nao comemorada?
  bool get subiuDeNivel => nivel > nivelCelebrado;

  /// A chegada do dia ainda não foi comemorada.
  ///
  /// Abrir o app é o gesto que o Baru mais espera, e ele passava em
  /// silêncio. Uma vez por dia — não a cada volta do background, senão vira
  /// interrupção — a chegada ganha a mesma cena de conquista que já existe.
  bool chegadaACelebrar = false;

  /// Existe alguma conquista esperando celebração?
  ///
  /// A ordem importa: conquista real vem antes da saudação. Quem subiu de
  /// nível quer ver o nível, não "bom te ver".
  bool get temCelebracaoPendente =>
      subiuDeNivel || marcosACelebrar.isNotEmpty || chegadaACelebrar;

  /// A celebração entrou em cena. O som acompanha a animação, não o clique de
  /// fechar — quem fecha já viu a conquista.
  void anunciaCelebracao() {
    unawaited(SomService.instance.toca(SomDoBaru.conquista));
  }

  /// O nível vem antes do marco: subir de nível é a conquista maior, e as duas
  /// costumam cair juntas.
  void celebrou() {
    if (subiuDeNivel) {
      nivelCelebrado = nivel;
      _markSync(_syncSession);
      notifyListeners();
      return;
    }
    if (marcosACelebrar.isNotEmpty) {
      marcosACelebrar = marcosACelebrar.sublist(1);
      notifyListeners();
      return;
    }
    if (chegadaACelebrar) {
      chegadaACelebrar = false;
      notifyListeners();
    }
  }

  /// Credita XP e colhe os marcos que isso destravou.
  ///
  /// Todo ganho de XP passa por aqui: e o unico lugar que confere a trilha
  /// depois, e marco alcancado sem premio creditado e exatamente a mentira que
  /// este turno esta consertando.
  void ganhaXp(int quanto) {
    if (quanto <= 0) return;
    xp += quanto;
    _colheMarcos();
    _markSync(_syncSession | _syncShop | _syncProgresso);
  }

  /// Um afago completo.
  ///
  /// O vínculo sobe sempre — carinho não tem teto. O **XP** tem: sem teto,
  /// esfregar a tela seria a forma mais barata de subir de nível, e o app
  /// passaria a recompensar isso em vez de foco. Passado o teto ele continua
  /// reagindo na tela; só não paga mais.
  ///
  /// Devolve o XP creditado, para a tela poder mostrar o "+3" só quando ele
  /// existe.
  int recebeCarinho() {
    afeto += 1;
    unawaited(SomService.instance.toca(SomDoBaru.carinho));
    var ganho = 0;
    if (carinhosHoje < Balanco.carinhosPorDia) {
      carinhosHoje += 1;
      ganho = Balanco.xpPorCarinho;
      ganhaXp(ganho);
    }
    _markSync(_syncProgresso);
    notifyListeners();
    return ganho;
  }

  /// Credita o premio dos marcos recem-alcancados.
  void _colheMarcos() {
    for (final m in progresso.alcancados) {
      if (marcosResgatados.contains(m.id)) continue;
      marcosResgatados = {...marcosResgatados, m.id};
      leaves += m.recompensa.folhas;
      marcosACelebrar = [...marcosACelebrar, m];
    }
  }

  // --- missoes -----------------------------------------------------------

  /// Minutos de foco somados hoje.
  int minutosDeFocoHoje = 0;

  /// A sessao mais longa de hoje, em minutos.
  int maiorSessaoHoje = 0;

  // --- missão do descanso -------------------------------------------------
  //
  // O descanso não é um cronômetro. Com o app em segundo plano o Flutter não
  // executa (ADR-014), e um contador que só andasse com a tela do Baru
  // aberta mediria o contrário do que a missão pede. É uma subtração do que
  // já se mede: relógio de parede, menos tempo de tela, menos o tempo dentro
  // do próprio Baru.

  /// Quando a tentativa em curso começou. `null` = ninguém descansando.
  DateTime? descansoComecouEm;

  /// O total de tela do dia no instante em que a tentativa começou.
  int descansoTelaNoInicio = 0;

  /// Quanto o Baru esteve em primeiro plano desde o começo da tentativa.
  ///
  /// O próprio Baru é excluído da contabilidade de tela, então este número
  /// não existe em lugar nenhum além do ciclo de vida do app. Olhar o Baru
  /// não rompe o descanso de propósito: se rompesse, conferir quanto falta
  /// acabaria com o que se estava conferindo.
  Duration descansoNoApp = Duration.zero;

  /// O melhor descanso de hoje. Só sobe — progresso não decai.
  Duration melhorDescansoHoje = Duration.zero;

  DateTime? _voltouAoAppEm;

  /// O presente de retorno já creditado, esperando virar recado na tela.
  VoltaAoNinho? voltaPendente;

  /// Sessoes, minutos e dias abaixo da meta da semana corrente.
  int sessoesNaSemana = 0;
  int minutosNaSemana = 0;
  int diasAbaixoNaSemana = 0;

  /// Chaves de missao ja resgatadas, com o periodo dentro. Resgate e
  /// idempotente: tocar duas vezes nao paga duas vezes.
  Set<String> missoesResgatadas = {};

  /// Missoes concluidas que ainda nao viraram animacao na tela.
  List<String> missoesACelebrar = [];

  static const _quadro = QuadroDeMissoes();

  ContadoresDeMissao get contadoresDeMissao => ContadoresDeMissao(
        sessoesHoje: completedToday,
        minutosHoje: minutosDeFocoHoje,
        maiorSessaoHoje: maiorSessaoHoje,
        fechouAbaixoHoje: usageAccess && usage < goal,
        dispersivoHoje: resumoTela?.dispersivo.inMinutes,
        neutroHoje: resumoTela?.neutro.inMinutes,
        produtivoHoje: resumoTela?.produtivo.inMinutes,
        sessoesNaSemana: sessoesNaSemana,
        minutosNaSemana: minutosNaSemana,
        diasAbaixoNaSemana: diasAbaixoNaSemana,
        temPermissaoDeUso: usageAccess,
        carinhosHoje: carinhosHoje,
        faixasDeFocoHoje: _faixasDeFocoHoje,
        // "Faltou" é ter passado um dia inteiro fora, não ter aberto ontem à
        // noite e hoje de manhã. `daysAway` já é isso, calculado da data e
        // não de um contador que se acumula (ADR-006).
        voltouDepoisDeFaltar: daysAway >= 1,
      );

  /// Em quantos períodos do dia houve foco **concluído** hoje.
  ///
  /// Sai de `sessions`, que já é persistido, sincronizado e restaurado — não
  /// precisou de campo novo, de migração nem de mexer no `row_codec`. É a
  /// mesma fonte que `horarioDoHabito` lê para aprender a hora do lembrete.
  ///
  /// Só as concluídas: uma sessão abandonada às 8h não é foco da manhã, e
  /// contá-la deixaria a missão de variedade de horário ser cumprida
  /// começando e desistindo em três horários diferentes.
  int get _faixasDeFocoHoje => faixasDeFoco(
        sessions.where((s) => s.completed).map((s) => s.at),
        dia: lastOpenDate,
      );

  /// As missoes de hoje. Sorteio deterministico por conta e data.
  List<Missao> get missoes => _quadro.doDia(
        dia: lastOpenDate,
        conta: _sementeDaConta,
        contadores: contadoresDeMissao,
        resgatadas: missoesResgatadas,
      );

  /// Semente estavel por conta: as missoes do dia sao as mesmas em qualquer
  /// aparelho, sem precisar sincronizar a escolha.
  String get _sementeDaConta =>
      BaruSupabase.instance.currentUserEmail ?? 'local';

  List<Missao> get missoesDiarias =>
      missoes.where((m) => m.ritmo == RitmoDaMissao.diaria).toList();

  List<Missao> get missoesSemanais =>
      missoes.where((m) => m.ritmo == RitmoDaMissao.semanal).toList();

  /// A missão da retomada, só no dia em que a pessoa volta depois de faltar.
  ///
  /// Fica fora do sorteio (ver `defDaRetomada`) e por isso fora de [missoes]:
  /// quem desenha decide se há o que desenhar.
  Missao? get missaoDeRetomada => _quadro.aRetomada(
        dia: lastOpenDate,
        contadores: contadoresDeMissao,
        resgatadas: missoesResgatadas,
      );

  /// Quantas há para colher agora, incluindo a da retomada.
  ///
  /// O distintivo da home lê daqui. Deixar a retomada de fora faria a home
  /// dizer "nada para colher" com folha parada na tela ao lado — e é
  /// justamente no dia da volta que o empurrão importa.
  int get missoesResgataveis =>
      missoes.where((m) => m.resgatavel).length +
      ((missaoDeRetomada?.resgatavel ?? false) ? 1 : 0);

  /// Recolhe o premio de uma missao concluida.
  ///
  /// Idempotente por construcao: a chave inclui o periodo e entra no conjunto
  /// antes de qualquer credito.
  void resgataMissao(Missao m) {
    if (!m.resgatavel) return;
    final chave = QuadroDeMissoes.chaveDeResgate(m.definicao, lastOpenDate);
    if (missoesResgatadas.contains(chave)) return;
    missoesResgatadas = {...missoesResgatadas, chave};
    _markSync(_syncProgresso);
    leaves += m.folhas;
    missoesACelebrar = [...missoesACelebrar, m.id];
    ganhaXp(m.xp);
    unawaited(SomService.instance.toca(SomDoBaru.resgate));
    _markSync(_syncShop | _syncSession);
    notifyListeners();
  }

  /// Consome o aviso de missao concluida depois de a tela anima-lo.
  void celebrouMissao(String id) {
    if (!missoesACelebrar.contains(id)) return;
    missoesACelebrar = [...missoesACelebrar]..remove(id);
    notifyListeners();
  }

  /// Detalhamento do tempo de tela de hoje. `null` = ainda não medido ou sem
  /// permissão — a tela mostra estado vazio honesto, nunca um número chutado.
  ResumoDeTela? resumoTela;

  /// Reclassificações feitas à mão pelo usuário. Ganham da tabela embutida.
  Map<String, CategoriaDeApp> ajustesDeCategoria = {};

  /// Bônus já creditados que ainda não viraram aviso na tela. Não vai para o
  /// snapshot: as folhas já estão em [leaves], isto é só o recado pendente.
  int pendingUnderGoalBonus = 0;

  /// A pilha de navegação, da raiz ao topo. Nunca vazia.
  ///
  /// Antes existia só uma variável `screen`: sem pilha o botão voltar do
  /// Android não tinha o que fazer e fechava o app em qualquer tela.
  final List<AppScreen> _pilha = [AppScreen.onb];

  /// A tela no topo.
  AppScreen get screen => _pilha.last;

  List<AppScreen> get pilha => List.unmodifiable(_pilha);
  int onb = 0;
  String lang = 'pt';
  Species species = Species.capybara;
  String? q0;
  String? q1;
  String? q2;
  int leaves = 0;
  int streak = 0;
  int usage = 0;
  int goal = 180;
  int avg = 240;
  String petName = '';
  int color = 0;
  List<String> owned = [];
  int dur = 25;
  int remaining = 0;
  bool running = false;
  bool confirming = false;
  int completedToday = 0;
  bool abandonedToday = false;

  /// Vínculo: afagos completos de todos os tempos. Só sobe.
  int afeto = 0;

  /// Afagos que já renderam XP hoje. Zera na virada do calendário.
  int carinhosHoje = 0;
  int daysAway = 0;
  int reward = 0;
  bool aborted = false;
  bool trial = false;
  bool evening = true;

  /// A que horas o relatório da noite chega. Era fixo em 21h no código.
  int eveningHour = 21;
  int eveningMinute = 0;

  /// O sexo do companheiro. Muda o pronome, não o desenho.
  Sexo sexo = Sexo.naoDito;

  /// Som ligado. Um app de foco que apita sem permissão é distração.
  bool som = true;
  bool missed = true;
  bool sharing = false;
  PayPlan payPlan = PayPlan.annual;

  /// Comprime o relógio da sessão em 60× (contrato de produto §12).
  ///
  /// Fica porque um teste de sessão de 90 minutos que roda em 90 minutos não
  /// é teste. `kDebugMode` é a barreira, e é real: o compilador de release
  /// resolve a constante para `false` e **não existe mais nada no app que
  /// escreva neste campo** — o botão que a virava saiu junto com o painel de
  /// depuração. Num APK de release a sessão de 25 minutos dura 25 minutos,
  /// sem caminho de volta.
  bool debugFast = kDebugMode;
  bool usageAccess = false;
  bool companionshipStarted = false;
  List<WeekDayKind> week = freshWeek();
  int todayIndex = weekdayIndex();
  int freezesLeft = 1;
  DateTime? trialStartedAt;

  /// Início e fim da sessão em curso, em relógio de parede. `null` = sem
  /// sessão. Persistidos: são o que permite retomar depois de o app ser morto.
  ///
  /// Guardar as duas pontas — em vez de só o fim — deixa a duração real da
  /// sessão explícita no dado. Sem isso, o restante exibido teria de ser
  /// deduzido a partir da flag de debug 60×, e uma sessão gravada com a flag
  /// num estado e lida com ela noutro sairia com o contador errado.
  DateTime? sessionStartedAt;
  DateTime? sessionEndsAt;

  /// Duração escolhida quando a sessão começou. Guardada à parte de [dur]
  /// para que mudar o chip de duração não altere uma sessão já em andamento.
  int sessionDur = 0;

  DateTime lastOpenDate = dateOnly(DateTime.now());
  List<SessionRecord> sessions = [];

  Timer? _timer;
  Timer? _saveTimer;
  int _syncMask = 0;
  bool _persisting = false;
  bool _syncFailNotified = false;

  /// Tabelas que o remoto não tem. Uma por episódio, e sem repetir: o aviso
  /// de schema desatualizado é acionável, o de rede não.
  final Set<String> _tabelasAusentesAvisadas = {};

  /// O usuário apertou voltar na home. A tela pergunta antes de deixar o
  /// sistema fechar o app.
  bool pedindoParaSair = false;

  void cancelaSaida() {
    if (!pedindoParaSair) return;
    pedindoParaSair = false;
    _notifyEfemero();
  }

  /// Quais domínios falharam no último episódio. Vazio quando está tudo bem.
  ///
  /// Existe porque "não foi possível sincronizar" sozinho não dá para
  /// investigar: são treze tabelas em seis domínios.
  String ultimoErroDeSync = '';

  static const _syncPet = 1;
  static const _syncShop = 2;
  static const _syncSession = 4;
  static const _syncSettings = 8;
  static const _syncTrial = 16;
  static const _syncProgresso = 32;
  static const _syncAll =
      _syncPet |
      _syncShop |
      _syncSession |
      _syncSettings |
      _syncTrial |
      _syncProgresso;

  void _markSync(int mask) => _syncMask |= mask;

  /// Repinta a tela sem gravar nem sincronizar.
  ///
  /// Para o que não vive no snapshot: folha de compartilhamento, confirmação
  /// de saída, a pergunta do quiz em que a tela está. Passar essas mudanças
  /// pelo `notifyListeners` normal
  /// disparava uma gravação e — como a máscara ficava vazia e máscara vazia
  /// significa "empurre tudo" — um push das 13 tabelas só para abrir a folha
  /// de compartilhamento.
  void _notifyEfemero() => super.notifyListeners();

  T get t => T(lang);

  bool get canSignOut =>
      BaruEnv.supabaseEnabled && BaruSupabase.instance.isEmailUser;

  /// O e-mail da conta, ou vazio quando não há conta.
  String get emailDaConta => BaruSupabase.instance.currentUserEmail ?? '';

  bool get emailConfirmado => BaruSupabase.instance.emailConfirmado;

  DateTime? get contaCriadaEm => BaruSupabase.instance.contaCriadaEm;

  /// Resultado de uma operação de conta: nulo deu certo, texto é o erro já
  /// traduzido.
  Future<String?> trocaEmail(String novo) async {
    if (!_emailValido(novo)) return t.contaEmailInvalido;
    try {
      await BaruSupabase.instance.trocaEmail(novo);
      return null;
    } catch (e) {
      return translateAuthError(e, lang);
    }
  }

  Future<String?> trocaSenha(String nova) async {
    if (nova.length < 6) return t.contaSenhaCurta;
    try {
      await BaruSupabase.instance.trocaSenha(nova);
      return null;
    } catch (e) {
      return translateAuthError(e, lang);
    }
  }

  Future<String?> recuperaSenha() async {
    final email = emailDaConta;
    if (email.isEmpty) return t.contaSemConta;
    try {
      await BaruSupabase.instance.recuperaSenha(email);
      return null;
    } catch (e) {
      return translateAuthError(e, lang);
    }
  }

  static bool _emailValido(String e) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e.trim());

  /// Apaga tudo: no aparelho e no servidor.
  ///
  /// Existe porque não existia. "Refazer o onboarding" zerava a tela e
  /// deixava sessões, folhas e progresso onde estavam — e no navegador o
  /// snapshot mora no `localStorage`, então limpar o banco não adiantava
  /// nada: o app reenviava tudo no salvamento seguinte.
  ///
  /// A ordem importa. **Primeiro o local**, porque enquanto ele existir
  /// qualquer gravação recoloca o dado no servidor.
  ///
  /// Devolve nulo se limpou; texto de erro se algo ficou.
  Future<String?> apagaMeusDados() async {
    // 1. Para de gravar. Um debounce em voo depois do apagamento reescreveria
    //    tudo de volta.
    _saveTimer?.cancel();
    _timer?.cancel();

    // 2. O aparelho. A credencial lembrada some junto: apagar tudo e
    //    deixar a senha no cofre seria deixar a porta aberta.
    await cofre.esquece();
    await repos?.clearSnapshot();

    // 3. O servidor.
    final falharam = await BaruSupabase.instance.apagaTudoDoUsuario();

    // 4. O estado em memória volta ao zero, senão o próximo `notifyListeners`
    //    grava o que ainda está aqui dentro.
    _zeraTudo();
    _syncMask = 0;
    notifyListeners();

    if (falharam.isEmpty) return null;
    if (falharam.length == 1 && falharam.first == 'sem_sessao') {
      // Sem conta: o local foi apagado e é tudo o que havia.
      return null;
    }
    return t.fill(t.contaApagarFalhou, {'q': falharam.join(', ')});
  }

  /// Volta ao estado de app recém-instalado.
  void _zeraTudo() {
    final idioma = lang;
    _applySnapshot(AppSnapshot.zerado(lang: idioma));
    perguntaAtual = 0;
    _restauraPilha(AppScreen.onb);
  }

  Duration get _noAppAgora {
    final desde = _voltouAoAppEm;
    if (desde == null || descansoComecouEm == null) return descansoNoApp;
    return descansoNoApp + DateTime.now().difference(desde);
  }

  LeituraDoDescanso? get leituraDoDescanso {
    final inicio = descansoComecouEm;
    final resumo = resumoTela;
    // Sem medição não há leitura: o app não estima tempo de tela.
    if (inicio == null || resumo == null) return null;
    return leDescanso(
      comecouEm: inicio,
      agora: DateTime.now(),
      minutosDeTelaNoInicio: descansoTelaNoInicio,
      minutosDeTelaAgora: resumo.minutosTotais,
      noProprioApp: _noAppAgora,
    );
  }

  MissaoDoDescanso get missaoDoDescanso => MissaoDoDescanso(
        melhorDoDia: melhorDescansoHoje,
        emCurso: leituraDoDescanso,
        resgatada: missoesResgatadas
            .contains(MissaoDoDescanso.chaveDeResgate(lastOpenDate)),
        temPermissaoDeUso: usageAccess,
      );

  void comecaODescanso() {
    descansoComecouEm = DateTime.now();
    descansoTelaNoInicio = resumoTela?.minutosTotais ?? 0;
    descansoNoApp = Duration.zero;
    _voltouAoAppEm = DateTime.now();
    _markSync(_syncSession);
    unawaited(_comecaAVigiarODescanso());
    notifyListeners();
  }

  void desisteDoDescanso() {
    final l = leituraDoDescanso;
    if (l != null) melhorDescansoHoje = melhorDescanso(melhorDescansoHoje, l);
    _fechaODescanso();
    notifyListeners();
  }

  void _fechaODescanso() {
    descansoComecouEm = null;
    descansoNoApp = Duration.zero;
    _markSync(_syncSession);
    unawaited(VigiaService.instance.para());
  }

  /// Reconcilia o descanso com o relógio e com o medidor de tela.
  ///
  /// Chamada depois de `resumoTela` ser atualizado: é o único instante em
  /// que a fuga se torna mensurável, e é o mesmo instante em que a pessoa
  /// volta para ver o estrago.
  void reconciliaODescanso() {
    final l = leituraDoDescanso;
    if (l == null) return;
    melhorDescansoHoje = melhorDescanso(melhorDescansoHoje, l);
    if (l.acabou) {
      onUserMessage?.call(recadoDoDescanso(t, missaoDoDescanso));
      _fechaODescanso();
    }
    _markSync(_syncSession);
  }

  void resgataODescanso() {
    final m = missaoDoDescanso;
    if (!m.resgatavel) return;
    final chave = MissaoDoDescanso.chaveDeResgate(lastOpenDate);
    if (missoesResgatadas.contains(chave)) return;
    missoesResgatadas = {...missoesResgatadas, chave};
    leaves += m.folhas;
    ganhaXp(m.xp);
    unawaited(SomService.instance.toca(SomDoBaru.resgate));
    _markSync(_syncProgresso | _syncShop | _syncSession);
    notifyListeners();
  }

  /// O companheiro por cima do app onde a pessoa foi parar.
  ///
  /// Fala de descanso, não de foco: são missões diferentes, e o texto de
  /// uma no lugar da outra confunde quem está lendo de relance.
  Future<void> _comecaAVigiarODescanso() async {
    if (!await OverlayService.instance.temPermissao()) {
      onUserMessage?.call(t.vigiaSemPermissao);
      return;
    }
    await VigiaService.instance.comeca(
      fala: t.descansoVigiaFala,
      // Mesma fala por app do foco (S-03). Faz ainda mais falta aqui: no
      // descanso, sair para outro app **é** o evento, e dizer sempre a
      // mesma frase transformaria o companheiro em despertador.
      falasPorPacote: falasPorPacote(t),
      pelo: AppColors.pelagemDe(species, color).toARGB32(),
      especie: species.name,
      acaoFechar: t.sobreFechar,
      acaoMais: t.sobreMais,
      notifTitulo: t.fill(t.descansoVigiaTitulo, {'n': displayName}),
      notifCorpo: t.descansoVigiaCorpo,
    );
  }

  /// O Baru saiu de primeiro plano.
  ///
  /// É o que faz `descansoNoApp` existir: sem estas duas chamadas, ficar
  /// olhando o bicho contaria como descanso.
  void saiuDoApp() {
    final desde = _voltouAoAppEm;
    if (desde != null && descansoComecouEm != null) {
      descansoNoApp += DateTime.now().difference(desde);
    }
    _voltouAoAppEm = null;
  }

  void voltouAoApp() => _voltouAoAppEm = DateTime.now();

  /// O cofre da credencial lembrada.
  ///
  /// Injetável para o teste; em produção é o do Keystore. Sair da conta e
  /// apagar os dados têm de esvaziá-lo — senão a senha sobrevive à saída e
  /// o próximo a pegar o aparelho entra com a digital dele.
  Cofre cofre = CofreSeguro();

  Future<void> signOut() async {
    if (!canSignOut) return;
    await BaruSupabase.instance.signOut();
    await repos?.clearSnapshot();
    await cofre.esquece();
  }

  String get displayName =>
      petName.isEmpty ? petNames[species]! : petName;

  /// A chave de texto do humor. Delegada a `chaveDoHumor` para que a fala
  /// enriquecida e o catálogo antigo nunca discordem de qual chave é qual —
  /// duas tabelas iguais mantidas à mão divergem na primeira mexida.
  String get moodKey => chaveDoHumor(mood);

  /// Os fatos medidos que explicam o humor de hoje.
  ///
  /// Só medição: nada aqui é estimado. `usageAccess` é o mesmo portão que o
  /// [mood] usa para olhar tempo de tela, então cena e legenda leem o dia da
  /// mesma fonte.
  FatosDoHumor get fatosDoHumor => FatosDoHumor(
        humor: mood,
        nomeDoPet: displayName,
        temMedicaoDeTela: usageAccess,
        minutosDeTela: usage,
        meta: goal,
        sessoesHoje: completedToday,
        minutosDeFocoHoje: minutosDeFocoHoje,
        desistiuHoje: abandonedToday,
        minutosDaDesistencia: _minutosDaDesistenciaDeHoje,
        diasFora: daysAway,
        raiz: streak,
        maiorRaiz: melhorSequencia,
        folhas: leaves,
        minutosDispersivos: resumoTela?.dispersivo.inMinutes,
      );

  /// A fala do humor: qual texto a home mostra, e com que números.
  FalaDoHumor get falaDoHumor {
    garanteTextosDoHumor();
    return escolheAFala(fatosDoHumor, t);
  }

  /// Quanto durava a sessão que parou no meio hoje.
  ///
  /// Sai de `sessions`, não de `sessionDur`: quem desiste de 25 min e depois
  /// completa 50 deixa `sessionDur` em 50, e a legenda diria que a sessão
  /// interrompida tinha 50 min. `null` quando não há registro — e aí a fala
  /// omite o número em vez de inventar um.
  int? get _minutosDaDesistenciaDeHoje {
    final hoje = dateOnly(lastOpenDate);
    for (final s in sessions.reversed) {
      if (!s.aborted) continue;
      if (dateOnly(s.at) != hoje) continue;
      return s.dur;
    }
    return null;
  }

  /// A última sessão registrada hoje, concluída ou não.
  ///
  /// Lê `sessions` de trás para frente porque o log é cronológico por
  /// construção — `_logSession` só acrescenta —, o mesmo idioma que
  /// [_minutosDaDesistenciaDeHoje] já usa.
  SessionRecord? get _ultimaSessaoDeHoje {
    final hoje = dateOnly(lastOpenDate);
    for (final s in sessions.reversed) {
      if (dateOnly(s.at) == hoje) return s;
    }
    return null;
  }

  /// A desistência de hoje ainda está de pé?
  ///
  /// [abandonedToday] continua sendo o **registro do dia**, e não muda de
  /// significado: vai para o snapshot, para `baru_daily_progress`, para o
  /// relatório e para as missões. Um fato que aconteceu não se apaga.
  ///
  /// O humor, porém, não é o extrato do dia — é o estado agora. Enquanto esta
  /// pergunta era simplesmente `abandonedToday`, parar uma sessão às nove da
  /// manhã deixava o bicho triste até a meia-noite, por mais sessões que a
  /// pessoa concluísse depois: um tropeço custava o dia inteiro. O contrato
  /// §1 diz o contrário com todas as letras — "abandonar uma sessão = sem
  /// recompensa, **nada mais**" — e um dia inteiro de tristeza é bem mais do
  /// que nada mais.
  ///
  /// A regra é a mais simples que devolve o bicho sem apagar o fato: vale a
  /// **última** sessão de hoje. Concluiu depois de parar, ele volta; parou
  /// depois de concluir, ele sente — e a sessão seguinte o traz de volta de
  /// novo. Descartei "qualquer sessão concluída perdoa", que deixaria uma
  /// desistência das cinco da tarde invisível, e "a sessão nova tem de ser
  /// pelo menos tão longa quanto a que parou", que é uma barra para transpor,
  /// isto é, exatamente a punição que o contrato proíbe.
  bool get desistenciaEmAberto {
    if (!abandonedToday) return false;
    final ultima = _ultimaSessaoDeHoje;
    if (ultima != null) return ultima.aborted;
    // Sem registro no log — snapshot antigo, corte das 80 últimas, linha
    // vinda de outro aparelho — sobra o contador do dia, que chega no mesmo
    // snapshot que `abandonedToday` e portanto some junto com ele ou com ele
    // sobrevive.
    return completedToday == 0;
  }

  String get speciesKey => species.name;

  /// O humor sai **só** dos fatos medidos, na ordem do contrato §3.
  ///
  /// Havia um `overrideMood` na frente desta cadeia: o painel de depuração
  /// escrevia nele e a cena inteira — bicho, atividade, legenda, ícone —
  /// passava a descrever um dia que não aconteceu. Era a porta dos fundos
  /// mais cara do app, porque o humor é o que o produto afirma sobre a
  /// pessoa. Sem ela não há como a tela mentir: se o humor mudou, algum
  /// destes fatos mudou.
  ///
  /// A primeira linha lê [desistenciaEmAberto], e não `abandonedToday` cru:
  /// ver o porquê lá.
  Mood get mood {
    if (desistenciaEmAberto || daysAway >= 2) return Mood.missingYou;
    if (!usageAccess) {
      return completedToday >= 1 ? Mood.radiant : Mood.content;
    }
    if (usage < goal && completedToday >= 1) return Mood.radiant;
    if (usage < goal || completedToday >= 1) return Mood.content;
    if (usage <= goal * 1.2) return Mood.neutral;
    return Mood.sleepy;
  }

  Activity get activity {
    switch (mood) {
      case Mood.sleepy:
      case Mood.neutral:
        return Activity.nap;
      case Mood.radiant:
        return Activity.swim;
      case Mood.content:
        return Activity.graze;
      case Mood.missingYou:
        return Activity.idle;
    }
  }

  /// A faixa de tabs some em tela de detalhe e em modal.
  bool get showTabs =>
      screen == AppScreen.home ||
      screen == AppScreen.trilha ||
      screen == AppScreen.missoes ||
      screen == AppScreen.profile;

  /// As respostas do quiz, por id de pergunta. **Id, não rótulo traduzido:**
  /// guardar o texto em português fazia trocar de idioma apagar tudo.
  Map<String, String> respostasDoQuiz = {};

  bool get quizDone => quiz.every((p) => respostasDoQuiz.containsKey(p.id));

  /// Quantas já foram respondidas — a barra de progresso do quiz.
  int get quizRespondidas =>
      quiz.where((p) => respostasDoQuiz.containsKey(p.id)).length;

  /// Em qual pergunta o quiz está.
  ///
  /// Uma por tela: seis perguntas empilhadas numa rolagem só viram um
  /// formulário, e formulário no onboarding é onde se desiste.
  int perguntaAtual = 0;

  PerguntaDoQuiz get perguntaDaVez =>
      quiz[perguntaAtual.clamp(0, quiz.length - 1)];

  bool get ehUltimaPergunta => perguntaAtual >= quiz.length - 1;

  /// O quanto do quiz já foi andado, de 0 a 1.
  double get fracaoDoQuiz =>
      quiz.isEmpty ? 1 : quizRespondidas / quiz.length;

  /// Volta uma pergunta. `false` quando já está na primeira.
  bool voltaPergunta() {
    if (perguntaAtual <= 0) return false;
    perguntaAtual -= 1;
    _notifyEfemero();
    return true;
  }

  bool get underGoal => usage < goal;
  bool get onGoal => usage == goal;
  bool get overGoal => usage > goal;

  bool get underGoalQuestDone => usageAccess && usage < goal;

  int get trialDaysLeft {
    final paid = dateOnly(paidPlanStart);
    final today = dateOnly(DateTime.now());
    final n = paid.difference(today).inDays;
    if (n < 0) return 0;
    if (n > 7) return 7;
    return n;
  }

  DateTime get paidPlanStart {
    final start = dateOnly(trialStartedAt ?? DateTime.now());
    return start.add(const Duration(days: 7));
  }

  /// Texto do catálogo já com o pronome do companheiro resolvido.
  ///
  /// `{p}` vira ele/ela, `{P}` a versão com maiúscula, `{d}` dele/dela.
  String frase(String bruto, [Map<String, Object> vars = const {}]) =>
      t.comPronome(bruto, sexo, vars);

  String get streakText => t.streakLabel(streak);

  String get usageShortLabel {
    if (onGoal) return t.usageEven;
    if (underGoal) return t.fill(t.usageLeft, {'x': fmt(goal - usage)});
    return t.fill(t.usageOver, {'x': fmt(usage - goal)});
  }

  String get usageVerdict {
    if (onGoal) return t.repEven;
    if (underGoal) return t.fill(t.repUnder, {'x': fmt(goal - usage)});
    return t.fill(t.repOver, {'x': fmt(usage - goal)});
  }

  ShopItemDef? get nextItem {
    final pending = shopItems.where((i) => !owned.contains(i.id)).toList()
      ..sort((a, b) => a.price.compareTo(b.price));
    return pending.isEmpty ? null : pending.first;
  }

  String fmt(int min) => fmtMinutes(min, lang);

  Species resolveSpecies() => especiePelasRespostas(respostasDoQuiz);

  /// Os pacotes que o usuário disse que roubam o foco dele. Vira dica na tela
  /// de tempo de tela antes mesmo da primeira medição.
  List<String> get suspeitosDoQuiz => pacotesSuspeitos(respostasDoQuiz);

  void go(AppScreen next) {
    confirming = false;
    _empilha(next);
    notifyListeners();
  }

  /// Onde cada tela entra na pilha. Sai do tipo da rota, não de quem chamou:
  /// assim a mesma tela nunca aparece de dois jeitos diferentes.
  void _empilha(AppScreen next) {
    switch (next.tipo) {
      case TipoDeRota.fluxo:
      case TipoDeRota.destino:
        // Trocar de destino zera o ramo. Tocar na aba em que já se está
        // volta à raiz dela — que é o que a barra fixa promete.
        _pilha
          ..clear()
          ..add(next);
      case TipoDeRota.detalhe:
      case TipoDeRota.modal:
        if (_pilha.last == next) return;
        // Um detalhe aberto a partir de um fluxo (o resultado depois da
        // sessão) não pode ficar sem raiz: sem isto o voltar sairia do app.
        if (_pilha.last.tipo == TipoDeRota.fluxo &&
            next.tipo == TipoDeRota.detalhe) {
          _pilha
            ..clear()
            ..add(AppScreen.home);
        }
        // Reabrir a mesma tela por outro caminho não pode deixar duas cópias
        // na pilha.
        _pilha
          ..remove(next)
          ..add(next);
    }
  }

  /// Um passo para trás.
  ///
  /// `false` quer dizer "não há para onde voltar" — só então o sistema
  /// assume, e no Android isso fecha o app.
  bool voltar() {
    if (confirming) {
      confirming = false;
      notifyListeners();
      return true;
    }
    if (_pilha.length > 1) {
      _pilha.removeLast();
      notifyListeners();
      return true;
    }
    final atual = _pilha.single;
    // Voltar durante a sessão não descarta o foco em silêncio: pergunta.
    if (atual == AppScreen.session) {
      askQuit();
      return true;
    }
    // De um destino que não é a home, voltar leva à home antes de sair.
    if (atual.tipo == TipoDeRota.destino && atual != AppScreen.home) {
      _pilha[0] = AppScreen.home;
      notifyListeners();
      return true;
    }
    // Na home, voltar pergunta antes. Fechar sem avisar num app de
    // companhia é justamente o gesto que a companhia não faz.
    if (!pedindoParaSair) {
      pedindoParaSair = true;
      _notifyEfemero();
      return true;
    }
    return false;
  }

  /// O `Navigator` removeu uma página (gesto de voltar do iOS, botão da
  /// AppBar). Mantém a pilha do estado em dia com a de verdade.
  void removeDaPilha(AppScreen tela) {
    if (_pilha.length > 1 && _pilha.last == tela) {
      _pilha.removeLast();
      notifyListeners();
    }
  }

  /// Abre uma tela vinda de fora: deep link, restauração de sessão do
  /// navegador. Reconstrói uma pilha plausível para ela.
  void abrePorEndereco(AppScreen tela) {
    // Quem não terminou o onboarding não entra por link.
    if (_pilha.first == AppScreen.onb && !companionshipStarted) return;
    if (screen == tela) return;
    _restauraPilha(tela);
    notifyListeners();
  }

  void _restauraPilha(AppScreen tela) {
    _pilha.clear();
    switch (tela.tipo) {
      case TipoDeRota.fluxo:
      case TipoDeRota.destino:
        _pilha.add(tela);
      case TipoDeRota.detalhe:
      case TipoDeRota.modal:
        _pilha
          ..add(AppScreen.home)
          ..add(tela);
    }
  }

  void setLang(String id) {
    lang = id;
    // As respostas do quiz **não** são mais apagadas aqui.
    //
    // Elas eram guardadas como rótulo traduzido, então trocar de idioma
    // quebrava a correspondência e o jeito de não mentir era zerar tudo.
    // Agora o que se guarda é o id da opção, que não muda com o idioma.
    _markSync(_syncSettings);
    notifyListeners();
  }

  /// Responde e anda.
  ///
  /// Escolher já avança: um botão "continuar" depois de cada resposta é um
  /// toque a mais em seis telas seguidas. Quem quiser mudar volta.
  void respondeEAvanca(String pergunta, String opcao) {
    pickQuiz(pergunta, opcao);
    if (!ehUltimaPergunta) {
      perguntaAtual += 1;
      _notifyEfemero();
    }
  }

  void pickQuiz(String pergunta, String opcao) {
    respostasDoQuiz = {...respostasDoQuiz, pergunta: opcao};
    // As três primeiras continuam nas colunas antigas, agora com o **id**:
    // elas existiam antes do mapa e não vale migração destrutiva para sumir.
    final i = quiz.indexWhere((p) => p.id == pergunta);
    if (i == 0) q0 = opcao;
    if (i == 1) q1 = opcao;
    if (i == 2) q2 = opcao;
    _markSync(_syncPet);
    notifyListeners();
  }

  void nextOnb() {
    if (onb >= 5) {
      if (!companionshipStarted) startCompanionship();
      go(AppScreen.paywall);
      return;
    }
    if (onb == 2) {
      onb = 3;
      species = resolveSpecies();
      petName = petNames[species]!;
      _markSync(_syncPet | _syncSettings);
      notifyListeners();
      return;
    }
    if (onb == 3) {
      final cleaned = petName.trim();
      petName = cleaned.isEmpty ? petNames[species]! : cleaned;
      onb = 4;
      // A meta sugerida ouve o que a pessoa disse que quer: quem veio por
      // menos tela recebe uma meta mais apertada que quem veio por companhia.
      goal = metaSugerida(avg, fatorDaMeta(respostasDoQuiz));
      _markSync(_syncPet | _syncSettings);
      notifyListeners();
      return;
    }
    onb += 1;
    notifyListeners();
  }

  Future<void> initPlatformServices() async {
    if (kIsWeb) return;
    await BaruNotifications.instance.init();
    // Quem já tinha o app antes dos ícones por espécie nunca passou por
    // `pickSpecies`: sem isto ficaria com a capivara para sempre.
    unawaited(IconeService.instance.usa(species.name));
    await syncPermissionsFromOs(notify: false);
  }

  /// Sincroniza toggles com permissões reais do SO e atualiza tempo de tela.
  Future<void> syncPermissionsFromOs({bool notify = true}) async {
    if (kIsWeb) return;

    var changed = false;
    final osUsage = await UsageService.instance.hasUsageAccess();
    if (usageAccess != osUsage) {
      usageAccess = osUsage;
      _markSync(_syncSettings);
      changed = true;
    }

    if (osUsage) {
      final resumo = await UsageService.instance.resumoDeHoje(
        ajustes: ajustesDeCategoria,
      );
      if (resumo != null) {
        resumoTela = resumo;
        reconciliaODescanso();
        final mins = resumo.minutosContabilizados;
        if (mins != usage) {
          usage = mins;
          _markSync(_syncSettings);
        }
        changed = true;
        unawaited(_talvezApareceSobreOsApps());
      }
    }

    if (_pendingOnbUsageAdvance || _usageTogglePending) {
      _finishUsagePermissionFlow(osUsage);
      changed = true;
    }

    await _syncNotificationSchedules();

    if (notify && changed) notifyListeners();
  }

  /// O companheiro dá um oi por cima do outro app.
  ///
  /// Só quando a meta já estourou — antes disso não há o que dizer — e a
  /// regra de não insistir mora no serviço, não aqui. O texto sai do
  /// catálogo já traduzido: o lado nativo não escreve produto.
  Future<void> _talvezApareceSobreOsApps() async {
    if (!usageAccess || usage <= goal) return;
    final falas = [t.sobreFala1, t.sobreFala2, t.sobreFala3];
    // Varia com o dia para não repetir a mesma frase toda vez.
    final fala = falas[lastOpenDate.day % falas.length];
    await OverlayService.instance.mostra(
      fala: fala,
      pelo: AppColors.pelagemDe(species, color).toARGB32(),
      especie: species.name,
      acaoFechar: t.sobreFechar,
      acaoMais: t.sobreMais,
    );
  }

  /// A recusa foi do sistema, não da pessoa.
  ///
  /// No Android o `PACKAGE_USAGE_STATS` fica travado quando o app veio de
  /// um arquivo, fora da loja: a chave nem liga. Mandar "ative nas
  /// configurações" seria mandar para a tela onde o botão está bloqueado.
  /// Quem escuta isto abre o passo a passo.
  void Function()? aoBloqueioDoSistema;

  void _finishUsagePermissionFlow(bool osUsage) {
    if (_pendingOnbUsageAdvance) {
      _pendingOnbUsageAdvance = false;
      if (osUsage) {
        onUserMessage?.call(t.permUsageGranted);
        nextOnb();
      } else {
        _avisaRecusa();
      }
      return;
    }
    if (_usageTogglePending) {
      _usageTogglePending = false;
      if (osUsage) {
        onUserMessage?.call(t.permUsageGranted);
      } else {
        _avisaRecusa();
      }
    }
  }

  /// Simula a volta da tela do sistema, para o teste.
  ///
  /// O caminho de verdade passa por `MethodChannel` e pelo ciclo de vida do
  /// Android; sem esta costura a regra "recusa abre o passo a passo" só
  /// seria verificável em aparelho.
  @visibleForTesting
  void pedeAcessoDeUsoParaTeste({required bool concedido}) {
    _usageTogglePending = true;
    _finishUsagePermissionFlow(concedido);
  }

  void _avisaRecusa() {
    final abre = aoBloqueioDoSistema;
    if (abre != null) {
      abre();
      return;
    }
    onUserMessage?.call(t.permUsageDenied);
  }

  Future<void> _refreshUsageFromOs({bool notify = true}) async {
    final resumo = await UsageService.instance.resumoDeHoje(
      ajustes: ajustesDeCategoria,
    );
    if (resumo == null) return;
    resumoTela = resumo;
    final mins = resumo.minutosContabilizados;
    if (mins != usage) {
      usage = mins;
      _markSync(_syncSettings);
    }
    if (notify) notifyListeners();
  }

  /// O usuário discordou da categoria de um app.
  ///
  /// Recalcula na hora: o número da meta muda na frente dele, senão a
  /// reclassificação parece não ter feito nada.
  Future<void> reclassifica(String pacote, CategoriaDeApp categoria) async {
    ajustesDeCategoria = {...ajustesDeCategoria, pacote: categoria};
    final anterior = resumoTela;
    if (anterior != null) {
      // Recalcula localmente a partir do que já está em mãos, sem esperar o
      // sistema: o toque tem de responder na hora.
      final porCategoria = <CategoriaDeApp, Duration>{};
      const contabilidade = ContabilidadeDeTela();
      for (final e in anterior.porApp.entries) {
        final c = contabilidade.categoriaDe(e.key, ajustesDeCategoria);
        porCategoria[c] = (porCategoria[c] ?? Duration.zero) + e.value;
      }
      resumoTela = ResumoDeTela(
        porApp: anterior.porApp,
        porCategoria: porCategoria,
      );
      usage = resumoTela!.minutosContabilizados;
    }
    _markSync(_syncSettings);
    notifyListeners();
  }

  Future<void> _syncNotificationSchedules() async {
    await BaruNotifications.instance.syncSchedules(
      evening: evening,
      eveningHour: eveningHour,
      eveningMinute: eveningMinute,
      missed: missed,
      eveningTitle: t.notifEveningTitle,
      eveningBody: t.fill(t.notifEveningBody, {'n': displayName}),
      missedTitle: t.notifMissedTitle,
      missedBody: t.fill(t.notifMissedBody, {'n': displayName}),
      daysAway: daysAway,
      trialActive: trial,
      trialEndsAt: trial ? paidPlanStart : null,
      trialTitle: t.notifTrialTitle,
      trialBody: t.fill(t.notifTrialBody, {'n': displayName}),
    );

    // Os lembretes de retenção: horário aprendido do comportamento, e não
    // um horário fixo que ignora quem a pessoa é. O teto de dois por dia
    // mora no plano — insistência que vira spam é desinstalação.
    final habito = horarioDoHabito(
      sessions.map((s) => s.at),
      agora: DateTime.now(),
    );
    final risco = avaliaRaizEmRisco(
      dias: streak,
      presenteHoje: completedToday > 0,
      congelamentos: freezesLeft,
      proximoMarco: RaizViva.proximoMarco(streak),
    );
    await BaruNotifications.instance.sincronizaRetencao(
      plano: planoDeLembretes(
        habito: habito,
        descansoFeitoHoje: missaoDoDescanso.concluida,
        risco: risco,
        relatorioLigado: evening,
        horaDoRelatorio: eveningHour,
      ),
      textos: textosDosLembretes(
        t,
        nomeDoPet: displayName,
        minutosDeDescanso: missaoDoDescanso.alvo,
        risco: risco,
      ),
    );
  }

  /// Onboarding passo 6 — abre fluxo nativo; só avança se o SO conceder.
  Future<void> requestUsageAccessFromOnboarding() async {
    if (kIsWeb) {
      skipUsage();
      return;
    }
    if (!UsageService.instance.platformSupportsUsage) {
      onUserMessage?.call(t.permIosLimit);
      await UsageService.instance.requestUsageAccess();
      return;
    }
    _pendingOnbUsageAdvance = true;
    await UsageService.instance.requestUsageAccess();
  }

  void skipUsage() {
    _pendingOnbUsageAdvance = false;
    usageAccess = false;
    _markSync(_syncSettings);
    nextOnb();
  }

  Future<void> requestUsageAccessFromSettings() async {
    if (kIsWeb) return;
    if (!UsageService.instance.platformSupportsUsage) {
      onUserMessage?.call(t.permIosLimit);
      await UsageService.instance.requestUsageAccess();
      return;
    }
    if (await UsageService.instance.hasUsageAccess()) {
      setUsageAccess(true);
      await _refreshUsageFromOs();
      return;
    }
    _usageTogglePending = true;
    await UsageService.instance.requestUsageAccess();
  }

  /// Primeiro dia real: habitat vazio, sem folhas herdadas do snapshot do design.
  void startCompanionship() {
    companionshipStarted = true;
    leaves = 0;
    streak = 0;
    usage = 0;
    completedToday = 0;
    owned = [];
    abandonedToday = false;
    daysAway = 0;
    todayIndex = weekdayIndex();
    week = freshWeek();
    freezesLeft = 1;
    reward = 0;
    aborted = false;
    sharing = false;
    sessions = [];
    sessionStartedAt = null;
    sessionEndsAt = null;
    sessionDur = 0;
    xp = 0;
    sessoesConcluidas = 0;
    melhorSequencia = 0;
    diasAbaixoDaMeta = 0;
    marcosResgatados = {};
    marcosACelebrar = [];
    nivelCelebrado = 1;
    minutosDeFocoHoje = 0;
    melhorDescansoHoje = Duration.zero;
    descansoComecouEm = null;
    descansoNoApp = Duration.zero;
    maiorSessaoHoje = 0;
    sessoesNaSemana = 0;
    minutosNaSemana = 0;
    diasAbaixoNaSemana = 0;
    missoesResgatadas = {};
    missoesACelebrar = [];
    lastOpenDate = dateOnly(DateTime.now());
    _markSync(_syncShop | _syncSession);
  }

  void setName(String value) {
    petName = value.length > 18 ? value.substring(0, 18) : value;
    _markSync(_syncPet);
    notifyListeners();
  }

  void setColor(int i) {
    // Limite da paleta **da espécie**, não um 3 escrito à mão: com paletas de
    // seis tons, as duas últimas bolinhas apareciam e não faziam nada.
    color = i.clamp(0, AppColors.coatDe(species).length - 1);
    _markSync(_syncPet);
    notifyListeners();
  }

  /// Troca o animal nos ajustes. Nome customizado fica; o padrão do design muda.
  void pickSpecies(Species s) {
    if (species == s) return;
    // A trilha entrega espécie como recompensa, e o app não estava
    // cobrando: `especiesLiberadas` existia sem nenhum consumidor, os dois
    // seletores iteravam `Species.values` inteiro, e uma conta nova
    // equipava o buldogue no primeiro dia — os 22 degraus viravam enfeite.
    //
    // O habitat já tinha essa porta (`escolheHabitat`); a assimetria é que
    // era o defeito. Silencioso pelo mesmo motivo dele: a tela não oferece
    // o toque, e uma chamada fora de hora não pode virar espécie.
    if (!podeEscolher(s)) return;
    final current = petName.trim();
    final wasDefault = current.isEmpty || current == petNames[species];
    species = s;
    // A paleta muda com a espécie: um índice válido na anterior pode não
    // existir na nova.
    color = color.clamp(0, AppColors.coatDe(s).length - 1);
    if (wasDefault) {
      petName = petNames[s]!;
    }
    // O ícone da gaveta acompanha: um app de companhia cujo ícone é outro
    // bicho não é o companheiro de ninguém.
    unawaited(IconeService.instance.usa(s.name));
    _markSync(_syncPet);
    notifyListeners();
  }

  void setUsageAccess(bool value) {
    usageAccess = value;
    _markSync(_syncSettings);
    notifyListeners();
  }

  Future<void> toggleUsageAccess() async {
    if (kIsWeb) return;
    if (usageAccess) {
      setUsageAccess(false);
      return;
    }
    await requestUsageAccessFromSettings();
  }

  void pickAvg(int value) {
    avg = value;
    goal = suggestedGoal(value);
    _markSync(_syncSettings);
    notifyListeners();
  }

  void pickGoal(int value) {
    goal = value.clamp(metaMinima, metaMaxima);
    _markSync(_syncSettings);
    notifyListeners();
  }

  /// Ajusta a meta em passos. O botão desabilitado no limite é papel da tela;
  /// aqui o valor só não sai da faixa.
  void ajustaMeta(int passos) =>
      pickGoal(goal + passos * metaPasso);

  void setEveningTime(int hora, int minuto) {
    eveningHour = hora.clamp(0, 23);
    eveningMinute = minuto.clamp(0, 59);
    _markSync(_syncSettings);
    unawaited(_syncNotificationSchedules());
    notifyListeners();
  }

  void toggleSom() {
    som = !som;
    SomService.instance.ligado = som;
    _markSync(_syncSettings);
    notifyListeners();
  }

  void setSexo(Sexo novo) {
    if (sexo == novo) return;
    sexo = novo;
    _markSync(_syncPet);
    notifyListeners();
  }

  void pickDur(int value) {
    dur = value;
    _markSync(_syncSettings);
    notifyListeners();
  }

  void startTrial() {
    trial = true;
    trialStartedAt ??= DateTime.now();
    _markSync(_syncTrial | _syncSettings);
    // O aviso de 24h antes do fim só pode ser agendado depois de existir uma
    // data de início.
    unawaited(_syncNotificationSchedules());
    go(AppScreen.home);
  }

  void pickPay(PayPlan plan) {
    payPlan = plan;
    _markSync(_syncTrial);
    notifyListeners();
  }

  void restartOnboarding() {
    _restauraPilha(AppScreen.onb);
    onb = 0;
    perguntaAtual = 0;
    respostasDoQuiz = {};
    q0 = null;
    q1 = null;
    q2 = null;
    notifyListeners();
  }

  void openShare() {
    sharing = true;
    _notifyEfemero();
  }

  void closeShare() {
    sharing = false;
    _notifyEfemero();
  }

  Future<void> toggleEvening() async {
    if (kIsWeb) {
      onUserMessage?.call(t.notifWebUnsupported);
      return;
    }
    final turningOn = !evening;
    if (turningOn) {
      final ok = await BaruNotifications.instance.ensurePermission();
      if (!ok) {
        onUserMessage?.call(t.notifDenied);
        return;
      }
    }
    evening = !evening;
    _markSync(_syncSettings);
    await _syncNotificationSchedules();
    notifyListeners();
  }

  Future<void> toggleMissed() async {
    if (kIsWeb) {
      onUserMessage?.call(t.notifWebUnsupported);
      return;
    }
    final turningOn = !missed;
    if (turningOn) {
      final ok = await BaruNotifications.instance.ensurePermission();
      if (!ok) {
        onUserMessage?.call(t.notifDenied);
        return;
      }
    }
    missed = !missed;
    _markSync(_syncSettings);
    await _syncNotificationSchedules();
    notifyListeners();
  }

  /// O que está de fato em uso.
  ///
  /// Comprar e usar deixaram de ser a mesma coisa: o item entra no inventário
  /// e só aparece no habitat (ou no bicho) se estiver aqui.
  Set<String> equipados = {};

  bool estaEquipado(String id) => equipados.contains(id);

  /// Os objetos de cena que devem ser desenhados agora.
  ///
  /// `itemPorId != null` filtra o habitat da trilha, que mora no mesmo par
  /// `owned`/`equipados` mas não é item de catálogo. Sem isso a cena abria um
  /// controlador de chegada para uma peça que não existe e nunca é desenhada.
  List<String> get objetosNaCena => owned
      .where((id) => equipados.contains(id) && itemPorId(id) != null)
      .toList();

  /// O cenário em uso, se houver. Um por vez.
  ShopItemDef? get cenarioAtivo {
    for (final id in equipados) {
      final item = itemPorId(id);
      if (item?.categoria == CategoriaDeItem.cenario) return item;
    }
    return null;
  }

  /// A peça de roupa naquele lugar do corpo, se houver.
  /// O que passar para o `PetView`: a cor de cada peça vestida.
  Map<Vestimenta, Color> get roupasDoBicho => {
        for (final onde in Vestimenta.values)
          if (roupaEm(onde)?.cor != null) onde: roupaEm(onde)!.cor!,
      };

  /// O id da peça de cabeça — chapéu, gorro e coroa têm desenhos diferentes.
  String? get roupaDeCabeca => roupaEm(Vestimenta.cabeca)?.id;

  ShopItemDef? roupaEm(Vestimenta onde) {
    for (final id in equipados) {
      final item = itemPorId(id);
      if (item?.categoria == CategoriaDeItem.roupa &&
          item?.vestimenta == onde) {
        return item;
      }
    }
    return null;
  }

  void buy(ShopItemDef item) {
    if (owned.contains(item.id) || leaves < item.price) return;
    leaves -= item.price;
    owned = [...owned, item.id];
    // Recém-comprado já entra em cena: ninguém compra para deixar na gaveta.
    _equipa(item);
    _markSync(_syncShop);
    notifyListeners();
  }

  /// Coloca ou tira. Devolve `true` se ficou equipado.
  bool alternaEquipado(ShopItemDef item) {
    if (!owned.contains(item.id)) return false;
    if (equipados.contains(item.id)) {
      equipados = {...equipados}..remove(item.id);
    } else {
      _equipa(item);
    }
    _markSync(_syncShop);
    notifyListeners();
    return equipados.contains(item.id);
  }

  /// Regras de exclusão: **um** cenário e **uma** peça por lugar do corpo.
  /// Dois chapéus na mesma cabeça é bug, não estilo.
  void _equipa(ShopItemDef item) {
    final novo = {...equipados};
    switch (item.categoria) {
      case CategoriaDeItem.cenario:
        novo.removeWhere(
          (id) => itemPorId(id)?.categoria == CategoriaDeItem.cenario,
        );
      case CategoriaDeItem.roupa:
        novo.removeWhere((id) {
          final outro = itemPorId(id);
          return outro?.categoria == CategoriaDeItem.roupa &&
              outro?.vestimenta == item.vestimenta;
        });
      case CategoriaDeItem.objeto:
        break;
    }
    novo.add(item.id);
    equipados = novo;
  }

  /// Duração da sessão que está na tela: a que ela começou, não a que está
  /// selecionada no chip agora.
  int get sessionMinutes => sessionDur > 0 ? sessionDur : dur;

  /// Quantos segundos de relógio a sessão realmente ocupa.
  ///
  /// Em produção é a duração escolhida. No modo debug de 60×, uma sessão de
  /// 25 minutos ocupa 25 segundos de relógio — a compressão vive aqui, e não
  /// no passo do timer, para que o resto do código lide sempre com o relógio
  /// de parede.
  int _segundosDeRelogio(int minutos) => debugFast ? minutos : minutos * 60;

  void startSession() {
    _timer?.cancel();
    sessionDur = dur;
    sessionStartedAt = DateTime.now();
    sessionEndsAt = sessionStartedAt!.add(
      Duration(seconds: _segundosDeRelogio(dur)),
    );
    remaining = dur * 60;
    running = true;
    confirming = false;
    _empilha(AppScreen.session);
    _markSync(_syncSession);
    // Grava a sessão em curso: se o app for morto agora, ela é retomada.
    notifyListeners();
    _iniciaTicker();
    unawaited(_anunciaSessao());
    unawaited(_comecaAVigiar());
  }

  /// Põe de pé quem chama a pessoa de volta quando ela sai do app.
  ///
  /// Sem isto, sair do Baru durante o foco não fazia nada: o Flutter não
  /// executa em segundo plano, e o único gatilho do companheiro só disparava
  /// quando a pessoa **voltava** — tarde demais para servir.
  Future<void> _comecaAVigiar() async {
    // Sem "desenhar sobre outros apps" o vigia sobe, vê que a pessoa saiu, e
    // não consegue aparecer — em silêncio. Silêncio aqui é indistinguível de
    // "o app não funciona", que foi exatamente o relato.
    if (!await OverlayService.instance.temPermissao()) {
      onUserMessage?.call(t.vigiaSemPermissao);
      return;
    }
    await VigiaService.instance.comeca(
      fala: t.vigiaFala,
      // A fala muda com o app da frente (S-03). O dicionário nasce em Dart e
      // viaja pronto: o lado nativo escolhe a linha, não escreve nenhuma.
      // Sem este argumento o vigia cai na fala única e S-03 fica desligado —
      // pedido registrado em BLOCKERS.md pela frente da sobreposição, e a
      // linha mora aqui.
      falasPorPacote: falasPorPacote(t),
      pelo: AppColors.pelagemDe(species, color).toARGB32(),
      especie: species.name,
      acaoFechar: t.sobreFechar,
      acaoMais: t.sobreMais,
      notifTitulo: t.fill(t.notifSessaoTitulo, {'n': displayName}),
      notifCorpo: t.notifSessaoCorpo,
    );
  }

  /// Põe a sessão na barra de notificações e agenda o aviso de conclusão.
  ///
  /// A contagem regressiva é desenhada pelo Android a partir do instante de
  /// término, então ela continua andando com o app fechado — que é o estado
  /// normal de uma sessão que deu certo.
  Future<void> _anunciaSessao() async {
    final fim = sessionEndsAt;
    if (fim == null) return;
    final minutos = sessionMinutes;
    await BaruNotifications.instance.mostraSessao(
      terminaEm: fim,
      titulo: t.fill(t.notifSessaoTitulo, {'n': displayName}),
      corpo: t.notifSessaoCorpo,
      rotuloDesistir: t.notifSessaoDesistir,
    );
    await BaruNotifications.instance.agendaFimDaSessao(
      terminaEm: fim,
      titulo: t.notifFimTitulo,
      corpo: t.fill(t.notifFimCorpo, {
        'm': minutos,
        'k': sessionReward(minutos),
      }),
    );
  }

  void _iniciaTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// O timer só pinta a tela. Quem conta o tempo é o relógio, via
  /// [sessionEndsAt] — timer de app suspenso atrasa ou para, e uma sessão de
  /// foco existe justamente para o usuário largar o telefone.
  void _tick() {
    _recalculaRestante();
    if (remaining > 0) {
      // Não passa pelo notifyListeners padrão: gravar a cada segundo só para
      // repintar o contador seria escrita à toa.
      super.notifyListeners();
      return;
    }
    _concluiSessao(em: sessionEndsAt ?? DateTime.now(), navega: true);
  }

  void _recalculaRestante() {
    final fim = sessionEndsAt;
    final ini = sessionStartedAt;
    if (fim == null || ini == null) return;
    final totalMs = fim.difference(ini).inMilliseconds;
    final faltaMs = fim.difference(DateTime.now()).inMilliseconds;
    if (totalMs <= 0 || faltaMs <= 0) {
      remaining = 0;
      return;
    }
    // A tela mostra a duração escolhida; o relógio pode estar comprimido no
    // modo debug. O que se exibe é a fração restante aplicada à duração.
    remaining = (faltaMs / totalMs * sessionDur * 60).ceil();
  }

  void _concluiSessao({required DateTime em, required bool navega}) {
    _timer?.cancel();
    final minutos = sessionDur > 0 ? sessionDur : dur;
    final gained = sessionReward(minutos);
    remaining = 0;
    running = false;
    confirming = false;
    aborted = false;
    reward = gained;
    leaves += gained;
    unawaited(SomService.instance.toca(SomDoBaru.fim));
    if (completedToday == 0) {
      streak += 1;
      if (streak > melhorSequencia) melhorSequencia = streak;
      ganhaXp(Balanco.xpPorDiaDeSequencia);
    }
    completedToday += 1;
    sessoesConcluidas += 1;
    // Contadores de missão vêm do evento de domínio, não da tela (§5).
    minutosDeFocoHoje += minutos;
    minutosNaSemana += minutos;
    sessoesNaSemana += 1;
    if (minutos > maiorSessaoHoje) maiorSessaoHoje = minutos;
    ganhaXp(Balanco.xpDeSessao(minutos));
    _logSession(
      completed: true,
      gained: gained,
      em: sessionStartedAt ?? em,
      minutos: minutos,
    );
    // `sessionEndsAt` nulo já marca "sem sessão"; `sessionDur` fica como
    // registro da última sessão, que é o que a tela de resultado mostra.
    sessionStartedAt = null;
    sessionEndsAt = null;
    if (navega) _empilha(AppScreen.result);
    _markSync(_syncSession | _syncShop);
    // O aviso agendado já cumpriu (ou vai cumprir) o papel; o que sai é a
    // notificação fixa. Agendamento sem motivo tem de sumir.
    unawaited(BaruNotifications.instance.encerraSessao());
    unawaited(VigiaService.instance.para());
    notifyListeners();
  }

  /// Reconcilia a sessão com o relógio ao voltar do background.
  ///
  /// Um `Timer` de app suspenso atrasa ou simplesmente para. Sem isto, quem
  /// larga o telefone — que é o comportamento que o app pede — voltaria e
  /// veria o contador congelado no segundo em que saiu.
  void reconcileSession() {
    final fim = sessionEndsAt;
    if (fim == null) return;
    _recalculaRestante();
    if (remaining <= 0) {
      _concluiSessao(em: fim, navega: true);
      return;
    }
    _iniciaTicker();
    // O app pode ter sido morto e reaberto no meio da sessão. Se o serviço
    // ainda estiver de pé, começar de novo não faz nada — ele só refaz o
    // `startForeground`. Se tiver morrido junto com o processo, é isto que
    // o traz de volta.
    unawaited(_comecaAVigiar());
    super.notifyListeners();
  }

  /// Retoma (ou conclui) uma sessão que atravessou o fechamento do app.
  void _restauraSessao(DateTime now) {
    final fim = sessionEndsAt;
    if (fim == null) return;
    if (sessionDur <= 0 || sessionStartedAt == null) {
      // Snapshot inconsistente: descarta a sessão em vez de premiar lixo.
      sessionStartedAt = null;
      sessionEndsAt = null;
      sessionDur = 0;
      return;
    }
    if (now.isBefore(fim)) {
      running = true;
      confirming = false;
      _empilha(AppScreen.session);
      _recalculaRestante();
      _iniciaTicker();
      // Reboot ou swipe podem ter tirado a notificação da barra; recoloca.
      unawaited(_anunciaSessao());
      return;
    }
    // O tempo acabou com o app fechado — que é exatamente o que se pede ao
    // usuário. A sessão conta. Só não abre a tela de resultado se ela terminou
    // num dia anterior: aí o resultado seria sobre um dia que já passou.
    _concluiSessao(em: fim, navega: dateOnly(fim) == dateOnly(now));
  }

  void askQuit() {
    confirming = true;
    notifyListeners();
  }

  void resume() {
    confirming = false;
    notifyListeners();
  }

  void abandon() {
    _timer?.cancel();
    final minutos = sessionDur > 0 ? sessionDur : dur;
    _empilha(AppScreen.result);
    aborted = true;
    reward = 0;
    abandonedToday = true;
    running = false;
    confirming = false;
    sessionStartedAt = null;
    sessionEndsAt = null;
    sessionDur = minutos;
    _logSession(completed: false, gained: 0, minutos: minutos);
    _markSync(_syncSession);
    unawaited(BaruNotifications.instance.encerraSessao());
    unawaited(VigiaService.instance.para());
    notifyListeners();
  }

  void _logSession({
    required bool completed,
    required int gained,
    DateTime? em,
    int? minutos,
  }) {
    sessions = [
      ...sessions,
      SessionRecord(
        id: const Uuid().v4(),
        at: em ?? DateTime.now(),
        dur: minutos ?? dur,
        completed: completed,
        aborted: !completed,
        reward: gained,
      ),
    ];
    if (sessions.length > 80) {
      sessions = sessions.sublist(sessions.length - 80);
    }
  }

  /// Faz a meia-noite passar uma vez, para o teste.
  ///
  /// Costura de teste, não atalho de produto: o único jeito de exercitar a
  /// virada do dia — bônus da meta, congelamento, expiração de missão — sem
  /// esperar até amanhã. Em produção quem vira o dia é [applyCalendar], a
  /// partir da data real; nada na árvore de widgets chama isto, e
  /// `@visibleForTesting` faz o analisador reclamar se alguém tentar.
  @visibleForTesting
  void nextDay() {
    final de = dateOnly(lastOpenDate);
    final para = de.add(const Duration(days: 1));
    _advanceDay(de: de, para: para);
    lastOpenDate = para;
    if (completedToday == 0) daysAway += 1;
    _markSync(_syncSession);
    notifyListeners();
  }

  /// Fecha o dia [de] e abre o dia [para].
  ///
  /// Os índices da semana saem da **data**, não de um contador incrementado:
  /// um contador desanda em relação ao calendário na primeira ausência longa,
  /// e o ponto de "hoje" passa a apontar o dia errado.
  ///
  /// [creditBonus] só vale para o dia que tem medição real de tempo de tela —
  /// o primeiro de um avanço. Nos dias seguintes de uma ausência longa o
  /// `usage` é sintético (zero), e pagar bônus por eles seria inventar dado.
  void _advanceDay({
    required DateTime de,
    required DateTime para,
    bool creditBonus = true,
  }) {
    if (creditBonus && _closedUnderGoal) {
      leaves += underGoalBonus;
      pendingUnderGoalBonus += 1;
      diasAbaixoDaMeta += 1;
      diasAbaixoNaSemana += 1;
      ganhaXp(Balanco.xpDiaAbaixoDaMeta);
      _markSync(_syncShop);
    }

    final iDe = weekdayIndex(de);
    final iPara = weekdayIndex(para);

    week = List<WeekDayKind>.from(week);
    if (completedToday >= 1) {
      week[iDe] = WeekDayKind.present;
    } else if (freezesLeft > 0) {
      // O congelamento absorve a falta: a presença continua contando.
      week[iDe] = WeekDayKind.frozen;
      freezesLeft -= 1;
      streak += 1;
      if (streak > melhorSequencia) melhorSequencia = streak;
    } else {
      week[iDe] = WeekDayKind.empty;
      streak = 0;
    }

    // Segunda-feira abre uma semana nova: a faixa mostra "esta semana", então
    // as marcas da semana anterior não podem sobreviver à virada.
    if (iPara == 0) {
      week = List<WeekDayKind>.filled(7, WeekDayKind.empty);
      freezesLeft = 1;
    }

    todayIndex = iPara;
    week[iPara] = WeekDayKind.today;
    // Dia novo começa sem medição nenhuma. Havia um `40` escrito aqui para o
    // painel de depuração abrir o dia seguinte já com tempo de tela — número
    // que aparelho nenhum tinha reportado. Quem preenche isto é
    // `syncPermissionsFromOs`, lendo o UsageStats; até ele responder, zero é
    // a única resposta honesta.
    usage = 0;
    completedToday = 0;
    abandonedToday = false;
    carinhosHoje = 0;

    // Missões diárias expiram à meia-noite, sem punição: o contador zera e a
    // missão de amanhã é outra.
    minutosDeFocoHoje = 0;
    maiorSessaoHoje = 0;
    // A tentativa de descanso não atravessa a meia-noite: o contador de tela
    // zera junto, e a subtração que mede o descanso passaria a descrever
    // outra coisa.
    melhorDescansoHoje = Duration.zero;
    descansoComecouEm = null;
    descansoNoApp = Duration.zero;
    resumoTela = null;
    if (iPara == 0) {
      // Semana nova, missões semanais novas.
      sessoesNaSemana = 0;
      minutosNaSemana = 0;
      diasAbaixoNaSemana = 0;
    }
  }

  /// O dia que está fechando terminou abaixo da meta?
  ///
  /// Exige permissão de uso: sem ela não há tempo de tela para comparar, e o
  /// app não inventa um bônus. Exige também companheirismo começado, para o
  /// bônus não cair antes do onboarding terminar.
  bool get _closedUnderGoal =>
      companionshipStarted && usageAccess && usage < goal;

  /// Teto de dias reconstruídos um a um num único avanço. Acima disso não há
  /// o que reconstruir com fidelidade — o calendário é realinhado à data real.
  static const maxDiasReconstruidos = 21;

  void applyCalendar(DateTime now, {bool persist = true}) {
    final today = dateOnly(now);
    final desde = dateOnly(lastOpenDate);
    var cursor = desde;
    var steps = 0;
    while (cursor.isBefore(today) && steps < maxDiasReconstruidos) {
      final proximo = cursor.add(const Duration(days: 1));
      _advanceDay(
        de: cursor,
        para: proximo,
        creditBonus: steps == 0,
      );
      cursor = proximo;
      steps += 1;
    }

    if (cursor.isBefore(today)) {
      // Ausência maior que o teto: reconstruir dia a dia não agrega nada.
      // Realinha a faixa com a data real em vez de deixar o índice à deriva.
      week = List<WeekDayKind>.filled(7, WeekDayKind.empty);
      freezesLeft = 1;
      streak = 0;
      todayIndex = weekdayIndex(today);
      week[todayIndex] = WeekDayKind.today;
      steps += 1;
    } else {
      _alinhaHoje(today);
    }

    // "Dias sem abrir" é um fato da data, não um contador que se acumula.
    daysAway = today.difference(desde).inDays - 1;
    if (daysAway < 0) daysAway = 0;

    // Quem sumiu volta para o pior dia possível: raiz zerada, nada a
    // resgatar, o habitat parado onde estava. Cobrar o reencontro é o
    // caminho mais curto entre uma recaída e uma desinstalação.
    final volta = avaliaVolta(
      diasFora: daysAway,
      hoje: today,
      jaCreditadas: missoesResgatadas,
    );
    if (volta != null && companionshipStarted) {
      missoesResgatadas = {...missoesResgatadas, volta.chave};
      leaves += volta.folhas;
      if (volta.devolveCongelamento && freezesLeft < 1) freezesLeft = 1;
      voltaPendente = volta;
      _markSync(_syncProgresso | _syncShop);
    }

    // Um dia novo começou com o app aberto ou foi aberto num dia novo: a
    // chegada merece cena. `steps > 0` é justamente "virou o dia".
    if (steps > 0 && companionshipStarted) chegadaACelebrar = true;

    lastOpenDate = today;
    if (persist && steps > 0) {
      _markSync(_syncSession);
      flushPendingNotices();
      notifyListeners();
    }
  }

  /// Garante que o ponto de "hoje" caia no dia da semana real.
  ///
  /// Um snapshot pode chegar com o índice defasado — vindo de outro aparelho,
  /// de outro fuso, ou de uma versão antiga que incrementava o contador em vez
  /// de derivá-lo da data. Sem isto, a faixa da semana marca o dia errado e o
  /// erro só cresce.
  void _alinhaHoje(DateTime today) {
    final idx = weekdayIndex(today);
    if (todayIndex == idx && week[idx] == WeekDayKind.today) return;
    week = List<WeekDayKind>.from(week);
    if (week[todayIndex] == WeekDayKind.today) {
      week[todayIndex] = WeekDayKind.empty;
    }
    todayIndex = idx;
    week[idx] = WeekDayKind.today;
  }

  /// Mostra os avisos que ficaram pendentes de um avanço de calendário.
  ///
  /// Existe porque o primeiro avanço acontece no construtor, antes de haver
  /// árvore de widgets para receber um SnackBar; `BaruApp` chama isto no
  /// primeiro frame.
  void flushPendingNotices() {
    // Dois recados podem estar pendentes, e um `return` cedo engolia o
    // outro: o bônus da meta não pode calar o presente de retorno.
    if (pendingUnderGoalBonus > 0) {
      pendingUnderGoalBonus = 0;
      onUserMessage?.call(t.fill(t.bonusUnderGoal, {'k': underGoalBonus}));
    }
    final v = voltaPendente;
    if (v != null) {
      voltaPendente = null;
      onUserMessage?.call(recadoDaVolta(t, v));
    }
  }

  void restorePurchases() {
    trial = true;
    trialStartedAt ??= DateTime.now();
    _markSync(_syncTrial);
    unawaited(_syncNotificationSchedules());
    go(AppScreen.home);
  }

  AppSnapshot toSnapshot() {
    final persistScreen =
        screen == AppScreen.session ? AppScreen.home : screen;
    return AppSnapshot(
      screen: persistScreen,
      onb: onb,
      lang: lang,
      species: species,
      q0: q0,
      q1: q1,
      q2: q2,
      leaves: leaves,
      streak: streak,
      usage: usage,
      goal: goal,
      avg: avg,
      petName: petName,
      color: color,
      owned: List<String>.from(owned),
      dur: dur,
      completedToday: completedToday,
      abandonedToday: abandonedToday,
      daysAway: daysAway,
      trial: trial,
      evening: evening,
      eveningHour: eveningHour,
      eveningMinute: eveningMinute,
      sexo: sexo,
      som: som,
      missed: missed,
      payPlan: payPlan,
      usageAccess: usageAccess,
      companionshipStarted: companionshipStarted,
      week: List<WeekDayKind>.from(week),
      todayIndex: todayIndex,
      freezesLeft: freezesLeft,
      trialStartedAt: trialStartedAt,
      lastOpenDate: lastOpenDate,
      sessions: List<SessionRecord>.from(sessions),
      sessionStartedAt: sessionStartedAt,
      sessionEndsAt: sessionEndsAt,
      sessionDur: sessionDur,
      ajustesDeCategoria: {
        for (final e in ajustesDeCategoria.entries) e.key: e.value.name,
      },
      xp: xp,
      afeto: afeto,
      carinhosHoje: carinhosHoje,
      sessoesConcluidas: sessoesConcluidas,
      melhorSequencia: melhorSequencia,
      diasAbaixoDaMeta: diasAbaixoDaMeta,
      marcosResgatados: marcosResgatados.toList(),
      nivelCelebrado: nivelCelebrado,
      minutosDeFocoHoje: minutosDeFocoHoje,
      maiorSessaoHoje: maiorSessaoHoje,
      descansoComecouEm: descansoComecouEm,
      descansoTelaNoInicio: descansoTelaNoInicio,
      descansoNoAppSegundos: descansoNoApp.inSeconds,
      melhorDescansoMinutos: melhorDescansoHoje.inMinutes,
      sessoesNaSemana: sessoesNaSemana,
      minutosNaSemana: minutosNaSemana,
      diasAbaixoNaSemana: diasAbaixoNaSemana,
      missoesResgatadas: missoesResgatadas.toList(),
      equipados: equipados.toList(),
      respostasDoQuiz: respostasDoQuiz,
    );
  }

  /// Restaura um snapshot. Só para o teste.
  ///
  /// O caminho de verdade passa pelo repositório e pelo arranque do app;
  /// sem esta costura, "o descanso sobrevive ao app ser morto" só seria
  /// verificável em aparelho.
  @visibleForTesting
  void applySnapshotParaTeste(AppSnapshot s) => _applySnapshot(s);

  void _applySnapshot(AppSnapshot s) {
    _restauraPilha(
        s.screen == AppScreen.session ? AppScreen.home : s.screen);
    onb = s.onb;
    lang = s.lang;
    species = s.species;
    q0 = s.q0;
    q1 = s.q1;
    q2 = s.q2;
    leaves = s.leaves;
    streak = s.streak;
    usage = s.usage;
    goal = s.goal;
    avg = s.avg;
    petName = s.petName;
    color = s.color;
    owned = List<String>.from(s.owned);
    dur = s.dur;
    completedToday = s.completedToday;
    abandonedToday = s.abandonedToday;
    daysAway = s.daysAway;
    trial = s.trial;
    evening = s.evening;
    eveningHour = s.eveningHour;
    eveningMinute = s.eveningMinute;
    sexo = s.sexo;
    som = s.som;
    SomService.instance.ligado = som;
    missed = s.missed;
    payPlan = s.payPlan;
    usageAccess = s.usageAccess;
    companionshipStarted = s.companionshipStarted;
    week = List<WeekDayKind>.from(s.week);
    todayIndex = s.todayIndex;
    freezesLeft = s.freezesLeft;
    trialStartedAt = s.trialStartedAt;
    lastOpenDate = s.lastOpenDate;
    sessions = List<SessionRecord>.from(s.sessions);
    sessionStartedAt = s.sessionStartedAt;
    sessionEndsAt = s.sessionEndsAt;
    sessionDur = s.sessionDur;
    ajustesDeCategoria = {
      for (final e in s.ajustesDeCategoria.entries)
        if (categoriaPorNome(e.value) != null)
          e.key: categoriaPorNome(e.value)!,
    };
    xp = s.xp;
    afeto = s.afeto;
    carinhosHoje = s.carinhosHoje;
    sessoesConcluidas = s.sessoesConcluidas;
    melhorSequencia = s.melhorSequencia;
    diasAbaixoDaMeta = s.diasAbaixoDaMeta;
    marcosResgatados = s.marcosResgatados.toSet();
    nivelCelebrado = s.nivelCelebrado;
    minutosDeFocoHoje = s.minutosDeFocoHoje;
    maiorSessaoHoje = s.maiorSessaoHoje;
    descansoComecouEm = s.descansoComecouEm;
    descansoTelaNoInicio = s.descansoTelaNoInicio;
    descansoNoApp = Duration(seconds: s.descansoNoAppSegundos);
    melhorDescansoHoje = Duration(minutes: s.melhorDescansoMinutos);
    // Quem restaura já está com o app na frente: sem isto, o tempo entre a
    // restauração e o próximo `voltouAoApp` contaria como descanso.
    _voltouAoAppEm = descansoComecouEm == null ? null : DateTime.now();
    sessoesNaSemana = s.sessoesNaSemana;
    minutosNaSemana = s.minutosNaSemana;
    diasAbaixoNaSemana = s.diasAbaixoNaSemana;
    missoesResgatadas = s.missoesResgatadas.toSet();
    // Inventário antigo não tinha "equipado": tudo o que já era do usuário
    // continua em cena, senão o habitat esvazia na atualização.
    respostasDoQuiz = Map<String, String>.from(s.respostasDoQuiz);
    equipados = s.equipados.isEmpty && s.owned.isNotEmpty
        ? s.owned
            .where(
              (id) => itemPorId(id)?.categoria == CategoriaDeItem.objeto,
            )
            .toSet()
        : s.equipados.toSet();
  }

  void _schedulePersist() {
    if (repos == null) return;
    // A sessão em curso precisa ser gravada — é o que permite retomá-la. O
    // tique de cada segundo não passa por aqui: usa super.notifyListeners().
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 280), _persistNow);
  }

  /// Reenvia o que ficou pendente de uma falha anterior.
  ///
  /// Chamado quando o app volta do background — é o momento em que a rede
  /// costuma ter voltado.
  void retryPendingSync() {
    if (_syncMask == 0) return;
    _schedulePersist();
  }

  Future<void> _persistNow() async {
    final r = repos;
    if (r == null) return;
    if (_persisting) {
      // Um envio anterior ainda está em voo. Correr junto duplicaria escrita
      // e embaralharia a máscara; reagenda.
      _schedulePersist();
      return;
    }
    _persisting = true;
    try {
      await r.saveSnapshot(toSnapshot());

      // Máscara vazia = origem desconhecida; empurra tudo por segurança.
      final mask = _syncMask == 0 ? _syncAll : _syncMask;
      _syncMask = 0;

      var falhou = 0;
      final dominiosQueFalharam = <String>[];
      Future<void> envia(
        int bit,
        String nome,
        Future<void> Function() push,
      ) async {
        if (mask & bit == 0) return;
        try {
          await push();
        } catch (e) {
          // Tabela que não existe no remoto não é falha de rede: tentar de
          // novo não resolve nunca, e chamar isso de "não foi possível
          // sincronizar, tente mais tarde" é mentir para o usuário.
          final ausente = TabelaAusenteNoRemoto.de(e);
          if (ausente != null) {
            if (_tabelasAusentesAvisadas.add(ausente.tabela)) {
              onSyncError?.call(
                t.fill(t.syncSchemaFail, {'t': ausente.tabela}),
              );
            }
            return;
          }
          // Sem o nome do domínio e sem o erro cru, "não foi possível
          // sincronizar" não dá para investigar: são treze tabelas.
          debugPrint('Baru: sync falhou em $nome — $e');
          dominiosQueFalharam.add(nome);
          // Devolve a intenção à máscara: o domínio tenta de novo na próxima
          // gravação, em vez de a mudança sumir sem ninguém saber.
          falhou |= bit;
        }
      }

      // Cada domínio é isolado: uma falha de rede no pet não pode impedir a
      // loja, os ajustes, as sessões e o trial de subirem.
      await envia(_syncPet, 'pet', r.pet.pushRemote);
      await envia(_syncShop, 'loja', r.shop.pushRemote);
      await envia(_syncSettings, 'ajustes', r.settings.pushRemote);
      await envia(_syncSession, 'sessoes', r.sessions.pushRemote);
      await envia(_syncTrial, 'assinatura', r.trial.pushRemote);
      await envia(_syncProgresso, 'progresso', r.progresso.pushRemote);

      if (falhou != 0) {
        _syncMask |= falhou;
        // Um aviso por episódio de falha, não um por gravação: offline, o
        // debounce dispara a cada toque e viraria enxurrada de SnackBar.
        if (!_syncFailNotified) {
          _syncFailNotified = true;
          ultimoErroDeSync = dominiosQueFalharam.join(', ');
          onSyncError?.call(
            t.fill(t.syncFail, {'q': ultimoErroDeSync}),
          );
        }
      } else {
        _syncFailNotified = false;
      }
    } finally {
      _persisting = false;
    }
  }

  /// O que o widget da tela inicial mostra agora.
  ///
  /// Montar aqui e mandar **lá fora** é de propósito. A primeira versão
  /// chamava o `WidgetService` de dentro do `notifyListeners`; rasterizar
  /// monta um `RenderView` próprio e roda um quadro, e fazer isso no meio
  /// das animações da tela derrubava o relógio dos `AnimationController`.
  ///
  /// Além do defeito, era a hora errada: o widget existe para quando o app
  /// **não** está na frente. Quem manda é o ciclo de vida.
  EstadoDoWidget get estadoDoWidget => EstadoDoWidget(
        especie: species,
        humor: mood,
        pelagem: color,
        nome: displayName,
        raiz: streak,
        usoDoDia: usage,
        meta: goal,
      );

  @override
  void notifyListeners() {
    super.notifyListeners();
    _schedulePersist();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _saveTimer?.cancel();
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope não encontrado');
    return scope!.notifier!;
  }
}
