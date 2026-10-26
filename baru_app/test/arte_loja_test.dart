@Tags(['capturas'])
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/widgets/habitat.dart';
import 'package:baru_app/widgets/icone_arte.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Arte em alta resolução para a ficha da Google Play, a página do Baru em
/// lhcx.tech e o vídeo: o ícone de 512 px que a loja pede e os companheiros
/// sobre fundo transparente.
///
/// Tudo sai dos mesmos `CustomPainter` do app — vetor, então a resolução é a
/// que se pedir. Nada aqui é desenhado à parte.
///
/// Só roda com `CAPTURAS=1` (escreve em `../play-store/arte`).
final _ligado = Platform.environment['CAPTURAS'] == '1';
const _pasta = '../play-store/arte';

Future<void> _grava(
  WidgetTester tester,
  String chave,
  String nome, {
  double pixelRatio = 1,
}) async {
  final b = tester.renderObject<RenderRepaintBoundary>(find.byKey(Key(chave)));
  await tester.runAsync(() async {
    final img = await b.toImage(pixelRatio: pixelRatio);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    final dir = Directory(_pasta)..createSync(recursive: true);
    File('${dir.path}/$nome.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
}

Widget _bicho(Species sp, Mood mood, {Activity activity = Activity.idle}) =>
    SizedBox(
      width: 200,
      height: 160,
      child: PetView(
        // Chave por bicho e humor: sem ela o mesmo PetView é reaproveitado de
        // um humor para o outro, a troca de humor começa, e a foto sai com o
        // rosto do humor anterior.
        key: ValueKey('${sp.name}-${mood.name}-${activity.name}'),
        species: sp,
        mood: mood,
        activity: activity,
        coat: 0,
        interativo: false,
        width: 200,
        height: 160,
      ),
    );

/// Onde o bicho tem tinta dentro da caixa 200 × 160, lido do pixel — a mesma
/// medida de `gera_icone_test.dart`, para centrar pelo corpo e não pela caixa.
Future<Rect> _limites(WidgetTester tester, Species sp) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: const Key('medida'),
          child: _bicho(sp, Mood.radiant),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 120));
  final b = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('medida')),
  );
  late Rect r;
  await tester.runAsync(() async {
    final img = await b.toImage(pixelRatio: 1);
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();
    final px = data!.buffer.asUint8List();
    var minX = 200, minY = 160, maxX = -1, maxY = -1;
    for (var y = 0; y < 160; y++) {
      for (var x = 0; x < 200; x++) {
        if (px[(y * 200 + x) * 4 + 3] > 8) {
          minX = math.min(minX, x);
          maxX = math.max(maxX, x);
          minY = math.min(minY, y);
          maxY = math.max(maxY, y);
        }
      }
    }
    r = Rect.fromLTRB(minX.toDouble(), minY.toDouble(), maxX + 1.0, maxY + 1.0);
  });
  return r;
}

void main() {
  testWidgets('ícone de 512 px para a ficha da loja', skip: !_ligado, (
    tester,
  ) async {
    const lado = 512.0;
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const sp = Species.capybara;
    final limites = await _limites(tester, sp);
    // Sem a máscara do adaptativo, o bicho pode ocupar mais do ladrilho:
    // a loja só arredonda os cantos.
    const alvo = lado * 0.70;
    final fator = alvo / math.max(limites.width, limites.height);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: const Key('icone'),
            child: SizedBox(
              width: lado,
              height: lado,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FundoDoIcone(lado: lado, semente: sp.index + 1),
                  const Align(
                    alignment: Alignment(0, 0.80),
                    child: SombraDoIcone(largura: alvo * 0.78),
                  ),
                  Transform.translate(
                    offset: Offset(
                      (100 - limites.center.dx) * fator,
                      (80 - limites.center.dy) * fator + lado * 0.03,
                    ),
                    child: Transform.scale(
                      scale: fator,
                      child: _bicho(sp, Mood.radiant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));
    await _grava(tester, 'icone', 'icone-512');
  });

  testWidgets('os companheiros em cada humor, transparentes', skip: !_ligado, (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const humores = {
      Mood.radiant: 'radiante',
      Mood.content: 'contente',
      Mood.sleepy: 'sono',
      Mood.missingYou: 'saudade',
    };
    for (final sp in Species.values) {
      for (final h in humores.entries) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RepaintBoundary(
                key: const Key('bicho'),
                child: _bicho(sp, h.key),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 120));
        await _grava(
          tester,
          'bicho',
          'pet-${sp.name}-${h.value}',
          pixelRatio: 6,
        );
      }
    }
  });

  testWidgets('o habitat nos quatro momentos do dia, em alta', skip: !_ligado, (
    tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const horas = {6: 'amanhecer', 12: 'dia', 18: 'entardecer', 22: 'noite'};
    for (final e in horas.entries) {
      const itens = ['lily', 'dock', 'rock', 'lantern'];
      final app = AppState()
        ..startCompanionship()
        ..owned = List<String>.from(itens)
        ..equipados = Set<String>.from(itens);
      addTearDown(app.dispose);
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
      final b = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(HabitatScene.cenaKey),
      );
      await tester.runAsync(() async {
        final img = await b.toImage(pixelRatio: 4);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        img.dispose();
        File(
          '$_pasta/habitat-${e.value}.png',
        ).writeAsBytesSync(data!.buffer.asUint8List());
      });
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }
  });
}
