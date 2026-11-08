// Prova da âncora da boca: desenha cada bicho (rosto virado, boca aberta) e
// grava onde o painter disse que a boca está. Só com CAPTURAS=1.
//   CAPTURAS=1 flutter test test/ancora_boca_test.dart → build/ancora/<espécie>.png + ancoras.json
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:baru_app/data/crescimento.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:baru_app/widgets/vida/motor_de_vida.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('âncora da boca por espécie', skip: Platform.environment['CAPTURAS'] != '1', (tester) async {
    final saida = <String, dynamic>{};
    for (final sp in Species.values) {
      final chave = GlobalKey();
      final ancoras = <Map<String, dynamic>>[];
      PetView.aoDesenharBoca = (m, o, w) => ancoras.add({'m': m.toList(), 'o': [o.dx, o.dy], 'w': w});
      await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: Center(child: RepaintBoundary(key: chave, child: SizedBox(width: 260, height: 220,
          child: PetView(species: sp, mood: Mood.content, activity: Activity.idle, coat: 0, estagio: EstagioDoBicho.adulto, interativo: false, width: 260, height: 220,
              quadro: const QuadroFixo(respiro: 0.6, vida: SaidaDaVida(boca: 0.8, virada: Offset(0.7, 0.1), olhar: Offset(0.8, 0.1), inclina: 0.12, cabecaGiro: 0.15))))))));
      final b = chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final img = await b.toImage(pixelRatio: 2);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        img.dispose();
        File('build/ancora/${sp.name}.png')..createSync(recursive: true)..writeAsBytesSync(png!.buffer.asUint8List());
      });
      saida[sp.name] = ancoras;
      PetView.aoDesenharBoca = null;
    }
    File('build/ancora/ancoras.json').writeAsStringSync(jsonEncode(saida));
  });
}
