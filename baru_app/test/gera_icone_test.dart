@Tags(['icone'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:baru_app/models.dart';
import 'package:baru_app/theme.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gera o ícone do app a partir do mesmo painter que desenha o bicho.
///
/// O APK saía com o ícone padrão do Flutter — na barra de notificações e na
/// gaveta do aparelho. Um app de companhia cujo ícone é o logo do
/// framework não tem cara nenhuma.
///
/// Desenhar o ícone à mão num editor criaria um segundo desenho do Baru,
/// que envelheceria em silêncio toda vez que a capivara mudasse. Aqui a
/// fonte é uma só: se o painter muda, o ícone muda junto, e basta rodar
/// `flutter test --tags icone`.
///
/// Sai um PNG por espécie, porque a troca de ícone por espécie é feita com
/// `activity-alias` e cada alias precisa do seu.

/// densidade → lado em pixels, como o Android espera.
const _tamanhos = <String, int>{
  'mdpi': 48,
  'hdpi': 72,
  'xhdpi': 96,
  'xxhdpi': 144,
  'xxxhdpi': 192,
};

const _res = 'android/app/src/main/res';

/// A espécie do ícone padrão: a capivara é o mascote.
const _padrao = Species.capybara;

Future<void> _escreve(WidgetTester tester, Species sp) async {
  for (final e in _tamanhos.entries) {
    final lado = e.value;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        // `Center` antes da borda: a raiz impõe restrição apertada do
        // tamanho da tela, e um `SizedBox` ali dentro é simplesmente
        // ignorado — a primeira tentativa capturou 800x600 com o bicho
        // perdido no meio.
        child: Center(
          child: RepaintBoundary(
            key: const Key('icone'),
            child: SizedBox(
              width: lado.toDouble(),
              height: lado.toDouble(),
              child: DecoratedBox(
                // Fundo cheio: ícone com transparência vira um borrão
                // branco no launcher claro.
                decoration: const BoxDecoration(color: Cores.primariaClara),
                child: Padding(
                  padding: EdgeInsets.all(lado * 0.08),
                  // `FittedBox` em vez de calcular escala na mão: cada
                  // espécie ocupa uma fatia diferente da própria tela, e
                  // um fator fixo deixaria a coruja gigante e a tartaruga
                  // perdida.
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: 200,
                      height: 170,
                      child: PetView(
                        species: sp,
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
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('icone')),
    );
    await tester.runAsync(() async {
      final img = await boundary.toImage(pixelRatio: 1);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      final dir = Directory('$_res/mipmap-${e.key}')
        ..createSync(recursive: true);
      final nome = sp == _padrao ? 'ic_launcher' : 'ic_launcher_${sp.name}';
      File('${dir.path}/$nome.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
    });
  }
}

void main() {
  testWidgets('o ícone do app é o Baru, uma espécie por arquivo', (
    tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );

    for (final sp in Species.values) {
      await _escreve(tester, sp);
    }

    // O padrão tem de existir em toda densidade: falta de uma delas faz o
    // Android escalar de outra e o ícone sai serrilhado.
    for (final d in _tamanhos.keys) {
      expect(
        File('$_res/mipmap-$d/ic_launcher.png').existsSync(),
        isTrue,
        reason: d,
      );
    }
    expect(
      File('$_res/mipmap-xxxhdpi/ic_launcher_owl.png').existsSync(),
      isTrue,
    );
  });
}
