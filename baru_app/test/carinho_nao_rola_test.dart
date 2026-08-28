import 'package:baru_app/models.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Arrastar no bicho faz carinho, não rola a tela.
///
/// O Baru mora dentro de uma lista rolável na home. Na arena de gestos o
/// `VerticalDragGestureRecognizer` do `Scrollable` ganha do `pan` por
/// padrão, então o dedo que ia acariciar descia a página — acariciar era
/// quase impossível.

Widget _homeDeMentira({required ScrollController controle}) {
  return MaterialApp(
    home: Scaffold(
      body: ListView(
        controller: controle,
        children: [
          const SizedBox(height: 40),
          const SizedBox(
            height: 300,
            child: PetView(
              species: Species.capybara,
              mood: Mood.content,
              activity: Activity.idle,
              coat: 0,
              width: 260,
              height: 300,
            ),
          ),
          // Altura suficiente para haver para onde rolar.
          const SizedBox(height: 1200),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('arrastar no bicho não rola a lista', (tester) async {
    final controle = ScrollController();
    addTearDown(controle.dispose);
    await tester.pumpWidget(_homeDeMentira(controle: controle));
    await tester.pump(const Duration(milliseconds: 300));

    expect(controle.offset, 0);

    // Um arrasto vertical franco, começando em cima do bicho.
    await tester.drag(find.byType(PetView), const Offset(0, -220));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      controle.offset,
      0,
      reason: 'o dedo era carinho; a tela não podia ter descido',
    );
  });

  testWidgets('fora do bicho a rolagem continua inteira', (tester) async {
    // A correção não pode ter travado a página: só o habitat fica com o
    // dedo, o resto rola como sempre.
    final controle = ScrollController();
    addTearDown(controle.dispose);
    await tester.pumpWidget(_homeDeMentira(controle: controle));
    await tester.pump(const Duration(milliseconds: 300));

    // Bem abaixo do habitat: o centro da lista cairia em cima do bicho, e
    // aí o teste provaria o contrário do que quer.
    await tester.dragFrom(const Offset(200, 520), const Offset(0, -220));
    await tester.pump(const Duration(milliseconds: 300));

    expect(controle.offset, greaterThan(0));
  });
}
