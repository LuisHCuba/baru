@Tags(['evidencia'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:baru_app/data/app_snapshot.dart';
import 'package:baru_app/data/tempo_de_tela.dart';
import 'package:baru_app/screens/home_screen.dart';
import 'package:baru_app/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Evidência visual da fala do humor na home.
///
/// Arquivo novo, separado do `evidencia_test.dart` e do
/// `evidencia_buldogue_test.dart`: há trabalho simultâneo nos dois e duas
/// frentes escrevendo no mesmo arquivo batem de frente. O destino dos PNGs é
/// o mesmo.
///
/// O que estas capturas provam, e um teste de string não provaria: o fato com
/// o número **cabe** no título de 26 px em três linhas, nos oito casos, sem
/// reticências comendo o número.

const _pasta = '../docs/evidence/2026-08-28';

Future<void> _salva(WidgetTester tester, Key chave, String nome) async {
  final b = tester.renderObject<RenderRepaintBoundary>(find.byKey(chave));
  await tester.runAsync(() async {
    final img = await b.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    final destino = Directory(_pasta)..createSync(recursive: true);
    File('${destino.path}/$nome.png')
        .writeAsBytesSync(data!.buffer.asUint8List());
  });
}

AppState _pet({
  String lang = 'pt',
  bool usageAccess = true,
  int usage = 0,
  int goal = 150,
  int completedToday = 0,
  bool abandonedToday = false,
  int daysAway = 0,
  int streak = 0,
  int melhorSequencia = 0,
  int minutosDeFocoHoje = 0,
  ResumoDeTela? resumo,
  List<SessionRecord> sessions = const [],
}) {
  final s = AppState()..startCompanionship();
  s.lang = lang;
  s.leaves = 137;
  s.owned = const ['lily', 'dock', 'rock'];
  s.equipados = {'lily', 'dock', 'rock'};
  s.usageAccess = usageAccess;
  s.usage = usage;
  s.goal = goal;
  s.completedToday = completedToday;
  s.abandonedToday = abandonedToday;
  s.daysAway = daysAway;
  s.streak = streak;
  s.melhorSequencia = melhorSequencia;
  s.minutosDeFocoHoje = minutosDeFocoHoje;
  s.resumoTela = resumo;
  s.sessions = List<SessionRecord>.from(sessions);
  return s;
}

Widget _home(AppState app) => MaterialApp(
      home: Scaffold(
        body: RepaintBoundary(
          key: const Key('captura-humor'),
          child: AppScope(state: app, child: const HomeScreen()),
        ),
      ),
    );

final _desistenciaDe25 = SessionRecord(
  id: 'x',
  at: dateOnly(DateTime.now()).add(const Duration(hours: 10)),
  dur: 25,
  completed: false,
  aborted: true,
  reward: 0,
);

const _resumo = ResumoDeTela(
  porApp: {'com.exemplo': Duration(minutes: 148)},
  porCategoria: {
    CategoriaDeApp.dispersivo: Duration(minutes: 148),
    CategoriaDeApp.neutro: Duration(minutes: 152),
  },
);

/// Carrega a Nunito de verdade no ambiente de teste.
///
/// Sem isto o `flutter test` desenha toda letra como um retângulo cheio — as
/// evidências antigas do repositório são assim. Para provar *layout* basta;
/// para provar **que a frase diz o fato** não serve de nada: ninguém lê "3
/// dias sem você por aqui" num tijolo. Lê do disco em vez do `rootBundle`
/// porque o caminho de arquivo não depende de o bundle de asset estar
/// montado no runner.
///
/// O chinês continua saindo em tofu: a Nunito não tem os glifos, e embutir
/// uma CJK só para a captura seria peso sem retorno. A prova de que os
/// quatro idiomas existem é o teste de catálogo, não o PNG.
Future<void> _carregaANunito() async {
  final loader = FontLoader('Nunito');
  for (final peso in ['Regular', 'SemiBold', 'Bold', 'ExtraBold']) {
    final bytes = File('assets/fonts/Nunito-$peso.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

void main() {
  setUpAll(_carregaANunito);

  // Um caso por fala que um dia real alcança, na ordem em que a regra as
  // escolhe. Os títulos capturados são o que a pessoa lê ao abrir o app.
  final casos = <String, AppState Function()>{
    'ausencia': () => _pet(daysAway: 3, usage: 0),
    'ausencia-com-raiz': () => _pet(daysAway: 4, streak: 9),
    'desistencia': () =>
        _pet(abandonedToday: true, sessions: [_desistenciaDe25]),
    'radiante-recorde': () => _pet(
          usage: 96,
          completedToday: 1,
          streak: 7,
          melhorSequencia: 7,
          minutosDeFocoHoje: 25,
        ),
    'radiante-abaixo': () => _pet(
          usage: 116,
          completedToday: 2,
          streak: 3,
          melhorSequencia: 9,
          minutosDeFocoHoje: 75,
        ),
    'radiante-sem-medicao': () => _pet(
          usageAccess: false,
          completedToday: 2,
          minutosDeFocoHoje: 50,
          streak: 3,
          melhorSequencia: 9,
        ),
    'contente-acima': () => _pet(
          usage: 300,
          completedToday: 1,
          streak: 3,
          melhorSequencia: 9,
          minutosDeFocoHoje: 50,
        ),
    'contente-abaixo': () => _pet(usage: 96, streak: 3),
    'contente-sem-medicao': () => _pet(usageAccess: false, streak: 3),
    'neutro-acima': () => _pet(usage: 170, streak: 3),
    'sonolento-dispersivo': () => _pet(usage: 300, streak: 3, resumo: _resumo),
  };

  // Guarda o que cada captura mostrou. Título **e** legenda: dois humores
  // podem legitimamente abrir com o mesmo número no título — cinco horas de
  // tela são cinco horas com ou sem sessão — e o que os separa é a linha de
  // baixo. Comparar só o título condenaria um par honesto.
  final falasCapturadas = <String, String>{};

  for (final caso in casos.entries) {
    testWidgets('home — ${caso.key}', (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final app = caso.value();
      await tester.pumpWidget(_home(app));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      final cap = tester.widget<Text>(find.byKey(const Key('home-humor-cap')));
      final sub = tester.widget<Text>(find.byKey(const Key('home-humor-sub')));
      expect(cap.data, isNotNull);
      expect('${cap.data}${sub.data}', isNot(contains('{')));
      falasCapturadas[caso.key] = '${cap.data} | ${sub.data}';

      await _salva(tester, const Key('captura-humor'), 'fala-${caso.key}');
      app.dispose();
    });
  }

  testWidgets('cada captura mostrou um título diferente', (tester) async {
    // Roda depois das outras (a ordem dos `testWidgets` é a de declaração).
    expect(falasCapturadas.length, casos.length);
    expect(
      falasCapturadas.values.toSet().length,
      casos.length,
      reason: '$falasCapturadas',
    );
  });

  testWidgets('a mesma home nos quatro idiomas', (tester) async {
    tester.view.physicalSize = const Size(1680, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final estados = [
      for (final lang in ['pt', 'en', 'es', 'zh'])
        _pet(
          lang: lang,
          usage: 116,
          completedToday: 2,
          streak: 3,
          melhorSequencia: 9,
          minutosDeFocoHoje: 75,
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: const Key('captura-idiomas'),
            child: Row(
              children: [
                for (final app in estados)
                  SizedBox(
                    width: 412,
                    child: AppScope(state: app, child: const HomeScreen()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Quatro idiomas, quatro textos: um idioma sem tradução cairia no `pt` e
    // a captura mostraria a mesma frase duas vezes.
    final falas = tester
        .widgetList<Text>(find.byKey(const Key('home-humor-cap')))
        .map((t) => t.data)
        .toSet();
    expect(falas.length, 4, reason: '$falas');

    await _salva(tester, const Key('captura-idiomas'), 'fala-quatro-idiomas');
    for (final app in estados) {
      app.dispose();
    }
  });
}
