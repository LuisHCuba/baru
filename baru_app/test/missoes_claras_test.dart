import 'package:baru_app/data/missoes.dart';
import 'package:baru_app/screens/missoes_screen.dart';
import 'package:baru_app/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// As missões dizem o que fazer e levam onde se faz.
///
/// A queixa foi "não sei exatamente o que eu tenho que fazer". O título já
/// dizia o alvo — "Faça 2 sessões de foco" —, mas nada dizia onde se faz
/// uma sessão, e o cartão não levava a lugar nenhum.

AppState _app() {
  final a = AppState()
    ..onb = 9
    ..companionshipStarted = true;
  return a;
}

void main() {
  test('toda missão tem um "como" e um destino', () {
    final app = _app();
    addTearDown(app.dispose);

    // Sem exceção: um tipo novo sem "como" seria um cartão que não explica
    // nada, e o `switch` exaustivo faz isso falhar na compilação — este
    // teste cobre o outro lado, o texto vazio.
    for (final tipo in TipoDeMissao.values) {
      final m = app.missoes.firstWhere(
        (x) => x.definicao.tipo == tipo,
        orElse: () => app.missoes.first,
      );
      if (m.definicao.tipo != tipo) continue;
      expect(comoDaMissao(app, m), isNotEmpty, reason: tipo.name);
      expect(destinoDaMissao(m), isNotNull, reason: tipo.name);
    }
  });

  testWidgets('o cartão mostra o "como" embaixo do título', (tester) async {
    final app = _app();
    addTearDown(app.dispose);
    final missao = app.missoes.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppScope(state: app, child: const MissoesScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(tituloDaMissao(app, missao)), findsOneWidget);
    expect(
      find.text(comoDaMissao(app, missao)),
      findsWidgets,
      reason: 'sem esta linha a missão vira placar, não tarefa',
    );
  });

  testWidgets('tocar numa missão por fazer leva ao lugar de fazer', (
    tester,
  ) async {
    final app = _app();
    addTearDown(app.dispose);
    final missao = app.missoes.firstWhere((m) => !m.resgatavel);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppScope(state: app, child: const MissoesScreen()),
        ),
      ),
    );
    await tester.pump();

    final antes = app.screen;
    await tester.tap(find.byKey(CartaoDeMissao.chaveDe(missao.id)));
    await tester.pump();

    expect(app.screen, destinoDaMissao(missao));
    expect(app.screen, isNot(antes));
  });
}
