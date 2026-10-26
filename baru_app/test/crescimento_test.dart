// O bicho nasce e cresce com as sessões de foco feitas com ele.
//
// Pedido do dono (item 6): "não dá para acompanhar o crescimento dos pets,
// deve ser extremamente visível a diferença; a coruja começa em um ovo".
// Régua e estágios: `docs/pesquisa/00-SINTESE.md` e ADR-024.
import 'dart:ui' as ui;

import 'package:baru_app/data/app_snapshot.dart';
import 'package:baru_app/data/crescimento.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/widgets/crescimento.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

AppState _app({Species especie = Species.owl}) => AppState()
  ..onb = 9
  ..companionshipStarted = true
  ..species = especie
  ..debugFast = false;

void _concluiUmaSessao(AppState s) {
  s.startSession();
  s.sessionEndsAt = DateTime.now().subtract(const Duration(seconds: 1));
  s.reconcileSession();
}

void main() {
  group('a régua', () {
    test('0, 1, 5, 15 e 40 sessões abrem os cinco estágios', () {
      expect(Crescimento.estagioPara(0), EstagioDoBicho.inicio);
      expect(Crescimento.estagioPara(1), EstagioDoBicho.filhote);
      expect(Crescimento.estagioPara(4), EstagioDoBicho.filhote);
      expect(Crescimento.estagioPara(5), EstagioDoBicho.jovem);
      expect(Crescimento.estagioPara(15), EstagioDoBicho.adulto);
      expect(Crescimento.estagioPara(39), EstagioDoBicho.adulto);
      expect(Crescimento.estagioPara(40), EstagioDoBicho.pleno);
      expect(Crescimento.estagioPara(4000), EstagioDoBicho.pleno);
    });

    test('nunca anda para trás: mais sessões, estágio igual ou maior', () {
      var anterior = Crescimento.estagioPara(0).index;
      for (var n = 1; n < 100; n++) {
        final agora = Crescimento.estagioPara(n).index;
        expect(agora, greaterThanOrEqualTo(anterior));
        anterior = agora;
      }
    });

    test('quanto falta e quanto andou', () {
      expect(Crescimento.faltamPara(0), 1);
      expect(Crescimento.faltamPara(1), 4);
      expect(Crescimento.faltamPara(14), 1);
      expect(Crescimento.faltamPara(40), isNull);
      expect(Crescimento.progressoNoEstagio(1), 0);
      expect(Crescimento.progressoNoEstagio(3), closeTo(0.5, 1e-9));
      expect(Crescimento.progressoNoEstagio(40), 1);
    });

    test('só bota ovo quem bota ovo', () {
      final ovo = Species.values.where(Crescimento.botaOvo).toSet();
      expect(ovo, {
        Species.owl,
        Species.penguin,
        Species.tortoise,
        Species.axolotl,
      });
    });
  });

  group('no estado', () {
    test('conta nova começa no ovo, e a primeira sessão choca', () {
      final s = _app();
      addTearDown(s.dispose);
      expect(s.estagio, EstagioDoBicho.inicio);
      expect(s.cresceuSemCelebrar, isFalse);

      _concluiUmaSessao(s);

      expect(s.sessoesJuntos, 1);
      expect(s.estagio, EstagioDoBicho.filhote);
      expect(s.cresceuSemCelebrar, isTrue);
      expect(s.temCelebracaoPendente, isTrue);
      expect(s.estagioJaVisto, EstagioDoBicho.inicio);
    });

    test('o crescimento passa na frente do nível, e só uma vez', () {
      final s = _app();
      addTearDown(s.dispose);
      _concluiUmaSessao(s);
      s.nivelCelebrado = 0;
      s.xp = 100000;

      s.celebrou();
      expect(s.cresceuSemCelebrar, isFalse);
      expect(s.subiuDeNivel, isTrue, reason: 'o nível espera a vez');
      expect(s.estagioCelebrado[Species.owl.name], EstagioDoBicho.filhote.index);
    });

    test('a sessão conta para a espécie de agora, e só para ela', () {
      final s = _app();
      addTearDown(s.dispose);
      _concluiUmaSessao(s);
      s.species = Species.capybara;
      expect(s.sessoesJuntos, 0);
      expect(s.estagio, EstagioDoBicho.inicio);
      _concluiUmaSessao(s);
      expect(s.sessoesPorEspecie, {'owl': 1, 'capybara': 1});
    });

    test('desistir não faz crescer', () {
      final s = _app();
      addTearDown(s.dispose);
      s.startSession();
      s.abandon();
      expect(s.sessoesJuntos, 0);
    });
  });

  group('contas de antes do crescimento', () {
    test('cada espécie liberada recebe o total, sem cena repetida', () {
      final s = _app(especie: Species.capybara);
      addTearDown(s.dispose);
      final antes = s.toSnapshot().copyWith(
            sessoesConcluidas: 20,
            sessoesPorEspecie: const {},
            estagioCelebrado: const {},
          );
      s.applySnapshotParaTeste(antes);

      expect(s.sessoesJuntos, 20);
      expect(s.estagio, EstagioDoBicho.adulto);
      expect(s.cresceuSemCelebrar, isFalse,
          reason: 'quem já tinha o bicho adulto não o vê "nascer" de novo');
      for (final e in s.especiesLiberadas) {
        expect(s.sessoesPorEspecie[e.name], 20);
      }
    });

    test('conta nova (zero sessões) não é semeada', () {
      expect(
        Crescimento.semeia(
          atual: const {},
          sessoesDaConta: 0,
          liberadas: const [Species.owl],
        ),
        isEmpty,
      );
    });

    test('mapa já existente nunca é sobrescrito pela semente', () {
      expect(
        Crescimento.semeia(
          atual: const {'owl': 3},
          sessoesDaConta: 50,
          liberadas: const [Species.owl, Species.cat],
        ),
        {'owl': 3},
      );
    });
  });

  test('sincronizar fica com o maior de cada espécie (nunca regride)', () {
    final remoto = AppSnapshot.zerado().copyWith(
      sessoesPorEspecie: const {'owl': 2, 'cat': 9},
      estagioCelebrado: const {'owl': 1},
    );
    final local = AppSnapshot.zerado().copyWith(
      sessoesPorEspecie: const {'owl': 7},
      estagioCelebrado: const {'owl': 2, 'cat': 2},
    );
    final f = remoto.fundeCom(local);
    expect(f.sessoesPorEspecie, {'owl': 7, 'cat': 9});
    expect(f.estagioCelebrado, {'owl': 2, 'cat': 2});
  });

  test('o snapshot leva e traz os dois mapas', () {
    final s = AppSnapshot.zerado().copyWith(
      sessoesPorEspecie: const {'fox': 16},
      estagioCelebrado: const {'fox': 3},
    );
    final volta = AppSnapshot.fromJson(s.toJson());
    expect(volta.sessoesPorEspecie, {'fox': 16});
    expect(volta.estagioCelebrado, {'fox': 3});
  });

  group('o desenho', () {
    /// Altura do que foi pintado (pixels não transparentes), em px.
    Future<({int altura, int largura})> medida(
      WidgetTester tester,
      Species sp,
      EstagioDoBicho e,
    ) async {
      final chave = GlobalKey();
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Center(
          child: RepaintBoundary(
            key: chave,
            child: PetView(
              species: sp,
              mood: Mood.content,
              activity: Activity.idle,
              coat: 0,
              interativo: false,
              estagio: e,
              width: 200,
              height: 160,
            ),
          ),
        ),
      ));
      final b = chave.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      late ({int altura, int largura}) r;
      await tester.runAsync(() async {
        final img = await b.toImage(pixelRatio: 1);
        final raw = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
        final w = img.width, h = img.height;
        img.dispose();
        final px = raw!.buffer.asUint8List();
        var minX = w, maxX = -1, minY = h, maxY = -1;
        for (var y = 0; y < h; y++) {
          for (var x = 0; x < w; x++) {
            if (px[(y * w + x) * 4 + 3] > 16) {
              if (x < minX) minX = x;
              if (x > maxX) maxX = x;
              if (y < minY) minY = y;
              if (y > maxY) maxY = y;
            }
          }
        }
        r = (altura: maxY - minY + 1, largura: maxX - minX + 1);
      });
      return r;
    }

    testWidgets('filhote < jovem < adulto em altura, nas nove espécies',
        (tester) async {
      for (final sp in Species.values) {
        final f = await medida(tester, sp, EstagioDoBicho.filhote);
        final j = await medida(tester, sp, EstagioDoBicho.jovem);
        final a = await medida(tester, sp, EstagioDoBicho.adulto);
        expect(f.altura, lessThan(j.altura), reason: '${sp.name}: filhote');
        expect(j.altura, lessThan(a.altura), reason: '${sp.name}: jovem');
        // "Extremamente visível": o filhote tem no máximo 3/4 da altura do
        // adulto.
        expect(f.altura, lessThan(a.altura * 0.75), reason: sp.name);
      }
    });

    testWidgets('o começo é um desenho próprio, menor que o filhote',
        (tester) async {
      for (final sp in Species.values) {
        final c = await medida(tester, sp, EstagioDoBicho.inicio);
        final f = await medida(tester, sp, EstagioDoBicho.filhote);
        expect(c.altura, lessThan(f.altura), reason: sp.name);
        expect(c.altura, greaterThan(20), reason: '${sp.name}: sumiu');
      }
    });
  });

  group('na tela', () {
    Widget comApp(AppState s, Widget filho) => AppScope(
          state: s,
          child: MaterialApp(home: Scaffold(body: Stack(children: [filho]))),
        );

    testWidgets('a cena mostra o nascimento e fecha no botão', (tester) async {
      final s = _app();
      addTearDown(s.dispose);
      s.petName = 'Nina';
      _concluiUmaSessao(s);
      var fechou = false;

      await tester.pumpWidget(comApp(
        s,
        CenaDoCrescimento(
          antes: s.estagioJaVisto,
          depois: s.estagio,
          aoFechar: () => fechou = true,
        ),
      ));
      // Um toque no meio só adianta a cena.
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.byKey(CenaDoCrescimento.chave));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      expect(fechou, isFalse);
      expect(find.text('Nina nasceu!'), findsOneWidget);
      expect(find.text('AGORA: FILHOTE'), findsOneWidget);

      await tester.tap(find.text('Continuar'));
      expect(fechou, isTrue);
      // O bicho respira para sempre: sem `pumpAndSettle`. Desmonta para os
      // relógios pararem.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a barra diz quanto falta para nascer', (tester) async {
      final s = _app();
      addTearDown(s.dispose);
      s.petName = 'Nina';
      await tester.pumpWidget(comApp(s, const BarraDoCrescimento()));
      expect(find.text('OVO'), findsOneWidget);
      expect(
        find.text('Falta 1 sessão de foco para Nina nascer'),
        findsOneWidget,
      );
    });

    testWidgets('no mamífero o começo é o ninho, e o verbo é abrir os olhos',
        (tester) async {
      final s = _app(especie: Species.capybara);
      addTearDown(s.dispose);
      s.petName = 'Tico';
      await tester.pumpWidget(comApp(s, const BarraDoCrescimento()));
      expect(find.text('NINHO'), findsOneWidget);
      expect(
        find.text('Falta 1 sessão de foco para Tico abrir os olhos'),
        findsOneWidget,
      );
    });
  });
}
