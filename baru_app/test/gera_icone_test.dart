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

/// densidade → lado do **ícone adaptativo**, que é sempre 108dp.
///
/// O launcher da Samsung (e todo Android 8+) aplica uma máscara ao ícone.
/// Um PNG quadrado comum é espremido dentro dela e sobra folga em volta —
/// era isso que fazia o ícone "não aparecer do jeito pedido". O adaptativo
/// resolve entregando duas camadas: fundo que pode ser cortado à vontade e
/// frente que respeita a **zona segura**, os 72dp centrais.
const _adaptativo = <String, int>{
  'mdpi': 108,
  'hdpi': 162,
  'xhdpi': 216,
  'xxhdpi': 324,
  'xxxhdpi': 432,
};

/// A fatia do lado que a máscara nunca corta: 72 de 108.
const _zonaSegura = 72 / 108;

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

/// A camada de frente do ícone adaptativo: só o bicho, fundo transparente.
Future<void> _escreveFrente(WidgetTester tester, Species sp) async {
  for (final e in _adaptativo.entries) {
    final lado = e.value;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: const Key('frente'),
            child: SizedBox(
              width: lado.toDouble(),
              height: lado.toDouble(),
              // Sem `DecoratedBox`: o fundo é a outra camada. Pintar aqui
              // devolveria o quadrado que a máscara corta.
              child: Center(
                child: SizedBox(
                  width: lado * _zonaSegura,
                  height: lado * _zonaSegura,
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
      find.byKey(const Key('frente')),
    );
    await tester.runAsync(() async {
      final img = await boundary.toImage(pixelRatio: 1);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      final dir = Directory('$_res/mipmap-${e.key}')
        ..createSync(recursive: true);
      File('${dir.path}/ic_frente_${sp.name}.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
    });
  }
}

/// O XML que amarra as duas camadas, um por espécie.
void _escreveXml(Species sp) {
  final dir = Directory('$_res/mipmap-anydpi-v26')
    ..createSync(recursive: true);
  final nome = sp == _padrao ? 'ic_launcher' : 'ic_launcher_${sp.name}';
  final xml = [
    '<?xml version="1.0" encoding="utf-8"?>',
    '<!-- Gerado por test/gera_icone_test.dart. Nao edite a mao. -->',
    '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">',
    '    <background android:drawable="@color/ic_fundo" />',
    '    <foreground android:drawable="@mipmap/ic_frente_${sp.name}" />',
    // `monochrome` faz o ícone acompanhar o tema do sistema no Android 13+,
    // onde o launcher pinta a silhueta com a cor do papel de parede.
    '    <monochrome android:drawable="@mipmap/ic_frente_${sp.name}" />',
    '</adaptive-icon>',
    '',
  ].join(String.fromCharCode(10));
  File('${dir.path}/$nome.xml').writeAsStringSync(xml);
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
      await _escreveFrente(tester, sp);
      _escreveXml(sp);
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
    // O adaptativo é o que a Samsung usa. Sem ele o launcher espreme o PNG
    // quadrado na máscara e sobra folga em volta.
    for (final d in _adaptativo.keys) {
      expect(
        File('$_res/mipmap-$d/ic_frente_capybara.png').existsSync(),
        isTrue,
        reason: d,
      );
    }
    expect(
      File('$_res/mipmap-anydpi-v26/ic_launcher.xml').existsSync(),
      isTrue,
    );
    expect(
      File('$_res/mipmap-anydpi-v26/ic_launcher_owl.xml').existsSync(),
      isTrue,
    );
  });
}
