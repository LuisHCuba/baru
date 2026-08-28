import 'dart:async';

import 'package:flutter/material.dart';

import 'data/app_snapshot.dart';
import 'data/repositories.dart';
import 'services/notification_service.dart';
import 'services/som_service.dart';
import 'services/vigia_service.dart';
import 'services/widget_service.dart';
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
import 'widgets/saida.dart';
import 'widgets/share_sheet.dart';

class BaruApp extends StatefulWidget {
  const BaruApp({
    super.key,
    this.repos,
    this.snapshot,
    this.bootstrapNotice,
  });

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
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
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
    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
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
    }
    if (s == AppLifecycleState.resumed) {
      // Antes do calendário: uma sessão que terminou ontem tem de contar como
      // presença de ontem, e é o avanço de calendário que fecha aquele dia.
      state.reconcileSession();
      state.applyCalendar(DateTime.now());
      state.syncPermissionsFromOs();
      // Voltar do background é o momento em que a rede costuma ter voltado.
      state.retryPendingSync();
    }
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
            builder: (context, navegador) =>
                AppFrame(child: _Casca(navegador: navegador!)),
          );
        },
      ),
    );
  }
}

class _Casca extends StatelessWidget {
  const _Casca({required this.navegador});

  final Widget navegador;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      backgroundColor: app.screen == AppScreen.session
          ? AppColors.sessionBg
          : AppColors.cream,
      body: SafeArea(
        bottom: !app.showTabs,
        child: Stack(
          children: [
            navegador,
            if (app.sharing) const ShareSheet(),
            if (app.temCelebracaoPendente) _celebracao(app),
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
        child: app.showTabs ? const BottomTabs() : const SizedBox(width: 412),
      ),
    );
  }

  /// Conquista aparece por cima de qualquer tela, inclusive da sessão.
  Widget _celebracao(AppState app) {
    final t = app.t;
    if (app.subiuDeNivel) {
      return Celebracao(
        titulo: t.fill(t.celebNivel, {'n': app.nivel}),
        subtitulo: t.fill(t.celebNivelSub, {'a': app.displayName}),
        icone: Icons.local_florist_rounded,
        cor: Cores.primaria,
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
        cor: Cores.acento,
        aoFechar: app.celebrou,
      );
    }
    final marco = app.marcosACelebrar.first;
    return Celebracao(
      titulo: t.celebMarco,
      subtitulo: tituloDoMarco(app, marco),
      cor: Cores.acento,
      aoFechar: app.celebrou,
    );
  }

}
