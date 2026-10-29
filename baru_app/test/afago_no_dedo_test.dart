import 'package:baru_app/models.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// O rastro do afago fica embaixo do dedo.
///
/// O gesto chega nas coordenadas da caixa sem escala e o bicho é desenhado
/// dentro de um `Transform.scale`. O rastro usava a posição crua: com escala
/// diferente de 1 ele aparecia longe do dedo, e em cada tela (escala e
/// âncora diferentes) num lugar diferente.

Widget _cena(double escala, Alignment ancora) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: PetView(
        species: Species.capybara,
        mood: Mood.content,
        activity: Activity.idle,
        coat: 0,
        scale: escala,
        alignment: ancora,
      ),
    ),
  ),
);

void main() {
  setUp(() => PetView.observadorDoDedo = ValueNotifier(null));
  tearDown(() => PetView.observadorDoDedo = null);

  for (final (escala, ancora) in [
    (1.0, Alignment.center),
    (1.6, Alignment.bottomCenter),
    (0.8, Alignment.topLeft),
  ]) {
    testWidgets('escala $escala, âncora $ancora: o rastro segue o dedo', (
      tester,
    ) async {
      await tester.pumpWidget(_cena(escala, ancora));
      await tester.pump(const Duration(milliseconds: 100));
      final caixa = tester.getTopLeft(find.byType(PetView));
      final centro = tester.getCenter(find.byType(PetView));

      final mao = await tester.startGesture(centro - const Offset(30, 0));
      await mao.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 16));
      for (var i = 0; i < 6; i++) {
        await mao.moveBy(const Offset(8, 3));
        await tester.pump(const Duration(milliseconds: 16));
        final dedoNaCaixa =
            centro + Offset(8.0 * (i + 1), 3.0 * (i + 1)) - caixa;
        final rastro = PetView.observadorDoDedo!.value;
        expect(rastro, isNotNull);
        expect(
          (rastro! - dedoNaCaixa).distance,
          lessThan(1.0),
          reason: 'o rastro tem de estar embaixo do dedo',
        );
      }
      await mao.up();
      await tester.pump(const Duration(seconds: 2));
      expect(PetView.observadorDoDedo!.value, isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
