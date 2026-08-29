import 'package:baru_app/data/descanso_do_dia.dart';
import 'package:baru_app/data/missoes.dart';
import 'package:baru_app/data/tempo_de_tela.dart';
import 'package:baru_app/l10n_missoes.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/screens/missoes_screen.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/widgets/toca.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A tela de missões, depois da queixa "está confuso, não é linear".
///
/// Dois defeitos, e cada grupo abaixo protege um.
///
/// O primeiro: a missão principal do dia — o descanso — estava modelada,
/// contabilizada e paga, e **não aparecia em lugar nenhum**. Quem abria a tela
/// via cinco sorteadas e nenhuma delas era a que o produto considera a do dia.
///
/// O segundo: cinco cartões idênticos sob dois rótulos de prazo. Prazo não é
/// hierarquia — às nove da manhã "até domingo" e "até meia-noite" não dizem
/// qual cartão merece o dedo. O que este arquivo trava é a **ordem**: o que já
/// é seu vem antes do que ainda dá para fechar hoje, que vem antes do que
/// corre sozinho até domingo.

ResumoDeTela _tela({int dispersivo = 0}) => ResumoDeTela(
      porApp: {'com.exemplo.feed': Duration(minutes: dispersivo)},
      porCategoria: {
        CategoriaDeApp.dispersivo: Duration(minutes: dispersivo),
      },
    );

AppState _app({
  bool permissao = true,
  int melhorDescanso = 0,
  bool descansando = false,
  int diasFora = 0,
}) {
  final a = AppState()
    ..onb = 9
    ..companionshipStarted = true
    ..leaves = 0
    ..usageAccess = permissao
    ..resumoTela = _tela()
    ..melhorDescansoHoje = Duration(minutes: melhorDescanso)
    ..daysAway = diasFora;
  if (descansando) {
    a
      ..descansoComecouEm = DateTime.now().subtract(const Duration(minutes: 5))
      ..descansoTelaNoInicio = 0;
  }
  return a;
}

/// Empurra a data até o sorteio determinístico (ADR-010) dar um quadro que
/// sirva ao caso em teste.
///
/// Não dá para "pedir" uma missão: o quadro do dia sai de `(conta, data)`. Um
/// teste que dependesse do sorteio de hoje passaria hoje e falharia amanhã —
/// e é uma armadilha que o arquivo antigo já carregava.
void _diaEmQue(AppState s, bool Function(List<Missao>) serve) {
  for (var i = 0; i < 730; i++) {
    s.lastOpenDate = DateTime(2026, 1, 5 + i);
    if (serve(s.missoes)) return;
  }
  fail('nenhum sorteio em dois anos de datas serviu ao caso');
}

Future<void> _mostra(WidgetTester tester, AppState app) async {
  // Alto o bastante para a tela inteira caber: o que este arquivo mede é
  // ordem, e ordem só se mede com tudo montado.
  tester.view.physicalSize = const Size(412, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppScope(state: app, child: const MissoesScreen()),
      ),
    ),
  );
  await tester.pump();
}

double _y(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;

void main() {
  group('a missão do descanso ganhou lugar na tela', () {
    testWidgets('aparece com o botão que a começa', (tester) async {
      final app = _app();
      addTearDown(app.dispose);
      await _mostra(tester, app);

      expect(find.byKey(CartaoDoDescanso.chave), findsOneWidget);
      expect(find.byKey(CartaoDoDescanso.chaveDoComecar), findsOneWidget);

      await tester.tap(find.byKey(CartaoDoDescanso.chaveDoComecar));
      await tester.pump();

      expect(
        app.descansoComecouEm,
        isNotNull,
        reason: 'o botão tem de começar o descanso de verdade',
      );
    });

    testWidgets('é o primeiro cartão da tela, acima das sorteadas', (
      tester,
    ) async {
      final app = _app();
      addTearDown(app.dispose);
      await _mostra(tester, app);

      final primeiraSorteada = app.missoes.first;
      expect(
        _y(tester, find.byKey(CartaoDoDescanso.chave)),
        lessThan(_y(tester, find.byKey(CartaoDeMissao.chaveDe(primeiraSorteada.id)))),
        reason: 'a principal do dia não pode aparecer depois das sorteadas',
      );
    });

    testWidgets('descansando, o caminho oferecido é parar — não recomeçar', (
      tester,
    ) async {
      final app = _app(descansando: true);
      addTearDown(app.dispose);
      await _mostra(tester, app);

      expect(find.byKey(CartaoDoDescanso.chaveDoComecar), findsNothing);
      expect(find.byKey(CartaoDoDescanso.chaveDoParar), findsOneWidget);

      await tester.tap(find.byKey(CartaoDoDescanso.chaveDoParar));
      await tester.pump();
      expect(app.descansoComecouEm, isNull);
    });

    testWidgets('sem acesso ao uso vira convite, nunca missão impossível', (
      tester,
    ) async {
      final app = _app(permissao: false);
      addTearDown(app.dispose);
      await _mostra(tester, app);

      expect(
        find.byKey(CartaoDoDescanso.chaveDoComecar),
        findsNothing,
        reason: 'sem medição, começar não mediria nada',
      );

      await tester.tap(find.byKey(CartaoDoDescanso.chave));
      await tester.pump();
      expect(
        app.screen,
        AppScreen.tempo,
        reason: 'o convite leva onde a permissão se concede e se explica',
      );
    });

    testWidgets('cumprida, ela paga pela toca — e só quando a terra abre', (
      tester,
    ) async {
      final app = _app(melhorDescanso: Descanso.alvo.inMinutes);
      addTearDown(app.dispose);
      await _mostra(tester, app);

      expect(find.byKey(CartaoDoDescanso.chaveDoColher), findsOneWidget);
      await tester.tap(find.byKey(CartaoDoDescanso.chaveDoColher));
      await tester.pumpAndSettle();

      expect(find.byKey(Toca.chave), findsOneWidget);
      expect(
        app.leaves,
        0,
        reason: 'abrir a folha não é o gesto que paga',
      );

      for (var i = 0; i < Toca.precisaDe; i++) {
        await tester.tap(find.byKey(Toca.chave));
        await tester.pump(const Duration(milliseconds: 300));
      }
      // Até a terra abrir e o prêmio subir; depois o respiro de 900 ms que
      // deixa a cena ser vista antes de a folha sair, e a saída dela.
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(
        app.leaves,
        Descanso.folhas,
        reason: 'R-04: a mesma cena serve a principal do dia',
      );
      expect(app.missaoDoDescanso.resgatada, isTrue);
    });
  });

  group('a retomada, no dia da volta', () {
    testWidgets('num dia comum não sobra rótulo nem cartão', (tester) async {
      final app = _app();
      addTearDown(app.dispose);
      await _mostra(tester, app);

      expect(app.missaoDeRetomada, isNull);
      expect(find.text(app.t.mqRetomada), findsNothing);
      expect(find.byKey(CartaoDeMissao.chaveDe('retomada')), findsNothing);
    });

    testWidgets('depois de faltar, vem logo abaixo da principal', (
      tester,
    ) async {
      final app = _app(diasFora: 2);
      addTearDown(app.dispose);
      await _mostra(tester, app);

      final cartao = find.byKey(CartaoDeMissao.chaveDe('retomada'));
      expect(cartao, findsOneWidget);
      expect(find.text(app.t.mqRetomada), findsOneWidget);
      expect(
        _y(tester, find.byKey(CartaoDoDescanso.chave)),
        lessThan(_y(tester, cartao)),
      );
      expect(
        _y(tester, cartao),
        lessThan(
          _y(tester, find.byKey(CartaoDeMissao.chaveDe(app.missoes.first.id))),
        ),
        reason: 'no dia da volta ela é o assunto, não mais uma sorteada',
      );
    });

    testWidgets('cumprida, paga pela toca', (tester) async {
      final app = _app(diasFora: 2)..completedToday = 1;
      addTearDown(app.dispose);
      await _mostra(tester, app);

      final antes = app.leaves;
      await tester.tap(find.byKey(CartaoDeMissao.chaveDe('retomada')));
      await tester.pumpAndSettle();
      expect(find.byKey(Toca.chave), findsOneWidget);

      for (var i = 0; i < Toca.precisaDe; i++) {
        await tester.tap(find.byKey(Toca.chave));
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(app.leaves, antes + defDaRetomada.folhas);
      expect(app.missaoDeRetomada!.resgatada, isTrue);
    });
  });

  group('a hierarquia da tela', () {
    testWidgets('o que dá para colher vem antes do que ainda falta fazer', (
      tester,
    ) async {
      // Meio dia de trabalho: algumas fechadas, outras no meio. É o único
      // cenário em que a ordem dos dois blocos significa alguma coisa — com
      // tudo fechado ou nada fechado, um dos dois some e trocá-los não muda
      // pixel nenhum.
      final app = _app()
        ..completedToday = 1
        ..minutosDeFocoHoje = 20
        ..maiorSessaoHoje = 20;
      addTearDown(app.dispose);
      bool diaria(Missao m) => m.ritmo == RitmoDaMissao.diaria;
      _diaEmQue(
        app,
        (ms) =>
            ms.any((m) => m.resgatavel && diaria(m)) &&
            ms.any((m) => m.estado == EstadoDaMissao.emProgresso && diaria(m)),
      );
      await _mostra(tester, app);

      final t = app.t;
      final colher = app.missoes.where((m) => m.resgatavel && diaria(m));
      final fazendo = app.missoes.where(
        (m) => m.estado == EstadoDaMissao.emProgresso && diaria(m),
      );

      expect(find.text(t.mqColher), findsOneWidget);
      expect(find.text(t.mqAgora), findsOneWidget);
      expect(
        _y(tester, find.text(t.mqColher)),
        lessThan(_y(tester, find.text(t.mqAgora))),
      );
      for (final m in colher) {
        for (final f in fazendo) {
          expect(
            _y(tester, find.byKey(CartaoDeMissao.chaveDe(m.id))),
            lessThan(_y(tester, find.byKey(CartaoDeMissao.chaveDe(f.id)))),
            reason: 'folha parada na mesa tem de vir primeiro',
          );
        }
      }
    });

    testWidgets('as de hoje vêm antes das que correm até domingo', (
      tester,
    ) async {
      final app = _app();
      addTearDown(app.dispose);
      await _mostra(tester, app);

      final t = app.t;
      expect(find.text(t.mqAgora), findsOneWidget);
      expect(find.text(t.mqSemana), findsOneWidget);
      expect(
        _y(tester, find.text(t.mqAgora)),
        lessThan(_y(tester, find.text(t.mqSemana))),
      );
    });

    testWidgets('a mais perto de fechar encabeça o bloco de hoje', (
      tester,
    ) async {
      // Uma missão a 90% responde melhor que uma a 10% à pergunta que a
      // pessoa está fazendo: o que ainda dá para fechar hoje?
      final app = _app()
        ..completedToday = 1
        ..minutosDeFocoHoje = 55
        ..maiorSessaoHoje = 40;
      addTearDown(app.dispose);
      await _mostra(tester, app);

      final hoje = app.missoes
          .where(
            (m) =>
                m.estado == EstadoDaMissao.emProgresso &&
                m.ritmo == RitmoDaMissao.diaria,
          )
          .toList()
        ..sort((a, b) => b.fracao.compareTo(a.fracao));
      if (hoje.length < 2 || hoje.first.fracao == hoje.last.fracao) return;

      expect(
        _y(tester, find.byKey(CartaoDeMissao.chaveDe(hoje.first.id))),
        lessThan(_y(tester, find.byKey(CartaoDeMissao.chaveDe(hoje.last.id)))),
      );
    });

    testWidgets('bloco vazio não deixa rótulo órfão na tela', (tester) async {
      // Sem permissão nada fecha sozinho: as que dependem de medição viram
      // convite e as outras estão em zero. Nenhum sorteio dá o que colher.
      final app = _app(permissao: false);
      addTearDown(app.dispose);
      await _mostra(tester, app);

      final t = app.t;
      expect(
        app.missoes.any((m) => m.resgatavel),
        isFalse,
        reason: 'dia recém-começado não tem o que colher',
      );
      expect(
        find.text(t.mqColher),
        findsNothing,
        reason: 'título que promete conteúdo e não entrega é ruído',
      );
      expect(find.text(t.mqFeitas), findsNothing);
    });

    testWidgets('o convite de permissão explica o que a missão pede', (
      tester,
    ) async {
      final app = _app(permissao: false);
      addTearDown(app.dispose);
      _diaEmQue(app, (ms) => ms.any((m) => m.definicao.precisaDeUso));
      await _mostra(tester, app);

      final travadas = app.missoes
          .where((m) => m.estado == EstadoDaMissao.precisaPermissao)
          .toList();
      expect(travadas, isNotEmpty);
      for (final m in travadas) {
        expect(
          find.text(comoDaMissao(app, m)),
          findsWidgets,
          reason: 'quem não concedeu é quem menos sabe o que a missão pede',
        );
      }

      await tester.tap(find.byKey(CartaoDeMissao.chaveDe(travadas.first.id)));
      await tester.pump();
      expect(
        app.screen,
        AppScreen.tempo,
        reason: 'sair para os ajustes do Android sem contexto perde a pessoa',
      );
    });

    testWidgets('travada leva ao tempo mesmo a que não é missão de tela', (
      tester,
    ) async {
      // `dia_completo` pede uma sessão de foco, e o lugar de fazer uma
      // sessão é a home. Mas sem o acesso ao uso ela não é uma missão a
      // fazer, é um convite a conceder — e a home não tem onde conceder.
      // Sem esta distinção o cartão despachava a pessoa para o lugar certo
      // da missão errada.
      const travada = 'dia_completo';
      final app = _app(permissao: false);
      addTearDown(app.dispose);
      _diaEmQue(app, (ms) => ms.any((m) => m.id == travada));
      await _mostra(tester, app);

      await tester.tap(find.byKey(CartaoDeMissao.chaveDe(travada)));
      await tester.pump();
      expect(app.screen, AppScreen.tempo);
    });
  });
}
