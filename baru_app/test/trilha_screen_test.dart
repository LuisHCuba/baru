import 'package:baru_app/data/progressao.dart';
import 'package:baru_app/screens/trilha_screen.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/widgets/componentes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A tela que responde "por que eu volto amanhã".
///
/// O §4 exige que o usuário **sempre** saiba qual é o próximo passo e o que
/// ganha nele. Isso é o que estes testes conferem.

AppState _conta({int xp = 0, int sessoes = 0, bool comecou = true}) {
  final s = AppState();
  if (comecou) s.startCompanionship();
  s.xp = xp;
  s.sessoesConcluidas = sessoes;
  return s;
}

Future<void> _abre(WidgetTester tester, AppState app) async {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppScope(state: app, child: const TrilhaScreen()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('mostra nível, XP e quanto falta para o próximo',
      (tester) async {
    final app = _conta(xp: 25);
    await _abre(tester, app);

    expect(find.byKey(CartaoNivel.chave), findsOneWidget);
    expect(find.text(app.t.fill(app.t.nivelRotulo, {'n': 1})), findsOneWidget);
    expect(
      find.text(
        app.t.fill(app.t.nivelFalta, {'x': app.xpParaProximoNivel, 'n': 2}),
      ),
      findsOneWidget,
      reason: 'o usuário precisa saber quanto falta, não só onde está',
    );
  });

  testWidgets('o próximo passo é destacado e diz o que ganha', (tester) async {
    final app = _conta();
    await _abre(tester, app);

    expect(find.byKey(CartaoProximoPasso.chave), findsOneWidget);
    expect(find.text(app.t.trilhaProximo), findsOneWidget);

    final proximo = app.proximoMarco!;
    // Aparece duas vezes de propósito: no resumo do topo e no degrau da
    // trilha. A trilha é longa e rolável; sem o resumo o usuário teria de
    // procurar onde está para saber o que fazer.
    expect(find.text(tituloDoMarco(app, proximo)), findsNWidgets(2));
    for (final premio in premiosDoMarco(app, proximo)) {
      expect(
        find.text(premio),
        findsWidgets,
        reason: 'o prêmio do próximo passo tem de estar visível',
      );
    }
  });

  testWidgets('marco alcançado mostra o ✓ no nó e diz "conquistado" ao abrir',
      (tester) async {
    final app = _conta(sessoes: 1)..ganhaXp(1);
    await _abre(tester, app);

    final primeiro = trilha.first;
    expect(app.progresso.alcancou(primeiro), isTrue);

    // No caminho o sinal é o ✓ dentro do nó, não a palavra: o rótulo ao lado
    // é o nome do marco.
    expect(
      find.byIcon(Icons.check_rounded),
      findsWidgets,
      reason: 'o que já passou tem de se ver de relance',
    );

    // A palavra vive no detalhe do nó.
    await tester.tap(find.text(tituloDoMarco(app, primeiro)).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(app.t.trilhaFeito), findsWidgets);
  });

  testWidgets('marco não alcançado mostra progresso x de y ao abrir', (
    tester,
  ) async {
    final app = _conta(sessoes: 3);
    await _abre(tester, app);

    // No caminho o progresso é o anel em volta do nó; o número exato vive no
    // detalhe. Cinco sessões está em 3/5.
    final marco = trilha.firstWhere((m) => m.id == 'cinco_focos');
    await tester.scrollUntilVisible(
      find.text(tituloDoMarco(app, marco)),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(tituloDoMarco(app, marco)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('3/5'), findsOneWidget);
  });

  testWidgets('todos os marcos da trilha aparecem', (tester) async {
    final app = _conta();
    await _abre(tester, app);

    final lista = find.byType(Scrollable).first;
    final proximo = app.proximoMarco;
    for (final m in trilha) {
      // O marco atual já aparece no resumo do topo; rolar até ele acharia
      // dois widgets com o mesmo texto.
      if (m.id == proximo?.id) {
        expect(find.text(tituloDoMarco(app, m)), findsWidgets, reason: m.id);
        continue;
      }
      await tester.scrollUntilVisible(
        find.text(tituloDoMarco(app, m)),
        160,
        scrollable: lista,
      );
      expect(find.text(tituloDoMarco(app, m)), findsOneWidget, reason: m.id);
    }
  });

  testWidgets('antes do onboarding a trilha não fica em branco',
      (tester) async {
    final app = _conta(comecou: false);
    await _abre(tester, app);
    expect(find.text(app.t.trilhaVaziaT), findsOneWidget);
  });

  testWidgets('as barras e o contador são animados', (tester) async {
    final app = _conta(xp: 30, sessoes: 2);
    await _abre(tester, app);
    expect(find.byType(BarraAnimada), findsWidgets);
    expect(find.byType(ContadorAnimado), findsWidgets);
  });

  testWidgets('cabe em 412x892 sem overflow', (tester) async {
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) {
        fail(details.exceptionAsString());
      }
    };
    final app = _conta(xp: 400, sessoes: 22);
    await _abre(tester, app);
    expect(tester.takeException(), isNull);
  });

  testWidgets('os títulos e prêmios existem nos 4 idiomas', (tester) async {
    for (final lang in ['pt', 'en', 'es', 'zh']) {
      final app = _conta()..lang = lang;
      for (final m in trilha) {
        final titulo = tituloDoMarco(app, m);
        expect(titulo, isNotEmpty, reason: '${m.id}/$lang');
        expect(titulo, isNot(contains('{')), reason: '${m.id}/$lang');
        for (final p in premiosDoMarco(app, m)) {
          expect(p, isNot(contains('{')), reason: '${m.id}/$lang');
        }
      }
    }
  });
}
