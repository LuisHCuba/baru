// O fim da sessão em sequência, colher tudo e o indicador na aba (item 8).
//
// Aceite do laudo 01 (U7, U11, U12): a tela anima a partir do retrato
// "antes"; as cenas de conquista esperam a vez dela; as missões tocadas
// andam do valor antigo ao novo; com várias prontas, uma toca colhe todas.
import 'package:baru_app/data/app_snapshot.dart';
import 'package:baru_app/data/resumo_da_sessao.dart';
import 'package:baru_app/data/missoes.dart';
import 'package:baru_app/l10n_missoes.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/screens/result_screen.dart';
import 'package:baru_app/screens/shop_screen.dart';
import 'package:baru_app/services/som_service.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/widgets/cena_da_missao.dart';
import 'package:baru_app/widgets/common.dart';
import 'package:baru_app/widgets/loja_vitrine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AppState _app([void Function(String)? recado]) => AppState(onUserMessage: recado)
  ..onb = 9
  ..companionshipStarted = true
  ..petName = 'Nina'
  ..debugFast = false;

void _concluiUmaSessao(AppState s) {
  s.startSession();
  s.sessionEndsAt = DateTime.now().subtract(const Duration(seconds: 1));
  s.reconcileSession();
}

void main() {
  late List<SomDoBaru> tocados;

  setUp(() {
    tocados = [];
    SomService.espiao = tocados;
    // Cada som chega um segundo depois do anterior: o limitador do serviço
    // é de relógio de parede, e o `pump` do teste não o faz andar.
    var relogio = DateTime(2026, 10, 26, 9);
    SomService.instance
      ..esqueceOsUltimos()
      ..agora = (() => relogio = relogio.add(const Duration(seconds: 1)))
      ..tocador = (_) async {};
  });

  tearDown(() {
    SomService.espiao = null;
    SomService.instance
      ..tocador = null
      ..agora = DateTime.now;
  });

  group('o retrato da sessão', () {
    test('guarda o antes e o que a sessão trouxe', () {
      final s = _app()..leaves = 40;
      addTearDown(s.dispose);
      final xpAntes = s.xp;
      _concluiUmaSessao(s);

      final r = s.ultimoResumo!;
      expect(r.folhasAntes, 40);
      expect(r.folhasDaSessao, s.reward);
      expect(r.xpAntes, xpAntes);
      expect(r.xpDaRaiz, greaterThan(0), reason: '1ª do dia: bônus da raiz');
      expect(r.missoes, isNotEmpty, reason: 'alguma missão de foco andou');
      for (final m in r.missoes) {
        expect(m.depois.progresso, isNot(m.antes.progresso));
      }
    });

    test('a segunda sessão do dia não repete o bônus da raiz', () {
      final s = _app();
      addTearDown(s.dispose);
      _concluiUmaSessao(s);
      _concluiUmaSessao(s);
      expect(s.ultimoResumo!.xpDaRaiz, 0);
    });
  });

  group('a vez das cenas', () {
    test('as conquistas esperam a tela de resultado', () {
      final s = _app();
      addTearDown(s.dispose);
      _concluiUmaSessao(s);
      expect(s.screen, AppScreen.result);
      expect(s.temCelebracaoPendente, isTrue);
      expect(s.celebracoesEmEspera, isTrue);
      s.liberaCelebracoes();
      expect(s.celebracoesEmEspera, isFalse);
    });

    test('sair da tela de resultado solta a espera sozinho', () {
      final s = _app();
      addTearDown(s.dispose);
      _concluiUmaSessao(s);
      s.voltar();
      expect(s.celebracoesEmEspera, isFalse,
          reason: 'trava esquecida calaria as conquistas do dia');
    });
  });

  group('colher tudo', () {
    test('credita todas, uma vez cada, com um som só', () {
      final s = _app();
      addTearDown(s.dispose);
      _concluiUmaSessao(s);
      _concluiUmaSessao(s);
      final prontas = s.missoes.where((m) => m.resgatavel).toList();
      expect(prontas.length, greaterThanOrEqualTo(1));
      final antes = s.leaves;
      final soma = prontas.fold<int>(0, (a, m) => a + m.folhas);
      tocados.clear();

      s.resgataTodas(prontas);
      expect(s.leaves, antes + soma);
      expect(tocados, [SomDoBaru.resgate]);

      s.resgataTodas(prontas);
      expect(s.leaves, antes + soma, reason: 'colher de novo não paga de novo');
    });
  });

  group('nada pronto se perde à meia-noite (U12)', () {
    test('a virada do dia colhe o que ficou pronto e conta na abertura', () {
      final recados = <String>[];
      final s = _app(recados.add);
      addTearDown(s.dispose);
      _concluiUmaSessao(s);
      final prontas = [
        ...s.missoes.where((m) => m.resgatavel),
      ];
      expect(prontas, isNotEmpty);
      final diarias = prontas.where((m) => m.ritmo == RitmoDaMissao.diaria);
      final soma = diarias.fold<int>(0, (a, m) => a + m.folhas);
      final antes = s.leaves;

      s.applyCalendar(DateTime.now().add(const Duration(days: 1)));
      expect(s.leaves, greaterThanOrEqualTo(antes + soma));
      final guardei = s.t.mqGuardadas.split('{').first;
      expect(recados.where((r) => r.startsWith(guardei)), hasLength(1));

      // Abrir de novo no mesmo dia não paga de novo.
      final depois = s.leaves;
      s.applyCalendar(DateTime.now().add(const Duration(days: 1)));
      expect(s.leaves, depois);
    });

    test('colhida à mão, a virada não paga outra vez', () {
      final recados = <String>[];
      final s = _app(recados.add);
      addTearDown(s.dispose);
      _concluiUmaSessao(s);
      s.resgataTodas(s.missoes.where((m) => m.resgatavel).toList());
      s.resgataODescanso();
      final antes = s.leaves;
      recados.clear();
      s.applyCalendar(DateTime.now().add(const Duration(days: 1)));
      final guardei = s.t.mqGuardadas.split('{').first;
      expect(recados.where((r) => r.startsWith(guardei)), isEmpty);
      expect(s.leaves, greaterThanOrEqualTo(antes));
    });
  });

  testWidgets('a aba Missões mostra quantas há para colher', (tester) async {
    final s = _app();
    addTearDown(s.dispose);
    _concluiUmaSessao(s);
    s.voltar();
    await tester.pumpWidget(AppScope(
      state: s,
      child: const MaterialApp(home: Scaffold(body: BottomTabs())),
    ));
    final n = s.missoesResgataveis;
    expect(n, greaterThan(0));
    expect(find.byKey(const Key('aba-missoes-a-colher')), findsOneWidget);
    expect(find.text('$n'), findsOneWidget);
  });

  testWidgets('a sequência: saldo contando, depois as missões andando',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    final s = _app()..leaves = 40;
    addTearDown(s.dispose);
    _concluiUmaSessao(s);
    final r = s.ultimoResumo!;
    await tester.pumpWidget(AppScope(
      state: s,
      child: const MaterialApp(home: Scaffold(body: ResultScreen())),
    ));

    // Começo: o saldo ainda é o de antes.
    expect(find.text('40'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2200));
    // O selo conta entre os passos por conta própria (`ContadorAnimado`).
    await tester.pump(const Duration(milliseconds: 1200));
    // O saldo real: a sessão e o que mais ela pagou (um marco da trilha).
    expect(s.leaves, greaterThanOrEqualTo(40 + r.folhasDaSessao));
    expect(find.text('${s.leaves}'), findsOneWidget);
    expect(s.celebracoesEmEspera, isFalse, reason: 'a E1 acabou: vez das cenas');
    expect(tocados, contains(SomDoBaru.folhas));

    // As cenas passam; então as barras andam.
    while (s.temCelebracaoPendente) {
      s.celebrou();
      await tester.pump();
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    final fechou = r.missoes.where((m) => m.fechou);
    expect(fechou, isNotEmpty);
    expect(find.text('Pronta para colher'), findsNWidgets(fechou.length));
    expect(find.byKey(const Key('resultado-fecho')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  group('missão cumprida', () {
    test('a sessão que fecha missão acende a cena, logo depois da raiz', () {
      final s = _app();
      addTearDown(s.dispose);
      _concluiUmaSessao(s);
      final fechadas =
          s.ultimoResumo!.missoes.where((m) => m.fechou).toList();
      expect(fechadas, isNotEmpty,
          reason: 'a primeira sessão fecha ao menos a missão de uma sessão');
      expect(s.missoesACumprir.map((m) => m.id),
          fechadas.map((m) => m.depois.id));
      expect(s.raizACelebrar, isNotNull);
      s.celebrou(); // a raiz
      expect(s.raizACelebrar, isNull);
      expect(s.temCelebracaoPendente, isTrue);
      expect(s.missoesACumprir, isNotEmpty, reason: 'a missão vem a seguir');

      final folhas = s.leaves;
      final paga =
          s.missoesACumprir.fold<int>(0, (t, m) => t + m.folhas);
      s.colheAsCumpridas();
      expect(s.leaves, folhas + paga);
      expect(s.missoesACumprir, isEmpty);
      expect(s.missoesCumpridas, isEmpty);
    });

    test('colhida pela tela de missões, a cena não aparece', () {
      final s = _app();
      addTearDown(s.dispose);
      _concluiUmaSessao(s);
      s.celebrou(); // a raiz
      s.resgataTodas(s.missoesACumprir);
      expect(s.missoesACumprir, isEmpty);
      // A lista velha não pode engolir a próxima conquista da fila: fechar
      // a cena que estiver na frente consome essa, e só essa.
      s.chegadaACelebrar = true;
      final cresceu = s.cresceuSemCelebrar;
      final nivel = s.subiuDeNivel;
      final marcos = s.marcosACelebrar.length;
      s.celebrou();
      expect(s.missoesCumpridas, isEmpty);
      if (cresceu) {
        expect(s.cresceuSemCelebrar, isFalse);
        expect(s.subiuDeNivel, nivel);
      } else if (nivel) {
        expect(s.subiuDeNivel, isFalse);
        expect(s.marcosACelebrar.length, marcos);
      } else if (marcos > 0) {
        expect(s.marcosACelebrar.length, marcos - 1);
        expect(s.chegadaACelebrar, isTrue);
      } else {
        expect(s.chegadaACelebrar, isFalse);
      }
    });

    testWidgets('a cena mostra a missão e o prêmio, e "Colher" chama quem paga',
        (tester) async {
      var colheu = 0, fechou = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              CenaDaMissao(
                missoes: const [
                  MissaoNaCena(titulo: 'Faça uma sessão', de: 0, folhas: 12, xp: 10),
                ],
                bicho: const SizedBox(width: 80, height: 80),
                titulo: 'Missão cumprida!',
                rotuloColher: 'Colher agora',
                rotuloDepois: 'Colho depois',
                aoColher: () => colheu++,
                aoFechar: () => fechou++,
              ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Missão cumprida!'), findsOneWidget);
      expect(find.text('Faça uma sessão'), findsOneWidget);
      expect(find.textContaining('12'), findsWidgets);
      await tester.tap(find.byKey(CenaDaMissao.chaveColher));
      await tester.pump();
      expect((colheu, fechou), (1, 0));
      await tester.tap(find.text('Colho depois'));
      await tester.pump();
      expect(fechou, 1);
      await tester.pumpWidget(const SizedBox());
    });

    test('"Depois" fecha a cena sem pagar; o prêmio segue na tela de missões',
        () {
      final s = _app();
      addTearDown(s.dispose);
      _concluiUmaSessao(s);
      s.celebrou(); // a raiz
      final folhas = s.leaves;
      s.celebrou(); // "Colho depois"
      expect(s.leaves, folhas);
      expect(s.missoesCumpridas, isEmpty);
      expect(s.missoesResgataveis, greaterThan(0));
    });
  });

  test('reabrir o app não volta para a tela de resultado', () {
    // Sem o retrato da sessão ela mostrava "desistiu" a quem concluiu
    // (auditoria da Onda 2, item 8, 7.1).
    final s = _app();
    addTearDown(s.dispose);
    _concluiUmaSessao(s);
    expect(s.screen, AppScreen.result);
    final volta = AppState()
      ..applySnapshotParaTeste(
          AppSnapshot.fromJson(s.toSnapshot().toJson()));
    addTearDown(volta.dispose);
    expect(volta.screen, isNot(AppScreen.result));
  });

  test('missão já colhida não entra no retrato', () {
    final s = _app();
    addTearDown(s.dispose);
    final antes = s.missoes;
    expect(ResumoDaSessao.tocadas(antes, antes), isEmpty);
  });

  testWidgets('desfazer a compra devolve as folhas e o que estava em cena',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    final s = _app()..leaves = 500;
    addTearDown(s.dispose);
    s.go(AppScreen.shop);
    await tester.pumpWidget(AppScope(
      state: s,
      child: const MaterialApp(home: Scaffold(body: ShopScreen())),
    ));
    await tester.pump();
    final preco = find
        .byWidgetPredicate((w) =>
            w is PilulaDaLoja && w.ativo && int.tryParse(w.rotulo) != null)
        .first;
    await tester.ensureVisible(preco);
    final folhas = s.leaves;
    final itens = [...s.owned];
    final emCena = {...s.equipados};
    await tester.tap(preco);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    expect(s.leaves, lessThan(folhas));

    await tester.tap(find.text(s.t.compraDesfazer));
    await tester.pump(const Duration(milliseconds: 500));
    expect(s.leaves, folhas);
    expect(s.owned, itens);
    expect(s.equipados, emCena);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('comprar abre a compra celebrada, e ela leva ao habitat',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    final s = _app()..leaves = 500;
    addTearDown(s.dispose);
    s.go(AppScreen.shop);
    await tester.pumpWidget(AppScope(
      state: s,
      child: const MaterialApp(home: Scaffold(body: ShopScreen())),
    ));
    await tester.pump();
    // Qualquer item à venda: a pílula com o preço em número.
    final preco = find
        .byWidgetPredicate((w) =>
            w is PilulaDaLoja && w.ativo && int.tryParse(w.rotulo) != null)
        .first;
    await tester.ensureVisible(preco);
    final antes = s.owned.length;
    await tester.tap(preco);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    expect(s.owned.length, antes + 1);
    expect(find.text('É seu!'), findsOneWidget);
    expect(tocados, contains(SomDoBaru.compra));

    await tester.tap(find.text('Ver no habitat'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(s.screen, AppScreen.home);
    await tester.pumpWidget(const SizedBox());
  });
}
