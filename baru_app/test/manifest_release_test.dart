import 'dart:io';

import 'package:baru_app/models.dart';
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

  /// O ícone por espécie (ADR-015) é feito de quatro peças que precisam
  /// concordar, e **nenhuma delas é código Dart**: o `activity-alias` no
  /// manifesto, a lista `ESPECIES` no Kotlin, os PNGs por densidade e o XML
  /// do adaptativo.
  ///
  /// Uma espécie nova no `enum` não quebra nada disso em tempo de compilação.
  /// Ela quebra no aparelho de quem escolher o bicho: `trocaIcone` não acha o
  /// nome na lista e devolve `false`, ou acha e liga um `ComponentName` que
  /// não existe. Em qualquer dos dois casos o ícone simplesmente não muda, em
  /// silêncio — e ninguém descobre isso rodando teste de widget.
  group('o ícone de cada espécie tem as quatro peças', () {
    final manifesto = main.readAsStringSync();
    final kotlin =
        File('android/app/src/main/kotlin/com/lhcx/baru_app/MainActivity.kt')
            .readAsStringSync();

    /// A capivara é o mascote e usa o nome sem sufixo, tanto no mipmap
    /// quanto no `ic_launcher.xml`. Ver `_padrao` em `gera_icone_test.dart`.
    String recurso(Species sp) =>
        sp == Species.capybara ? 'ic_launcher' : 'ic_launcher_${sp.name}';

    /// O alias sai do `sp.name` com a inicial em maiúscula — é o que
    /// `MainActivity.trocaIcone` monta com `replaceFirstChar`.
    String alias(Species sp) =>
        '.Icone${sp.name[0].toUpperCase()}${sp.name.substring(1)}';

    for (final sp in Species.values) {
      test(sp.name, () {
        expect(
          manifesto,
          contains('android:name="${alias(sp)}"'),
          reason: 'sem o activity-alias o ícone não troca para ${sp.name}',
        );
        expect(
          manifesto,
          contains('android:icon="@mipmap/${recurso(sp)}"'),
          reason: 'o alias de ${sp.name} aponta para outro mipmap',
        );
        expect(
          kotlin,
          contains('"${sp.name}"'),
          reason: 'ESPECIES no Kotlin não conhece ${sp.name}: `trocaIcone` '
              'devolve false e o ícone fica no bicho anterior',
        );
        expect(
          File('android/app/src/main/res/mipmap-anydpi-v26/'
                  '${recurso(sp)}.xml')
              .existsSync(),
          isTrue,
          reason: 'falta o adaptativo de ${sp.name} — rode '
              '`flutter test --tags icone`',
        );
        // Todas as densidades: faltando uma, o Android escala de outra e o
        // ícone sai serrilhado no aparelho que usa justamente aquela.
        for (final d in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
          expect(
            File('android/app/src/main/res/mipmap-$d/${recurso(sp)}.png')
                .existsSync(),
            isTrue,
            reason: '${sp.name} sem PNG em $d',
          );
          for (final camada in ['ic_frente', 'ic_fundo']) {
            expect(
              File('android/app/src/main/res/mipmap-$d/'
                      '${camada}_${sp.name}.png')
                  .existsSync(),
              isTrue,
              reason: '${sp.name} sem $camada em $d',
            );
          }
        }
      });
    }
  });
}
