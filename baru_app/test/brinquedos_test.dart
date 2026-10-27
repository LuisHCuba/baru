import 'package:baru_app/models.dart';
import 'package:baru_app/services/som_service.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/widgets/brinquedos.dart';
import 'package:baru_app/widgets/habitat.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A bolinha e a castanha (pesquisa 20, mecânicas 9 e 10): o bicho tem de
/// ir atrás, de verdade, e comer o que recebe.

Widget _cena(AppState app, {bool brinquedos = true}) {
  return MaterialApp(
    home: Scaffold(
      body: AppScope(
        state: app,
        child: SizedBox(
          width: 372,
          height: 296,
          child: HabitatScene(brinquedos: brinquedos),
        ),
      ),
    ),
  );
}

/// Um bicho crescido: o recém-nascido no ninho não brinca.
AppState _crescido() => AppState()
  ..startCompanionship()
  ..sessoesPorEspecie = {for (final e in Species.values) e.name: 20}
  ..estagioCelebrado = {for (final e in Species.values) e.name: 3};

Future<void> _passa(WidgetTester tester, double segundos) async {
  for (var t = 0.0; t < segundos; t += 1 / 30) {
    await tester.pump(const Duration(milliseconds: 33));
  }
}

void main() {
  final tocados = <SomDoBaru>[];
  setUp(() {
    tocados.clear();
    SomService.instance.tocador = (s) async => tocados.add(s);
    PetView.observadorDoCentro = ValueNotifier(null);
  });
  tearDown(() {
    SomService.instance.tocador = null;
    PetView.observadorDoCentro = null;
  });

  testWidgets('sem pedir, a cena não tem brinquedo', (tester) async {
    await tester.pumpWidget(
      _cena(AppState()..startCompanionship(), brinquedos: false),
    );
    await tester.pump();
    expect(find.byKey(BrinquedosDoHabitat.bolaKey), findsNothing);
    expect(find.byKey(BrinquedosDoHabitat.poteKey), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a bola arremessada voa, quica, e ele vai atrás', (tester) async {
    await tester.pumpWidget(_cena(_crescido()));
    await _passa(tester, 0.5);
    final bicho = PetView.observadorDoCentro!.value!;
    final bola = tester.getCenter(find.byKey(BrinquedosDoHabitat.bolaKey));

    final g = await tester.startGesture(bola);
    await tester.pump(const Duration(milliseconds: 16));
    for (var i = 0; i < 6; i++) {
      await g.moveBy(const Offset(-24, -14));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await _passa(tester, 0.25);
    final noAr = tester.getCenter(find.byKey(BrinquedosDoHabitat.bolaKey));
    expect(noAr.dy, lessThan(bola.dy - 20), reason: 'ela sobe');
    expect(noAr.dx, lessThan(bola.dx - 40), reason: 'para onde foi jogada');

    await _passa(tester, 3);
    expect(tocados, contains(SomDoBaru.quique), reason: 'quicou no chão');
    final depois = PetView.observadorDoCentro!.value!;
    expect(
      (depois.dx - bicho.dx).abs(),
      greaterThan(10),
      reason: 'ele saiu do lugar atrás dela',
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a castanha levada à boca ele come da mão', (tester) async {
    await tester.pumpWidget(_cena(_crescido()));
    await _passa(tester, 0.5);
    final pote = tester.getCenter(find.byKey(BrinquedosDoHabitat.poteKey));
    final g = await tester.startGesture(pote);
    await tester.pump(const Duration(milliseconds: 33));
    for (var i = 1; i <= 40 && !tocados.contains(SomDoBaru.mastiga); i++) {
      // Persegue a boca: ele se mexe enquanto a mão vem.
      final boca = PetView.observadorDoCentro!.value! + const Offset(0, -10);
      final atual = pote + (boca - pote) * (i / 40);
      await g.moveTo(atual);
      await tester.pump(const Duration(milliseconds: 33));
    }
    await _passa(tester, 1);
    await g.up();
    expect(tocados, contains(SomDoBaru.mastiga));
    // Mastiga e fica satisfeito; o pote só volta a encher depois.
    await _passa(tester, 5);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('o recém-nascido no ninho não ganha brinquedo', (tester) async {
    await tester.pumpWidget(_cena(AppState()..startCompanionship()));
    await tester.pump();
    expect(find.byKey(BrinquedosDoHabitat.bolaKey), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('cochilando, ele acorda com a bola e vai atrás', (tester) async {
    final app = _crescido()
      ..usageAccess = true
      ..usage = 300
      ..goal = 100;
    expect(app.activity, Activity.nap);
    await tester.pumpWidget(_cena(app));
    await _passa(tester, 0.5);
    final bicho = PetView.observadorDoCentro!.value!;
    final bola = tester.getCenter(find.byKey(BrinquedosDoHabitat.bolaKey));
    final g = await tester.startGesture(bola);
    await tester.pump(const Duration(milliseconds: 16));
    await g.moveBy(const Offset(-90, -30));
    await tester.pump(const Duration(milliseconds: 16));
    await g.up();
    await _passa(tester, 4);
    final depois = PetView.observadorDoCentro!.value!;
    expect((depois.dx - bicho.dx).abs(), greaterThan(10));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
