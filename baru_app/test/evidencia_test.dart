@Tags(['evidencia'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/widgets/habitat.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gera a evidência visual do turno em `docs/evidence/<data>/`.
///
/// São PNGs de verdade, rasterizados a partir da árvore de widgets — não
/// goldens de comparação e não descrição de animação. O §10 do mandato exige
/// que ninguém chame uma animação de pronta sem tê-la exercitado; aqui ela é
/// exercitada e o resultado fica no disco.
const _pasta = '../docs/evidence/2026-08-27';

Future<void> _salva(WidgetTester tester, Key chave, String nome) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(chave));
  await tester.runAsync(() async {
    final img = await boundary.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    final destino = Directory(_pasta)..createSync(recursive: true);
    File('${destino.path}/$nome.png').writeAsBytesSync(
      data!.buffer.asUint8List(),
    );
  });
}

AppState _estado({List<String> itens = const []}) {
  final s = AppState()..startCompanionship();
  s.owned = List<String>.from(itens);
  return s;
}

Widget _habitat(AppState app, DateTime agora) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: AppScope(
            state: app,
            child: const SizedBox(
              width: 372,
              height: 296,
              child: HabitatScene(),
            ),
          ),
        ),
      ),
    );

void main() {
  setUp(() {
    // Cena determinística: sem a deriva contínua, dois quadros do mesmo
    // momento saem iguais e a evidência é reproduzível.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('habitat nos quatro momentos do dia', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const horas = {
      6: 'amanhecer',
      12: 'dia',
      18: 'entardecer',
      22: 'noite',
    };
    for (final e in horas.entries) {
      final app = _estado(itens: const ['lily', 'dock', 'rock', 'lantern']);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppScope(
                state: app,
                child: SizedBox(
                  width: 372,
                  height: 296,
                  child: HabitatScene(agora: DateTime(2026, 8, 27, e.key)),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await _salva(tester, HabitatScene.cenaKey, 'habitat-${e.value}');
    }
  });

  testWidgets('habitat vazio e habitat cheio', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );

    for (final caso in {'vazio': <String>[], 'cheio': habitats['full']!}.entries) {
      final app = _estado(itens: caso.value);
      await tester.pumpWidget(_habitat(app, DateTime(2026, 8, 27, 12)));
      await tester.pump();
      await _salva(tester, HabitatScene.cenaKey, 'habitat-${caso.key}');
    }
  });

  testWidgets('o companheiro em cada atividade', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );

    const casos = {
      Activity.swim: Mood.radiant,
      Activity.graze: Mood.content,
      Activity.nap: Mood.sleepy,
      Activity.idle: Mood.missingYou,
    };
    for (final e in casos.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PetView(
                species: Species.capybara,
                mood: e.value,
                activity: e.key,
                coat: 0,
                interativo: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await _salva(tester, PetView.cenaKey, 'pet-${e.key.name}');
    }
  });

  testWidgets('as quatro espécies', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );

    for (final sp in Species.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PetView(
                species: sp,
                mood: Mood.content,
                activity: Activity.idle,
                coat: 0,
                interativo: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await _salva(tester, PetView.cenaKey, 'especie-${sp.name}');
    }
  });

  testWidgets('sequência de quadros da respiração', (tester) async {
    // Sem desligar animação: a sequência É a evidência do movimento.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: PetView(
              species: Species.capybara,
              mood: Mood.content,
              activity: Activity.idle,
              coat: 0,
              interativo: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await _salva(tester, PetView.cenaKey, 'respiracao-${i + 1}');
      await tester.pump(const Duration(milliseconds: 280));
    }
  });

  testWidgets('sequência de quadros da chegada de um item', (tester) async {
    final app = _estado(itens: const ['lily'])..leaves = 500;
    await tester.pumpWidget(_habitat(app, DateTime(2026, 8, 27, 12)));
    await tester.pump();
    await _salva(tester, HabitatScene.cenaKey, 'chegada-0-antes');

    app.buy(shopItems.firstWhere((i) => i.id == 'bridge'));
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 150));
      await _salva(tester, HabitatScene.cenaKey, 'chegada-${i + 1}');
    }
  });
}
