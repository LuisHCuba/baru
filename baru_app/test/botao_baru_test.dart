// O botão único (laudo 03, §4.8 e R-V4): afunda sob o dedo, responde com
// háptico, não aceita toque desabilitado e respeita "reduzir movimento".
import 'package:baru_app/widgets/botao_baru.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget filho, {bool reduzido = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: reduzido),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: SizedBox(width: 300, child: filho)),
      ),
    );

double _topoDaFace(WidgetTester t) =>
    t.getTopLeft(find.byType(AnimatedContainer)).dy;

void main() {
  late List<String> hapticos;

  setUp(() {
    hapticos = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        hapticos.add(call.arguments as String);
      }
      return null;
    });
  });

  testWidgets('afunda sob o dedo e volta, com um toque curto', (t) async {
    var tocou = 0;
    await t.pumpWidget(_app(BotaoBaru(rotulo: 'Focar', aoTocar: () => tocou++)));
    final emCima = _topoDaFace(t);

    final dedo = await t.startGesture(t.getCenter(find.text('Focar')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(_topoDaFace(t) - emCima, 4, reason: 'a face desce até o lábio');

    await dedo.up();
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    expect(_topoDaFace(t), emCima);
    expect(tocou, 1);
    expect(hapticos, ['HapticFeedbackType.lightImpact']);
  });

  testWidgets('desabilitado: sem lábio, sem toque, sem háptico', (t) async {
    var tocou = 0;
    await t.pumpWidget(_app(
      BotaoBaru(rotulo: 'Comprar', aoTocar: () => tocou++, ativo: false),
    ));
    final emCima = _topoDaFace(t);
    await t.tap(find.text('Comprar'));
    await t.pump(const Duration(milliseconds: 200));
    expect(tocou, 0);
    expect(hapticos, isEmpty);
    expect(_topoDaFace(t), emCima);
    final s = t.getSemantics(find.byType(BotaoBaru));
    expect(s.label, 'Comprar');
    expect(s.flagsCollection.isEnabled, isNot(true));
  });

  testWidgets('com "reduzir movimento" o botão não se mexe, só escurece',
      (t) async {
    await t.pumpWidget(_app(
      BotaoBaru(rotulo: 'Focar', aoTocar: () {}),
      reduzido: true,
    ));
    final emCima = _topoDaFace(t);
    final dedo = await t.startGesture(t.getCenter(find.text('Focar')));
    await t.pump(const Duration(milliseconds: 100));
    expect(_topoDaFace(t), emCima);
    await dedo.up();
    await t.pump(const Duration(milliseconds: 200));
  });

  testWidgets('expande na largura, ou fica do tamanho do rótulo', (t) async {
    await t.pumpWidget(_app(BotaoBaru(rotulo: 'Colher', aoTocar: () {})));
    expect(t.getSize(find.byType(BotaoBaru)).width, 300);
    await t.pumpWidget(_app(
      Align(
        alignment: Alignment.centerLeft,
        child: BotaoBaru(rotulo: 'Colher', aoTocar: () {}, expande: false),
      ),
    ));
    expect(t.getSize(find.byType(BotaoBaru)).width, lessThan(200));
  });

  test('cada papel tem face e texto próprios', () {
    final faces = paresDoBotao.values.map((p) => p.$1).toSet();
    // Secundário e destrutivo dividem a face creme; o texto os separa.
    expect(faces.length, PapelDoBotao.values.length - 1);
  });
}
