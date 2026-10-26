// A raiz cresceu hoje: a cena do primeiro foco do dia (item 7 do plano).
//
// Aceite do laudo 01 (§5): o contador mostra N antes de girar e N+1 depois;
// o ponto de hoje vira ✓; o som da cena toca uma vez; no marco a cena ganha
// o galho e o botão de compartilhar; "reduzir movimento" vai direto ao fim.
import 'dart:ui' as ui;

import 'package:baru_app/l10n.dart';
import 'package:baru_app/services/som_service.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/widgets/cena_da_raiz.dart';
import 'package:baru_app/widgets/raiz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

AppState _app() => AppState()
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
    SomService.instance
      ..esqueceOsUltimos()
      ..tocador = (_) async {};
  });

  tearDown(() {
    SomService.espiao = null;
    SomService.instance.tocador = null;
  });

  group('no estado', () {
    test('a primeira sessão do dia acende a cena; a segunda, não', () {
      final s = _app();
      addTearDown(s.dispose);
      s.streak = 4;
      s.melhorSequencia = 9;

      _concluiUmaSessao(s);
      expect(s.raizACelebrar, 5);
      expect(s.raizRecorde, isFalse);
      s.celebrou();
      expect(s.raizACelebrar, isNull);

      _concluiUmaSessao(s);
      expect(s.raizACelebrar, isNull, reason: 'a raiz cresce uma vez por dia');
    });

    test('recorde só quando passa a melhor de sempre, e nunca no 1º dia', () {
      final s = _app();
      addTearDown(s.dispose);
      _concluiUmaSessao(s);
      expect(s.raizACelebrar, 1);
      expect(s.raizRecorde, isFalse);

      // A primeira raiz não é "recorde" todo dia: não há raiz anterior.
      final primeira = _app();
      addTearDown(primeira.dispose);
      primeira
        ..streak = 9
        ..melhorSequencia = 9;
      _concluiUmaSessao(primeira);
      expect(primeira.raizRecorde, isFalse);

      // Uma raiz de 9 quebrou; a de agora tem 9 e vai a 10: recorde, uma vez.
      final r = _app();
      addTearDown(r.dispose);
      r
        ..recordeAnterior = 9
        ..streak = 9
        ..melhorSequencia = 9;
      _concluiUmaSessao(r);
      expect(r.raizRecorde, isTrue);

      final depois = _app();
      addTearDown(depois.dispose);
      depois
        ..recordeAnterior = 9
        ..streak = 10
        ..melhorSequencia = 10;
      _concluiUmaSessao(depois);
      expect(depois.raizRecorde, isFalse, reason: 'recorde é o dia de passar');
    });

    test('quebrar a raiz guarda a melhor como a marca a passar', () {
      final s = _app()
        ..streak = 6
        ..melhorSequencia = 6
        ..freezesLeft = 0;
      addTearDown(s.dispose);
      s.applyCalendar(s.lastOpenDate.add(const Duration(days: 2)));
      expect(s.streak, 0);
      expect(s.recordeAnterior, 6);
    });

    test('a raiz vem antes do bicho nascer na fila', () {
      final s = _app();
      addTearDown(s.dispose);
      _concluiUmaSessao(s);
      expect(s.raizACelebrar, isNotNull);
      expect(s.cresceuSemCelebrar, isTrue);
      s.celebrou();
      expect(s.raizACelebrar, isNull);
      expect(s.cresceuSemCelebrar, isTrue, reason: 'o nascimento vem depois');
    });
  });

  group('a linha do dia', () {
    final t = T('pt');

    test('recorde vence tudo', () {
      expect(linhaDaRaiz(t, dias: 6, recorde: true), t.raizRecorde);
    });

    test('galho perto (1 a 3 dias) vem antes da rotação', () {
      expect(linhaDaRaiz(t, dias: 6, recorde: false), t.raizFaltaGalho1);
      expect(
        linhaDaRaiz(t, dias: 11, recorde: false),
        t.fill(t.raizFaltaGalho, {'n': 3}),
      );
    });

    test('longe de marco, uma das cinco', () {
      final cinco = {
        t.raizLinha1,
        t.raizLinha2,
        t.raizLinha3,
        t.raizLinha4,
        t.raizLinha5,
      };
      for (final d in [8, 9, 10, 15, 16, 17, 18, 19, 20]) {
        expect(cinco, contains(linhaDaRaiz(t, dias: d, recorde: false)));
      }
    });
  });

  testWidgets('a ponta calculada é onde o pintor termina a raiz',
      (tester) async {
    for (final dias in [1, 5, 20, 80]) {
      final chave = GlobalKey();
      const tamanho = Size(200, 300);
      await tester.pumpWidget(Center(
        child: RepaintBoundary(
          key: chave,
          child: SizedBox.fromSize(
            size: tamanho,
            child: RaizViva(dias: dias, mostraTerra: false),
          ),
        ),
      ));
      final b =
          chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      late int maisFundo;
      await tester.runAsync(() async {
        final img = await b.toImage();
        final raw = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
        img.dispose();
        final px = raw!.buffer.asUint8List();
        maisFundo = 0;
        for (var y = 0; y < 300; y++) {
          for (var x = 0; x < 200; x++) {
            if (px[(y * 200 + x) * 4 + 3] > 40) maisFundo = y;
          }
        }
      });
      final ponta = RaizViva.pontaEm(tamanho, dias.toDouble());
      // A ponta é arredondada (meia grossura, até 5 px) e os galhos não
      // descem abaixo dela nos primeiros meses.
      expect((maisFundo - ponta.dy).abs(), lessThan(8), reason: 'dia $dias');
    }
  });

  group('a cena', () {
    Widget comApp(AppState s, Widget filho, {bool reduzido = false}) =>
        AppScope(
          state: s,
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(412, 892),
                disableAnimations: reduzido,
              ),
              child: Scaffold(body: Stack(children: [filho])),
            ),
          ),
        );

    testWidgets('o contador gira de N para N+1 e o som toca uma vez',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 892));
      final s = _app()..streak = 5;
      addTearDown(s.dispose);
      var fechou = false;
      await tester.pumpWidget(comApp(
        s,
        CenaDaRaiz(dias: 5, recorde: false, aoFechar: () => fechou = true),
      ));

      Offset numero(String n) => tester.getCenter(find.text(n).first);
      await tester.pump(const Duration(milliseconds: 1100));
      final antes4 = numero('4').dy;
      final antes5 = numero('5').dy;
      expect(antes4, lessThan(antes5), reason: 'o 4 está na janela, o 5 abaixo');

      await tester.pump(const Duration(milliseconds: 400));
      final chave = tester.getCenter(find.byKey(CenaDaRaiz.chaveDoContador));
      expect((chave.dy - antes4).abs(), lessThan(4),
          reason: 'aos 1500 ms o 5 ocupa o lugar do 4');

      await tester.pump(const Duration(milliseconds: 1000));
      expect(tocados, [SomDoBaru.raiz]);
      expect(find.text('Raiz de 5 dias'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      expect(fechou, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('no marco: galho novo e compartilhar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 892));
      final s = _app()..streak = 7;
      addTearDown(s.dispose);
      await tester.pumpWidget(comApp(
        s,
        CenaDaRaiz(dias: 7, recorde: false, aoFechar: () {}),
      ));
      await tester.pump(const Duration(milliseconds: 3400));
      expect(find.text('Galho novo!'), findsOneWidget);
      expect(find.byKey(const Key('raiz-compartilhar')), findsOneWidget);
      expect(tocados, [SomDoBaru.raizMarco]);
      expect(tester.takeException(), isNull, reason: 'nada transborda');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('tocar antes de 600 ms não pula; depois, vai ao fim e cala',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 892));
      final s = _app()..streak = 5;
      addTearDown(s.dispose);
      await tester.pumpWidget(comApp(
        s,
        CenaDaRaiz(dias: 5, recorde: false, aoFechar: () {}),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(CenaDaRaiz.chave));
      await tester.pump();
      final botao = find.text('Continuar');
      expect(tester.widget<Opacity>(
        find.ancestor(of: botao, matching: find.byType(Opacity)).first,
      ).opacity, 0);

      // 300 + 340 = 640 ms: depois do limite de 600, antes da gota (700).
      await tester.pump(const Duration(milliseconds: 340));
      await tester.tap(find.byKey(CenaDaRaiz.chave));
      await tester.pump();
      expect(tester.widget<Opacity>(
        find.ancestor(of: botao, matching: find.byType(Opacity)).first,
      ).opacity, 1);
      expect(tocados, isEmpty, reason: 'pulou antes da gota: sem som atrasado');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('reduzir movimento: direto ao quadro final, um som',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 892));
      final s = _app()..streak = 5;
      addTearDown(s.dispose);
      await tester.pumpWidget(comApp(
        s,
        CenaDaRaiz(dias: 5, recorde: false, aoFechar: () {}),
        reduzido: true,
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Raiz de 5 dias'), findsOneWidget);
      expect(tocados, [SomDoBaru.raiz]);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
