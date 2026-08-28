import 'package:baru_app/data/progressao.dart';
import 'package:baru_app/screens/trilha_screen.dart';
import 'package:baru_app/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Em que passo eu estou, e o que falta para ele.
///
/// O relato foi literal: "eu tô tipo num nível e os outros níveis já estão
/// carregando. Aí eu clico no critério não é coerente, não faz muito sentido
/// exatamente em que momento eu tô, em que passo".
///
/// São três defeitos distintos e cada um tem teste aqui:
/// 1. degrau futuro desenhado com progresso, como se estivesse em curso;
/// 2. critério sem frase — a fração "4/7" não diz de que unidade é;
/// 3. nenhum lugar dizendo o número do passo.

AppState _conta({
  int sessoes = 0,
  int abaixo = 0,
  int sequencia = 0,
  int xp = 0,
}) {
  final s = AppState()..startCompanionship();
  s.sessoesConcluidas = sessoes;
  s.diasAbaixoDaMeta = abaixo;
  s.melhorSequencia = sequencia;
  s.xp = xp;
  return s;
}

/// Rola até o alvo aparecer **na tela**, não só na árvore.
///
/// Todos os nós do caminho são construídos de uma vez (é uma `Stack`, não uma
/// lista preguiçosa), então um `Finder` cru já acha o degrau lá embaixo sem
/// rolar nada — e o toque seguinte cai fora da viewport. `hitTestable` é o que
/// obriga a rolagem a acontecer de verdade.
Future<void> _rolaAte(WidgetTester tester, Finder alvo) => tester
    .scrollUntilVisible(
  alvo.hitTestable(),
  160,
  scrollable: find.byType(Scrollable).first,
);

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
  group('o estado de cada degrau', () {
    test('o degrau em aberto mais adiante está travado, não em curso', () {
      // Quatro sessões: o primeiro marco de sessão já foi, e "cinco focos"
      // está em 4/5 — o degrau que aparecia quase cheio lá embaixo.
      final p = _conta(sessoes: 4).progresso;
      final cinco = trilha.firstWhere((m) => m.id == 'cinco_focos');

      expect(p.estadoDe(cinco), EstadoNaTrilha.travado);
      expect(
        p.proximoMarco?.id,
        isNot('cinco_focos'),
        reason: 'a frente da trilha é o primeiro degrau em aberto',
      );
    });

    test('só existe um degrau atual', () {
      final p = _conta(sessoes: 4, abaixo: 2, sequencia: 5, xp: 300).progresso;
      final atuais =
          trilha.where((m) => p.estadoDe(m) == EstadoNaTrilha.atual).toList();
      expect(atuais.length, 1, reason: 'um caminho tem uma frente só');
    });

    test('marco alcançado fora de ordem continua conquistado', () {
      // Sem permissão de uso ninguém fecha dia abaixo da meta, então o passo
      // 2 trava para sempre — e as sessões seguem contando. O ✓ do que foi
      // feito não pode virar cadeado por causa da posição.
      final p = _conta(sessoes: 5).progresso;
      final cinco = trilha.firstWhere((m) => m.id == 'cinco_focos');
      expect(p.proximoMarco?.id, 'primeiro_dia_abaixo');
      expect(p.estadoDe(cinco), EstadoNaTrilha.conquistado);
    });

    test('o passo atual é a posição do primeiro degrau em aberto', () {
      final p = _conta(sessoes: 4).progresso;
      expect(p.passoAtual, passoDoMarco(p.proximoMarco!));
      expect(p.totalDePassos, trilha.length);
    });
  });

  group('o que falta, em uma frase', () {
    test('a frase carrega o número real que falta', () {
      final app = _conta(sessoes: 4);
      final cinco = trilha.firstWhere((m) => m.id == 'cinco_focos');
      expect(app.progresso.quantoFalta(cinco), 1);
      expect(oQueFaltaNoMarco(app, cinco), contains('1'));
      expect(oQueFaltaNoMarco(app, cinco), isNot(contains('{')));
    });

    test('a frase de nível fala em XP, não em níveis', () {
      // "Faltam 2 níveis" não diz o que fazer hoje. O que a pessoa junta é XP.
      final app = _conta(xp: 30);
      final nivel3 = trilha.firstWhere((m) => m.id == 'nivel_3');
      final faltaXp = Balanco.xpAcumuladoPara(3) - 30;
      expect(faltaXp, greaterThan(0));
      expect(oQueFaltaNoMarco(app, nivel3), contains('$faltaXp'));
    });

    test('marco conquistado não diz que falta alguma coisa', () {
      final app = _conta(sessoes: 1);
      final primeiro = trilha.first;
      expect(app.progresso.alcancou(primeiro), isTrue);
      expect(oQueFaltaNoMarco(app, primeiro), app.t.s('trilhaJaSeu'));
    });

    test('a frase acompanha o progresso em todos os tipos de marco', () {
      // O número da frase sai do mesmo contador que o anel desenha: se um
      // mentir, o outro mente junto.
      for (final tipo in TipoDeMarco.values) {
        final m = trilha.firstWhere((x) => x.tipo == tipo);
        final app = _conta();
        final frase = oQueFaltaNoMarco(app, m);
        expect(frase, isNotEmpty, reason: tipo.name);
        expect(frase, isNot(contains('{')), reason: tipo.name);
        if (tipo != TipoDeMarco.nivel) {
          expect(
            frase,
            contains('${app.progresso.quantoFalta(m)}'),
            reason: tipo.name,
          );
        }
      }
    });
  });

  group('a tela', () {
    testWidgets('diz em que passo a pessoa está', (tester) async {
      final app = _conta(sessoes: 4);
      await _abre(tester, app);
      final p = app.progresso;
      expect(
        find.text(
          app.t.fill(app.t.s('trilhaPassoDe'), {
            'n': p.passoAtual,
            't': p.totalDePassos,
          }),
        ),
        findsOneWidget,
        reason: '"em que passo eu tô" precisa de resposta escrita',
      );
    });

    testWidgets('nenhum degrau travado desenha anel de progresso',
        (tester) async {
      // O defeito exato: com 4 sessões, "cinco focos" ficava com o anel em
      // 80% e "vinte focos" em 20%, e o caminho inteiro parecia em curso.
      // O degrau atual aqui é "fechar um dia abaixo da meta", em 0/1 — sem
      // anel também. Logo: nenhum anel na tela inteira.
      final app = _conta(sessoes: 4);
      await _abre(tester, app);

      expect(app.progresso.proximoMarco?.id, 'primeiro_dia_abaixo');
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: 'passo futuro com barra pela metade foi a reclamação',
      );
    });

    testWidgets('o degrau atual pode desenhar anel; os de trás dele, não',
        (tester) async {
      // Aqui o degrau atual é "três dias seguidos", em 2/3, e merece o anel.
      // Logo atrás dele "três dias abaixo da meta" também está em 2/3 — e é
      // exatamente esse que não pode acender.
      final app = _conta(
        sessoes: 5,
        abaixo: 2,
        sequencia: 2,
        xp: Balanco.xpAcumuladoPara(3),
      );
      await _abre(tester, app);

      expect(app.progresso.proximoMarco?.id, 'tres_dias');
      expect(
        app.progresso.fracaoDe(
          trilha.firstWhere((m) => m.id == 'tres_dias_abaixo'),
        ),
        greaterThan(0),
        reason: 'o travado tem progresso real; o que não pode é desenhá-lo',
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('o degrau travado mostra cadeado no caminho', (tester) async {
      final app = _conta(sessoes: 4);
      await _abre(tester, app);

      // O seletor de habitat também tem cadeados. Contar os de lá e exigir
      // que sobre pelo menos um é o que prende o cadeado ao **caminho** —
      // sem isso o teste passaria só pelos habitats travados.
      final todos = find.byIcon(Icons.lock_rounded);
      final noSeletor = find.descendant(
        of: find.byKey(SeletorDeHabitat.chave),
        matching: find.byIcon(Icons.lock_rounded),
      );
      expect(
        tester.widgetList(todos).length,
        greaterThan(tester.widgetList(noSeletor).length),
        reason: 'sem cadeado, o nó apagado lê como degrau disponível',
      );
    });

    testWidgets('o leitor de tela também sabe que o degrau está travado',
        (tester) async {
      final app = _conta(sessoes: 4);
      await _abre(tester, app);
      final cinco = trilha.firstWhere((m) => m.id == 'cinco_focos');
      expect(
        find.bySemanticsLabel(
          '${tituloDoMarco(app, cinco)} · ${app.t.s('trilhaTravado')}',
        ),
        findsOneWidget,
        reason: 'cor e ícone não chegam a quem usa leitor de tela',
      );
    });

    testWidgets('a frase do que falta aparece no passo atual', (tester) async {
      final app = _conta(sessoes: 4);
      await _abre(tester, app);
      final atual = app.progresso.proximoMarco!;
      expect(
        find.text(oQueFaltaNoMarco(app, atual)),
        findsWidgets,
        reason: 'o critério tem de estar legível sem abrir nada',
      );
    });

    testWidgets('o detalhe de um degrau travado ainda diz o critério',
        (tester) async {
      // O cadeado é sobre a ordem do caminho, não sobre esconder o número:
      // quem abriu o detalhe perguntou de propósito.
      final app = _conta(sessoes: 4);
      await _abre(tester, app);
      final cinco = trilha.firstWhere((m) => m.id == 'cinco_focos');

      await _rolaAte(tester, find.text(tituloDoMarco(app, cinco)));
      await tester.tap(find.text(tituloDoMarco(app, cinco)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('4/5'), findsOneWidget);
      expect(find.text(oQueFaltaNoMarco(app, cinco)), findsOneWidget);
    });

    testWidgets('cabe em 412x892 sem overflow em vários estágios',
        (tester) async {
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) {
          fail(details.exceptionAsString());
        }
      };
      for (final app in [
        _conta(),
        _conta(sessoes: 4),
        _conta(sessoes: 22, abaixo: 6, sequencia: 8, xp: 900),
      ]) {
        await _abre(tester, app);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
