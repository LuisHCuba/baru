import 'package:baru_app/data/progressao.dart';
import 'package:baru_app/l10n.dart';
import 'package:baru_app/app.dart';
import 'package:baru_app/data/app_snapshot.dart';
import 'package:baru_app/design/motion.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/screens/settings_screen.dart';
import 'package:baru_app/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {

  Future<void> pumpAt412(WidgetTester tester, AppScreen screen) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(BaruApp(snapshot: _snap(screen)));
    await tester.pump();
    // A tela agora entra por uma rota de verdade, e uma rota em transição
    // ignora ponteiro. Sem esperar a transição, todo toque no teste cai no
    // vazio.
    await tester.pump(Tempo.tela + const Duration(milliseconds: 50));
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
      AppScreen.tempo,
      AppScreen.trilha,
      AppScreen.missoes,
    ]) {
      await pumpAt412(tester, screen);
      expect(tester.takeException(), isNull, reason: 'exceção em ${screen.name}');
    }
  });

  testWidgets('ajustes mostra perfil e permissão de uso', (tester) async {
    await pumpAt412(tester, AppScreen.profile);
    // A raiz e a frase do Baru saíram dos Ajustes, junto com o cartão.
    // Espécie, pelagem e sexo são personalização do bicho: saíram dos
    // Ajustes. Nada da tela leva a eles.
    expect(find.text(T('pt').revealKicker), findsNothing);
    expect(find.text(T('pt').coat), findsNothing);
    expect(find.text(T('pt').setSexo), findsNothing);
    expect(find.text('Capivara'), findsNothing);

    // A folha da espécie continua funcionando, aberta pela API pública
    // que outra tela usará no futuro.
    final ctx = tester.element(find.byType(SettingsScreen));
    SettingsScreen.abreEspecie(ctx, AppScope.of(ctx));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text('Lontra'),
      findsOneWidget,
      reason: 'a folha tem de abrir com as opções',
    );
    await tester.tap(find.text('Lontra'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      AppScope.of(ctx).species,
      Species.otter,
      reason: 'escolhida, ela vira a espécie do Baru',
    );
    await tester.scrollUntilVisible(
      find.text('Permitir acesso ao uso'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Permitir acesso ao uso'), findsOneWidget);
    // Privacidade, termos e "refazer a apresentação" moram em Sua conta.
    expect(find.text('Refazer a apresentação'), findsNothing);
  });

  testWidgets('ajustes abre privacidade', (tester) async {
    await pumpAt412(tester, AppScreen.profile);
    expect(find.byType(SettingsScreen), findsOneWidget);
    // A conta fica no topo dos Ajustes; a privacidade, dentro dela.
    await tester.tap(find.byKey(SettingsScreen.chaveConta));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.scrollUntilVisible(
      find.text('Privacidade e seus dados'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    // Pumps limitados, não `pumpAndSettle`: o companheiro respira em laço
    // infinito, então a árvore nunca fica quieta enquanto ele estiver em
    // cena. Com a tela de ajustes mais curta ele deixou de sair do viewport.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Privacidade e seus dados'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      find.textContaining('o total diário de tempo de tela'),
      findsOneWidget,
    );
  });

  testWidgets('tabs usam ícones Material no lugar dos quadrados', (tester) async {
    await pumpAt412(tester, AppScreen.home);
    // Três abas: Família, Baru (a home) e Ajustes.
    expect(find.byIcon(Icons.people_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });

  testWidgets('home anuncia tabs e streak no singular', (tester) async {
    final semantica = tester.ensureSemantics();
    await pumpAt412(tester, AppScreen.home);
    // Na home a raiz é um número no indicador; o texto inteiro ("Raiz de 1
    // dia") é o que o leitor de tela anuncia.
    expect(find.bySemanticsLabel(T('pt').streakOne), findsWidgets);
    expect(find.text('Baru'), findsWidgets);
    // Missões e Trilha viraram um atalho só no painel do Baru.
    expect(find.text('Missões · Trilha'), findsOneWidget);
    // A home é o mundo dele: o foco fica sempre à vista, sem rolar.
    expect(find.text('Começar foco'), findsOneWidget);
    semantica.dispose();
  });
}
