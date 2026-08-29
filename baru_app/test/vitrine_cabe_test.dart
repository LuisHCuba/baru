@Tags(['evidencia'])
library;

import 'dart:ui' as ui;

import 'package:baru_app/models.dart';
import 'package:baru_app/theme.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// O bicho cabe na miniatura da loja.
///
/// A vitrine desenha o companheiro vestido numa caixa de 148×96 com
/// `scale: 0.46`. As nove espécies têm proporções diferentes — a coruja é
/// alta, o buldogue é alto **e** largo por causa das orelhas de morcego — e
/// a caixa foi dimensionada quando o elenco era menor.
///
/// Um bicho que extrapola não estoura layout nenhum (`PetView` desenha em
/// `CustomPaint`, que simplesmente recorta), e é justamente por isso que
/// passa despercebido: a miniatura sai com a orelha cortada e a suíte fica
/// verde. Este teste mede o desenho de verdade.

/// Quanto do bicho está fora da caixa, em pixels, de cada lado.
Future<EdgeInsets> _quantoVazou(WidgetTester tester, Species sp) async {
  const w = 148.0;
  const h = 96.0;
  // Uma margem generosa em volta para o vazamento ter onde aparecer.
  const folga = 60.0;

  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: const Key('vitrine'),
          child: ColoredBox(
            color: Cores.superficie,
            child: SizedBox(
              width: w + folga * 2,
              height: h + folga * 2,
              child: Center(
                // Sem `ClipRect`: é o vazamento que se quer medir.
                child: OverflowBox(
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: PetView(
                    species: sp,
                    mood: Mood.content,
                    activity: Activity.idle,
                    coat: 0,
                    scale: 0.46,
                    width: w,
                    height: h,
                    interativo: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));

  final b = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('vitrine')),
  );
  late EdgeInsets vazou;
  await tester.runAsync(() async {
    final img = await b.toImage(pixelRatio: 1);
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();
    final px = data!.buffer.asUint8List();
    final larg = img.width;

    // O fundo é medido, não suposto: o canto tem só a cor da superfície.
    final fr = px[0], fg = px[1], fb = px[2];
    var minX = larg, minY = img.height, maxX = -1, maxY = -1;
    for (var y = 0; y < img.height; y++) {
      for (var x = 0; x < larg; x++) {
        final i = (y * larg + x) * 4;
        final d = (px[i] - fr).abs() +
            (px[i + 1] - fg).abs() +
            (px[i + 2] - fb).abs();
        if (d > 18) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
    if (maxX < 0) {
      vazou = EdgeInsets.zero;
      return;
    }
    vazou = EdgeInsets.fromLTRB(
      (folga - minX).clamp(0, folga).toDouble(),
      (folga - minY).clamp(0, folga).toDouble(),
      (maxX - (folga + w)).clamp(0, folga).toDouble(),
      (maxY - (folga + h)).clamp(0, folga).toDouble(),
    );
  });
  return vazou;
}

void main() {
  testWidgets('nenhuma espécie vaza da miniatura da loja', (tester) async {
    tester.view.physicalSize = const Size(400, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final vazamentos = <Species, EdgeInsets>{};
    for (final sp in Species.values) {
      vazamentos[sp] = await _quantoVazou(tester, sp);
    }

    final culpados = vazamentos.entries
        .where((e) => e.value != EdgeInsets.zero)
        .map((e) => '${e.key.name}: ${e.value}')
        .toList();

    expect(
      culpados,
      isEmpty,
      reason: 'a miniatura corta em silêncio — o layout não estoura, só sai '
          'o bicho pela metade:\n${culpados.join('\n')}',
    );
  });
}
