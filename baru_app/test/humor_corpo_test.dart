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

  testWidgets('trocar de humor: o corpo anda, só o rosto esmaece',
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
    // Um só esmaecido, o de cima. O de baixo opaco: os dois a meio
    // caminho deixavam o fundo vazar pelo bicho (auditoria, 11a-M1).
    expect(opacidades(), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    expect(opacidades(), findsNothing, reason: 'acabou: só o humor novo');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('no meio da troca não há dois bichos nem bicho translúcido',
      (tester) async {
    // Conta os pixels do desenho: opacos e não vazios. Dois corpos em
    // posturas diferentes aumentam a área ocupada; dois a 50% derrubam os
    // opacos.
    Future<(int, int)> conta() async {
      final borda = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(PetView.cenaKey),
      );
      late (int, int) r;
      await tester.runAsync(() async {
        final img = await borda.toImage();
        final bytes = (await img.toByteData())!;
        img.dispose();
        var ocupados = 0, opacos = 0;
        for (var i = 3; i < bytes.lengthInBytes; i += 4) {
          final a = bytes.getUint8(i);
          if (a > 8) ocupados++;
          if (a >= 250) opacos++;
        }
        r = (ocupados, opacos);
      });
      return r;
    }

    Widget bicho(Mood m) => Center(
          child: PetView(
            species: Species.fox,
            mood: m,
            activity: Activity.idle,
            coat: 0,
            interativo: false,
          ),
        );
    await tester.pumpWidget(bicho(Mood.radiant));
    await tester.pump(const Duration(seconds: 1));
    final (areaDe, opacosDe) = await conta();
    await tester.pumpWidget(bicho(Mood.missingYou));
    await tester.pump(const Duration(seconds: 1));
    final (areaPara, opacosPara) = await conta();

    await tester.pumpWidget(bicho(Mood.radiant));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 175));
    final (areaMeio, opacosMeio) = await conta();

    final maiorArea = areaDe > areaPara ? areaDe : areaPara;
    final menosOpacos = opacosDe < opacosPara ? opacosDe : opacosPara;
    expect(areaMeio, lessThan(maiorArea * 1.06),
        reason: 'dois corpos em posturas diferentes ocupariam mais área');
    expect(opacosMeio, greaterThan(menosOpacos * 0.94),
        reason: 'o bicho não fica translúcido no meio da troca');
    await tester.pumpWidget(const SizedBox());
  });
}
