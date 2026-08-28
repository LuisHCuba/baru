@Tags(['evidencia'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:baru_app/theme.dart';
import 'package:baru_app/widgets/cartao_da_raiz.dart';
import 'package:baru_app/widgets/toca.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Evidência visual da toca e do cartão da raiz.
///
/// Arquivo separado do `evidencia_test.dart` de propósito: há trabalho
/// simultâneo naquele, e duas frentes escrevendo no mesmo arquivo batem de
/// frente. O destino dos PNGs é o mesmo.

const _pasta = '../docs/evidence/2026-08-27';

Future<void> _salva(WidgetTester tester, Key chave, String nome) async {
  final b = tester.renderObject<RenderRepaintBoundary>(find.byKey(chave));
  await tester.runAsync(() async {
    final img = await b.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    final destino = Directory(_pasta)..createSync(recursive: true);
    File('${destino.path}/$nome.png')
        .writeAsBytesSync(data!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('a toca abrindo, camada por camada', (tester) async {
    tester.view.physicalSize = const Size(1000, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Quatro tocas lado a lado, cada uma com um número de gestos diferente.
    // A sequência é o que prova que a terra sai por camadas — uma captura
    // única mostraria só um estado e não diria nada sobre o gesto.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Cores.superficie,
          body: RepaintBoundary(
            key: const Key('captura-toca'),
            child: Row(
              children: [
                for (var i = 0; i < 4; i++)
                  Expanded(
                    child: Toca(
                      key: ValueKey('toca-$i'),
                      rotuloDoPremio: '+10 folhas',
                      aoAbrir: () {},
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Cava a i-ésima toca i vezes: 0, 1, 2, 3 (a última abre).
    for (var i = 1; i < 4; i++) {
      for (var n = 0; n < i; n++) {
        await tester.tap(find.byKey(ValueKey('toca-$i')));
        await tester.pump(const Duration(milliseconds: 300));
      }
    }
    await tester.pump(const Duration(milliseconds: 800));

    await _salva(tester, const Key('captura-toca'), 'toca-camadas');
    expect(find.text('+10 folhas'), findsWidgets);
  });

  testWidgets('o cartão da raiz, como sai para fora do app', (tester) async {
    tester.view.physicalSize = const Size(1200, 620);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Cores.canvas,
          body: Center(
            child: RepaintBoundary(
              key: const Key('captura-cartao'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CartaoDaRaiz(dias: 7, nomeDoPet: 'Coruja', lang: 'pt'),
                  SizedBox(width: 16),
                  CartaoDaRaiz(dias: 100, nomeDoPet: 'Coruja', lang: 'pt'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _salva(tester, const Key('captura-cartao'), 'cartao-da-raiz');
  });
}
