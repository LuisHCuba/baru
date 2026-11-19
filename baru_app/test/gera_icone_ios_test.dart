@Tags(['icone'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:baru_app/models.dart';
import 'package:baru_app/widgets/icone_arte.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// O ícone do iPhone e da App Store, com a mesma arte do Android: o fundo
/// desenhado (FundoDoIcone) e a capivara radiante na zona segura.
///
/// Sai um 1024 × 1024 em build/icone_ios_1024.png; o script
/// tool/icone_ios.sh tira os outros tamanhos e remove o canal alfa (a App
/// Store recusa ícone com alfa).
void main() {
  testWidgets('gera o ícone do iPhone (1024)', (tester) async {
    const lado = 1024.0;
    tester.view.physicalSize = const Size(lado, lado);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: const Key('ios'),
            child: SizedBox(
              width: lado,
              height: lado,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FundoDoIcone(lado: lado, semente: Species.capybara.index + 1),
                  Padding(
                    padding: const EdgeInsets.all(lado * 0.14),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: 200,
                        height: 170,
                        child: PetView(
                          species: Species.capybara,
                          mood: Mood.radiant,
                          activity: Activity.idle,
                          coat: 0,
                          interativo: false,
                          width: 200,
                          height: 170,
                          scale: 1.15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('ios')));
    await tester.runAsync(() async {
      final img = await boundary.toImage(pixelRatio: 1);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      Directory('build').createSync(recursive: true);
      File('build/icone_ios_1024.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
  });
}
