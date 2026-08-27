import 'dart:ui' as ui;

import 'package:baru_app/data/progressao.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Acariciar.
///
/// O bicho só tinha um jeito de ser tocado: cutucar. Afagar é outra coisa —
/// é a **mão andando** em cima dele, e a resposta tem de crescer com o
/// percurso, não com o número de toques.

var _carinhos = 0;

Widget _cena({bool interativo = true, Species especie = Species.capybara}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: PetView(
          species: especie,
          mood: Mood.content,
          activity: Activity.idle,
          coat: 0,
          interativo: interativo,
          aoCarinho: () => _carinhos += 1,
        ),
      ),
    ),
  );
}

Future<Uint8List> _quadro(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(PetView.cenaKey),
  );
  final bytes = await tester.runAsync(() async {
    final img = await boundary.toImage();
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
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

/// Passa a mão no bicho, de ida e volta, até percorrer [px].
Future<TestGesture> _afaga(WidgetTester tester, double px) async {
  final centro = tester.getCenter(find.byType(PetView));
  final mao = await tester.startGesture(centro - const Offset(50, 0));
  // O reconhecedor de arrasto só acorda depois do slop do toque; sem esta
  // primeira passada larga o gesto nem começa.
  await mao.moveBy(const Offset(30, 0));
  await tester.pump(const Duration(milliseconds: 16));

  var andado = 0.0;
  var direcao = 1.0;
  while (andado < px) {
    for (var i = 0; i < 10 && andado < px; i++) {
      await mao.moveBy(Offset(10 * direcao, 0));
      await tester.pump(const Duration(milliseconds: 16));
      andado += 10;
    }
    direcao = -direcao;
  }
  return mao;
}

void main() {
  setUp(() => _carinhos = 0);

  group('a economia do vínculo', () {
    test('um afago completo sobe o vínculo e dá XP', () {
      final s = AppState()..startCompanionship();
      final xpAntes = s.xp;
      final ganho = s.recebeCarinho();
      expect(ganho, Balanco.xpPorCarinho);
      expect(s.afeto, 1);
      expect(s.xp, xpAntes + Balanco.xpPorCarinho);
      s.dispose();
    });

    test('o XP tem teto por dia; o vínculo não', () {
      final s = AppState()..startCompanionship();
      for (var i = 0; i < Balanco.carinhosPorDia; i++) {
        expect(s.recebeCarinho(), Balanco.xpPorCarinho);
      }
      final xpNoTeto = s.xp;

      expect(
        s.recebeCarinho(),
        0,
        reason: 'sem teto, esfregar a tela seria a forma mais barata de subir '
            'de nível — e o app passaria a recompensar isso em vez de foco',
      );
      expect(s.xp, xpNoTeto);
      expect(
        s.afeto,
        Balanco.carinhosPorDia + 1,
        reason: 'o vínculo é a relação, não a economia: ele sempre sobe',
      );
      s.dispose();
    });

    test('a virada do dia devolve os afagos que pagam', () {
      final s = AppState()..startCompanionship();
      for (var i = 0; i < Balanco.carinhosPorDia; i++) {
        s.recebeCarinho();
      }
      expect(s.recebeCarinho(), 0);

      s.applyCalendar(DateTime.now().add(const Duration(days: 1)));

      expect(s.recebeCarinho(), Balanco.xpPorCarinho);
      expect(s.afeto, Balanco.carinhosPorDia + 2, reason: 'o total não zera');
      s.dispose();
    });

    test('o vínculo sobrevive ao snapshot', () {
      final s = AppState()..startCompanionship();
      s.recebeCarinho();
      s.recebeCarinho();
      final snap = s.toSnapshot();
      expect(snap.afeto, 2);
      expect(snap.carinhosHoje, 2);

      final volta = AppState(snapshot: snap);
      expect(volta.afeto, 2);
      expect(volta.carinhosHoje, 2);
      s.dispose();
      volta.dispose();
    });
  });

  group('o gesto', () {
    testWidgets('a mão andando muda o desenho', (tester) async {
      // Movimento reduzido isola: sem o contínuo, a única coisa que anda é a
      // reação ao afago.
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await tester.pumpWidget(_cena());
      await tester.pump();
      final parado = await _quadro(tester);

      final mao = await _afaga(tester, PetView.percursoDoAfago * 0.7);
      final afagado = await _quadro(tester);
      expect(_mudou(parado, afagado), isTrue);

      await mao.up();
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('a satisfação cresce com o percurso, não com o tempo', (
      tester,
    ) async {
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await tester.pumpWidget(_cena());
      await tester.pump();

      // Dedo pousado e parado pelo mesmo tempo que um afago inteiro levaria.
      final centro = tester.getCenter(find.byType(PetView));
      final parado = await tester.startGesture(centro);
      await tester.pump(const Duration(seconds: 3));
      expect(
        _carinhos,
        0,
        reason: 'dedo pousado não é carinho — se contasse por tempo, seria',
      );
      await parado.up();
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('percorrer o bicho inteiro completa o afago, uma vez só', (
      tester,
    ) async {
      await tester.pumpWidget(_cena());
      await tester.pump();

      final mao = await _afaga(tester, PetView.percursoDoAfago * 1.6);
      expect(_carinhos, 1, reason: 'um gesto, um crédito');

      await mao.up();
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('meio afago não credita nada', (tester) async {
      await tester.pumpWidget(_cena());
      await tester.pump();

      final mao = await _afaga(tester, PetView.percursoDoAfago * 0.5);
      expect(_carinhos, 0);

      await mao.up();
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('o afago ronrona: um clique a cada tanto de percurso', (
      tester,
    ) async {
      final cliques = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            cliques.add('${call.arguments}');
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(_cena());
      await tester.pump();
      final mao = await _afaga(tester, PetView.percursoDoAfago);

      // Um clique a cada `passoDoRonrom`, mais o impacto do afago completo.
      expect(
        cliques.length,
        greaterThan(PetView.percursoDoAfago ~/ PetView.passoDoRonrom - 4),
        reason: 'sem o ronronar o afago é mudo na mão',
      );
      expect(cliques, contains(contains('mediumImpact')));

      await mao.up();
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('a satisfação desce sozinha quando a mão sai', (tester) async {
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await tester.pumpWidget(_cena());
      await tester.pump();
      final repouso = await _quadro(tester);

      final mao = await _afaga(tester, PetView.percursoDoAfago * 0.8);
      final gostando = await _quadro(tester);
      expect(_mudou(repouso, gostando), isTrue);

      await mao.up();
      // Em passos, não num salto só: um `pump` de vários segundos entrega um
      // delta único ao ticker e a simulação não chega a andar.
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final depois = await _quadro(tester);

      expect(
        _mudou(repouso, depois),
        isFalse,
        reason: 'passado o carinho ele volta ao repouso; sobra é pose travada',
      );
    });

    testWidgets('miniatura não é afagável', (tester) async {
      await tester.pumpWidget(_cena(interativo: false));
      await tester.pump();
      expect(find.byType(GestureDetector), findsNothing);
    });
  });
}
