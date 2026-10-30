import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'data/app_snapshot.dart';
import 'data/repositories.dart';
import 'services/notification_service.dart';
import 'services/cenas_dos_recados.dart';
import 'services/quadros_do_bicho.dart';
import 'services/som_service.dart';
import 'services/vigia_service.dart';
import 'services/widget_service.dart';
import 'l10n_descanso.dart';
import 'l10n_notificacao.dart';
import 'models.dart';
import 'navegacao.dart';
import 'widgets/folha_restrita.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/report_screen.dart';
import 'screens/result_screen.dart';
import 'screens/session_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/conta_screen.dart';
import 'screens/folhas_screen.dart';
import 'screens/sequencia_screen.dart';
import 'screens/sobreposicao_screen.dart';
import 'screens/tempo_screen.dart';
import 'screens/missoes_screen.dart';
import 'screens/trilha_screen.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets/common.dart';
import 'widgets/celebracao.dart';
import 'widgets/cena_da_missao.dart';
import 'widgets/cena_da_raiz.dart';
import 'widgets/crescimento.dart';
import 'widgets/pet.dart';
import 'widgets/saida.dart';
import 'widgets/share_sheet.dart';

class BaruApp extends StatefulWidget {
  const BaruApp({super.key, this.repos, this.snapshot, this.bootstrapNotice});

  final BaruRepositories? repos;
  final AppSnapshot? snapshot;
  final String? bootstrapNotice;

  @override
  State<BaruApp> createState() => _BaruAppState();
}

class _BaruAppState extends State<BaruApp> with WidgetsBindingObserver {
  late final AppState state = AppState(
    repos: widget.repos,
    snapshot: widget.snapshot,
    onSyncError: _onSyncError,
    onUserMessage: _onUserMessage,
  );
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  late final _rotas = BaruRouterDelegate(app: state, paginaDe: _telaDe);
  static const _parser = BaruRouteParser();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // O som só pode existir depois que há binding: é aqui, e em nenhum lugar
    // antes, que o player pode ser construído.
    SomService.instance
      ..arma()
      ..ligado = state.som;
    // Mesma razão do som: `MethodChannel` exige binding, e o domínio é
    // testado sem nenhum.
    VigiaService.instance.arma();
    IconeService.instance.arma();
    WidgetService.instance.arma();
    state.initPlatformServices();
    // Recusa vinda do sistema abre o passo a passo, não um aviso que manda
    // a pessoa para a tela onde o botão está travado.
    state.aoBloqueioDoSistema = _mostraComoLiberar;
    // "Desistir" na notificação da sessão age no app, não só some da barra.
    BaruNotifications.instance.aoDesistirPelaBarra = () {
      if (state.sessionEndsAt != null) state.abandon();
    };
    // O mesmo para a missão do descanso — e é `desisteDoDescanso`, não
    // `abandon`: encerrar o descanso não custa nada, o melhor do dia fica
    // guardado (§1).
    BaruNotifications.instance.aoEncerrarDescansoPelaBarra = () {
      if (state.descansoComecouEm != null) state.desisteDoDescanso();
    };
    // Os dois catálogos de módulo que a barra de notificações usa. Registrar
    // aqui, e não na primeira leitura, porque a primeira leitura pode
    // acontecer no `didChangeAppLifecycleState` — e uma chave que não
    // resolve devolve a **própria chave**, que iria para a barra como texto.
    garanteTextosDaNotificacao();
    garanteTextosDoDescanso();
    // O rótulo vem por função, não por valor: o idioma muda nos ajustes e a
    // notificação pode ser postada horas depois.
    BaruNotifications.instance.rotuloDeVolta = () => state.t.notifBarraVoltar;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.bootstrapNotice != null) {
        _scaffoldKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(widget.bootstrapNotice!),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      // O primeiro avanço de calendário acontece no construtor do AppState,
      // antes de existir árvore para receber um SnackBar.
      state.flushPendingNotices();
    });
  }

  void _onSyncError(String message) {
    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _mostraComoLiberar() {
    final ctx = _scaffoldKey.currentState?.context;
    if (ctx == null || !ctx.mounted) {
      _onUserMessage(state.t.permUsageDenied);
      return;
    }
    unawaited(FolhaRestrita.mostra(ctx, state.lang));
  }

  void _onUserMessage(String message) {
    // Na sessão o único botão da tela ("Desistir") fica embaixo: o recado
    // sobe para não tapá-lo (simulador da Fase 4, médio 16).
    final naSessao = state.screen == AppScreen.session;
    final ctx = _scaffoldKey.currentState?.context;
    final alto = ctx == null ? 0.0 : MediaQuery.sizeOf(ctx).height;
    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        margin: naSessao && alto > 0
            ? EdgeInsets.fromLTRB(16, 0, 16, alto * 0.62)
            : null,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    // Sair do app é a hora exata de o widget ficar em dia: é agora que ele
    // passa a ser a única cara do Baru na tela da pessoa. E é a hora
    // segura de rasterizar, com as animações da tela já paradas.
    if (s != AppLifecycleState.resumed) {
      WidgetService.instance.atualiza(state.estadoDoWidget);
      // Pelo mesmo motivo, os quadros do bicho da sobreposição: ela só
      // aparece com a pessoa noutro app, e é agora que ela sai. Só em
      // `hidden` — a tela do app já saiu —, não em `inactive`, que também é
      // a cortina de notificações aberta por cima do app ainda animando.
      if (s == AppLifecycleState.hidden) {
        unawaited(QuadrosDoBicho.instance.atualiza(state.aparenciaDoBicho));
        // E as cenas das notificações animadas: tocam com o app fechado.
        unawaited(CenasDosRecados.instance.atualiza(state.aparenciaDoBicho));
      }
      // Fecha a conta do tempo dentro do Baru. Sem isto, olhar o bicho
      // contaria como descanso — e a missão é justamente ficar longe.
      state.saiuDoApp();
    }
    if (s == AppLifecycleState.resumed) {
      state.voltouAoApp();
      // Antes do calendário: uma sessão que terminou ontem tem de contar como
      // presença de ontem, e é o avanço de calendário que fecha aquele dia.
      state.reconcileSession();
      state.applyCalendar(DateTime.now());
      state.syncPermissionsFromOs();
      // Voltar do background é o momento em que a rede costuma ter voltado.
      state.retryPendingSync();
    }
    // Depois das duas pontas, porque as duas mudam a conta: sair fecha o
    // tempo dentro do Baru, e voltar reconcilia a fuga com o medidor de tela.
    unawaited(_sincronizaDescansoNaBarra());
  }

  /// A missão do descanso na barra de notificações.
  ///
  /// **Por que aqui e não no domínio.** O descanso não tem prazo de parede:
  /// o que conta é relógio menos tela menos tempo dentro do Baru, então o
  /// instante em que ele acaba **se move** toda vez que a pessoa pega o
  /// telefone. Publicar a cada `notifyListeners` seria uma ida à plataforma
  /// por segundo; publicar só na troca de primeiro plano acerta os dois
  /// únicos instantes em que a conta muda de verdade — e o momento em que
  /// a pessoa larga o telefone é exatamente quando a notificação passa a ser
  /// a única cara da missão.
  ///
  /// A projeção é `agora + o que falta`, não `começou + 40 min`: enquanto o
  /// telefone está parado nada é subtraído e a projeção é exata; quando não
  /// está, é este método que a refaz.
  Future<void> _sincronizaDescansoNaBarra() async {
    final fim = BaruNotifications.contagemDoDescanso(
      state.leituraDoDescanso,
      DateTime.now(),
    );
    if (fim == null) {
      // Quem sabe se há foco correndo é o estado, não a notificação: a
      // memória de quem escreveu a barra morre com o processo, e a barra
      // não.
      await BaruNotifications.instance.encerraDescanso(
        focoEmCurso: state.sessionEndsAt != null,
      );
      return;
    }
    await BaruNotifications.instance.mostraDescanso(
      terminaEm: fim,
      titulo: state.t.fill(state.t.descansoVigiaTitulo, {
        'n': state.displayName,
      }),
      corpo: state.t.descansoVigiaCorpo,
      rotuloEncerrar: state.t.notifDescansoDesistir,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WidgetService.instance.cancela();
    unawaited(SomService.instance.dispose());
    _rotas.dispose();
    state.dispose();
    super.dispose();
  }

  Widget _telaDe(AppScreen tela) {
    switch (tela) {
      case AppScreen.onb:
        return const OnboardingScreen();
      case AppScreen.paywall:
        return const PaywallScreen();
      case AppScreen.home:
        return const HomeScreen();
      case AppScreen.session:
        return const SessionScreen();
      case AppScreen.result:
        return const ResultScreen();
      case AppScreen.report:
        return const ReportScreen();
      case AppScreen.shop:
        return const ShopScreen();
      case AppScreen.profile:
        return const SettingsScreen();
      case AppScreen.tempo:
        return const TempoScreen();
      case AppScreen.conta:
        return const ContaScreen();
      case AppScreen.sobreposicao:
        return const SobreposicaoScreen();
      case AppScreen.folhas:
        return const FolhasScreen();
      case AppScreen.sequencia:
        return const SequenciaScreen();
      case AppScreen.trilha:
        return const TrilhaScreen();
      case AppScreen.missoes:
        return const MissoesScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          return MaterialApp.router(
            title: 'Baru',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.data,
            locale: localeFor(state.lang),
            scrollBehavior: const BaruScrollBehavior(),
            scaffoldMessengerKey: _scaffoldKey,
            routerDelegate: _rotas,
            routeInformationParser: _parser,
            // A casca — fundo, barra de destinos, celebração, folha de
            // compartilhamento — envolve o `Navigator`. Ela não é uma rota:
            // a barra é fixa e sobrevive à troca de tela, que é o que §4B
            // pede.
            builder: (context, navegador) => AppFrame(
              child: _Casca(navegador: navegador!, chave: _rotas.navigatorKey),
            ),
          );
        },
      ),
    );
  }
}

/// Mede a altura do filho a cada layout e avisa depois do quadro.
class _MedeAltura extends SingleChildRenderObjectWidget {
  const _MedeAltura({required this.aoMedir, required super.child});

  final ValueChanged<double> aoMedir;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMedeAltura(aoMedir);

  @override
  void updateRenderObject(BuildContext context, _RenderMedeAltura r) =>
      r.aoMedir = aoMedir;
}

class _RenderMedeAltura extends RenderProxyBox {
  _RenderMedeAltura(this.aoMedir);

  ValueChanged<double> aoMedir;
  double? _ultima;

  @override
  void performLayout() {
    super.performLayout();
    final h = size.height;
    if (h == _ultima) return;
    _ultima = h;
    // Mudar estado no meio do layout é proibido: avisa depois do quadro.
    WidgetsBinding.instance.addPostFrameCallback((_) => aoMedir(h));
  }
}

class _Casca extends StatelessWidget {
  const _Casca({required this.navegador, required this.chave});

  final Widget navegador;

  /// O `Navigator` das telas: a casca fica fora dele, e as folhas que o
  /// painel da home abre precisam dele.
  final GlobalKey<NavigatorState> chave;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    // A home é o mundo dele, de borda a borda: passa por baixo da barra de
    // status e dos cantos arredondados do painel de baixo.
    final home = app.screen == AppScreen.home;
    return Scaffold(
      extendBody: home,
      backgroundColor: app.screen == AppScreen.session
          ? AppColors.sessionBg
          : AppColors.cream,
      body: SafeArea(
        top: !home,
        bottom: !app.showTabs,
        child: Stack(
          children: [
            navegador,
            if (app.sharing) const ShareSheet(),
            // A cena tira a tela de baixo do leitor de tela: sem isto ele
            // lia o resultado atrás da toca, e um toque pela acessibilidade
            // ia parar no "+10 folhas" escondido.
            if (app.temCelebracaoPendente && !app.celebracoesEmEspera)
              Positioned.fill(
                child: BlockSemantics(
                  child: Stack(children: [_celebracao(app)]),
                ),
              ),
            if (app.pedindoParaSair) const FolhaDeSaida(),
          ],
        ),
      ),
      // `AnimatedSize` para a barra não sumir num corte seco ao abrir um
      // detalhe.
      bottomNavigationBar: AnimatedSize(
        duration: Tempo.componente,
        curve: Curvas.padrao,
        alignment: Alignment.topCenter,
        // Com uma folha da home (ou o compartilhar) aberta, o painel sai da
        // frente: a folha é a camada de cima, e não um cartão espremido
        // entre o mundo e as abas, com duas alças à vista.
        // Atrás de uma celebração ou do pedido para sair, também: o
        // "Começar foco" mora aqui fora e ficava tocável por baixo deles
        // (auditoria de dcf82c9, 1).
        child:
            app.showTabs &&
                !(home &&
                    (app.folhasDaHome > 0 ||
                        app.sharing ||
                        app.cenaNaFrente ||
                        app.pedindoParaSair))
            ? (home
                  ? _MedeAltura(
                      aoMedir: app.defineAlturaDoPainel,
                      child: BottomTabs(
                        acima: AcessorioDaHome(navegador: chave),
                      ),
                    )
                  : const BottomTabs())
            : const SizedBox(width: 412),
      ),
    );
  }

  /// O bicho da pessoa — espécie, pelagem, estágio e roupa — radiante.
  Widget _bichoComemorando(AppState app) => PetView(
    species: app.species,
    mood: Mood.radiant,
    activity: Activity.idle,
    coat: app.color,
    estagio: app.estagioVisivel,
    roupas: app.roupasDoBicho,
    roupaDeCabeca: app.roupaDeCabeca,
    interativo: false,
    width: 180,
    height: 150,
  );

  /// Conquista aparece por cima de qualquer tela, inclusive da sessão.
  Widget _celebracao(AppState app) {
    final t = app.t;
    final raiz = app.raizACelebrar;
    if (raiz != null) {
      return CenaDaRaiz(
        key: ValueKey('raiz-$raiz'),
        dias: raiz,
        recorde: app.raizRecorde,
        aoFechar: app.celebrou,
      );
    }
    final cumpridas = app.missoesACumprir;
    if (cumpridas.isNotEmpty || app.descansoACumprir) {
      final descanso = app.missaoDoDescanso;
      final antes = {for (final c in app.missoesCumpridas) c.antes.id: c.antes};
      return CenaDaMissao(
        key: ValueKey(
          'missao-${cumpridas.map((m) => m.id).join()}'
          '${app.descansoACumprir ? '-descanso' : ''}',
        ),
        missoes: [
          for (final m in cumpridas)
            MissaoNaCena(
              titulo: tituloDaMissao(app, m),
              de: antes[m.id]?.fracao ?? 0,
              folhas: m.folhas,
              xp: m.xp,
            ),
          if (app.descansoACumprir)
            MissaoNaCena(
              titulo: tituloDoDescanso(t, descanso),
              de: 0,
              folhas: descanso.folhas,
              xp: descanso.xp,
            ),
        ],
        bicho: _bichoComemorando(app),
        titulo: cumpridas.length + (app.descansoACumprir ? 1 : 0) == 1
            ? t.missaoCumprida
            : t.missoesCumpridas,
        rotuloColher: t.colherAgora,
        rotuloDepois: t.colherDepois,
        aoColher: app.colheAsCumpridas,
        aoFechar: app.celebrou,
      );
    }
    if (app.cresceuSemCelebrar) {
      return CenaDoCrescimento(
        // A chave muda com o estágio: duas viradas seguidas são duas cenas,
        // não a mesma reaproveitada pela metade.
        key: ValueKey('crescimento-${app.species.name}-${app.estagio.name}'),
        antes: app.estagioJaVisto,
        depois: app.estagio,
        aoFechar: app.celebrou,
      );
    }
    if (app.subiuDeNivel) {
      return Celebracao(
        titulo: t.fill(t.celebNivel, {'n': app.nivel}),
        subtitulo: t.fill(t.celebNivelSub, {'a': app.displayName}),
        icone: Icons.local_florist_rounded,
        // Nível é conquista: mel (ADR-027).
        cor: Cores.mel400,
        // Nível é recompensa: sai da toca, cavada.
        precisaCavar: true,
        tituloDaToca: t.tocaTitulo,
        ajudaDaToca: t.tocaAjuda,
        bicho: _bichoComemorando(app),
        aoFechar: app.celebrou,
      );
    }
    if (app.marcosACelebrar.isEmpty) {
      // A saudação da chegada. Vem por último de propósito: conquista real
      // ganha a cena antes de "bom te ver".
      return Celebracao(
        titulo: t.celebChegada,
        subtitulo: t.fill(t.celebChegadaSub, {'a': app.displayName}),
        icone: Icons.favorite_rounded,
        cor: Cores.afeto,
        bicho: _bichoComemorando(app),
        som: SomDoBaru.chegada,
        aoFechar: app.celebrou,
      );
    }
    final marco = app.marcosACelebrar.first;
    return Celebracao(
      titulo: t.celebMarco,
      // O prêmio pelo nome, e não só o marco: "+20 folhas" não aparecia.
      subtitulo: [
        tituloDoMarco(app, marco),
        ...premiosDoMarco(app, marco),
      ].join(' · '),
      tituloDaToca: t.tocaTitulo,
      ajudaDaToca: t.tocaAjuda,
      cor: Cores.mel400,
      bicho: _bichoComemorando(app),
      // Marco da trilha também é recompensa. A saudação da chegada, logo
      // acima, não é — e por isso continua chegando sozinha.
      precisaCavar: true,
      som: SomDoBaru.marco,
      aoFechar: app.celebrou,
    );
  }
}
