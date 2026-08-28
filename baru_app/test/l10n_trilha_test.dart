import 'package:baru_app/l10n_trilha.dart';
import 'package:flutter_test/flutter_test.dart';

/// O catálogo da trilha, sob a mesma regra do §2 que `l10n_test.dart` trava
/// para o catálogo principal.
///
/// O `T.s` de um módulo não estoura quando a chave falta — devolve a própria
/// chave. Isso é bom para a tela abrir, e péssimo para descobrir o buraco: um
/// texto faltando em zh viraria "trilhaFaltaXp" escrito na tela, em silêncio.
/// Por isso a paridade é conferida aqui.

Set<String> _placeholders(String texto) =>
    RegExp(r'\{(\w+)\}').allMatches(texto).map((m) => m[1]!).toSet();

void main() {
  const base = 'pt';
  final pt = textosDaTrilha[base]!;
  final outros = textosDaTrilha.keys.where((l) => l != base);

  test('os 4 idiomas do contrato existem', () {
    expect(textosDaTrilha.keys.toSet(), {'pt', 'en', 'es', 'zh'});
  });

  for (final lang in outros) {
    final m = textosDaTrilha[lang]!;

    test('$lang tem exatamente as mesmas chaves de $base', () {
      expect(
        m.keys.toSet().difference(pt.keys.toSet()),
        isEmpty,
        reason: '$lang tem chave que não existe em $base',
      );
      expect(
        pt.keys.toSet().difference(m.keys.toSet()),
        isEmpty,
        reason: 'chave de $base faltando em $lang — vira a chave crua na tela',
      );
    });

    test('$lang preserva os placeholders de $base', () {
      for (final chave in pt.keys) {
        if (!m.containsKey(chave)) continue;
        expect(
          _placeholders(m[chave]!),
          _placeholders(pt[chave]!),
          reason: 'placeholders divergem em $lang.$chave — a UI mostraria o '
              'token cru ou perderia o valor',
        );
      }
    });

    test('$lang não tem texto vazio', () {
      for (final e in m.entries) {
        expect(e.value.trim(), isNotEmpty, reason: '$lang.${e.key}');
      }
    });
  }
}
