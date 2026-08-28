import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// O manifesto que entra no APK de release.
///
/// O template do Flutter declara `INTERNET` apenas em
/// `android/app/src/debug/AndroidManifest.xml` e `.../profile/`, porque é
/// disso que o `flutter run` precisa para o hot reload. O build de release
/// não funde esses dois: entra o `main` e mais nada.
///
/// O efeito é cruel de diagnosticar — o app instala, abre, desenha tudo, e
/// só a rede morre. Foi o que aconteceu com o primeiro APK exportado: "erro
/// de internet" no aparelho, e nada de errado no código Dart.
void main() {
  final main = File('android/app/src/main/AndroidManifest.xml');

  test('o manifesto de release pede INTERNET', () {
    expect(main.existsSync(), isTrue);
    expect(
      main.readAsStringSync(),
      contains('android.permission.INTERNET'),
      reason:
          'sem isto o APK de release instala e toda chamada de rede falha; '
          'o manifesto de debug não entra no release',
    );
  });

  test('toda permissão do debug também está no release', () {
    // Se um dia entrar outra permissão só no debug, a diferença aparece
    // aqui em vez de aparecer no aparelho de alguém.
    final permissao = RegExp(r'android:name="(android\.permission\.[\w.]+)"');
    Set<String> lidas(File f) => !f.existsSync()
        ? <String>{}
        : permissao
              .allMatches(f.readAsStringSync())
              .map((m) => m.group(1)!)
              .toSet();

    final doDebug = lidas(File('android/app/src/debug/AndroidManifest.xml'));
    final doRelease = lidas(main);

    expect(doDebug, isNotEmpty, reason: 'o manifesto de debug sumiu?');
    expect(doDebug.difference(doRelease), isEmpty);
  });
}
