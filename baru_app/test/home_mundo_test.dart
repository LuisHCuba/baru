import 'package:baru_app/app.dart';
import 'package:baru_app/data/app_snapshot.dart';
import 'package:baru_app/data/progressao.dart';
import 'package:baru_app/design/motion.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/screens/home_screen.dart';
import 'package:baru_app/screens/trilha_screen.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/widgets/mundo/mundo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A home é o mundo dele: a cena de borda a borda, a interface por cima,
/// o resto do dia na folha "Seu dia".

AppSnapshot _snap(AppScreen screen) {
  final now = DateTime.now();
  return AppSnapshot(
    screen: screen,
    onb: 5,
    lang: 'pt',
    species: Species.capybara,
    // A trilha passou a cobrar a espécie que entrega, e a lontra é prêmio
    // de degrau. Sem o marco, a folha abre com ela **travada** e o toque
    // não faz nada — o teste falharia por uma regra nova e correta, e
    // afrouxar a porta para ele passar apagaria a regra.
    marcosResgatados: [
      trilha.firstWhere((m) => m.recompensa.especie == Species.otter).id,
    ],
    q0: 'Água',
    q1: 'À tarde',
    q2: 'Uma rotina',
    leaves: 40,
    streak: 1,
    usage: 20,
    goal: 180,
    avg: 240,
    petName: 'Baru',
    color: 0,
    owned: const ['lily'],
    dur: 25,
    completedToday: 1,
    abandonedToday: false,
    daysAway: 0,
    trial: false,
    evening: true,
    missed: true,
    payPlan: PayPlan.annual,
    usageAccess: false,
    companionshipStarted: true,
    week: freshWeek(now),
    todayIndex: weekdayIndex(now),
    freezesLeft: 1,
    trialStartedAt: null,
    lastOpenDate: DateTime(now.year, now.month, now.day),
    sessions: const [],
  );
}

Future<AppState> _abre(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(BaruApp(snapshot: _snap(AppScreen.home)));
  await tester.pump();
  await tester.pump(Tempo.tela + const Duration(milliseconds: 50));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  return (tester.state(find.byType(BaruApp)) as dynamic).state as AppState;
}

Future<void> _fecha(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('a home é o mundo: sem lista, foco à vista, ele falando', (
    tester,
  ) async {
    await _abre(tester);
    expect(find.byType(MundoDoBaru), findsOneWidget);
    expect(find.text('Começar foco'), findsOneWidget);
    expect(find.byKey(HomeScreen.balaoKey), findsOneWidget);
    expect(find.byKey(const Key('home-humor-cap')), findsOneWidget);
    // Os cartões não estão na home: moram no "Seu dia".
    expect(find.byKey(CartaoNivel.chave), findsNothing);
    await _fecha(tester);
  });

  testWidgets('"Seu dia" sobe com os cartões do dia', (tester) async {
    await _abre(tester);
    await tester.tap(find.byKey(HomeScreen.seuDiaKey));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(find.byKey(CartaoNivel.chave), findsOneWidget);
    await _fecha(tester);
  });

  testWidgets('a duração escolhe-se numa folha e vale para o foco', (
    tester,
  ) async {
    final app = await _abre(tester);
    await tester.tap(find.byKey(const Key('home-duracao')));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    await tester.tap(find.text('50min').last);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(app.dur, 50);
    await _fecha(tester);
  });

  testWidgets('o chip da lagoa leva a câmera até lá', (tester) async {
    await _abre(tester);
    final mundo = tester.state<MundoDoBaruState>(find.byType(MundoDoBaru));
    final antes = mundo.cameraX;
    await tester.tap(find.text('Lagoa'));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(mundo.cameraX, greaterThan(antes + 50));
    await _fecha(tester);
  });
}
