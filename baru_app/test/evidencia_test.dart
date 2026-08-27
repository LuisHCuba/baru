@Tags(['evidencia'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:baru_app/data/tempo_de_tela.dart';
import 'package:baru_app/data/app_snapshot.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/data/progressao.dart';
import 'package:baru_app/screens/home_screen.dart';
import 'package:baru_app/screens/missoes_screen.dart';
import 'package:baru_app/screens/conta_screen.dart';
import 'package:baru_app/screens/folhas_screen.dart';
import 'package:baru_app/screens/sequencia_screen.dart';
import 'package:baru_app/screens/settings_screen.dart';
import 'package:baru_app/screens/onboarding_screen.dart';
import 'package:baru_app/screens/shop_screen.dart';
import 'package:baru_app/screens/sobreposicao_screen.dart';
import 'package:baru_app/screens/tempo_screen.dart';
import 'package:baru_app/screens/trilha_screen.dart';
import 'package:baru_app/theme.dart';
import 'package:baru_app/widgets/celebracao.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/widgets/habitat.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:baru_app/widgets/saida.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gera a evidência visual do turno em `docs/evidence/<data>/`.
///
/// São PNGs de verdade, rasterizados a partir da árvore de widgets — não
/// goldens de comparação e não descrição de animação. O §10 do mandato exige
/// que ninguém chame uma animação de pronta sem tê-la exercitado; aqui ela é
/// exercitada e o resultado fica no disco.
const _pasta = '../docs/evidence/2026-08-27';

Future<void> _salva(WidgetTester tester, Key chave, String nome) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(chave));
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

AppState _estado({List<String> itens = const []}) {
  final s = AppState()..startCompanionship();
  s.owned = List<String>.from(itens);
  return s;
}

Widget _habitat(AppState app, DateTime agora) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: AppScope(
            state: app,
            child: const SizedBox(
              width: 372,
              height: 296,
              child: HabitatScene(),
            ),
          ),
        ),
      ),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Sem isto o flutter_test desenha texto com a fonte de teste e a captura
    // sai com caixinhas no lugar das letras — evidência inútil.
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

    // Fonte de ícones do Material: sem ela, todo Icon vira um quadrado vazio
    // na captura, e a evidência mostraria um bug que não existe.
    final iconesEm = Platform.environment['FLUTTER_ROOT'] ?? r'C:\devlutter';
    final arquivo = File(
      '$iconesEm/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
    );
    if (arquivo.existsSync()) {
      final bytes = arquivo.readAsBytesSync();
      final loader = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.view(bytes.buffer)));
      await loader.load();
    }
  });

  testWidgets('habitat nos quatro momentos do dia', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const horas = {
      6: 'amanhecer',
      12: 'dia',
      18: 'entardecer',
      22: 'noite',
    };
    for (final e in horas.entries) {
      final app = _estado(itens: const ['lily', 'dock', 'rock', 'lantern']);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppScope(
                state: app,
                child: SizedBox(
                  width: 372,
                  height: 296,
                  child: HabitatScene(agora: DateTime(2026, 8, 27, e.key)),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await _salva(tester, HabitatScene.cenaKey, 'habitat-${e.value}');
    }
  });

  testWidgets('habitat vazio e habitat cheio', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );

    for (final caso in {'vazio': <String>[], 'cheio': habitats['full']!}.entries) {
      final app = _estado(itens: caso.value);
      await tester.pumpWidget(_habitat(app, DateTime(2026, 8, 27, 12)));
      await tester.pump();
      await _salva(tester, HabitatScene.cenaKey, 'habitat-${caso.key}');
    }
  });

  testWidgets('o companheiro em cada atividade', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );

    const casos = {
      Activity.swim: Mood.radiant,
      Activity.graze: Mood.content,
      Activity.nap: Mood.sleepy,
      Activity.idle: Mood.missingYou,
    };
    for (final e in casos.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PetView(
                species: Species.capybara,
                mood: e.value,
                activity: e.key,
                coat: 0,
                interativo: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await _salva(tester, PetView.cenaKey, 'pet-${e.key.name}');
    }
  });

  testWidgets('folha das quatro especies em quatro humores', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const casos = [
      (Mood.radiant, Activity.swim),
      (Mood.content, Activity.graze),
      (Mood.sleepy, Activity.nap),
      (Mood.missingYou, Activity.idle),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Cores.habitat,
          body: RepaintBoundary(
            key: const Key('captura-folha'),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final sp in Species.values)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final (humor, atividade) in casos)
                        SizedBox(
                          width: 200,
                          height: 150,
                          child: PetView(
                            species: sp,
                            mood: humor,
                            activity: atividade,
                            coat: 0,
                            interativo: false,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await _salva(tester, const Key('captura-folha'), 'folha-especies');
  });

  testWidgets('folha de reacoes: o que muda quando alguem interage', (
    tester,
  ) async {
    // Sem movimento reduzido aqui: o gesto de ocioso só existe com o contínuo
    // ligado. O preço é que respiração e cauda também andam — o que a folha
    // prova é a reação, não a ausência de outro movimento (isso é papel do
    // pet_vivo_test).
    // 400x300 físicos a 2x = 200x150 lógicos: o quadro inteiro do bicho.
    tester.view.physicalSize = const Size(400, 300);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> monta(Species sp) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Cores.habitat,
            body: Center(
              child: PetView(
                species: sp,
                mood: Mood.content,
                activity: Activity.idle,
                coat: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    // 1. Repouso.
    await monta(Species.capybara);
    await _salva(tester, PetView.cenaKey, 'reacao-1-repouso');

    // 2. Um toque: a quicada.
    await tester.tap(find.byType(PetView));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    await _salva(tester, PetView.cenaKey, 'reacao-2-um-toque');
    await tester.pump(const Duration(milliseconds: 900));

    // 3. Três toques seguidos: coraçõezinhos.
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byType(PetView));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.tap(find.byType(PetView));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));
    await _salva(tester, PetView.cenaKey, 'reacao-3-carinho');
    await tester.pump(const Duration(seconds: 4));

    // 3b. Afago: a mão passando pelo corpo.
    await monta(Species.capybara);
    final centro = tester.getCenter(find.byType(PetView));
    final mao = await tester.startGesture(centro - const Offset(55, 0));
    // Ida e volta, como se afaga de verdade — em linha reta a mão sai do
    // bicho antes de ele começar a gostar.
    for (var passada = 0; passada < 5; passada++) {
      final dx = passada.isEven ? 10.0 : -10.0;
      for (var i = 0; i < 11; i++) {
        await mao.moveBy(Offset(dx, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
    }
    await _salva(tester, PetView.cenaKey, 'reacao-7-afago');
    await mao.up();
    await tester.pump(const Duration(seconds: 4));

    // 4 a 6. Os gestos de ocioso. O sorteio é fixado: sem isso a captura do
    // bocejo dependia de o dado de três faces cair no lado certo, e o teste
    // falhava um terço das vezes.
    final observador = ValueNotifier(GestoOcioso.nenhum);
    PetView.observadorDeGesto = observador;
    addTearDown(() {
      PetView.observadorDeGesto = null;
      PetView.gestoForcado = null;
      observador.dispose();
    });

    const gestos = {
      GestoOcioso.espreguica: ('reacao-4-espreguica', 800),
      GestoOcioso.sacode: ('reacao-5-sacode', 200),
      GestoOcioso.olhaEmVolta: ('reacao-6-olha-em-volta', 400),
    };

    for (final g in gestos.entries) {
      PetView.gestoForcado = g.key;
      observador.value = GestoOcioso.nenhum;
      await monta(Species.owl);
      var achou = false;
      // O gesto sai entre 7 e 15 s.
      for (var i = 0; i < 180 && !achou; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        achou = observador.value == g.key;
      }
      expect(achou, isTrue, reason: 'o gesto ${g.key.name} não veio em 18 s');
      // Instante escolhido dentro do gesto (ele dura 1600 ms).
      await tester.pump(Duration(milliseconds: g.value.$2));
      await _salva(tester, PetView.cenaKey, g.value.$1);
      await tester.pump(const Duration(seconds: 3));
    }
  });

  testWidgets('folhas, sequencia e ajustes', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final comHistorico = _estado()
      ..leaves = 96
      ..streak = 5
      ..melhorSequencia = 9
      ..sessoesConcluidas = 14
      ..diasAbaixoDaMeta = 6
      ..owned = ['lily', 'bamboo']
      ..sessions = [
        for (var i = 0; i < 5; i++)
          SessionRecord(
            id: 's$i',
            at: DateTime(2026, 8, 27 - i, 9 + i),
            dur: i.isEven ? 25 : 50,
            completed: true,
            aborted: false,
            reward: i.isEven ? 10 : 25,
          ),
      ];

    final casos = <String, (Widget, AppState)>{
      'folhas': (const FolhasScreen(), comHistorico),
      'sequencia': (const SequenciaScreen(), comHistorico),
      'ajustes': (const SettingsScreen(), comHistorico),
      'conta': (const ContaScreen(), comHistorico),
      'sobreposicao': (const SobreposicaoScreen(), comHistorico),
      'loja': (
        const ShopScreen(),
        _estado()
          ..leaves = 260
          ..owned = ['lily', 'rock', 'chapeu_palha', 'cachecol']
          ..equipados = {'lily', 'chapeu_palha'},
      ),
    };

    for (final e in casos.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Cores.superficie,
            body: RepaintBoundary(
              key: const Key('captura-tela'),
              child: AppScope(state: e.value.$2, child: e.value.$1),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await _salva(tester, const Key('captura-tela'), 'tela-${e.key}');
    }
  });

  testWidgets('folha de saida', (tester) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final app = _estado()..streak = 5;
    app.voltar(); // pede para sair
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Cores.superficie,
          body: RepaintBoundary(
            key: const Key('captura-saida'),
            child: AppScope(
              state: app,
              child: const Stack(children: [FolhaDeSaida()]),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(Tempo.tela);
    await _salva(tester, const Key('captura-saida'), 'folha-de-saida');
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('folha de roupas', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    tester.view.physicalSize = const Size(900, 920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final roupas = shopItems
        .where((i) => i.categoria == CategoriaDeItem.roupa)
        .toList();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Cores.habitat,
          body: RepaintBoundary(
            key: const Key('captura-roupas'),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final sp in Species.values)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final r in roupas)
                        SizedBox(
                          width: 170,
                          height: 110,
                          child: PetView(
                            species: sp,
                            mood: Mood.content,
                            activity: Activity.idle,
                            coat: 0,
                            scale: 0.72,
                            interativo: false,
                            roupas: {r.vestimenta!: r.cor!},
                            roupaDeCabeca: r.id,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await _salva(tester, const Key('captura-roupas'), 'folha-roupas');
  });

  testWidgets('o quiz do onboarding', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    tester.view.physicalSize = const Size(412, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final app = AppState()..onb = 2;
    addTearDown(app.dispose);
    app.pickQuiz('elemento', 'fogo');
    app.pickQuiz('clareza', 'madrugada');
    app.pickQuiz('rouba_foco', 'videos');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Cores.superficie,
          body: RepaintBoundary(
            key: const Key('captura-quiz'),
            child: AppScope(state: app, child: const OnboardingScreen()),
          ),
        ),
      ),
    );
    await tester.pump();
    await _salva(tester, const Key('captura-quiz'), 'onboarding-quiz');
  });

  testWidgets('as quatro espécies', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );

    for (final sp in Species.values) {
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
      await _salva(tester, PetView.cenaKey, 'especie-${sp.name}');
    }
  });

  testWidgets('tela de tempo de tela, nos tres estados', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const dia = ResumoDeTela(
      porApp: {
        'com.instagram.android': Duration(minutes: 62),
        'com.whatsapp': Duration(minutes: 31),
        'com.spotify.music': Duration(minutes: 48),
        'com.amazon.kindle': Duration(minutes: 25),
        'com.google.android.youtube': Duration(minutes: 19),
      },
      porCategoria: {
        CategoriaDeApp.dispersivo: Duration(minutes: 81),
        CategoriaDeApp.neutro: Duration(minutes: 31),
        CategoriaDeApp.passivo: Duration(minutes: 48),
        CategoriaDeApp.produtivo: Duration(minutes: 25),
      },
    );

    final casos = <String, AppState>{
      'tempo-com-dados': _estado()
        ..usageAccess = true
        ..goal = 150
        ..resumoTela = dia,
      'tempo-sem-permissao': _estado()..usageAccess = false,
      'tempo-vazio': _estado()..usageAccess = true,
    };

    for (final e in casos.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            key: const Key('tela-tempo'),
            body: RepaintBoundary(
              key: const Key('captura-tempo'),
              child: AppScope(state: e.value, child: const TempoScreen()),
            ),
          ),
        ),
      );
      await tester.pump();
      // Barras e contadores animam: um pump só marca o t0 do ticker.
      await tester.pump(const Duration(seconds: 2));
      await _salva(tester, const Key('captura-tempo'), e.key);
    }
  });

  testWidgets('trilha, no comeco e em andamento', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final casos = <String, AppState>{
      'trilha-inicio': _estado(),
      'trilha-andamento': _estado()
        ..sessoesConcluidas = 6
        ..melhorSequencia = 4
        ..diasAbaixoDaMeta = 2
        ..xp = Balanco.xpAcumuladoPara(4) + 30
        ..afeto = 23,
    };
    for (final e in casos.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: const Key('captura-trilha'),
              child: AppScope(state: e.value, child: const TrilhaScreen()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await _salva(tester, const Key('captura-trilha'), e.key);
    }
  });

  testWidgets('missoes, com progresso e resgate', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final app = _estado()
      ..leaves = 137
      ..usageAccess = true
      ..usage = 90
      ..goal = 150
      ..completedToday = 1
      ..minutosDeFocoHoje = 50
      ..maiorSessaoHoje = 50
      ..sessoesNaSemana = 4
      ..minutosNaSemana = 210
      ..diasAbaixoNaSemana = 2;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: const Key('captura-missoes'),
            child: AppScope(state: app, child: const MissoesScreen()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await _salva(tester, const Key('captura-missoes'), 'missoes');
  });

  testWidgets('home completa', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final app = _estado(itens: const ['lily', 'dock', 'rock'])
      ..leaves = 137
      ..streak = 4
      ..usageAccess = true
      ..usage = 96
      ..goal = 150
      ..completedToday = 1
      ..minutosDeFocoHoje = 50
      ..sessoesConcluidas = 6
      ..melhorSequencia = 4
      ..xp = Balanco.xpAcumuladoPara(4) + 30;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: const Key('captura-home'),
            child: AppScope(state: app, child: const HomeScreen()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await _salva(tester, const Key('captura-home'), 'home');
  });

  testWidgets('celebracao de nivel', (tester) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: const Key('captura-celebracao'),
            child: Stack(
              children: [
                const ColoredBox(
                  color: Cores.superficie,
                  child: SizedBox.expand(),
                ),
                Celebracao(
                  titulo: 'Nível 4',
                  subtitulo: 'Baru está mais em casa.',
                  icone: Icons.local_florist_rounded,
                  cor: Cores.primaria,
                  aoFechar: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // Meio da explosão: é onde as partículas estão espalhadas.
    await tester.pump(const Duration(milliseconds: 480));
    await _salva(tester, const Key('captura-celebracao'), 'celebracao-nivel');
  });

  testWidgets('sequência de quadros da respiração', (tester) async {
    // Sem desligar animação: a sequência É a evidência do movimento.
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
    for (var i = 0; i < 6; i++) {
      await _salva(tester, PetView.cenaKey, 'respiracao-${i + 1}');
      await tester.pump(const Duration(milliseconds: 280));
    }
  });

  testWidgets('sequência de quadros da chegada de um item', (tester) async {
    final app = _estado(itens: const ['lily'])..leaves = 500;
    await tester.pumpWidget(_habitat(app, DateTime(2026, 8, 27, 12)));
    await tester.pump();
    await _salva(tester, HabitatScene.cenaKey, 'chegada-0-antes');

    app.buy(shopItems.firstWhere((i) => i.id == 'bridge'));
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 150));
      await _salva(tester, HabitatScene.cenaKey, 'chegada-${i + 1}');
    }
  });
}
