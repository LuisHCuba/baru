// As decisões de desenho do ADR-026, presas por teste (auditoria da Onda 3,
// 11b-M4). Cada uma é uma escolha da biologia que pode regredir em silêncio
// num ajuste de pincel: o teste conta as cores que só aquela marca tem.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:baru_app/data/crescimento.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Largura, em pixels, da última imagem desenhada.
var _largura = 0;

Future<ByteData> _desenha(
  WidgetTester tester,
  Species sp, {
  Mood mood = Mood.content,
  EstagioDoBicho estagio = EstagioDoBicho.adulto,
}) async {
  final chave = GlobalKey();
  await tester.pumpWidget(MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: Center(
      child: RepaintBoundary(
        key: chave,
        child: PetView(
          species: sp,
          mood: mood,
          activity: Activity.idle,
          coat: 0,
          estagio: estagio,
          interativo: false,
        ),
      ),
    ),
  ));
  await tester.pump();
  late ByteData bytes;
  await tester.runAsync(() async {
    final borda =
        chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await borda.toImage(pixelRatio: 2);
    _largura = img.width;
    bytes = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    img.dispose();
  });
  return bytes;
}

/// Quantos pixels opacos caem na faixa de matiz e saturação dada.
int _conta(
  ByteData b, {
  required double matizDe,
  required double matizAte,
  double saturacaoMin = 0.45,
  double brilhoMin = 0.45,
}) {
  var n = 0;
  for (var i = 0; i < b.lengthInBytes; i += 4) {
    if (b.getUint8(i + 3) < 200) continue;
    final hsv = HSVColor.fromColor(Color.fromARGB(
      255,
      b.getUint8(i),
      b.getUint8(i + 1),
      b.getUint8(i + 2),
    ));
    if (hsv.hue >= matizDe &&
        hsv.hue <= matizAte &&
        hsv.saturation >= saturacaoMin &&
        hsv.value >= brilhoMin) {
      n++;
    }
  }
  return n;
}

/// Amarelo-dourado: o olho da buraqueira, a crista que o pinguim não tem.
int _amarelos(ByteData b) => _conta(b, matizDe: 38, matizAte: 56);

/// Laranja vivo: bico de pinguim de livro infantil, que o magalhães não tem.
int _laranjas(ByteData b) =>
    _conta(b, matizDe: 15, matizAte: 37, saturacaoMin: 0.55, brilhoMin: 0.6);

void main() {
  testWidgets('a buraqueira tem o olho amarelo, acordada', (tester) async {
    for (final m in [Mood.radiant, Mood.content, Mood.missingYou]) {
      final d = await _desenha(tester, Species.owl, mood: m);
      expect(_amarelos(d), greaterThan(300), reason: m.name);
    }
  });

  testWidgets('o pinguim não tem laranja nem crista, em estágio nenhum',
      (tester) async {
    for (final e in [
      EstagioDoBicho.filhote,
      EstagioDoBicho.jovem,
      EstagioDoBicho.adulto,
      EstagioDoBicho.pleno,
    ]) {
      final d = await _desenha(tester, Species.penguin, estagio: e);
      expect(_laranjas(d), lessThan(20), reason: 'laranja no ${e.name}');
      expect(_amarelos(d), lessThan(20), reason: 'crista no ${e.name}');
    }
  });

  testWidgets('as faixas do peito do pinguim só no adulto', (tester) async {
    // A faixa preta do peito é a marca do adulto do magalhães: o jovem tem
    // o peito liso.
    // Pela coluna do meio, de cima a baixo: quantas vezes o claro da
    // barriga vira escuro. Sem faixa, a barriga é um claro só; com as duas
    // faixas do adulto, ela é cortada duas vezes. Contar transições e não
    // pixels deixa o porte (o jovem é menor) fora da conta.
    int cortesNaBarriga(ByteData b, int largura) {
      final altura = b.lengthInBytes ~/ (largura * 4);
      final x = largura ~/ 2;
      var cortes = 0;
      var claro = false;
      for (var y = altura ~/ 2; y < altura; y++) {
        final i = (y * largura + x) * 4;
        if (b.getUint8(i + 3) < 200) continue;
        final v = HSVColor.fromColor(Color.fromARGB(
          255,
          b.getUint8(i),
          b.getUint8(i + 1),
          b.getUint8(i + 2),
        )).value;
        if (v > 0.72) {
          claro = true;
        } else if (v < 0.45 && claro) {
          cortes++;
          claro = false;
        }
      }
      return cortes;
    }

    final jovem = await _desenha(tester, Species.penguin,
        estagio: EstagioDoBicho.jovem);
    final noJovem = cortesNaBarriga(jovem, _largura);
    final adulto = await _desenha(tester, Species.penguin);
    final noAdulto = cortesNaBarriga(adulto, _largura);
    expect(noAdulto, greaterThan(noJovem),
        reason: 'adulto $noAdulto × jovem $noJovem');
  });

  testWidgets('a raposa tem branco no peito e na ponta da cauda',
      (tester) async {
    final d = await _desenha(tester, Species.fox);
    final brancos = _conta(d,
        matizDe: 0, matizAte: 360, saturacaoMin: 0, brilhoMin: 0.93);
    expect(brancos, greaterThan(800));
  });
}
