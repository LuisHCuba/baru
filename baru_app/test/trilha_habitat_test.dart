import 'dart:ui' as ui;

import 'package:baru_app/data/progressao.dart';
import 'package:baru_app/l10n.dart';
import 'package:baru_app/l10n_trilha.dart';
import 'package:baru_app/screens/trilha_screen.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/widgets/habitat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Habitats abertos pela trilha, à moda das arenas do Clash Royale.
///
/// Antes o habitat não tinha relação nenhuma com a trilha: `estagioDoHabitat`
/// era calculado e ninguém lia, e a única coisa que mudava a cena era comprar
/// um cenário na loja. Aqui se prova o contrário — subir de marco muda o
/// lugar, e o lugar dá para escolher de dentro da trilha.

AppState _conta({int xp = 0, int sessoes = 0}) {
  final s = AppState()..startCompanionship();
  s.xp = xp;
  s.sessoesConcluidas = sessoes;
  return s;
}

/// Uma conta com o segundo habitat aberto (marco de nível 3).
AppState _comIgarape() => _conta(xp: Balanco.xpAcumuladoPara(3));

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

/// A fila de habitats é horizontal e preguiçosa: o que está fora do quadro
/// nem existe na árvore. Rolar é o que traz o cartão para o teste — e é o
/// mesmo gesto que a pessoa faz.
Future<void> _rolaHabitats(WidgetTester tester, Finder alvo) =>
    tester.scrollUntilVisible(
      alvo.hitTestable(),
      140,
      scrollable: find.descendant(
        of: find.byKey(SeletorDeHabitat.chave),
        matching: find.byType(Scrollable),
      ),
    );

Future<Uint8List> _quadro(WidgetTester tester) async {
  final b = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(HabitatScene.cenaKey),
  );
  final bytes = await tester.runAsync(() async {
    final img = await b.toImage();
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();
    return data!.buffer.asUint8List();
  });
  return bytes!;
}

bool _mudou(Uint8List a, Uint8List b) {
  if (a.length != b.length) return true;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return true;
  }
  return false;
}

void main() {
  group('a escada de habitats', () {
    test('conta nova mora no primeiro e não tem outro aberto', () {
      final s = _conta();
      expect(s.habitatAtivo.id, 'lagoa');
      expect(s.habitatsLiberados.map((h) => h.id), ['lagoa']);
    });

    test('subir o marco abre o habitat e muda de lugar sozinho', () {
      final s = _conta();
      expect(s.habitatAtivo.id, 'lagoa');

      s.xp = Balanco.xpAcumuladoPara(3);

      expect(s.progresso.habitatLiberado('igarape'), isTrue);
      expect(
        s.habitatAtivo.id,
        'igarape',
        reason: 'a arena nova é a casa nova — a pessoa não precisa pedir',
      );
    });

    test('cada estágio de habitat tem um marco que o entrega', () {
      for (final h in habitatsDaTrilha.where((h) => h.estagio > 1)) {
        final marcos = trilha
            .where((m) => m.recompensa.estagioDeHabitat == h.estagio)
            .toList();
        expect(
          marcos.length,
          1,
          reason: '${h.id} não tem exatamente um marco que o abre',
        );
      }
    });

    test('o passo que abre cada habitat cresce junto com o estágio', () {
      var anterior = 0;
      for (final h in habitatsDaTrilha) {
        final passo = passoQueAbreOHabitat(h);
        expect(
          passo,
          greaterThanOrEqualTo(anterior),
          reason: '${h.id} abre antes de um habitat mais baixo',
        );
        anterior = passo;
      }
    });

    test('todo habitat da trilha tem desenho', () {
      for (final h in habitatsDaTrilha) {
        expect(
          CenarioDoHabitat.porId.containsKey(h.id),
          isTrue,
          reason: '${h.id} cairia na lagoa em silêncio',
        );
      }
    });
  });

  group('escolher o habitat', () {
    test('dá para voltar para um habitat já aberto', () {
      final s = _comIgarape();
      expect(s.habitatAtivo.id, 'igarape');

      s.escolheHabitat('lagoa');
      expect(s.habitatAtivo.id, 'lagoa');
    });

    test('escolher um habitat que a trilha não abriu não faz nada', () {
      final s = _conta();
      s.escolheHabitat('praia');
      expect(
        s.habitatAtivo.id,
        'lagoa',
        reason: 'cenário não conquistado não pode entrar por chamada solta',
      );
      expect(s.habitatEscolhido, isNull);
    });

    test('a escolha sobrevive ao snapshot', () {
      final s = _comIgarape()..escolheHabitat('lagoa');
      final reaberto = AppState(snapshot: s.toSnapshot());
      expect(reaberto.habitatEscolhido, 'lagoa');
      expect(reaberto.habitatAtivo.id, 'lagoa');
    });

    test('um habitat por vez: trocar não acumula', () {
      final s = _comIgarape()
        ..escolheHabitat('lagoa')
        ..escolheHabitat('igarape');
      final guardados =
          s.equipados.where((e) => e.startsWith('habitat:')).toList();
      expect(guardados.length, 1);
      expect(s.habitatAtivo.id, 'igarape');
    });

    test('a escolha não vira item de cena nem cenário de loja', () {
      // O id fica em `equipados`, que a cena e a loja também leem. Se ele
      // vazasse para lá, o habitat viraria um objeto invisível no quadro ou
      // um cenário fantasma que ninguém comprou.
      final s = _comIgarape()..escolheHabitat('igarape');
      expect(s.objetosNaCena, isEmpty);
      expect(s.cenarioAtivo, isNull);
    });

    test('escolha antiga some quando a trilha não a cobre mais', () {
      // Snapshot de outro aparelho, com um habitat que esta conta ainda não
      // conquistou: vale o que a trilha diz, não o que o arquivo pede.
      final adiantado = _conta()..equipados = {'habitat:praia'};
      final s = AppState(snapshot: adiantado.toSnapshot());
      expect(s.habitatAtivo.id, 'lagoa');
    });
  });

  group('a silhueta da colina', () {
    // Caixa de 200×120 com o pé em y=200, então o ápice está em y=80.
    //
    // Em x=28 o domo (raio 100, centro em y=180) começa em y≈111, e a reta do
    // pico só chega em y≈151. O ponto (28, 130) cai entre os dois: é terra na
    // duna e céu na serra.
    const caixa = (esquerda: 0.0, base: 200.0, largura: 200.0, altura: 120.0);
    const ombro = Offset(28, 130);

    Path colina(double pico) => silhuetaDeColina(
          esquerda: caixa.esquerda,
          base: caixa.base,
          largura: caixa.largura,
          altura: caixa.altura,
          pico: pico,
        );

    test('a duna é larga no alto e o pico não', () {
      expect(colina(0).contains(ombro), isTrue, reason: 'duna');
      expect(colina(1).contains(ombro), isFalse, reason: 'pico');
    });

    test('os dois extremos têm o mesmo pé e o mesmo ápice', () {
      // Interpolar a forma só vale se as pontas não se mexerem: é isso que
      // deixa a colina no lugar quando o habitat troca.
      for (final pico in [0.0, 0.5, 1.0]) {
        final b = colina(pico).getBounds();
        expect(b.bottom, moreOrLessEquals(caixa.base, epsilon: 0.01));
        expect(
          b.top,
          moreOrLessEquals(caixa.base - caixa.altura, epsilon: 0.01),
        );
        expect(b.width, moreOrLessEquals(caixa.largura, epsilon: 0.01));
      }
    });
  });

  group('a cena', () {
    testWidgets('o habitat da trilha muda o desenho do fundo', (tester) async {
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      final app = _comIgarape();
      Widget cena() => MaterialApp(
            home: Scaffold(
              body: AppScope(
                state: app,
                child: SizedBox(
                  width: 372,
                  height: 296,
                  child: HabitatScene(
                    agora: DateTime(2026, 8, 27, 12),
                    animado: false,
                  ),
                ),
              ),
            ),
          );

      app.escolheHabitat('lagoa');
      await tester.pumpWidget(cena());
      await tester.pump();
      final naLagoa = await _quadro(tester);

      app.escolheHabitat('igarape');
      await tester.pumpWidget(cena());
      await tester.pump();
      final noIgarape = await _quadro(tester);

      expect(
        _mudou(naLagoa, noIgarape),
        isTrue,
        reason: 'o habitat da trilha tem de aparecer na cena, não só no dado',
      );
    });
  });

  group('o seletor dentro da trilha', () {
    testWidgets('lista os habitats e marca o que está em uso', (tester) async {
      final app = _comIgarape();
      await _abre(tester, app);

      expect(find.byKey(SeletorDeHabitat.chave), findsOneWidget);
      expect(find.text(app.t.s('trilhaHabitatEmUso')), findsOneWidget);
      for (final h in habitatsDaTrilha) {
        await _rolaHabitats(tester, find.text(nomeDoHabitat(app, h)));
        expect(
          find.text(nomeDoHabitat(app, h)),
          findsWidgets,
          reason: '${h.id} não aparece no seletor',
        );
      }
    });

    testWidgets('tocar num habitat aberto muda a casa do bicho',
        (tester) async {
      final app = _comIgarape();
      expect(app.habitatAtivo.id, 'igarape');
      await _abre(tester, app);

      await tester.tap(find.text(nomeDoHabitat(app, habitatsDaTrilha.first)));
      await tester.pump();

      expect(
        app.habitatAtivo.id,
        'lagoa',
        reason: 'trocar de habitat de dentro da trilha é o pedido T-04',
      );
    });

    testWidgets('habitat travado não responde ao toque e diz onde abre',
        (tester) async {
      final app = _conta();
      await _abre(tester, app);

      final serra = habitatsDaTrilha.firstWhere((h) => h.id == 'serra');
      await _rolaHabitats(tester, find.text(nomeDoHabitat(app, serra)));

      expect(
        find.text(
          app.t.fill(app.t.s('trilhaAbreNoPasso'), {
            'n': passoQueAbreOHabitat(serra),
          }),
        ),
        findsWidgets,
        reason: 'o travado tem de dizer quando abre — é o que dá vontade',
      );

      await tester.tap(find.text(nomeDoHabitat(app, serra)));
      await tester.pump();
      expect(app.habitatAtivo.id, 'lagoa');
    });
  });

  group('o prêmio', () {
    test('o marco anuncia o habitat pelo nome, não "o habitat cresce"', () {
      final app = _conta();
      final marco = trilha.firstWhere((m) => m.id == 'nivel_3');
      final premios = premiosDoMarco(app, marco);
      expect(
        premios.any((p) => p.contains(nomeDoHabitat(app, habitatDoEstagio(2)))),
        isTrue,
      );
    });

    test('o nome do habitat existe nos 4 idiomas, sem cair na chave crua', () {
      // `T.s` devolve a própria chave quando o catálogo não está registrado.
      // Este teste esquece os extras de propósito para provar que o registro
      // preguiçoso acontece na chamada, não só no `build` da tela.
      T.esqueceOsExtras();
      for (final lang in ['pt', 'en', 'es', 'zh']) {
        final app = _conta()..lang = lang;
        for (final h in habitatsDaTrilha) {
          final nome = nomeDoHabitat(app, h);
          expect(nome, isNotEmpty, reason: '${h.id}/$lang');
          expect(nome, isNot(startsWith('hab')), reason: '${h.id}/$lang');
        }
      }
      garanteTextosDaTrilha();
    });
  });
}
