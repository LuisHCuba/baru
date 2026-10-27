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

  testWidgets('o bicho responde ao toque em qualquer ponto do mundo', (
    tester,
  ) async {
    // A caixa do mundo tinha uma tela de largura: o toque não chegava ao
    // bicho, que nasce no meio de um mundo de 2,6 telas (auditoria, 1).
    await _abre(tester);
    expect(find.byKey(const Key('mundo-pet')).hitTestable(), findsOneWidget);
    await _fecha(tester);
  });

  testWidgets('a home tem um indicador, um painel e nada por cima do mundo', (
    tester,
  ) async {
    await _abre(tester);
    expect(find.byKey(HomeScreen.indicadorKey), findsOneWidget);
    // Sem chips de zona nem botões soltos sobre a cena (pesquisa 23).
    expect(find.text('Lagoa'), findsNothing);
    expect(find.text('Toca'), findsNothing);
    expect(find.byIcon(Icons.palette_outlined), findsNothing);
    expect(find.byIcon(Icons.photo_camera_outlined), findsNothing);
    // A ação e a duração vivem no painel das abas, embaixo de tudo.
    final acao = tester.getRect(find.text('Começar foco'));
    final aba = tester.getRect(find.text('Missões'));
    expect(acao.bottom, lessThan(aba.top));
    expect(acao.top, greaterThan(892 * 0.7));
    await _fecha(tester);
  });

  testWidgets('o painel sai da frente do pedido para sair', (tester) async {
    // O "Começar foco" mora na casca, fora da cena: sem isto ele ficava
    // tocável por baixo do pedido para sair (auditoria de dcf82c9, 1).
    final app = await _abre(tester);
    expect(find.text('Começar foco'), findsOneWidget);
    app.pedindoParaSair = true;
    app.notifyListeners();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(find.text('Começar foco').hitTestable(), findsNothing);
    await _fecha(tester);
  });

  testWidgets('um cartão do "Seu dia" fecha a folha ao sair', (tester) async {
    final app = await _abre(tester);
    await tester.tap(find.byKey(HomeScreen.seuDiaKey));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(app.folhasDaHome, 1);
    app.go(AppScreen.report);
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(app.folhasDaHome, 0);
    app.voltar();
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(app.screen, AppScreen.home);
    expect(find.text('Começar foco'), findsOneWidget);
    await _fecha(tester);
  });

  testWidgets('a fala some sozinha, sem deixar ícone na cabeça dele', (
    tester,
  ) async {
    await _abre(tester);
    expect(find.byKey(HomeScreen.balaoKey).hitTestable(), findsOneWidget);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.byKey(HomeScreen.balaoKey).hitTestable(), findsNothing);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
    await _fecha(tester);
  });

  testWidgets('voltando de uma tela de detalhe, ele fala de novo', (
    tester,
  ) async {
    final app = await _abre(tester);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.byKey(HomeScreen.balaoKey).hitTestable(), findsNothing);
    app.go(AppScreen.report);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    app.voltar();
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(find.byKey(HomeScreen.balaoKey).hitTestable(), findsOneWidget);
    await _fecha(tester);
  });
}
