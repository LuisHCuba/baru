import 'dart:ui' as ui;

import 'package:baru_app/widgets/raiz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// A raiz, desenhada.
///
/// "12 dias" é um placar, e placar se perde sem doer. Uma raiz que a pessoa
/// viu engrossar ao longo de doze dias é uma coisa que ela construiu.
///
/// O que se prova aqui é que o desenho **é função dos dias**: cresce,
/// ramifica em marcos, e é sempre o mesmo para o mesmo número — a raiz de
/// alguém não pode mudar de forma entre duas aberturas do app.

Future<ui.Image> _desenha(WidgetTester tester, int dias) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 160,
          height: 220,
          child: RaizViva(dias: dias),
        ),
      ),
    ),
  );
  await tester.pump();
  final b = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(RaizViva.chave),
  );
  late ui.Image img;
  await tester.runAsync(() async {
    img = await b.toImage(pixelRatio: 1);
  });
  return img;
}

/// Quantos pixels diferem do fundo.
///
/// Contar "o que é escuro" não serve: a semente do dia zero é desenhada com
/// alfa sobre a terra clara, e o limiar a deixava de fora. O que interessa
/// é **quanto foi pintado por cima da terra**, então o fundo é medido, não
/// suposto.
Future<int> _pixelsDesenhados(WidgetTester tester, ui.Image img) async {
  late int n;
  await tester.runAsync(() async {
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    final b = data!.buffer.asUint8List();
    final l = img.width * 4;

    // Um ponto de terra sem raiz nenhuma: canto de baixo, à esquerda.
    final base = (img.height - 4) * l + 4 * 4;
    final fr = b[base], fg = b[base + 1], fb = b[base + 2];

    var conta = 0;
    for (var i = 0; i < b.length; i += 4) {
      if (b[i + 3] == 0) continue;
      final d = (b[i] - fr).abs() + (b[i + 1] - fg).abs() + (b[i + 2] - fb).abs();
      if (d > 24) conta++;
    }
    n = conta;
  });
  return n;
}

void main() {
  group('a forma vem dos dias', () {
    test('os galhos nascem em marcos, não todo dia', () {
      expect(RaizViva.galhosEm(0), 0);
      expect(RaizViva.galhosEm(2), 0);
      expect(RaizViva.galhosEm(3), 1);
      expect(RaizViva.galhosEm(6), 1, reason: 'galho por dia viraria mato');
      expect(RaizViva.galhosEm(7), 2);
      expect(RaizViva.galhosEm(30), 4);
      expect(RaizViva.galhosEm(10000), RaizViva.marcos.length);
    });

    test('o próximo marco é o primeiro ainda não alcançado', () {
      expect(RaizViva.proximoMarco(0), 3);
      expect(RaizViva.proximoMarco(3), 7);
      expect(RaizViva.proximoMarco(6), 7);
      expect(
        RaizViva.proximoMarco(10000),
        isNull,
        reason: 'quem passou de todos não tem o que perseguir',
      );
    });

    test('os marcos sobem, sem repetir', () {
      for (var i = 1; i < RaizViva.marcos.length; i++) {
        expect(RaizViva.marcos[i], greaterThan(RaizViva.marcos[i - 1]));
      }
    });
  });

  group('o desenho', () {
    testWidgets('dia zero desenha a semente, não o vazio', (tester) async {
      // Desenhar "nada" faria a tela parecer quebrada em vez de
      // recém-começada.
      final img = await _desenha(tester, 0);
      expect(await _pixelsDesenhados(tester, img), greaterThan(0));
    });

    testWidgets('mais dias, mais raiz', (tester) async {
      final poucos = await _pixelsDesenhados(
        tester,
        await _desenha(tester, 2),
      );
      final muitos = await _pixelsDesenhados(
        tester,
        await _desenha(tester, 60),
      );

      expect(
        muitos,
        greaterThan(poucos),
        reason: 'a raiz tem de crescer visivelmente, não só no número',
      );
    });

    testWidgets('o mesmo número de dias desenha sempre a mesma raiz', (
      tester,
    ) async {
      // Sem isto a raiz de alguém mudaria de forma entre duas aberturas do
      // app — e deixaria de ser dela.
      final a = await _pixelsDesenhados(tester, await _desenha(tester, 21));
      final b = await _pixelsDesenhados(tester, await _desenha(tester, 21));

      expect(a, b);
    });

    testWidgets('cruzar um marco muda o desenho', (tester) async {
      final antes = await _pixelsDesenhados(
        tester,
        await _desenha(tester, 6),
      );
      final depois = await _pixelsDesenhados(
        tester,
        await _desenha(tester, 7),
      );

      expect(
        depois,
        isNot(antes),
        reason: 'um galho novo tem de ser um acontecimento visível',
      );
    });
  });
}
