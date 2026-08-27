import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:baru_app/data/progressao.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/theme.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// As oito espécies.
///
/// Quatro saem do quiz do onboarding; quatro se desbloqueiam na trilha —
/// quiz é quem você é, trilha é o que você conquistou.

Future<Uint8List> _quadro(WidgetTester tester) async {
  final b = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(PetView.cenaKey),
  );
  final bytes = await tester.runAsync(() async {
    final img = await b.toImage();
    final d = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    return d!.buffer.asUint8List();
  });
  return bytes!;
}

Future<Uint8List> _desenha(WidgetTester tester, Species sp) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: PetView(
            species: sp,
            mood: Mood.content,
            activity: Activity.idle,
            coat: 0,
            interativo: false,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return _quadro(tester);
}

void main() {
  testWidgets('as oito espécies desenham, e nenhuma igual à outra', (
    tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );

    final vistas = <Species, Uint8List>{};
    for (final sp in Species.values) {
      vistas[sp] = await _desenha(tester, sp);
    }

    // Duas espécies com o mesmo desenho seriam um `case` esquecido no switch
    // caindo no padrão — exatamente o erro que passa despercebido.
    final lista = Species.values;
    for (var i = 0; i < lista.length; i++) {
      for (var j = i + 1; j < lista.length; j++) {
        final a = vistas[lista[i]]!;
        final b = vistas[lista[j]]!;
        var igual = a.length == b.length;
        if (igual) {
          for (var k = 0; k < a.length; k++) {
            if (a[k] != b[k]) {
              igual = false;
              break;
            }
          }
        }
        expect(
          igual,
          isFalse,
          reason: '${lista[i].name} desenha igual a ${lista[j].name}',
        );
      }
    }
  });

  group('o catálogo das espécies', () {
    test('toda espécie tem paleta própria, nome e nome de bicho', () {
      for (final sp in Species.values) {
        expect(AppColors.coatDe(sp), isNotEmpty, reason: sp.name);
        expect(petNames[sp], isNotNull, reason: sp.name);
        expect(petNames[sp], isNotEmpty, reason: sp.name);
      }
    });

    test('o nome da espécie existe nos quatro idiomas', () {
      for (final lang in ['pt', 'en', 'es', 'zh']) {
        final s = AppState()..lang = lang;
        for (final sp in Species.values) {
          final nome = s.t.animalName(sp.name);
          expect(nome, isNotEmpty, reason: '${sp.name}/$lang');
          expect(
            nome,
            isNot(sp.name),
            reason: '${sp.name}/$lang caiu no id, sem tradução',
          );
        }
        s.dispose();
      }
    });

    test('nenhuma paleta repete a de outra espécie', () {
      final vistas = <String, Species>{};
      for (final sp in Species.values) {
        final chave =
            AppColors.coatDe(sp).map((c) => c.toARGB32()).join(',');
        expect(
          vistas[chave],
          isNull,
          reason: '${sp.name} usa a mesma paleta de ${vistas[chave]?.name}',
        );
        vistas[chave] = sp;
      }
    });
  });

  group('o desbloqueio', () {
    test('as quatro do quiz vêm liberadas; as outras não', () {
      final s = AppState()..startCompanionship();
      final liberadas = s.especiesLiberadas;
      expect(liberadas, contains(s.species));
      for (final nova in [
        Species.axolotl,
        Species.penguin,
        Species.cat,
        Species.fox,
      ]) {
        expect(
          liberadas.contains(nova),
          isFalse,
          reason: '${nova.name} não pode nascer liberada',
        );
      }
      s.dispose();
    });

    test('cada espécie nova tem exatamente um marco que a libera', () {
      for (final sp in Species.values) {
        final marcos =
            trilha.where((m) => m.recompensa.especie == sp).toList();
        if (sp == Species.capybara) continue; // a do quiz padrão
        expect(
          marcos.length,
          lessThanOrEqualTo(1),
          reason: '${sp.name} liberada por mais de um marco',
        );
      }
      // As quatro novas têm de estar na trilha.
      for (final nova in [
        Species.axolotl,
        Species.penguin,
        Species.cat,
        Species.fox,
      ]) {
        expect(
          trilha.any((m) => m.recompensa.especie == nova),
          isTrue,
          reason: '${nova.name} não é conquistável em lugar nenhum',
        );
      }
    });

    test('alcançar o marco libera a espécie', () {
      final s = AppState()..startCompanionship();
      final marco =
          trilha.firstWhere((m) => m.recompensa.especie == Species.fox);
      s.sessoesConcluidas = marco.alvo;
      expect(s.especiesLiberadas, contains(Species.fox));
      s.dispose();
    });
  });
}
