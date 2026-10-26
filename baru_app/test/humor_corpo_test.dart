// O humor no corpo, não só no rosto (item 11a; laudo 06 rec. 6, laudo 07 R8).
//
// Antes, contente e saudade mudavam 2–3% dos pixels: a mesma silhueta com
// outra boca. O aceite do laudo é ≥10% entre quaisquer dois humores.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:baru_app/models.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> _pixels(WidgetTester tester, Species sp, Mood m) async {
  final chave = GlobalKey();
  await tester.pumpWidget(MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: Center(
      child: RepaintBoundary(
        key: chave,
        child: PetView(
          species: sp,
          mood: m,
          activity: Activity.idle,
          coat: 0,
          interativo: false,
          width: 170,
          height: 150,
        ),
      ),
    ),
  ));
  final b = chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  late Uint8List px;
  await tester.runAsync(() async {
    final img = await b.toImage();
    px = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
    img.dispose();
  });
  return px;
}

/// Fração de pixels do bicho que mudam entre dois desenhos.
double _diferenca(Uint8List a, Uint8List b) {
  var muda = 0, bicho = 0;
  for (var i = 0; i < a.length; i += 4) {
    if (a[i + 3] < 16 && b[i + 3] < 16) continue;
    bicho++;
    final d = (a[i] - b[i]).abs() +
        (a[i + 1] - b[i + 1]).abs() +
        (a[i + 2] - b[i + 2]).abs() +
        (a[i + 3] - b[i + 3]).abs();
    if (d > 40) muda++;
  }
  return muda / bicho;
}

void main() {
  testWidgets('saudade, sono e radiante mudam a silhueta, não só a boca',
      (tester) async {
    for (final sp in Species.values) {
      final contente = await _pixels(tester, sp, Mood.content);
      for (final m in [Mood.missingYou, Mood.sleepy, Mood.radiant]) {
        final outro = await _pixels(tester, sp, m);
        expect(_diferenca(contente, outro), greaterThan(0.10),
            reason: '${sp.name}: contente × ${m.name}');
      }
    }
  });

  testWidgets('trocar de humor esmaece de um desenho para o outro',
      (tester) async {
    Widget bicho(Mood m) => Center(
          child: PetView(
            species: Species.capybara,
            mood: m,
            activity: Activity.idle,
            coat: 0,
            interativo: false,
          ),
        );
    Finder opacidades() => find.descendant(
          of: find.byType(PetView),
          matching: find.byType(Opacity),
        );
    await tester.pumpWidget(bicho(Mood.content));
    expect(opacidades(), findsNothing);

    await tester.pumpWidget(bicho(Mood.missingYou));
    await tester.pump(const Duration(milliseconds: 150));
    expect(opacidades(), findsNWidgets(2), reason: 'os dois humores na tela');

    await tester.pump(const Duration(milliseconds: 400));
    expect(opacidades(), findsNothing, reason: 'acabou: só o humor novo');
    await tester.pumpWidget(const SizedBox());
  });
}
