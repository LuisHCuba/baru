import 'package:baru_app/l10n.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/theme.dart';
import 'package:flutter_test/flutter_test.dart';

/// O catálogo cobre todas as espécies, e não derruba tela quando não cobre.
///
/// **O defeito que isto trava.** Quatro espécies entraram no `enum` e na
/// migração 12 — axolote, pinguim, gata e raposa — e ninguém escreveu a
/// descrição delas. `t.species(id)` fazia `as List` no que voltava do mapa,
/// e trocar de bicho em Ajustes quebrava a tela inteira com
/// `type 'Null' is not a subtype of type 'List'`.
///
/// Duas coberturas, de propósito: uma exige o conteúdo, a outra garante que
/// a falta de conteúdo nunca mais vire tela vermelha. Texto faltando é
/// defeito de tradução; tela em branco vermelho é defeito de produto.

const _idiomas = ['pt', 'en', 'es', 'zh'];

void main() {
  group('toda espécie tem nome e frase', () {
    for (final lang in _idiomas) {
      test('em $lang', () {
        final t = T(lang);
        for (final sp in Species.values) {
          final d = t.species(sp.name);
          expect(d.length, greaterThanOrEqualTo(2), reason: sp.name);
          expect(d[0], isNotEmpty, reason: '${sp.name}: nome');
          expect(d[1], isNotEmpty, reason: '${sp.name}: frase');
          // O id cru passando por nome seria um texto que aprova no
          // `isNotEmpty` e reprova aos olhos.
          expect(d[0], isNot(sp.name), reason: '${sp.name}: id cru');
        }
      });
    }

    test('e um nome curto, para os seletores', () {
      final t = T('pt');
      for (final sp in Species.values) {
        expect(t.animalName(sp.name), isNot(sp.name), reason: sp.name);
      }
    });
  });

  group('os mapas indexados por espécie', () {
    // Mesma classe do defeito das descrições: `Map<Species, X>` com `!` no
    // fim estoura quando alguém acrescenta uma espécie ao `enum` e esquece
    // o mapa. Aqui a falta aparece na suíte, não na tela de Ajustes.
    test('todo bicho tem nome padrão', () {
      for (final sp in Species.values) {
        expect(petNames[sp], isNotNull, reason: sp.name);
        expect(petNames[sp], isNotEmpty, reason: sp.name);
      }
    });

    test('todo bicho tem paleta de pelagem, com mais de um tom', () {
      for (final sp in Species.values) {
        final paleta = AppColors.coatDe(sp);
        expect(paleta, isNotEmpty, reason: sp.name);
        expect(
          paleta.length,
          greaterThan(1),
          reason: '${sp.name}: um tom só é seletor sem escolha',
        );
      }
    });
  });

  group('chave que falta não derruba a tela', () {
    test('espécie desconhecida devolve algo desenhável', () {
      final d = T('pt').species('unicornio');
      expect(d.length, greaterThanOrEqualTo(2));
      expect(() => d[0], returnsNormally);
    });

    test('humor desconhecido devolve vazio, não estoura', () {
      final t = T('pt');
      expect(t.moodCap('inexistente'), '');
      expect(t.moodSub('inexistente'), '');
      expect(t.moodLbl('inexistente'), '');
    });

    test('os humores de verdade continuam vindo', () {
      final t = T('pt');
      for (final m in ['radiant', 'content', 'neutral', 'sleepy']) {
        expect(t.moodCap(m), isNotEmpty, reason: m);
      }
    });
  });
}
