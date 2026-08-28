import 'package:baru_app/services/som_service.dart';
import 'package:baru_app/widgets/toca.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A toca de onde sai a recompensa.
///
/// Resgatar era um toque e um número que mudava. Recompensa que chega
/// sozinha não é sentida: é o gesto que transforma "ganhei" em "eu tirei
/// dali".
///
/// O que se prova aqui é o contrato da cena — **sem o gesto não abre**, o
/// som certo toca na hora certa, e abrir acontece uma vez só.

Future<int> _monta(
  WidgetTester tester, {
  required VoidCallback aoAbrir,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Toca(rotuloDoPremio: '+10 folhas', aoAbrir: aoAbrir),
        ),
      ),
    ),
  );
  await tester.pump();
  return 0;
}

void main() {
  late List<SomDoBaru> sons;

  setUp(() {
    sons = [];
    SomService.instance
      ..esqueceOsUltimos()
      ..ligado = true
      ..tocador = (s) async => sons.add(s);
  });

  tearDown(() => SomService.instance.tocador = null);

  testWidgets('um toque não abre: a terra sai por camadas', (tester) async {
    var abriu = 0;
    await _monta(tester, aoAbrir: () => abriu++);

    await tester.tap(find.byKey(Toca.chave));
    await tester.pump(const Duration(milliseconds: 300));

    expect(abriu, 0, reason: 'um toque é acidente, não intenção');
    expect(sons, [SomDoBaru.cavar]);
  });

  testWidgets('os gestos combinados abrem, e o prêmio sobe', (tester) async {
    var abriu = 0;
    await _monta(tester, aoAbrir: () => abriu++);

    for (var i = 0; i < Toca.precisaDe; i++) {
      await tester.tap(find.byKey(Toca.chave));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pump(const Duration(milliseconds: 900));

    expect(abriu, 1);
    expect(find.text('+10 folhas'), findsOneWidget);
  });

  testWidgets('o som do prêmio toca na abertura, não no primeiro toque', (
    tester,
  ) async {
    await _monta(tester, aoAbrir: () {});

    for (var i = 0; i < Toca.precisaDe - 1; i++) {
      await tester.tap(find.byKey(Toca.chave));
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(
      sons,
      isNot(contains(SomDoBaru.premio)),
      reason: 'a cena inteira em silêncio seria animação decorativa',
    );

    await tester.tap(find.byKey(Toca.chave));
    await tester.pump(const Duration(milliseconds: 300));
    expect(sons.last, SomDoBaru.premio);
  });

  testWidgets('continuar cavando depois de aberta não abre de novo', (
    tester,
  ) async {
    var abriu = 0;
    await _monta(tester, aoAbrir: () => abriu++);

    for (var i = 0; i < Toca.precisaDe + 4; i++) {
      await tester.tap(find.byKey(Toca.chave));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pump(const Duration(milliseconds: 900));

    expect(abriu, 1, reason: 'creditar duas vezes é folha de graça');
  });

  testWidgets('arrastar também cava', (tester) async {
    // Quem tenta raspar a terra com o dedo está fazendo o gesto que a cena
    // pede; recusar isso seria ensinar a pessoa a não tentar.
    var abriu = 0;
    await _monta(tester, aoAbrir: () => abriu++);

    for (var i = 0; i < Toca.precisaDe; i++) {
      await tester.drag(find.byKey(Toca.chave), const Offset(0, 24));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pump(const Duration(milliseconds: 900));

    expect(abriu, 1);
  });
}
