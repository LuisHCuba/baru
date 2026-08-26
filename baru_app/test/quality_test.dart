import 'package:baru_app/app.dart';
import 'package:baru_app/data/app_snapshot.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

AppSnapshot _snap(AppScreen screen) {
  final now = DateTime.now();
  return AppSnapshot(
    screen: screen,
    onb: 5,
    lang: 'pt',
    species: Species.capybara,
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

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> pumpAt412(WidgetTester tester, AppScreen screen) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(BaruApp(snapshot: _snap(screen)));
    await tester.pump();
  }

  testWidgets('8 telas cabem em 412×892 sem overflow', (tester) async {
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      if (text.contains('overflowed') || text.contains('OVERFLOW')) {
        fail(text);
      }
    };

    for (final screen in [
      AppScreen.onb,
      AppScreen.home,
      AppScreen.session,
      AppScreen.result,
      AppScreen.report,
      AppScreen.shop,
      AppScreen.profile,
      AppScreen.paywall,
    ]) {
      await pumpAt412(tester, screen);
      expect(tester.takeException(), isNull, reason: 'exceção em ${screen.name}');
    }
  });

  testWidgets('ajustes mostra perfil e permissão de uso', (tester) async {
    await pumpAt412(tester, AppScreen.profile);
    expect(find.text('Você é uma capivara.'), findsOneWidget);
    expect(find.text('Capivara'), findsOneWidget);
    expect(find.text('Lontra'), findsOneWidget);
    expect(find.text('PELAGEM'), findsOneWidget);
    expect(find.text('1 dia presente'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Permitir acesso ao uso'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Permitir acesso ao uso'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Refazer o onboarding'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
  });

  testWidgets('ajustes abre privacidade', (tester) async {
    await pumpAt412(tester, AppScreen.profile);
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Política de privacidade'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -90));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Política de privacidade'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('só o total de tempo de tela'),
      findsOneWidget,
    );
  });

  testWidgets('tabs usam ícones Material no lugar dos quadrados', (tester) async {
    await pumpAt412(tester, AppScreen.home);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
    expect(find.byIcon(Icons.insights_outlined), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });

  testWidgets('home anuncia tabs e streak no singular', (tester) async {
    await pumpAt412(tester, AppScreen.home);
    expect(find.text('1 dia presente'), findsWidgets);
    expect(find.text('Habitat'), findsWidgets);
    expect(find.text('Loja'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Começar foco'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Começar foco'), findsOneWidget);
  });
}
