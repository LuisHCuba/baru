// Uma moeda, um glifo, uma cor (laudo 03, R-V2), e um botão só (R-V4).
//
// O teste lê o código: o que ele impede é alguém desenhar de novo, numa
// tela, a folha ou o botão que já existem — que é exatamente como o app
// chegou a ter quatro folhas e cinco botões.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<(String, String)> _codigo() sync* {
  for (final f in Directory('lib').listSync(recursive: true)) {
    if (f is File && f.path.endsWith('.dart')) {
      yield (f.path, f.readAsStringSync());
    }
  }
}

void main() {
  test('nenhuma folha do Material nem desenho paralelo da moeda', () {
    final achados = <String>[];
    for (final (caminho, texto) in _codigo()) {
      if (caminho.endsWith('glifos.dart')) continue;
      if (RegExp(r'Icons\.eco').hasMatch(texto)) achados.add('$caminho: Icons.eco');
      if (texto.contains('LeafMark')) achados.add('$caminho: LeafMark');
    }
    expect(achados, isEmpty);
  });

  test('a folha é verde, salvo sobre um botão ou apagada', () {
    // A expressão inteira depois de `cor:`, até o fim do argumento: num
    // `apagada ? Cores.tinta500 : Cores.folha600` as duas cores contam.
    final cor = RegExp(r'GlifoFolha\([^)]*cor:\s*([^,)]+)');
    const permitidas = {'Cores.folha600', 'Cores.tintaClara', 'Cores.tinta500'};
    var vistas = 0;
    for (final (caminho, texto) in _codigo()) {
      for (final m in cor.allMatches(texto)) {
        final cores = RegExp(r'Cores\.\w+').allMatches(m.group(1)!);
        expect(cores, isNotEmpty, reason: '$caminho: ${m.group(1)}');
        for (final c in cores) {
          vistas++;
          expect(permitidas, contains(c.group(0)), reason: caminho);
        }
      }
    }
    expect(vistas, greaterThan(0), reason: 'a regra tem de ver alguma cor');
  });

  test('os botões antigos saíram', () {
    final achados = <String>[];
    for (final (caminho, texto) in _codigo()) {
      // O botão novo cita os antigos na própria história.
      if (caminho.endsWith('botao_baru.dart')) continue;
      for (final nome in ['PrimaryButton', 'GhostButton', '_BotaoCompacto']) {
        if (texto.contains(nome)) achados.add('$caminho: $nome');
      }
    }
    expect(achados, isEmpty);
  });

  test('texto secundário não é mais tinta translúcida', () {
    // Tinta a 30–69% sobre o creme dava de 1,9:1 a 4,4:1. O tom opaco
    // `Cores.tinta700` passa; a regra pega a recaída em estilos de texto.
    final translucida = RegExp(
      r'(nunito|estilo|TextStyle)\([^;]{0,160}?color:\s*(AppColors\.inkA|Cores\.tintaA)\(0?\.[3-6]\d*\)',
      dotAll: true,
    );
    final achados = <String>[];
    for (final (caminho, texto) in _codigo()) {
      if (caminho.contains('pet.dart')) continue;
      for (final m in translucida.allMatches(texto)) {
        achados.add('$caminho:${texto.substring(0, m.start).split('\n').length}');
      }
    }
    expect(achados, isEmpty);
  });
}
