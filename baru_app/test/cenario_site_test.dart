// O cenário do site (baru.lhcx.tech), tirado do mundo da home do app.
//
// O mesmo `FundoDoMundo` (céu, chapadas do Cerrado, colinas, árvores de
// baru, o chão com a toca, a lagoa, tufos e flores) e o mesmo
// `FrenteDoMundo` (o capim do primeiro plano), com os objetos da cena
// sobre a lagoa, nos quatro momentos do dia. O fundo e a frente saem em
// arquivos separados para o site fazer o paralaxe entre eles.
//
// A geometria vai junto em `build/cenario_site/geometria.json`: onde fica o
// chão (os pés dos bichos) e a linha d'água, em frações da altura, e onde
// a lagoa começa, em frações da largura.
//
// Só roda com CAPTURAS=1:
//   CAPTURAS=1 flutter test test/cenario_site_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:baru_app/models.dart';
import 'package:baru_app/widgets/habitat.dart';
import 'package:baru_app/widgets/mundo/mundo.dart';
import 'package:baru_app/widgets/mundo/pinta_mundo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

final _ligado = Platform.environment['CAPTURAS'] == '1';
const _pasta = 'build/cenario_site';

/// A "tela" do site: 16:9 largo. No celular o site recorta pelos lados.
const _tela = Size(1600, 900);
const _densidade = 1.5;

const _itens = ['juncos', 'lily', 'dock', 'lantern', 'rock', 'bamboo', 'cardume'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> grava(WidgetTester tester, Widget w, String nome) async {
    final chave = GlobalKey();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: RepaintBoundary(key: chave, child: SizedBox.fromSize(size: _tela, child: w))),
    ));
    final b = chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final img = await b.toImage(pixelRatio: _densidade);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      File('$_pasta/$nome.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  testWidgets('o mundo do app nos quatro momentos', skip: !_ligado, (tester) async {
    tester.view.physicalSize = const Size(2000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final g = GeometriaDoMundo(_tela);
    // A câmera deixa a margem à esquerda e a lagoa à direita, com a beira
    // um pouco à direita do meio.
    final camera = g.x(ZonasDoMundo.beira) - _tela.width * 0.58;
    final cam = ValueNotifier<double>(camera);
    final tempo = ValueNotifier<double>(0);
    final cenario = CenarioDoHabitat.de('lagoa');

    final palcoK = g.x(1 - ZonasDoMundo.beira) / HabitatScene.design.width;
    final palco = Rect.fromLTWH(
      g.x(ZonasDoMundo.beira) - 12 - camera,
      g.linhaDagua + 118 * palcoK * 0.55 - HabitatScene.design.height * palcoK,
      HabitatScene.design.width * palcoK,
      HabitatScene.design.height * palcoK,
    );

    const horas = {6: 'amanhecer', 12: 'dia', 18: 'entardecer', 22: 'noite'};
    for (final e in horas.entries) {
      final luz = LuzDaCena.de(periodoDe(DateTime(2026, 10, 31, e.key)));
      final ids = [..._itens, if (e.key == 22) 'vagalumes'];
      final itens = itensDeCena.where((i) => ids.contains(i.id)).toList();
      await grava(
        tester,
        Stack(children: [
          Positioned.fill(child: CustomPaint(painter: FundoDoMundo(g: g, luz: luz, cenario: cenario, camera: cam, tempo: tempo))),
          for (final item in itens)
            Positioned.fromRect(rect: palco, child: CustomPaint(painter: pintorDeObjetoDaCena(item, sx: palcoK, sy: palcoK))),
        ]),
        'fundo-${e.value}',
      );
      await grava(
        tester,
        CustomPaint(painter: FrenteDoMundo(g: g, luz: luz, cenario: cenario, camera: cam, tempo: tempo)),
        'frente-${e.value}',
      );
    }

    File('$_pasta/geometria.json').writeAsStringSync(jsonEncode({
      'largura': _tela.width,
      'altura': _tela.height,
      'chao': g.chao / _tela.height,
      'linhaDagua': g.linhaDagua / _tela.height,
      'horizonte': g.horizonte / _tela.height,
      'beira': (g.x(ZonasDoMundo.beira) - camera) / _tela.width,
      'escala': g.escala,
    }));
    // Para quem lê: a escala do bicho no mundo (px por unidade).
    // (as peças soltas saem no teste seguinte)
    debugPrint('escala do mundo: ${g.escala}, camera: ${math.max(0, camera)}');
  });

  // Cada objeto da loja, sozinho e com fundo transparente, para o site
  // compor o cenário dele com as peças do app (no lugar onde cabem).
  testWidgets('as peças do cenário, uma a uma', skip: !_ligado, (tester) async {
    tester.view.physicalSize = const Size(2000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const palco = HabitatScene.design;
    for (final item in itensDeCena) {
      for (final hora in [12, 22]) {
        if (hora == 22 && !['lantern', 'vagalumes', 'varal_de_luzes', 'casa_de_passaro'].contains(item.id)) continue;
        final chave = GlobalKey();
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: chave,
              child: SizedBox.fromSize(
                size: palco,
                child: CustomPaint(painter: pintorDeObjetoDaCena(item, sx: 1, sy: 1, fase: hora == 22 ? 0.5 : 0)),
              ),
            ),
          ),
        ));
        final b = chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final img = await b.toImage(pixelRatio: 3);
          final png = await img.toByteData(format: ui.ImageByteFormat.png);
          img.dispose();
          File('$_pasta/pecas/${item.id}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png!.buffer.asUint8List());
        });
      }
    }
  });
}
