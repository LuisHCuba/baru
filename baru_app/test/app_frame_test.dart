import 'package:baru_app/widgets/app_frame.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A moldura de aparelho existe para o app parecer um celular no Chrome e no
/// desktop. Desenhá-la *dentro* de um celular é o bug: era decidida só pela
/// largura, e um telefone deitado (~850 px) passava do breakpoint.

Widget _app() => const MaterialApp(
      home: AppFrame(child: Scaffold(body: Text('conteúdo'))),
    );

/// O framework confere que as variáveis de debug voltaram ao normal no fim do
/// corpo do teste — antes de qualquer `addTearDown`. Por isso o reset é aqui.
Future<void> _comPlataforma(
  TargetPlatform plataforma,
  Future<void> Function() corpo,
) async {
  debugDefaultTargetPlatformOverride = plataforma;
  try {
    await corpo();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

Future<void> _pump(WidgetTester tester, Size tamanho) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_app());
  await tester.pump();
}

void main() {
  const retrato = Size(412, 892);
  const paisagem = Size(892, 412); // o mesmo aparelho, deitado

  group('em telefone a moldura nunca aparece', () {
    for (final plataforma in [TargetPlatform.android, TargetPlatform.iOS]) {
      testWidgets('${plataforma.name} em retrato', (tester) async {
        await _comPlataforma(plataforma, () async {
          await _pump(tester, retrato);
          expect(find.byKey(AppFrame.molduraKey), findsNothing);
          expect(find.text('conteúdo'), findsOneWidget);
        });
      });

      testWidgets('${plataforma.name} deitado', (tester) async {
        await _comPlataforma(plataforma, () async {
          await _pump(tester, paisagem);
          expect(
            find.byKey(AppFrame.molduraKey),
            findsNothing,
            reason: 'girar o aparelho não pode fazer o app desenhar um bezel '
                'falso em volta de si mesmo',
          );
          expect(find.text('conteúdo'), findsOneWidget);
        });
      });
    }
  });

  group('em desktop a moldura continua fazendo o seu papel', () {
    testWidgets('janela larga mostra a moldura', (tester) async {
      await _comPlataforma(TargetPlatform.macOS, () async {
        await _pump(tester, const Size(1400, 1000));
        expect(find.byKey(AppFrame.molduraKey), findsOneWidget);
      });
    });

    testWidgets('janela estreita dispensa a moldura', (tester) async {
      await _comPlataforma(TargetPlatform.macOS, () async {
        await _pump(tester, const Size(420, 900));
        expect(find.byKey(AppFrame.molduraKey), findsNothing);
      });
    });
  });

  test('a decisão de moldura por plataforma', () {
    try {
      for (final movel in [TargetPlatform.android, TargetPlatform.iOS]) {
        debugDefaultTargetPlatformOverride = movel;
        expect(AppFrame.molduraFazSentido(), isFalse, reason: '${movel.name}');
      }
      for (final mesa in [
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      ]) {
        debugDefaultTargetPlatformOverride = mesa;
        expect(AppFrame.molduraFazSentido(), isTrue, reason: '${mesa.name}');
      }
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
