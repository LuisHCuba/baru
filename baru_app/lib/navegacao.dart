/// Rotas de verdade.
///
/// Até aqui a navegação era uma variável de estado lida por um `switch`: sem
/// pilha, sem histórico, sem URL — e, o que o usuário sentia primeiro, **o
/// botão voltar do Android fechava o app** em qualquer tela.
///
/// Três coisas moram aqui:
///
/// **Classificação.** Cada tela é destino, detalhe, modal ou fluxo. É a
/// classificação que decide se ela empilha ou substitui, que transição usa, e
/// o que o voltar faz a partir dela.
///
/// **Transição.** Irmãos deslizam de lado, filho entra em profundidade, modal
/// sobe de baixo. Nada de corte seco. As distâncias e curvas vêm de
/// `design/motion.dart` — nenhum número aqui.
///
/// **Endereço.** Cada tela tem um caminho, então o app tem deep link e o
/// navegador do Chrome mostra onde você está.
library;

import 'package:flutter/material.dart';

import 'design/motion.dart';
import 'models.dart';
import 'state.dart';

/// O papel de uma tela na hierarquia. É isto que o voltar consulta.
enum TipoDeRota {
  /// Destino de primeiro nível: os quatro da barra fixa. Trocar de destino
  /// não empilha — uma barra de destinos não acumula histórico entre abas.
  destino,

  /// Filho de um destino. Empilha e entra em profundidade.
  detalhe,

  /// Sobe por cima de tudo e pode ser dispensado.
  modal,

  /// Toma a tela inteira e não tem irmãos: onboarding, sessão de foco.
  fluxo,
}

extension RotaDaTela on AppScreen {
  TipoDeRota get tipo => switch (this) {
        AppScreen.home ||
        AppScreen.trilha ||
        AppScreen.missoes ||
        AppScreen.profile =>
          TipoDeRota.destino,
        AppScreen.report ||
        AppScreen.shop ||
        AppScreen.tempo ||
        AppScreen.result =>
          TipoDeRota.detalhe,
        AppScreen.paywall => TipoDeRota.modal,
        AppScreen.onb || AppScreen.session => TipoDeRota.fluxo,
      };

  /// Endereço da tela. Muda o que aparece na barra do navegador na web e é o
  /// que um deep link no telefone resolve.
  String get caminho => switch (this) {
        AppScreen.home => '/',
        AppScreen.trilha => '/trilha',
        AppScreen.missoes => '/missoes',
        AppScreen.profile => '/ajustes',
        AppScreen.report => '/relatorio',
        AppScreen.shop => '/loja',
        AppScreen.tempo => '/tempo',
        AppScreen.result => '/resultado',
        AppScreen.paywall => '/assinatura',
        AppScreen.session => '/sessao',
        AppScreen.onb => '/comecar',
      };

  static AppScreen? deCaminho(String caminho) {
    final limpo = caminho.isEmpty ? '/' : caminho;
    for (final s in AppScreen.values) {
      if (s.caminho == limpo) return s;
    }
    return null;
  }
}

/// Uma página da pilha. A transição sai do tipo da rota, não do chamador —
/// assim a mesma tela nunca entra de dois jeitos diferentes.
class PaginaBaru extends Page<void> {
  const PaginaBaru({required this.tela, required this.filho})
      : super(key: const ValueKey(0));

  final AppScreen tela;
  final Widget filho;

  @override
  LocalKey get key => ValueKey(tela);

  @override
  String get name => tela.caminho;

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder<void>(
      settings: this,
      transitionDuration: Movimento.duracao(context, Tempo.tela),
      reverseTransitionDuration: Movimento.duracao(context, Tempo.componente),
      opaque: true,
      pageBuilder: (_, __, ___) => filho,
      transitionsBuilder: (context, entra, sai, child) =>
          _transicao(context, tela.tipo, entra, sai, child),
    );
  }

  static Widget _transicao(
    BuildContext context,
    TipoDeRota tipo,
    Animation<double> entra,
    Animation<double> sai,
    Widget child,
  ) {
    final suave = CurvedAnimation(parent: entra, curve: Curvas.padrao);
    switch (tipo) {
      case TipoDeRota.destino:
        // Irmãos: um empurrãozinho lateral e fade. Sem direção "certa" —
        // a barra pode pular de qualquer aba para qualquer outra.
        final d = Movimento.amplitude(context, Desloca.irmao);
        return FadeTransition(
          opacity: suave,
          child: SlideTransition(
            position: Tween(
              begin: Offset(d, 0),
              end: Offset.zero,
            ).animate(suave),
            child: child,
          ),
        );
      case TipoDeRota.detalhe:
        // Filho: entra em profundidade — vem de trás e cresce.
        final z = Movimento.amplitude(context, Desloca.profundidade);
        return FadeTransition(
          opacity: suave,
          child: ScaleTransition(
            scale: Tween(begin: 1 - z * 2, end: 1.0).animate(suave),
            child: child,
          ),
        );
      case TipoDeRota.modal:
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: entra, curve: Curvas.enfatica)),
          child: child,
        );
      case TipoDeRota.fluxo:
        return FadeTransition(opacity: suave, child: child);
    }
  }
}

/// Liga a pilha do [AppState] ao `Navigator` e ao botão voltar do sistema.
class BaruRouterDelegate extends RouterDelegate<AppScreen>
    with ChangeNotifier {
  BaruRouterDelegate({required this.app, required this.paginaDe}) {
    app.addListener(notifyListeners);
  }

  final AppState app;

  /// Constrói o widget de cada tela. Fica de fora para este arquivo não
  /// depender de todas as telas — e para o teste poder usar telas falsas.
  final Widget Function(AppScreen) paginaDe;

  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  AppScreen get currentConfiguration => app.screen;

  @override
  void dispose() {
    app.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        for (final tela in app.pilha)
          PaginaBaru(tela: tela, filho: paginaDe(tela)),
      ],
      onDidRemovePage: (pagina) {
        final tela = (pagina as PaginaBaru).tela;
        app.removeDaPilha(tela);
      },
    );
  }

  /// O voltar do sistema.
  ///
  /// Primeiro o que estiver por cima das páginas — um `showModalBottomSheet`,
  /// um diálogo. Só depois a pilha do app. `false` devolve a decisão ao
  /// sistema, que no Android fecha o app: é o único lugar onde isso é certo.
  @override
  Future<bool> popRoute() async {
    final nav = navigatorKey.currentState;
    if (nav != null && nav.canPop()) return nav.maybePop();
    return app.voltar();
  }

  /// O caminho do arranque.
  ///
  /// A plataforma entrega `/` quando **não** há deep link, e isso não é uma
  /// escolha do usuário: honrá-lo jogava fora a tela em que ele estava quando
  /// fechou o app — abrir em Ajustes e cair na home.
  @override
  Future<void> setInitialRoutePath(AppScreen configuration) async {
    if (configuration == AppScreen.home) return;
    app.abrePorEndereco(configuration);
  }

  @override
  Future<void> setNewRoutePath(AppScreen configuration) async {
    app.abrePorEndereco(configuration);
  }
}

/// Traduz URL em tela e vice-versa.
class BaruRouteParser extends RouteInformationParser<AppScreen> {
  const BaruRouteParser();

  @override
  Future<AppScreen> parseRouteInformation(RouteInformation routeInformation) async {
    return RotaDaTela.deCaminho(routeInformation.uri.path) ?? AppScreen.home;
  }

  @override
  RouteInformation restoreRouteInformation(AppScreen configuration) {
    return RouteInformation(uri: Uri.parse(configuration.caminho));
  }
}
