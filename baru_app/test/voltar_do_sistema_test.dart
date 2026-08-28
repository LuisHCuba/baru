import 'package:baru_app/models.dart';
import 'package:baru_app/navegacao.dart';
import 'package:baru_app/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// O voltar do aparelho numa aba.
///
/// O app fechava quando se apertava voltar na trilha. A causa não estava em
/// `app.voltar()` — estava antes: o Android nunca entregava o evento.
///
/// O Flutter avisa o sistema com
/// `canHandlePop = navigatorCanPop || routeBlocksPop`
/// (`NavigatorState._handleHistoryChanged`). Numa aba a pilha tem uma
/// página só, `canPop()` é falso e nenhuma rota bloqueia — então
/// `canHandlePop` é falso. Com `targetSdk 36` o *predictive back* vem
/// ligado por padrão, e nesse caso o sistema encerra a activity sem chamar
/// o Dart. Numa tela de detalhe há duas páginas e por isso ali funcionava.
///
/// O que se prova aqui é que a rota de baixo **declara** que bloqueia o
/// pop. É o que faz o Android entregar o evento; o que fazer com ele já é
/// `app.voltar()`, testado em outro lugar.

RoutePopDisposition _disposicaoDoTopo(WidgetTester tester) {
  final estado = tester.state<NavigatorState>(find.byType(Navigator));
  late RoutePopDisposition d;
  estado.popUntil((rota) {
    d = rota.popDisposition;
    return true;
  });
  return d;
}

Future<AppState> _monta(WidgetTester tester, AppScreen tela) async {
  final app = AppState()
    ..onb = 9
    ..companionshipStarted = true;
  addTearDown(app.dispose);
  app.go(tela);

  // Uma página qualquer serve: o que está em teste é a rota, não o
  // conteúdo dela.
  final delegate = BaruRouterDelegate(
    app: app,
    paginaDe: (tela) => const SizedBox.expand(),
  );
  addTearDown(delegate.dispose);

  await tester.pumpWidget(
    MaterialApp.router(
      routerDelegate: delegate,
      routeInformationParser: const BaruRouteParser(),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  return app;
}

void main() {
  testWidgets('numa aba, a rota de baixo segura o voltar do sistema', (
    tester,
  ) async {
    final app = await _monta(tester, AppScreen.trilha);

    expect(app.pilha.length, 1, reason: 'aba não empilha');
    expect(
      _disposicaoDoTopo(tester),
      RoutePopDisposition.doNotPop,
      reason: 'sem isto o Android encerra a activity e o app some',
    );
  });

  testWidgets('na home também, senão o popup de saída nunca aparece', (
    tester,
  ) async {
    await _monta(tester, AppScreen.home);
    expect(_disposicaoDoTopo(tester), RoutePopDisposition.doNotPop);
  });

  testWidgets('num detalhe, a rota de cima pop normalmente', (tester) async {
    // Aqui `canPop()` já é verdadeiro, então declarar `doNotPop` no topo
    // seria pior que o problema: o `maybePop` recusaria e nenhuma tela de
    // detalhe voltaria mais.
    final app = await _monta(tester, AppScreen.folhas);

    expect(app.pilha.length, greaterThan(1));
    expect(_disposicaoDoTopo(tester), RoutePopDisposition.pop);
  });
}
