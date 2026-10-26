// O "voltar" com uma cena de conquista na frente (reauditoria da Onda 2,
// V1 e V2).
import 'package:baru_app/models.dart';
import 'package:baru_app/navegacao.dart';
import 'package:baru_app/services/som_service.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/widgets/celebracao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => SomService.instance.tocador = (_) async {});
  tearDown(() => SomService.instance.tocador = null);

  testWidgets('V2: o 1º voltar fecha a cena, não a tela de resultado de baixo',
      (tester) async {
    final app = AppState()
      ..onb = 9
      ..companionshipStarted = true
      ..petName = 'Nina'
      ..debugFast = false;
    addTearDown(app.dispose);
    app.startSession();
    app.sessionEndsAt = DateTime.now().subtract(const Duration(seconds: 1));
    app.reconcileSession();
    app.liberaCelebracoes();
    expect(app.pilha.last, AppScreen.result);
    expect(app.cenaNaFrente, isTrue, reason: 'a 1ª sessão traz cena');

    final delegate = BaruRouterDelegate(
      app: app,
      paginaDe: (tela) => const SizedBox.expand(),
    );
    addTearDown(delegate.dispose);
    await tester.pumpWidget(MaterialApp.router(
      routerDelegate: delegate,
      routeInformationParser: const BaruRouteParser(),
    ));
    await tester.pump(const Duration(seconds: 1));

    expect(app.raizACelebrar, isNotNull, reason: 'a 1ª da fila é a raiz');
    expect(await delegate.popRoute(), isTrue);
    await tester.pump(const Duration(seconds: 1));
    expect(app.pilha.last, AppScreen.result,
        reason: 'a tela de resultado continua debaixo da cena');
    expect(app.raizACelebrar, isNull, reason: 'a cena da raiz fechou');
  });

  testWidgets('V1: fechar uma cena que pede cavar antes de cavar não estoura',
      (tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(children: [
        Celebracao(
          titulo: 'Nível 2',
          subtitulo: 'Você subiu',
          aoFechar: () {},
          precisaCavar: true,
        ),
      ]),
    ));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
