import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/widgets/habitat.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A presença do bicho na cena (PB-01).
///
/// "O pet está pequeno na tela." Era 0,82 de escala fixa dentro de uma cena de
/// 296 px — o companheiro ocupava pouco mais de 40% da altura do quadro que
/// existe para mostrá-lo. Escala fixa também estava errada por construção:
/// não acompanhava a cena quando ela mudava de tamanho.
///
/// O que se afirma aqui é geometria medida na árvore, não a constante: se
/// alguém trocar a fórmula por outra que devolva um bicho pequeno ou cortado,
/// estes testes caem.

AppState _estado() => AppState()..startCompanionship();

/// Um estado que **chega** a cada humor pela regra do §3 (contrato de produto).
///
/// Escrevia `overrideMood` antes — o campo era a porta dos fundos do painel
/// de depuração e saiu do app. Montar os fatos custa três linhas a mais e
/// vale a pena: a geometria passa a ser medida num bicho que o app poria
/// mesmo naquela pose, e não num humor plantado.
AppState _estadoNoHumor(Mood humor) {
  final s = _estado();
  s.usageAccess = true;
  s.goal = 100;
  switch (humor) {
    case Mood.missingYou:
      s.abandonedToday = true;
    case Mood.radiant:
      s.usage = 50;
      s.completedToday = 1;
    case Mood.content:
      s.usage = 50;
    case Mood.neutral:
      s.usage = 100;
    case Mood.sleepy:
      s.usage = 121;
  }
  expect(s.mood, humor, reason: 'o cenário de ${humor.name} deixou de valer');
  return s;
}

Widget _cena(AppState app, {double? altura, double largura = 372}) {
  return MaterialApp(
    home: Scaffold(
      body: AppScope(
        state: app,
        child: Center(
          child: SizedBox(
            width: largura,
            height: altura,
            child: HabitatScene(
              agora: DateTime(2026, 8, 27, 12),
              animado: false,
            ),
          ),
        ),
      ),
    ),
  );
}

void _semMovimento(WidgetTester tester) {
  tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(
    tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
  );
}

/// O retângulo que o bicho de fato ocupa depois da escala.
///
/// `PetView` desenha numa caixa de 200×150 e aplica `Transform.scale` com
/// âncora no rodapé: o layout não muda, o desenho sim. Medir a caixa crua
/// diria sempre 200×150 e não provaria nada.
Rect _bichoDesenhado(WidgetTester tester) {
  final pet = tester.widget<PetView>(find.byType(PetView));
  final caixa = tester.getRect(find.byType(PetView));
  final w = pet.width * pet.scale;
  final h = pet.height * pet.scale;
  final centro = caixa.center.dx;
  return Rect.fromLTRB(
    centro - w / 2,
    caixa.bottom - h,
    centro + w / 2,
    caixa.bottom,
  );
}

void main() {
  testWidgets('o bicho domina a cena, não divide espaço com ela',
      (tester) async {
    _semMovimento(tester);
    await tester.pumpWidget(_cena(_estado()));
    await tester.pump();

    final cena = tester.getRect(find.byKey(HabitatScene.cenaKey));
    final bicho = _bichoDesenhado(tester);

    expect(
      bicho.height / cena.height,
      greaterThan(0.5),
      reason: 'ele é o produto: menos da metade da altura é o que havia',
    );
    expect(
      bicho.width / cena.width,
      greaterThan(0.6),
      reason: 'largura de sobra em volta é o que fazia parecer miniatura',
    );
  });

  testWidgets('em nenhuma atividade o bicho é cortado pela borda',
      (tester) async {
    _semMovimento(tester);
    // Cada humor põe o bicho numa altura diferente da cena — nadando ele
    // afunda, pastando ele sobe. É subindo que ele encosta no topo.
    final atividades = <Activity>{};
    for (final humor in Mood.values) {
      final app = _estadoNoHumor(humor);
      atividades.add(app.activity);
      await tester.pumpWidget(_cena(app));
      await tester.pump();

      final cena = tester.getRect(find.byKey(HabitatScene.cenaKey));
      final bicho = _bichoDesenhado(tester);
      expect(bicho.top, greaterThanOrEqualTo(cena.top), reason: humor.name);
      expect(bicho.left, greaterThanOrEqualTo(cena.left), reason: humor.name);
      expect(bicho.right, lessThanOrEqualTo(cena.right), reason: humor.name);
    }
    expect(
      atividades,
      Activity.values.toSet(),
      reason: 'os humores do contrato cobrem as quatro atividades',
    );
  });

  testWidgets('em tela estreita ele encolhe junto, sem estourar as bordas',
      (tester) async {
    _semMovimento(tester);
    // 280 px é a largura útil de um aparelho de 320 com as margens da home.
    await tester.pumpWidget(_cena(_estado(), largura: 280));
    await tester.pump();

    final cena = tester.getRect(find.byKey(HabitatScene.cenaKey));
    final bicho = _bichoDesenhado(tester);
    expect(bicho.left, greaterThanOrEqualTo(cena.left));
    expect(bicho.right, lessThanOrEqualTo(cena.right));
    expect(bicho.top, greaterThanOrEqualTo(cena.top));
  });

  testWidgets(
      'a cena espremida num quadro menor desenha na escala daquele quadro',
      (tester) async {
    // A folha de compartilhamento encaixa a cena num `SizedBox(296)`. O
    // `Container` acata a restrição apertada do pai e fica em 296 — mas a
    // escala saía de `widget.height`, que continuava dizendo 372. Resultado:
    // céu, linha d'água e bicho fora do lugar na miniatura e no PNG que sai
    // para os amigos.
    _semMovimento(tester);

    await tester.pumpWidget(_cena(_estado(), altura: 296));
    await tester.pump();
    final espremida = tester.getRect(find.byKey(HabitatScene.cenaKey)).bottom -
        tester.getRect(find.byType(PetView)).bottom;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppScope(
            state: _estado(),
            child: Center(
              child: SizedBox(
                width: 372,
                child: HabitatScene(
                  height: 296,
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
    final declarada = tester.getRect(find.byKey(HabitatScene.cenaKey)).bottom -
        tester.getRect(find.byType(PetView)).bottom;

    expect(
      espremida,
      moreOrLessEquals(declarada, epsilon: 0.5),
      reason: 'o mesmo quadro de 296 px tem de dar o mesmo desenho',
    );
  });
}
