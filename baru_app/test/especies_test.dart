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

/// As espécies.
///
/// Quatro saem do quiz do onboarding; as demais se desbloqueiam na trilha —
/// quiz é quem você é, trilha é o que você conquistou.
///
/// **O buraco que este arquivo tinha, e que o buldogue expôs.** A comparação
/// entre espécies era feita sobre o RGBA inteiro, então bastava a paleta ser
/// diferente para dois bichos passarem — mesmo desenhando a **mesma
/// silhueta**. Foi exatamente o que aconteceu: durante o trabalho da nona
/// espécie, `Species.frenchie` chegou a cair no `case` da gata, e a suíte
/// inteira passou. O teste que existia para pegar "um `case` esquecido no
/// switch" era cego justamente para ele.
///
/// A correção é comparar também o **canal alfa sozinho**, que é a silhueta
/// sem cor nenhuma. Dois bichos com o mesmo alfa são o mesmo desenho pintado
/// de outra cor, e isso nunca é intencional.

/// As espécies que o quiz do onboarding pode sortear, lidas da própria tabela
/// de pesos — e não de uma lista escrita à mão, que envelhece calada.
final _doQuiz = <Species>{
  for (final pergunta in quizWeights)
    for (final opcao in pergunta) ...opcao.keys,
};

/// Só o canal alfa: a silhueta, sem a cor.
Uint8List _silhueta(Uint8List rgba) {
  final out = Uint8List(rgba.length ~/ 4);
  for (var i = 0; i < out.length; i++) {
    out[i] = rgba[i * 4 + 3];
  }
  return out;
}

bool _iguais(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

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
  testWidgets('toda espécie desenha, e nenhuma igual à outra', (
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
    // caindo no de outro bicho — exatamente o erro que passa despercebido.
    //
    // Duas comparações, e a segunda é a que importa: a silhueta. Cor
    // diferente com forma idêntica é o mesmo painter chamado duas vezes, e a
    // comparação de RGBA aprova isso sem piscar.
    final lista = Species.values;
    for (var i = 0; i < lista.length; i++) {
      for (var j = i + 1; j < lista.length; j++) {
        final a = vistas[lista[i]]!;
        final b = vistas[lista[j]]!;
        expect(
          _iguais(a, b),
          isFalse,
          reason: '${lista[i].name} desenha igual a ${lista[j].name}',
        );
        expect(
          _iguais(_silhueta(a), _silhueta(b)),
          isFalse,
          reason: '${lista[i].name} tem a mesma silhueta de ${lista[j].name} '
              '— é o mesmo desenho pintado de outra cor',
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
    test('as do quiz vêm liberadas; as outras não', () {
      final s = AppState()..startCompanionship();
      final liberadas = s.especiesLiberadas;
      expect(liberadas, contains(s.species));
      for (final nova in Species.values.where((sp) => !_doQuiz.contains(sp))) {
        expect(
          liberadas.contains(nova),
          isFalse,
          reason: '${nova.name} não pode nascer liberada',
        );
      }
      s.dispose();
    });

    test('toda espécie fora do quiz tem exatamente um marco que a libera', () {
      // Derivado do `enum` e da tabela do quiz, e não de uma lista escrita à
      // mão: a lista de "as quatro novas" que morava aqui aprovaria uma
      // quinta espécie que ninguém pudesse conquistar. Foi o que quase
      // aconteceu com o buldogue.
      for (final sp in Species.values) {
        final marcos = trilha.where((m) => m.recompensa.especie == sp).length;
        if (_doQuiz.contains(sp)) {
          expect(
            marcos,
            lessThanOrEqualTo(1),
            reason: '${sp.name} liberada por mais de um marco',
          );
          continue;
        }
        expect(
          marcos,
          1,
          reason: '${sp.name} está no enum mas não é conquistável em '
              'lugar nenhum — ou é entregue por mais de um marco',
        );
      }
    });

    test('alcançar o marco libera a espécie', () {
      // Bater o critério do marco não basta desde que a trilha virou
      // corrente: a raposa mora no último degrau, e o último degrau só abre
      // com todos os de trás fechados. Por isso a conta aqui satisfaz a
      // trilha inteira, não só as cem sessões.
      final s = AppState()
        ..startCompanionship()
        ..sessoesConcluidas = 100
        ..melhorSequencia = 30
        ..diasAbaixoDaMeta = 30
        ..xp = Balanco.xpAcumuladoPara(15);
      expect(s.progresso.passosConquistados, trilha.length);
      expect(s.especiesLiberadas, contains(Species.fox));
      s.dispose();
    });

    test('o critério da espécie sozinho não a libera fora da vez', () {
      // O outro lado: só as cem sessões, sem nada mais. A raposa é o prêmio
      // do passo 22 — chegar nele por fora seria pular vinte e um degraus.
      final s = AppState()
        ..startCompanionship()
        ..sessoesConcluidas = 100;
      expect(s.especiesLiberadas.contains(Species.fox), isFalse);
      s.dispose();
    });
  });
}
