import 'package:baru_app/l10n.dart';
import 'package:baru_app/screens/teste_encerrado_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Na Google Play o app não vende: nada de preço nem convite para assinar.
void main() {
  for (final lang in ['pt', 'en', 'es', 'zh']) {
    testWidgets('fim do teste em $lang: leva ao site, sem vender', (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var site = 0;
      var verificou = 0;
      final t = T(lang);
      await tester.pumpWidget(MaterialApp(
        home: TesteEncerradoScreen(
          lang: lang,
          aoAbrirSite: () => site++,
          aoVerificar: () => verificou++,
          aoSair: () {},
        ),
      ));
      await tester.pump();

      expect(find.text(t.testeFimT), findsOneWidget);
      expect(find.textContaining('R\$'), findsNothing);
      expect(find.textContaining(r'$'), findsNothing);
      await tester.tap(find.text(t.testeFimSite));
      await tester.tap(find.text(t.testeFimVerificar));
      expect((site, verificou), (1, 1));
    });
  }
}
