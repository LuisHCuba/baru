@Tags(['evidencia'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:baru_app/data/progressao.dart';
import 'package:baru_app/screens/home_screen.dart';
import 'package:baru_app/screens/trilha_screen.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/widgets/habitat.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Evidência visual da trilha e do tamanho do bicho.
///
/// Arquivo separado de `evidencia_test.dart` de propósito: aquele é território
/// compartilhado entre frentes que trabalham ao mesmo tempo, e duas mãos no
/// mesmo arquivo é como se perde trabalho. Os PNGs caem na mesma pasta.
const _pasta = '../docs/evidence/2026-08-27';

Future<void> _salva(WidgetTester tester, Key chave, String nome) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(chave),
  );
  await tester.runAsync(() async {
    final img = await boundary.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    final destino = Directory(_pasta)..createSync(recursive: true);
    File('${destino.path}/$nome.png').writeAsBytesSync(
      data!.buffer.asUint8List(),
    );
  });
}

void _semMovimento(WidgetTester tester) {
  tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(
    tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
  );
}

void _frame(WidgetTester tester, {Size tamanho = const Size(412, 892)}) {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

AppState _conta({int sessoes = 0, int abaixo = 0, int seq = 0, int xp = 0}) {
  final s = AppState()..startCompanionship();
  s.sessoesConcluidas = sessoes;
  s.diasAbaixoDaMeta = abaixo;
  s.melhorSequencia = seq;
  s.xp = xp;
  return s;
}

/// Carrega as fontes de verdade. Sem isto o `flutter_test` desenha com a
/// fonte de teste e a captura sai com caixinhas no lugar das letras — e um
/// ícone vira quadrado vazio, o que mostraria um bug que não existe.
Future<void> _carregaFontes() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final peso in [
    'Nunito-Regular',
    'Nunito-SemiBold',
    'Nunito-Bold',
    'Nunito-ExtraBold',
  ]) {
    final loader = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/$peso.ttf'));
    await loader.load();
  }

  final iconesEm = Platform.environment['FLUTTER_ROOT'] ?? r'C:\devlutter';
  final arquivo = File(
    '$iconesEm/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  if (arquivo.existsSync()) {
    final bytes = arquivo.readAsBytesSync();
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }
}

void main() {
  setUpAll(_carregaFontes);

  testWidgets('trilha: onde estou, o que falta e o que está travado',
      (tester) async {
    _semMovimento(tester);
    _frame(tester);

    final casos = <String, AppState>{
      // Passo 2: primeiro foco feito, o resto travado.
      'trilha-passo-2': _conta(sessoes: 4),
      // Meio da trilha: conquistados atrás, atual no meio, travados à frente.
      'trilha-passo-meio': _conta(
        sessoes: 12,
        abaixo: 4,
        seq: 6,
        xp: Balanco.xpAcumuladoPara(6) + 40,
      ),
    };

    for (final e in casos.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: const Key('captura-trilha-passo'),
              child: AppScope(state: e.value, child: const TrilhaScreen()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await _salva(tester, const Key('captura-trilha-passo'), e.key);
    }
  });

  testWidgets('trilha: o detalhe de um marco travado, com o habitat que abre',
      (tester) async {
    _semMovimento(tester);
    _frame(tester);
    final app = _conta(sessoes: 12, abaixo: 4, seq: 6);

    // A borda fica **fora** do `MaterialApp`: a folha de detalhe vive no
    // `Overlay` do `Navigator`, então uma borda dentro do `Scaffold` captura
    // a tela de baixo e a folha some da evidência.
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('captura-trilha-detalhe'),
        child: MaterialApp(
          // A borda ficou fora do `MaterialApp`, então a tarja de debug
          // entraria na captura.
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: AppScope(state: app, child: const TrilhaScreen()),
          ),
        ),
      ),
    );
    await tester.pump();

    final marco = trilha.firstWhere((m) => m.id == 'vinte_focos');
    await tester.scrollUntilVisible(
      find.text(tituloDoMarco(app, marco)).hitTestable(),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    // O trecho travado do caminho, antes de abrir nada.
    await _salva(
      tester,
      const Key('captura-trilha-detalhe'),
      'trilha-travados',
    );

    await tester.tap(find.text(tituloDoMarco(app, marco)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await _salva(
      tester,
      const Key('captura-trilha-detalhe'),
      'trilha-detalhe-travado',
    );
  });

  testWidgets('os habitats que a trilha abre', (tester) async {
    _semMovimento(tester);
    _frame(tester, tamanho: const Size(412, 480));

    // Trilha inteira feita: todos os lugares abertos.
    final app = _conta(sessoes: 100, abaixo: 30, seq: 30, xp: 12000);
    expect(app.habitatsLiberados.length, habitatsDaTrilha.length);

    for (final h in habitatsDaTrilha) {
      app.escolheHabitat(h.id);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppScope(
              state: app,
              child: Center(
                child: SizedBox(
                  width: 372,
                  child: HabitatScene(
                    agora: DateTime(2026, 8, 27, 12),
                    animado: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await _salva(tester, HabitatScene.cenaKey, 'habitat-trilha-${h.id}');
    }
  });

  testWidgets('a home com o bicho no tamanho novo', (tester) async {
    _semMovimento(tester);
    _frame(tester);

    final app = _conta(sessoes: 6, abaixo: 2, seq: 4, xp: 300)
      ..leaves = 137
      ..streak = 4
      ..usageAccess = true
      ..usage = 96
      ..goal = 150
      ..completedToday = 1;
    app.owned = ['lily', 'dock', 'rock'];
    app.equipados = {'lily', 'dock', 'rock'};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: const Key('captura-home-pet'),
            child: AppScope(state: app, child: const HomeScreen()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await _salva(tester, const Key('captura-home-pet'), 'home-pet-grande');
  });

  testWidgets('o tamanho do bicho na cena', (tester) async {
    _semMovimento(tester);
    _frame(tester, tamanho: const Size(412, 480));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppScope(
            state: _conta(),
            child: Center(
              child: SizedBox(
                width: 372,
                child: HabitatScene(
                  agora: DateTime(2026, 8, 27, 12),
                  animado: false,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await _salva(tester, HabitatScene.cenaKey, 'habitat-pet-grande');

    // O número que acompanha a imagem, para não depender de olhômetro.
    final pet = tester.widget<PetView>(find.byType(PetView));
    final cena = tester.getSize(find.byKey(HabitatScene.cenaKey));
    debugPrint(
      'evidencia: cena ${cena.width.toStringAsFixed(0)}x'
      '${cena.height.toStringAsFixed(0)}, bicho desenhado '
      '${(pet.width * pet.scale).toStringAsFixed(0)}x'
      '${(pet.height * pet.scale).toStringAsFixed(0)} '
      '(escala ${pet.scale.toStringAsFixed(2)})',
    );
  });
}
