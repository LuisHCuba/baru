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
import 'design/tokens.dart';
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
        AppScreen.folhas ||
        AppScreen.sequencia ||
        AppScreen.conta ||
        AppScreen.sobreposicao ||
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
        AppScreen.folhas => '/folhas',
        AppScreen.conta => '/conta',
        AppScreen.sobreposicao => '/sobreposicao',
        AppScreen.sequencia => '/sequencia',
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
  const PaginaBaru({
    required this.tela,
    required this.filho,
    this.seguraOVoltarDoSistema = false,
  }) : super(key: const ValueKey(0));

  final AppScreen tela;
  final Widget filho;

  /// Esta página diz ao Android que **o app** trata o voltar.
  ///
  /// Sem isso o app fechava numa aba. O Flutter avisa o Android com
  /// `canHandlePop = navigatorCanPop || routeBlocksPop`; numa aba a pilha
  /// tem uma página só, `canPop()` é falso, e com `targetSdk 36` o
  /// *predictive back* está ligado por padrão — o sistema encerra a
  /// activity sem nunca entregar o evento ao Dart. Numa tela de detalhe há
  /// duas páginas e por isso ali sempre funcionou.
  ///
  /// Um `PopScope(canPop: false)` deixa `routeBlocksPop` verdadeiro, o
  /// Android passa a entregar, e o evento cai no `popRoute` de sempre — a
  /// lógica de `app.voltar()` continua intacta.
  ///
  /// Só na página **de baixo**. Na de cima, `doNotPop` faria o
  /// `maybePop` recusar e nenhuma tela de detalhe voltaria mais.
  final bool seguraOVoltarDoSistema;

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
      // Fundo opaco na própria página.
      //
      // O `Scaffold` da casca fica **atrás** do `Navigator`, então a página
      // em si não tinha fundo: durante a transição dava para ver uma tela
      // através da outra — o efeito fantasma. `opaque: true` na rota diz ao
      // Navigator que ele pode parar de desenhar o que está embaixo; não
      // pinta nada.
      pageBuilder: (_, __, ___) => ColoredBox(
        color: tela == AppScreen.session ? Cores.foco : Cores.superficie,
        child: seguraOVoltarDoSistema
            // Sem `onPopInvokedWithResult`: quem decide é o `popRoute` do
            // delegate. Aqui só se declara que há quem trate.
            ? PopScope(canPop: false, child: filho)
            : filho,
      ),
      transitionsBuilder: (context, entra, sai, child) =>
          _transicao(context, tela.tipo, entra, sai, child),
    );
  }

  /// Eixo compartilhado, no espírito do Material: a tela que sai some
  /// **antes** de a que entra aparecer, em vez de as duas dividirem a tela
  /// meio transparentes.
  ///
  /// Um cross-fade de dois conteúdos opacos é o que produz o fantasma. A
  /// saída ocupa os primeiros 35% do tempo; a entrada, os últimos 65%.
  static Widget _transicao(
    BuildContext context,
    TipoDeRota tipo,
    Animation<double> entra,
    Animation<double> sai,
    Widget child,
  ) {
    final aparece = CurvedAnimation(
      parent: entra,
      curve: const Interval(0.35, 1, curve: Curvas.padrao),
    );
    final move = CurvedAnimation(parent: entra, curve: Curvas.padrao);
    // Quando esta página é a de baixo, `sai` anda: ela recua e some.
    final recua = CurvedAnimation(parent: sai, curve: Curvas.padrao);

    Widget comSaida(Widget dentro) => FadeTransition(
          opacity: Tween(begin: 1.0, end: 0.0).animate(
            CurvedAnimation(
              parent: sai,
              curve: const Interval(0, 0.35, curve: Curvas.saida),
            ),
          ),
          child: dentro,
        );

    switch (tipo) {
      case TipoDeRota.destino:
        // Irmãos: deslizam de lado. Sem direção "certa" — a barra pode pular
        // de qualquer aba para qualquer outra.
        final d = Movimento.amplitude(context, Desloca.irmao);
        return comSaida(
          FadeTransition(
            opacity: aparece,
            child: SlideTransition(
              position: Tween(
                begin: Offset(d, 0),
                end: Offset.zero,
              ).animate(move),
              child: SlideTransition(
                position: Tween(
                  begin: Offset.zero,
                  end: Offset(-d, 0),
                ).animate(recua),
                child: child,
              ),
            ),
          ),
        );
      case TipoDeRota.detalhe:
        // Filho: entra em profundidade — vem de trás e cresce, enquanto o pai
        // afunda um pouco.
        final z = Movimento.amplitude(context, Desloca.profundidade);
        return comSaida(
          FadeTransition(
            opacity: aparece,
            child: ScaleTransition(
              scale: Tween(begin: 1 - z * 2.5, end: 1.0).animate(move),
              child: ScaleTransition(
                scale: Tween(begin: 1.0, end: 1 - z).animate(recua),
                child: child,
              ),
            ),
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
        return comSaida(FadeTransition(opacity: aparece, child: child));
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
        for (final (i, tela) in app.pilha.indexed)
          PaginaBaru(
            tela: tela,
            filho: paginaDe(tela),
            seguraOVoltarDoSistema: i == 0,
          ),
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
    final uri = routeInformation.uri;
    // `baru://sequencia` tem a tela no **host**, não no caminho: um esquema
    // próprio não põe barra depois dos dois-pontos. É o que o widget da
    // tela inicial manda, e sem isto todo toque abriria a home.
    if (uri.path.isEmpty || uri.path == '/') {
      final porHost = RotaDaTela.deCaminho('/${uri.host}');
      if (porHost != null) return porHost;
    }
    return RotaDaTela.deCaminho(uri.path) ?? AppScreen.home;
  }

  @override
  RouteInformation restoreRouteInformation(AppScreen configuration) {
    return RouteInformation(uri: Uri.parse(configuration.caminho));
  }
}
