import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/widgets/habitat.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ticker órfão.
///
/// Um `AnimationController` que ninguém descarta continua pedindo quadro para
/// sempre. No Android isso é bateria; no Flutter web é o assert
/// "Trying to render a disposed EngineFlutterView" no instante em que a view
/// morre.
///
/// O `flutter_test` já reclama de ticker vivo ao fim do teste — é isso que
/// transforma "vazou" em falha aqui.

AppState _comItens(List<String> ids) {
  final s = AppState()..startCompanionship();
  s.leaves = 5000;
  for (final id in ids) {
    final item = itemPorId(id);
    if (item != null) s.buy(item);
  }
  return s;
}

Widget _cena(AppState app) => MaterialApp(
      home: Scaffold(
        body: AppScope(state: app, child: const HabitatScene()),
      ),
    );

void main() {
  testWidgets('tirar um item da cena descarta o controller dele', (
    tester,
  ) async {
    // O `flutter_test` só acusa ticker **animando** no fim. Um controller de
    // chegada termina o `forward()` e fica parado: vaza memória sem acusar
    // nada. Daí a costura que conta quantos estão vivos.
    final vivos = ValueNotifier(0);
    HabitatScene.observadorDeChegadas = vivos;
    addTearDown(() {
      HabitatScene.observadorDeChegadas = null;
      vivos.dispose();
    });

    final app = _comItens(['lily', 'rock', 'bamboo']);
    addTearDown(app.dispose);

    await tester.pumpWidget(_cena(app));
    await tester.pump();
    expect(vivos.value, 3);

    app.alternaEquipado(itemPorId('rock')!);
    app.alternaEquipado(itemPorId('bamboo')!);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(app.objetosNaCena, ['lily']);
    expect(
      vivos.value,
      1,
      reason: 'os dois que saíram deixavam um controller órfão cada',
    );
  });

  testWidgets('colocar e tirar em sequência não acumula controller', (
    tester,
  ) async {
    final vivos = ValueNotifier(0);
    HabitatScene.observadorDeChegadas = vivos;
    addTearDown(() {
      HabitatScene.observadorDeChegadas = null;
      vivos.dispose();
    });

    final app = _comItens(['rock']);
    addTearDown(app.dispose);

    await tester.pumpWidget(_cena(app));
    await tester.pump();

    for (var i = 0; i < 6; i++) {
      app.alternaEquipado(itemPorId('rock')!);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
    }

    expect(app.estaEquipado('rock'), isTrue);
    expect(
      vivos.value,
      1,
      reason: 'sem o descarte isto crescia um por volta',
    );
  });

  testWidgets('o companheiro para de respirar com o app escondido', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: PetView(
              species: Species.capybara,
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
    expect(
      SchedulerBinding.instance.transientCallbackCount,
      greaterThan(0),
      reason: 'em cena ele respira',
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(
      SchedulerBinding.instance.transientCallbackCount,
      0,
      reason: 'escondido, nenhum ticker pode continuar pedindo quadro',
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(
      SchedulerBinding.instance.transientCallbackCount,
      greaterThan(0),
      reason: 'e volta a respirar quando o app volta',
    );
  });

  testWidgets('a cena para de derivar com o app escondido', (tester) async {
    final app = _comItens(const []);
    addTearDown(app.dispose);

    await tester.pumpWidget(_cena(app));
    await tester.pump();
    expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    expect(SchedulerBinding.instance.transientCallbackCount, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0));
  });
}
