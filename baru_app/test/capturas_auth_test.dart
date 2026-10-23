@Tags(['capturas'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:baru_app/data/biometria.dart';
import 'package:baru_app/data/cofre.dart';
import 'package:baru_app/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fotografa as telas de entrada para revisão visual (não é teste de regra).
///
/// `CAPTURAS=1 flutter test test/capturas_auth_test.dart` → build/capturas_auth/
final _ligado = Platform.environment['CAPTURAS'] == '1';
const _fisico = Size(1080, 2340);
const _dpr = 2.625;

Future<void> _salva(WidgetTester tester, String nome) async {
  final b = tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('cap')));
  await tester.runAsync(() async {
    final img = await b.toImage(pixelRatio: _dpr);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/capturas_auth').createSync(recursive: true);
    File('build/capturas_auth/$nome.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
}

Future<void> _abre(WidgetTester tester, {Cofre? cofre}) async {
  tester.view.physicalSize = _fisico;
  tester.view.devicePixelRatio = _dpr;
  tester.view.padding = const FakeViewPadding(top: 24 * _dpr);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(RepaintBoundary(
    key: const Key('cap'),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthScreen(
        lang: 'pt',
        cofre: cofre ?? CofreDeMentira(),
        biometria: BiometriaDeMentira(),
        onAuthenticated: () async {},
      ),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(() async {
    for (final peso in ['Nunito-Regular', 'Nunito-SemiBold', 'Nunito-Bold', 'Nunito-ExtraBold']) {
      await (FontLoader('Nunito')..addFont(rootBundle.load('assets/fonts/$peso.ttf'))).load();
    }
    // Ícones do Material: o teste não traz a fonte, e eles sairiam como quadrados.
    var d = File(Platform.resolvedExecutable).parent;
    while (d.parent.path != d.path && !Directory('${d.path}/bin/cache/artifacts').existsSync()) {
      d = d.parent;
    }
    final icones = File('${d.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (icones.existsSync()) {
      final bytes = icones.readAsBytesSync();
      await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
    }
  });

  testWidgets('captura login', skip: !_ligado, (tester) async {
    await _abre(tester);
    await _salva(tester, '1-login');
  });

  testWidgets('captura cadastro', skip: !_ligado, (tester) async {
    await _abre(tester);
    await tester.tap(find.text('Criar conta').last);
    await tester.pump(const Duration(milliseconds: 300));
    await _salva(tester, '2-cadastro');
  });

  testWidgets('captura desbloqueio', skip: !_ligado, (tester) async {
    await _abre(
      tester,
      cofre: CofreDeMentira(
        const CredencialLembrada(email: 'voce@email.com', senha: 'segredo123', comBiometria: true),
      ),
    );
    await _salva(tester, '3-desbloqueio');
  });
}
