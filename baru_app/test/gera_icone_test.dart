@Tags(['icone'])
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:baru_app/models.dart';
import 'package:baru_app/theme.dart';
import 'package:baru_app/widgets/icone_arte.dart';
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

/// A camada de fundo do ícone adaptativo.
///
/// Era uma cor chapada, e o ícone lia como placeholder — "simplório demais"
/// foi a palavra. Agora é desenhada: luz vinda de cima, folhagem atrás e
/// vinheta na borda, para o corte da máscara parecer intenção.
///
/// Full bleed de propósito: o launcher corta o que quiser, e é para isso que
/// a camada de fundo existe.
Future<void> _escreveFundo(WidgetTester tester, Species sp) async {
  for (final e in _adaptativo.entries) {
    final lado = e.value;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: const Key('fundo'),
            child: FundoDoIcone(
              lado: lado.toDouble(),
              semente: sp.index + 1,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('fundo')),
    );
    await tester.runAsync(() async {
      final img = await boundary.toImage(pixelRatio: 1);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      final dir = Directory('$_res/mipmap-${e.key}')
        ..createSync(recursive: true);
      File('${dir.path}/ic_fundo_${sp.name}.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
    });
  }
}

/// Onde o bicho realmente começa e acaba, dentro da tela dele.
///
/// **Por que medir em vez de chutar.** A `PetView` desenha numa caixa fixa e
/// cada espécie ocupa uma fatia diferente dela: a coruja é alta e estreita,
/// a capivara é larga e baixa, a tartaruga é quase toda horizontal. Um
/// `scale` fixo deixava a capivara aceitável e a coruja perdida no meio do
/// ladrilho — foi exatamente a queixa.
///
/// Aqui o bicho é desenhado uma vez sobre transparente, os limites do que
/// tem tinta são lidos do pixel, e a segunda passada usa esses limites para
/// preencher a zona segura. Vale para as oito espécies sem número mágico
/// nenhum.
Future<Rect> _limitesDoBicho(WidgetTester tester, Species sp) async {
  const lado = 400.0;
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: const Key('medida'),
          child: SizedBox(
            width: lado,
            height: lado,
            child: Center(
              child: SizedBox(
                width: 200,
                height: 160,
                child: PetView(
                  species: sp,
                  mood: Mood.radiant,
                  activity: Activity.idle,
                  coat: 0,
                  interativo: false,
                  width: 200,
                  height: 160,
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

  final b = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('medida')),
  );
  late Rect r;
  await tester.runAsync(() async {
    final img = await b.toImage(pixelRatio: 1);
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();
    final px = data!.buffer.asUint8List();
    final w = lado.toInt();
    var minX = w, minY = w, maxX = -1, maxY = -1;
    for (var y = 0; y < w; y++) {
      for (var x = 0; x < w; x++) {
        // Alfa acima de 8 e não o zero cru: as bordas suavizadas deixam um
        // rastro quase invisível que inflaria a caixa.
        if (px[(y * w + x) * 4 + 3] > 8) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
    r = maxX < 0
        ? const Rect.fromLTWH(0, 0, 200, 160)
        : Rect.fromLTRB(
            minX.toDouble(),
            minY.toDouble(),
            (maxX + 1).toDouble(),
            (maxY + 1).toDouble(),
          );
  });
  return r;
}

/// A camada de frente do ícone adaptativo: só o bicho, fundo transparente.
Future<void> _escreveFrente(
  WidgetTester tester,
  Species sp,
  Rect limites,
) async {
  for (final e in _adaptativo.entries) {
    final lado = e.value.toDouble();
    // 0.96 da zona segura: encosta na borda do que a máscara garante, sem
    // tocar nela.
    final alvo = lado * _zonaSegura * 0.96;
    final fator = alvo / math.max(limites.width, limites.height);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: const Key('frente'),
            child: SizedBox(
              width: lado,
              height: lado,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // A sombra primeiro: sem ela o bicho flutua, e flutuar é o
                  // que faz um ícone parecer recortado e colado.
                  Align(
                    alignment: const Alignment(0, 0.86),
                    child: SombraDoIcone(largura: alvo * 0.78),
                  ),
                  // O deslocamento leva o **centro medido** do bicho ao
                  // centro do ladrilho. Centralizar a tela dele em vez do
                  // corpo deixava a coruja alta e a tartaruga baixa.
                  Transform.translate(
                    offset: Offset(
                      (200 / 2 - limites.center.dx + 100) * fator,
                      (160 / 2 - limites.center.dy + 120) * fator,
                    ),
                    child: Transform.scale(
                      scale: fator,
                      child: SizedBox(
                        width: 200,
                        height: 160,
                        child: PetView(
                          species: sp,
                          mood: Mood.radiant,
                          activity: Activity.idle,
                          coat: 0,
                          interativo: false,
                          width: 200,
                          height: 160,
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
    '    <background android:drawable="@mipmap/ic_fundo_${sp.name}" />',
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
      final limites = await _limitesDoBicho(tester, sp);
      await _escreve(tester, sp);
      await _escreveFundo(tester, sp);
      await _escreveFrente(tester, sp, limites);
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
