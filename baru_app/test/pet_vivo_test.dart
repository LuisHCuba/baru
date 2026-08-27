import 'dart:ui' as ui;

import 'package:baru_app/models.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// O companheiro nunca está parado.
///
/// Estes testes não conferem se a animação "existe no código" — eles
/// **capturam os pixels** em dois instantes e exigem que tenham mudado. Um
/// `AnimationController` esquecido sem `repeat()` passaria em qualquer teste
/// que só olhasse a árvore de widgets.

Widget _cena({
  Activity activity = Activity.swim,
  Mood mood = Mood.content,
  bool interativo = true,
  Species species = Species.capybara,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: PetView(
          species: species,
          mood: mood,
          activity: activity,
          coat: 0,
          interativo: interativo,
        ),
      ),
    ),
  );
}

/// Pixels do desenho do companheiro neste instante.
///
/// `toImage()` completa na thread de rasterização, fora do fake-async do
/// `flutter_test` — sem `runAsync` o Future nunca resolve e o teste trava.
Future<Uint8List> _quadro(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(PetView.cenaKey),
  );
  final bytes = await tester.runAsync(() async {
    final img = await boundary.toImage();
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    return data!.buffer.asUint8List();
  });
  return bytes!;
}

bool _mudou(Uint8List a, Uint8List b) {
  if (a.length != b.length) return true;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return true;
  }
  return false;
}

void _movimentoReduzido(WidgetTester tester, bool valor) {
  tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: valor);
  addTearDown(
    tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
  );
}

void main() {
  testWidgets('o companheiro respira: o desenho muda sozinho', (tester) async {
    await tester.pumpWidget(_cena(activity: Activity.idle));
    await tester.pump();

    final antes = await _quadro(tester);
    // Meio ciclo de respiração: tempo de sobra para o peito encher.
    await tester.pump(const Duration(milliseconds: 900));
    final depois = await _quadro(tester);

    expect(
      _mudou(antes, depois),
      isTrue,
      reason: 'um bicho parado é wallpaper, não habitat',
    );
  });

  testWidgets('na água ele boia e as ondas andam', (tester) async {
    await tester.pumpWidget(_cena(activity: Activity.swim));
    await tester.pump();

    final antes = await _quadro(tester);
    await tester.pump(const Duration(milliseconds: 1200));
    final depois = await _quadro(tester);

    expect(_mudou(antes, depois), isTrue);
  });

  testWidgets('cochilando ele continua respirando', (tester) async {
    await tester.pumpWidget(_cena(activity: Activity.nap, mood: Mood.sleepy));
    await tester.pump();

    final antes = await _quadro(tester);
    await tester.pump(const Duration(milliseconds: 1100));
    final depois = await _quadro(tester);

    expect(_mudou(antes, depois), isTrue);
  });

  testWidgets('ele reage ao toque', (tester) async {
    _movimentoReduzido(tester, true); // isola o toque do movimento contínuo
    await tester.pumpWidget(_cena(activity: Activity.idle));
    await tester.pump();

    final parado = await _quadro(tester);
    await tester.pump(const Duration(milliseconds: 400));
    final aindaParado = await _quadro(tester);
    expect(
      _mudou(parado, aindaParado),
      isFalse,
      reason: 'com movimento reduzido a cena fica quieta até alguém tocar',
    );

    await tester.tap(find.byType(PetView));
    // O primeiro pump depois de iniciar uma animação só marca o t0 do ticker:
    // o valor ainda é zero. É o segundo que anda.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70)); // pico da quicada
    final tocado = await _quadro(tester);

    expect(
      _mudou(aindaParado, tocado),
      isTrue,
      reason: 'movimento reduzido diminui a amplitude, não remove o feedback',
    );
  });

  testWidgets('movimento reduzido para a animação contínua', (tester) async {
    _movimentoReduzido(tester, true);
    await tester.pumpWidget(_cena(activity: Activity.swim, interativo: false));
    await tester.pump();

    final antes = await _quadro(tester);
    await tester.pump(const Duration(milliseconds: 1500));
    final depois = await _quadro(tester);

    expect(_mudou(antes, depois), isFalse);
  });

  testWidgets('o toque dá retorno háptico', (tester) async {
    final chamadas = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          chamadas.add('${call.arguments}');
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(_cena());
    await tester.tap(find.byType(PetView));
    await tester.pump();

    expect(chamadas, isNotEmpty, reason: 'toque sem háptico é toque mudo');
  });

  testWidgets('sozinho, ele faz alguma coisa além de respirar', (tester) async {
    final visto = <GestoOcioso>[];
    final observador = ValueNotifier(GestoOcioso.nenhum);
    observador.addListener(() => visto.add(observador.value));
    PetView.observadorDeGesto = observador;
    addTearDown(() {
      PetView.observadorDeGesto = null;
      observador.dispose();
    });

    await tester.pumpWidget(_cena(activity: Activity.idle));
    await tester.pump();

    // O gesto é sorteado entre 7 e 15 s. Trinta segundos cabem dois.
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }

    final gestos = visto.where((g) => g != GestoOcioso.nenhum).toList();
    expect(
      gestos,
      isNotEmpty,
      reason: 'em meio minuto parado ele tem que ter feito algo',
    );
    expect(
      visto,
      contains(GestoOcioso.nenhum),
      reason: 'todo gesto termina e devolve o bicho ao repouso — se nunca '
          'voltasse a nenhum, ele ficaria preso na pose',
    );
  });

  testWidgets('nadando ele não se espreguiça: o corpo já está ocupado', (
    tester,
  ) async {
    final visto = <GestoOcioso>[];
    final observador = ValueNotifier(GestoOcioso.nenhum);
    observador.addListener(() => visto.add(observador.value));
    PetView.observadorDeGesto = observador;
    addTearDown(() {
      PetView.observadorDeGesto = null;
      observador.dispose();
    });

    await tester.pumpWidget(_cena(activity: Activity.swim));
    await tester.pump();
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }

    expect(visto.where((g) => g != GestoOcioso.nenhum), isEmpty);
  });

  testWidgets('tocar interrompe o gesto de ocioso', (tester) async {
    final observador = ValueNotifier(GestoOcioso.nenhum);
    PetView.observadorDeGesto = observador;
    addTearDown(() {
      PetView.observadorDeGesto = null;
      observador.dispose();
    });

    await tester.pumpWidget(_cena(activity: Activity.idle));
    await tester.pump();

    // Anda até pegar um gesto no meio.
    for (var i = 0; i < 80; i++) {
      if (observador.value != GestoOcioso.nenhum) break;
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(observador.value, isNot(GestoOcioso.nenhum), reason: 'nada a testar');

    await tester.tap(find.byType(PetView));
    await tester.pump();
    expect(
      observador.value,
      GestoOcioso.nenhum,
      reason: 'quem está sendo tocado para de se espreguiçar e olha',
    );

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('carinho insistente muda o que aparece na tela', (tester) async {
    // Com movimento reduzido o contínuo para: o único que anda é o toque.
    // Assim a diferença entre um toque e três é só a reação, não a fase da
    // respiração.
    _movimentoReduzido(tester, true);

    Future<Uint8List> comToques(int quantos) async {
      await tester.pumpWidget(_cena(activity: Activity.idle));
      await tester.pump();
      for (var i = 0; i < quantos; i++) {
        await tester.tap(find.byType(PetView));
        await tester.pump();
        // 500 ms: a orelha (420 ms) já assentou, então ela não entra na
        // diferença entre as duas capturas.
        await tester.pump(const Duration(milliseconds: 500));
      }
      final q = await _quadro(tester);
      // Deixa o toque acabar antes de trocar a árvore.
      await tester.pump(const Duration(seconds: 4));
      return q;
    }

    final umToque = await comToques(1);
    final tresToques = await comToques(3);

    expect(
      _mudou(umToque, tresToques),
      isTrue,
      reason: 'do terceiro toque em diante o háptico muda; a tela também tem '
          'que mudar, senão a escalada é invisível',
    );
  });

  testWidgets('depois do toque nada fica preso na pose', (tester) async {
    // Coruja de propósito: o tufo dela responde de forma linear a `orelha`, e
    // um controller que termina em 1.0 e fica lá deixa o tufo torto. Na
    // orelha redonda o defeito se esconde, porque `sin(2π)` volta a zero.
    //
    // Movimento reduzido isola: sem o contínuo, o único que anda é o toque.
    _movimentoReduzido(tester, true);
    await tester.pumpWidget(
      _cena(activity: Activity.idle, species: Species.owl),
    );
    await tester.pump();

    final repouso = await _quadro(tester);

    await tester.tap(find.byType(PetView));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 210));
    final reagindo = await _quadro(tester);
    expect(_mudou(repouso, reagindo), isTrue, reason: 'o toque tem que aparecer');

    // Bem depois do fim de tudo: toque (900 ms) e tremor de orelha (420 ms).
    await tester.pump(const Duration(milliseconds: 1200));
    final voltou = await _quadro(tester);

    expect(
      _mudou(repouso, voltou),
      isFalse,
      reason: 'acabada a reação ele volta exatamente ao repouso; qualquer '
          'sobra é uma parte do corpo que ficou travada',
    );
  });

  testWidgets('miniatura não é interativa', (tester) async {
    await tester.pumpWidget(_cena(interativo: false));
    await tester.pump();
    expect(find.byType(GestureDetector), findsNothing);
  });
}
