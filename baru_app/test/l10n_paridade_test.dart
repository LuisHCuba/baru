import 'package:baru_app/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

/// Toda frase do catálogo principal existe nos quatro idiomas: chave só em
/// português aparece em português para quem escolheu inglês, espanhol ou
/// chinês.
void main() {
  test('o catálogo principal tem as mesmas chaves nos 4 idiomas', () {
    final pt = T.catalog['pt']!.keys.toSet();
    for (final lang in T.catalog.keys) {
      final chaves = T.catalog[lang]!.keys.toSet();
      expect(pt.difference(chaves), isEmpty, reason: 'faltam em $lang');
      expect(chaves.difference(pt), isEmpty, reason: 'sobram em $lang');
    }
  });

  test('as novas frases da revisão existem nos 4 idiomas', () {
    for (final lang in T.catalog.keys) {
      final t = T(lang);
      expect(t.diasCurtos.length, 7, reason: lang);
      expect(t.s('revealNome'), isNot('revealNome'), reason: lang);
      expect(t.goalNote, contains('{p}'), reason: lang);
    }
  });
}
