@Tags(['capturas'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:baru_app/app.dart';
import 'package:baru_app/data/app_snapshot.dart';
import 'package:baru_app/data/progressao.dart';
import 'package:baru_app/data/tempo_de_tela.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Telas do app inteiro, com a casca e a barra de destinos, para a ficha da
/// Google Play, para a página do Baru em lhcx.tech e para o vídeo.
///
/// Diferente de `evidencia_test.dart`, que fotografa cada tela solta com
/// fundo transparente, aqui a captura pega a árvore desde a raiz: o fundo é
/// o do app e a barra de destinos aparece como o usuário a vê.
///
/// Só roda quando pedido, porque escreve arquivos fora de `test/`:
///
/// ```
/// CAPTURAS=1 CAPTURAS_LANG=pt TZ=Etc/GMT-5 \
///   flutter test test/capturas_loja_test.dart
/// ```
///
/// O habitat lê a hora de `DateTime.now()`, então o momento do dia vem do
/// fuso (`TZ`) com que o teste roda — `play-store/capturar.sh` escolhe.
///
/// Chinês fica de fora: o `flutter_tester` não tem fonte CJK de reserva e a
/// tela sairia em quadradinhos.
final _env = Platform.environment;
final _ligado = _env['CAPTURAS'] == '1';
final _lang = _env['CAPTURAS_LANG'] ?? 'pt';
final _sufixo = _env['CAPTURAS_SUFIXO'] ?? '';
final _pasta = 'build/visual';

/// 1080 × 2400, a tela de um Android comum (20:9).
const _fisico = Size(1080, 2400);
const _dpr = 2.625;

/// Barra de status: a casca usa `SafeArea`, então a área fica reservada e a
/// barra é desenhada depois, na composição.
const _statusBar = 28.0;

AppSnapshot _base(AppScreen tela, Species sp, String nome) {
  final now = DateTime.now();
  return AppSnapshot(
    screen: tela,
    onb: 5,
    lang: _lang,
    species: sp,
    q0: 'agua',
    q1: 'tarde',
    q2: 'rotina',
    leaves: 137,
    streak: 4,
    usage: 96,
    goal: 150,
    avg: 200,
    petName: nome,
    color: 0,
    owned: const ['lily', 'dock', 'rock'],
    dur: 25,
    completedToday: 1,
    abandonedToday: false,
    daysAway: 0,
    trial: true,
    evening: true,
    missed: true,
    payPlan: PayPlan.annual,
    usageAccess: true,
    companionshipStarted: true,
    week: freshWeek(now),
    todayIndex: weekdayIndex(now),
    freezesLeft: 1,
    trialStartedAt: now.subtract(const Duration(days: 2)),
    lastOpenDate: DateTime(now.year, now.month, now.day),
    sessions: const [],
  );
}

const _dia = ResumoDeTela(
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

void _historico(AppState s) {
  s
    ..leaves = 137
    ..streak = 4
    ..melhorSequencia = 4
    ..usageAccess = true
    ..usage = 96
    ..goal = 150
    ..completedToday = 1
    ..minutosDeFocoHoje = 50
    ..maiorSessaoHoje = 50
    ..sessoesConcluidas = 6
    ..diasAbaixoDaMeta = 2
    ..sessoesNaSemana = 4
    ..minutosNaSemana = 210
    ..diasAbaixoNaSemana = 2
    // Os bichos da loja aparecem adultos: 20 sessões juntos com cada um.
    ..sessoesPorEspecie = {for (final e in Species.values) e.name: 20}
    ..afeto = 23
    ..xp = Balanco.xpAcumuladoPara(4) + 30
    ..resumoTela = _dia
    ..equipados = {'lily', 'dock', 'rock'}
    ..sessions = [
      for (var i = 0; i < 5; i++)
        SessionRecord(
          id: 's$i',
          at: DateTime.now().subtract(Duration(days: i, hours: 2)),
          dur: i.isEven ? 25 : 50,
          completed: true,
          aborted: false,
          reward: i.isEven ? 10 : 25,
        ),
    ];
}

Future<void> _salva(WidgetTester tester, String nome) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('captura-loja')),
  );
  await tester.runAsync(() async {
    final img = await boundary.toImage(pixelRatio: _dpr);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    final destino = Directory(_pasta)..createSync(recursive: true);
    File(
      '${destino.path}/$nome$_sufixo.png',
    ).writeAsBytesSync(data!.buffer.asUint8List());
  });
}

class _Caso {
  const _Caso(this.nome, this.tela, {this.sp = Species.capybara, this.ajusta});
  final String nome;
  final AppScreen tela;
  final Species sp;
  final void Function(AppState s)? ajusta;
}

const _nomes = {
  Species.capybara: 'Baru',
  Species.otter: 'Rio',
  Species.tortoise: 'Toco',
  Species.owl: 'Nina',
  Species.axolotl: 'Lume',
  Species.penguin: 'Nino',
  Species.cat: 'Mel',
  Species.fox: 'Faísca',
  Species.frenchie: 'Bolota',
};

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Sem registrante de plugins no teste, as notificações não têm
    // implementação e o arranque do app quebra depois da captura.
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (call) async => switch (call.method) {
            'initialize' || 'areNotificationsEnabled' => true,
            'requestNotificationsPermission' => true,
            _ => null,
          },
        );
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
    // O `flutter test` nem sempre repassa FLUTTER_ROOT ao processo do teste;
    // sobe a partir do executável até achar a raiz do SDK.
    var raiz = Platform.environment['FLUTTER_ROOT'] ?? '';
    if (raiz.isEmpty) {
      var d = File(Platform.resolvedExecutable).parent;
      while (d.parent.path != d.path &&
          !Directory('${d.path}/bin/cache/artifacts').existsSync()) {
        d = d.parent;
      }
      raiz = d.path;
    }
    final icones = File(
      '$raiz/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (icones.existsSync()) {
      final bytes = icones.readAsBytesSync();
      final loader = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.view(bytes.buffer)));
      await loader.load();
    }
  });

  final casos = <_Caso>[
    _Caso('raiz-dia', AppScreen.home, sp: Species.owl, ajusta: (s) {
      _historico(s);
      s.streak = 5;
      s.raizACelebrar = 5;
    }),
    _Caso('raiz-marco', AppScreen.home, sp: Species.fox, ajusta: (s) {
      _historico(s);
      s.streak = 7;
      s.raizACelebrar = 7;
    }),
  ];
  for (final c in casos) {
    testWidgets('captura ${c.nome}', skip: !_ligado, (tester) async {
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      addTearDown(
        tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      tester.view.physicalSize = _fisico;
      tester.view.devicePixelRatio = _dpr;
      tester.view.padding = const FakeViewPadding(top: _statusBar * _dpr);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('captura-loja'),
          child: BaruApp(snapshot: _base(c.tela, c.sp, _nomes[c.sp]!)),
        ),
      );
      await tester.pump();
      final estado =
          (tester.state(find.byType(BaruApp)) as dynamic).state as AppState;
      c.ajusta?.call(estado);
      // Pôr XP de uma vez sobe de nível e chega o dia: a casca cobriria a
      // tela com a celebração.
      final r = estado.raizACelebrar;
      while (estado.temCelebracaoPendente) {
        estado.celebrou();
      }
      estado.raizACelebrar = r;
      estado.notifyListeners();
      await tester.pump();
      var t = 0;
      for (final ms in [300, 650, 800, 1100, 1300, 1600, 2500, 3400]) {
        await tester.pump(Duration(milliseconds: ms - t));
        t = ms;
        await _salva(tester, '${c.nome}-$ms');
      }
      // Desmonta antes do fim: timers da sessão e do bicho não podem vazar.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
