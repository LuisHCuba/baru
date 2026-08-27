import 'package:baru_app/app.dart';
import 'package:baru_app/data/app_snapshot.dart';
import 'package:baru_app/design/motion.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/navegacao.dart';
import 'package:baru_app/screens/home_screen.dart';
import 'package:baru_app/widgets/saida.dart';
import 'package:baru_app/screens/settings_screen.dart';
import 'package:baru_app/screens/shop_screen.dart';
import 'package:baru_app/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Navegação de verdade.
///
/// A queixa que originou isto foi específica: **"eu clico em voltar pelo
/// celular e ele sai do app"**. Não havia pilha — a tela era uma variável — e
/// o botão voltar do Android nunca era tratado, então o sistema fechava o app
/// de qualquer tela.
///
/// Os testes de widget aqui não conferem se existe um `Navigator`: eles
/// disparam o **voltar do sistema** e olham se `SystemNavigator.pop` foi
/// chamado, que é literalmente o app fechando.

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

/// Aperta o voltar do sistema e diz se o app teria fechado.
///
/// Quando ninguém trata o voltar, o framework chama `SystemNavigator.pop` —
/// e é isso que fecha o app no Android.
Future<bool> _voltarDoSistemaFechaOApp(WidgetTester tester) async {
  var fechou = false;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemNavigator.pop') fechou = true;
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  await tester.binding.handlePopRoute();
  await tester.pump();
  await tester.pump(Tempo.tela + const Duration(milliseconds: 50));
  return fechou;
}

Future<void> _abre(WidgetTester tester, AppScreen tela) async {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(BaruApp(snapshot: _snap(tela)));
  await tester.pump();
  await tester.pump(Tempo.tela + const Duration(milliseconds: 50));
}

AppState _estado(AppScreen tela) => AppState(snapshot: _snap(tela));

void main() {
  group('a pilha', () {
    test('um detalhe empilha e o voltar desempilha', () {
      final s = _estado(AppScreen.home);
      s.go(AppScreen.shop);
      expect(s.pilha, [AppScreen.home, AppScreen.shop]);
      expect(s.voltar(), isTrue);
      expect(s.screen, AppScreen.home);
      s.dispose();
    });

    test('trocar de destino não empilha', () {
      final s = _estado(AppScreen.home);
      s.go(AppScreen.trilha);
      s.go(AppScreen.missoes);
      expect(
        s.pilha,
        [AppScreen.missoes],
        reason: 'uma barra de destinos fixa não acumula histórico entre abas',
      );
      s.dispose();
    });

    test('tocar na aba em que já se está volta à raiz dela', () {
      final s = _estado(AppScreen.home);
      s.go(AppScreen.shop);
      s.go(AppScreen.home);
      expect(s.pilha, [AppScreen.home]);
      s.dispose();
    });

    test('de um destino que não é a home, o voltar leva à home', () {
      final s = _estado(AppScreen.trilha);
      expect(s.voltar(), isTrue);
      expect(s.screen, AppScreen.home);
      s.dispose();
    });

    test('na home o voltar pergunta antes, e so depois entrega ao sistema',
        () {
      final s = _estado(AppScreen.home);

      expect(
        s.voltar(),
        isTrue,
        reason: 'fechar sem avisar e o gesto que a companhia nao faz',
      );
      expect(s.pedindoParaSair, isTrue);
      expect(s.voltar(), isFalse);

      s.cancelaSaida();
      expect(s.pedindoParaSair, isFalse);
      expect(s.voltar(), isTrue, reason: 'pergunta de novo, nao sai calado');
      s.dispose();
    });

    test('reabrir a mesma tela por outro caminho não a duplica', () {
      final s = _estado(AppScreen.home);
      s.go(AppScreen.report);
      s.go(AppScreen.tempo);
      s.go(AppScreen.report); // volta para o relatório pela pilha
      expect(s.pilha, [AppScreen.home, AppScreen.tempo, AppScreen.report]);
      expect(
        s.pilha.where((e) => e == AppScreen.report).length,
        1,
        reason: 'duas cópias na pilha fazem o voltar parecer travado',
      );
      s.dispose();
    });

    test('o resultado depois da sessão tem a home embaixo', () {
      final s = _estado(AppScreen.home)
        ..debugFast = false
        ..dur = 25;
      s.startSession();
      expect(s.pilha, [AppScreen.session]);
      s.abandon();
      expect(
        s.pilha,
        [AppScreen.home, AppScreen.result],
        reason: 'sem raiz, o voltar a partir do resultado fecharia o app',
      );
      expect(s.voltar(), isTrue);
      expect(s.screen, AppScreen.home);
      s.dispose();
    });

    test('voltar durante a sessão pergunta em vez de descartar o foco', () {
      final s = _estado(AppScreen.home)
        ..debugFast = false
        ..dur = 25;
      s.startSession();
      expect(s.voltar(), isTrue);
      expect(s.confirming, isTrue);
      expect(s.screen, AppScreen.session, reason: 'a sessão continua de pé');
      // O segundo voltar fecha a pergunta, não a sessão.
      expect(s.voltar(), isTrue);
      expect(s.confirming, isFalse);
      expect(s.screen, AppScreen.session);
      s.dispose();
    });
  });

  group('o botão voltar do aparelho', () {
    testWidgets('num detalhe, volta — não fecha o app', (tester) async {
      await _abre(tester, AppScreen.shop);
      expect(find.byType(ShopScreen), findsOneWidget);

      final fechou = await _voltarDoSistemaFechaOApp(tester);

      expect(fechou, isFalse, reason: 'era exatamente a queixa do usuário');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(ShopScreen), findsNothing);
    });

    testWidgets('numa aba que não é a home, vai para a home', (tester) async {
      await _abre(tester, AppScreen.profile);
      expect(find.byType(SettingsScreen), findsOneWidget);

      final fechou = await _voltarDoSistemaFechaOApp(tester);

      expect(fechou, isFalse);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('na home, pergunta primeiro e nao fecha ainda', (tester) async {
      await _abre(tester, AppScreen.home);

      final fechouNoPrimeiro = await _voltarDoSistemaFechaOApp(tester);
      expect(fechouNoPrimeiro, isFalse);
      expect(
        find.byKey(FolhaDeSaida.chave),
        findsOneWidget,
        reason: 'a pergunta tem de aparecer',
      );

      // Com a pergunta aberta, o segundo voltar entrega ao sistema: quem
      // insiste no gesto quer sair mesmo.
      final fechouNoSegundo = await _voltarDoSistemaFechaOApp(tester);
      expect(
        fechouNoSegundo,
        isTrue,
        reason: 'prender o usuario dentro do app e o defeito oposto',
      );
    });

    testWidgets('ficar mais um pouco fecha a pergunta e nao sai', (tester) async {
      await _abre(tester, AppScreen.home);
      await _voltarDoSistemaFechaOApp(tester);
      expect(find.byKey(FolhaDeSaida.chave), findsOneWidget);

      await tester.tap(find.text('Ficar mais um pouco'));
      await tester.pump();
      await tester.pump(Tempo.tela);

      expect(find.byKey(FolhaDeSaida.chave), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('transições', () {
    test('cada tipo de tela tem o seu tipo de rota', () {
      expect(AppScreen.home.tipo, TipoDeRota.destino);
      expect(AppScreen.trilha.tipo, TipoDeRota.destino);
      expect(AppScreen.tempo.tipo, TipoDeRota.detalhe);
      expect(AppScreen.paywall.tipo, TipoDeRota.modal);
      expect(AppScreen.session.tipo, TipoDeRota.fluxo);
    });

    testWidgets('a tela nova entra em transição, não em corte seco', (
      tester,
    ) async {
      // Telas falsas: o que está sob teste é a rota, não o conteúdo.
      final app = _estado(AppScreen.home);
      addTearDown(app.dispose);
      final rotas = BaruRouterDelegate(
        app: app,
        paginaDe: (tela) => Center(child: Text(tela.name)),
      );
      addTearDown(rotas.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: rotas,
          routeInformationParser: const BaruRouteParser(),
        ),
      );
      await tester.pump(Tempo.tela + const Duration(milliseconds: 50));
      expect(find.text('home'), findsOneWidget);

      app.go(AppScreen.shop);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      // No meio da transição as duas telas coexistem, cada uma com a sua
      // opacidade. Num corte seco só uma existiria em qualquer instante.
      expect(find.text('shop', skipOffstage: false), findsOneWidget);
      expect(find.text('home', skipOffstage: false), findsOneWidget);
      final opacidades = tester
          .widgetList<FadeTransition>(find.byType(FadeTransition))
          .map((f) => f.opacity.value)
          .where((v) => v > 0 && v < 1);
      expect(
        opacidades,
        isNotEmpty,
        reason: 'alguma coisa tem que estar no meio do caminho',
      );

      await tester.pump(Tempo.tela);
      // Terminada a transição só a nova fica em cena. A antiga continua na
      // árvore, fora de cena: é uma rota opaca por cima, não um descarte.
      expect(find.text('home'), findsNothing);
      expect(find.text('shop'), findsOneWidget);
    });
  });

  group('endereços', () {
    test('toda tela tem um caminho e nenhum se repete', () {
      final caminhos = AppScreen.values.map((s) => s.caminho).toList();
      expect(caminhos.toSet().length, caminhos.length);
      for (final s in AppScreen.values) {
        expect(RotaDaTela.deCaminho(s.caminho), s);
      }
    });

    test('caminho desconhecido não quebra', () {
      expect(RotaDaTela.deCaminho('/nao-existe'), isNull);
    });

    test('um deep link para um detalhe nasce com a home embaixo', () {
      final s = _estado(AppScreen.home);
      s.abrePorEndereco(AppScreen.tempo);
      expect(s.pilha, [AppScreen.home, AppScreen.tempo]);
      expect(s.voltar(), isTrue);
      expect(s.screen, AppScreen.home);
      s.dispose();
    });

    test('quem não terminou o onboarding não entra por link', () {
      final s = AppState();
      expect(s.screen, AppScreen.onb);
      s.abrePorEndereco(AppScreen.trilha);
      expect(
        s.screen,
        AppScreen.onb,
        reason: 'um link não pode pular a criação do companheiro',
      );
      s.dispose();
    });
  });
}
