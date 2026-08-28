import 'package:baru_app/l10n.dart';
import 'package:baru_app/screens/sequencia_screen.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/widgets/cartao_da_raiz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// O cartão da raiz, feito para sair do app.
///
/// Compartilhar gera uma **imagem própria**, não uma captura de tela: print
/// leva junto barra de status, hora e bateria, e o que a pessoa quer mostrar
/// é o que ela construiu.

Future<AppState> _abre(WidgetTester tester, {required int raiz}) async {
  tester.view.physicalSize = const Size(412, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final app = AppState()
    ..onb = 9
    ..companionshipStarted = true
    ..streak = raiz;
  addTearDown(app.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppScope(state: app, child: const SequenciaScreen()),
      ),
    ),
  );
  await tester.pump();
  return app;
}

void main() {
  group('o cartão', () {
    testWidgets('mostra o número, a raiz desenhada e o nome do bicho', (
      tester,
    ) async {
      garanteTextosDoCartaoDaRaiz();
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: CartaoDaRaiz(dias: 21, nomeDoPet: 'Coruja', lang: 'pt'),
        ),
      );
      await tester.pump();

      expect(find.text('21'), findsOneWidget);
      expect(find.textContaining('Coruja'), findsOneWidget);
      expect(find.byKey(CartaoDaRaiz.chave), findsOneWidget);
    });

    testWidgets('existe nos quatro idiomas', (tester) async {
      for (final lang in ['pt', 'en', 'es', 'zh']) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CartaoDaRaiz(dias: 7, nomeDoPet: 'Baru', lang: lang),
          ),
        );
        await tester.pump();
        expect(
          find.text(T(lang).raizCartaoTitulo),
          findsOneWidget,
          reason: lang,
        );
      }
    });
  });

  group('o botão na tela da raiz', () {
    testWidgets('aparece quando há raiz', (tester) async {
      final app = await _abre(tester, raiz: 5);
      expect(find.byKey(const Key('raiz-compartilhar')), findsOneWidget);
      expect(find.text(app.t.raizCompartilhar), findsOneWidget);
    });

    testWidgets('não aparece no dia zero', (tester) async {
      // Oferecer o botão sem raiz seria convidar a pessoa a exibir um
      // número que ela ainda não tem.
      await _abre(tester, raiz: 0);
      expect(find.byKey(const Key('raiz-compartilhar')), findsNothing);
    });
  });
}
