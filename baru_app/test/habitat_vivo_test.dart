import 'dart:ui' as ui;

import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/widgets/habitat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// O habitat é um lugar, não um papel de parede.
///
/// Como no teste do companheiro, o que se afirma aqui é medido em pixels: se
/// a cena das 22h fosse idêntica à das 9h, o teste falharia.

Widget _cena(AppState app, {DateTime? agora, bool animado = true}) {
  return MaterialApp(
    home: Scaffold(
      body: AppScope(
        state: app,
        child: SizedBox(
          width: 372,
          height: 296,
          child: HabitatScene(agora: agora, animado: animado),
        ),
      ),
    ),
  );
}

AppState _estado({List<String> itens = const []}) {
  final s = AppState()..startCompanionship();
  s.owned = List<String>.from(itens);
  return s;
}

Future<Uint8List> _quadro(WidgetTester tester) async {
  final b = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(HabitatScene.cenaKey),
  );
  final bytes = await tester.runAsync(() async {
    final img = await b.toImage();
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();
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

void _semMovimento(WidgetTester tester) {
  tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(
    tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
  );
}

void main() {
  group('o momento do dia', () {
    test('cada faixa de hora tem o seu período', () {
      expect(periodoDe(DateTime(2026, 8, 27, 6)), PeriodoDoDia.amanhecer);
      expect(periodoDe(DateTime(2026, 8, 27, 12)), PeriodoDoDia.dia);
      expect(periodoDe(DateTime(2026, 8, 27, 18)), PeriodoDoDia.entardecer);
      expect(periodoDe(DateTime(2026, 8, 27, 22)), PeriodoDoDia.noite);
      expect(periodoDe(DateTime(2026, 8, 27, 3)), PeriodoDoDia.noite);
    });

    test('cada período tem uma luz distinta', () {
      final luzes = PeriodoDoDia.values.map(LuzDaCena.de).toList();
      final ceus = luzes.map((l) => l.ceuAlto).toSet();
      final aguas = luzes.map((l) => l.agua).toSet();
      expect(ceus.length, 4, reason: 'céus repetidos entre períodos');
      expect(aguas.length, 4, reason: 'águas repetidas entre períodos');
    });

    test('a noite é mais escura que o dia', () {
      final dia = LuzDaCena.de(PeriodoDoDia.dia);
      final noite = LuzDaCena.de(PeriodoDoDia.noite);
      expect(
        noite.ceuAlto.computeLuminance(),
        lessThan(dia.ceuAlto.computeLuminance()),
      );
      expect(
        noite.agua.computeLuminance(),
        lessThan(dia.agua.computeLuminance()),
      );
    });
  });

  testWidgets('a cena das 22h não é a mesma das 9h', (tester) async {
    _semMovimento(tester); // isola a hora da deriva contínua

    await tester.pumpWidget(
      _cena(_estado(), agora: DateTime(2026, 8, 27, 9)),
    );
    await tester.pump();
    final deDia = await _quadro(tester);

    await tester.pumpWidget(
      _cena(_estado(), agora: DateTime(2026, 8, 27, 22)),
    );
    await tester.pump();
    final deNoite = await _quadro(tester);

    expect(
      _mudou(deDia, deNoite),
      isTrue,
      reason: 'o habitat às 22h não pode ser idêntico ao das 9h',
    );
  });

  testWidgets('as quatro luzes do dia dão quatro cenas diferentes',
      (tester) async {
    _semMovimento(tester);
    final quadros = <Uint8List>[];
    for (final hora in [6, 12, 18, 22]) {
      await tester.pumpWidget(
        _cena(_estado(), agora: DateTime(2026, 8, 27, hora)),
      );
      await tester.pump();
      quadros.add(await _quadro(tester));
    }
    for (var i = 0; i < quadros.length; i++) {
      for (var j = i + 1; j < quadros.length; j++) {
        expect(
          _mudou(quadros[i], quadros[j]),
          isTrue,
          reason: 'as cenas $i e $j saíram iguais',
        );
      }
    }
  });

  testWidgets('a cena tem vida própria: as camadas derivam', (tester) async {
    final app = _estado();
    await tester.pumpWidget(_cena(app, agora: DateTime(2026, 8, 27, 12)));
    await tester.pump();

    final antes = await _quadro(tester);
    await tester.pump(const Duration(seconds: 3));
    final depois = await _quadro(tester);

    expect(_mudou(antes, depois), isTrue);
  });

  testWidgets('movimento reduzido deixa a cena quieta', (tester) async {
    _semMovimento(tester);
    final app = _estado();
    await tester.pumpWidget(
      _cena(app, agora: DateTime(2026, 8, 27, 12), animado: false),
    );
    await tester.pump();

    final antes = await _quadro(tester);
    await tester.pump(const Duration(seconds: 3));
    final depois = await _quadro(tester);

    expect(_mudou(antes, depois), isFalse);
  });

  testWidgets('comprar um item muda a cena de forma inequívoca',
      (tester) async {
    _semMovimento(tester);
    final app = _estado()..leaves = 500;
    await tester.pumpWidget(
      _cena(app, agora: DateTime(2026, 8, 27, 12), animado: false),
    );
    await tester.pump();
    final vazio = await _quadro(tester);

    app.buy(shopItems.firstWhere((i) => i.id == 'bridge'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200)); // chegada completa
    final comPonte = await _quadro(tester);

    expect(
      _mudou(vazio, comPonte),
      isTrue,
      reason: 'comprar é a única ação que muda a cena — ela tem de mudar',
    );
  });

  testWidgets('o item comprado chega animado, não aparece de uma vez',
      (tester) async {
    final app = _estado()..leaves = 500;
    await tester.pumpWidget(_cena(app, agora: DateTime(2026, 8, 27, 12)));
    await tester.pump();

    app.buy(shopItems.firstWhere((i) => i.id == 'bridge'));
    await tester.pump(); // t0 do ticker
    await tester.pump(const Duration(milliseconds: 120));
    final chegando = await _quadro(tester);
    await tester.pump(const Duration(milliseconds: 300));
    final maisPerto = await _quadro(tester);

    expect(
      _mudou(chegando, maisPerto),
      isTrue,
      reason: 'a peça tem de estar em movimento durante a chegada',
    );
  });
}
