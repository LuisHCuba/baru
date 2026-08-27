import 'package:baru_app/data/quiz.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// O quiz.
///
/// Ele decide o bicho **e** é a única vez em que o app pergunta algo à
/// pessoa. Uma resposta que não pesa na escolha nem informa nada é pergunta a
/// mais no onboarding — o lugar do app onde se desiste.

void main() {
  group('a forma do quiz', () {
    test('toda pergunta tem quatro opções e id único', () {
      final ids = <String>{};
      for (final p in quiz) {
        expect(p.opcoes.length, 4, reason: p.id);
        expect(ids.add(p.id), isTrue, reason: '${p.id} repetido');
        final opcoes = p.opcoes.map((o) => o.id).toSet();
        expect(opcoes.length, 4, reason: '${p.id} tem opção repetida');
      }
    });

    test('id de opção é único no quiz inteiro, não só dentro da pergunta', () {
      // O id é a chave da tradução. Dois iguais em perguntas diferentes
      // fazem uma mostrar o rótulo da outra — foi o que aconteceu com
      // `companhia`, que existia em "o que te acalma" e em "o que você quer".
      final vistos = <String, String>{};
      for (final p in quiz) {
        for (final o in p.opcoes) {
          expect(
            vistos[o.id],
            isNull,
            reason: '${o.id} está em ${vistos[o.id]} e em ${p.id}',
          );
          vistos[o.id] = p.id;
        }
      }
    });

    test('nenhum id vazou para a tela sem tradução, em nenhum idioma', () {
      for (final lang in ['pt', 'en', 'es', 'zh']) {
        final s = AppState()..lang = lang;
        for (final p in quiz) {
          final titulo = s.t.perguntaDoQuiz(p.id);
          expect(titulo, isNot(p.id), reason: '${p.id}/$lang sem tradução');
          expect(titulo, isNotEmpty, reason: '${p.id}/$lang');
          for (final o in p.opcoes) {
            final rotulo = s.t.opcaoDoQuiz(o.id);
            expect(rotulo, isNot(o.id), reason: '${o.id}/$lang sem tradução');
            expect(rotulo, isNotEmpty, reason: '${o.id}/$lang');
          }
        }
        s.dispose();
      }
    });

    test('toda pergunta serve para alguma coisa', () {
      for (final p in quiz) {
        final pesa = p.opcoes.any((o) => o.peso.isNotEmpty);
        final informa = p.serve != ParaQueServe.escolhaDoBicho;
        expect(
          pesa || informa,
          isTrue,
          reason: '${p.id} não pesa na escolha nem informa nada',
        );
      }
    });

    test('a astrologia saiu; o elemento ficou', () {
      final s = AppState();
      final titulo = s.t.perguntaDoQuiz('elemento').toLowerCase();
      expect(titulo, isNot(contains('signo')));
      expect(
        quiz.first.opcoes.map((o) => o.id),
        containsAll(['agua', 'fogo', 'terra', 'ar']),
      );
      s.dispose();
    });
  });

  group('a escolha do bicho', () {
    test('as quatro de origem são alcançáveis, varrendo tudo', () {
      // Uma coluna uniforme (tudo na opção 2, por exemplo) não prova nada:
      // basta uma combinação existir. São 4^6 = 4096, dá para varrer.
      final contagem = <Species, int>{};
      var total = 0;

      void varre(int i, Map<String, String> acc) {
        if (i == quiz.length) {
          final e = especiePelasRespostas(acc);
          contagem[e] = (contagem[e] ?? 0) + 1;
          total++;
          return;
        }
        for (final o in quiz[i].opcoes) {
          varre(i + 1, {...acc, quiz[i].id: o.id});
        }
      }

      varre(0, {});
      expect(total, 4096);
      expect(contagem.keys.toSet(), {
        Species.capybara,
        Species.otter,
        Species.tortoise,
        Species.owl,
      });

      // Nenhuma pode ser quase impossível: menos de 10% seria uma espécie
      // que ninguém vê.
      for (final e in contagem.entries) {
        expect(
          e.value / total,
          greaterThan(0.10),
          reason: '${e.key.name} sai em só ${e.value} de $total',
        );
        expect(
          e.value / total,
          lessThan(0.45),
          reason: '${e.key.name} domina o quiz',
        );
      }
    });

    test('nunca devolve uma espécie que se conquista na trilha', () {
      const daTrilha = {
        Species.axolotl,
        Species.penguin,
        Species.cat,
        Species.fox,
      };
      for (var i = 0; i < 4; i++) {
        final e = especiePelasRespostas({
          for (final p in quiz) p.id: p.opcoes[i].id,
        });
        expect(daTrilha.contains(e), isFalse);
      }
    });

    test('é determinístico: a mesma resposta dá sempre o mesmo bicho', () {
      final r = {for (final p in quiz) p.id: p.opcoes[2].id};
      final primeiro = especiePelasRespostas(r);
      for (var i = 0; i < 20; i++) {
        expect(especiePelasRespostas(r), primeiro);
      }
    });
  });

  group('trocar de idioma não apaga o que você respondeu', () {
    test('a resposta atravessa os quatro idiomas', () {
      final s = AppState();
      s.pickQuiz('elemento', 'fogo');
      s.pickQuiz('clareza', 'madrugada');
      final antes = s.resolveSpecies();

      for (final lang in ['en', 'es', 'zh', 'pt']) {
        s.setLang(lang);
        expect(
          s.respostasDoQuiz['elemento'],
          'fogo',
          reason: 'em $lang a resposta sumia porque era o rótulo traduzido',
        );
        expect(s.resolveSpecies(), antes);
      }
      s.dispose();
    });
  });

  group('as respostas não são dado morto', () {
    test('quem quer menos tela recebe uma meta mais apertada', () {
      int metaCom(String intencao) {
        final s = AppState()..pickQuiz('quer', intencao);
        final m = metaSugerida(300, fatorDaMeta(s.respostasDoQuiz));
        s.dispose();
        return m;
      }

      expect(metaCom('menos_tela'), lessThan(metaCom('companhia')));
      expect(metaCom('mais_foco'), lessThan(metaCom('uma_rotina')));
    });

    test('a meta sugerida nunca sai da faixa que a tela aceita', () {
      for (final avg in [30, 120, 400, 900]) {
        for (final p in quiz.last.opcoes) {
          final m = metaSugerida(avg, fatorDaMeta({'quer': p.id}));
          expect(m, greaterThanOrEqualTo(metaMinima));
          expect(m, lessThanOrEqualTo(metaMaxima));
        }
      }
    });

    test('o que rouba o foco vira uma lista de suspeitos', () {
      final s = AppState()..pickQuiz('rouba_foco', 'redes');
      expect(s.suspeitosDoQuiz, isNotEmpty);
      expect(s.suspeitosDoQuiz, contains('com.instagram.android'));
      s.dispose();
    });

    test('sem resposta, nenhum suspeito é inventado', () {
      final s = AppState();
      expect(s.suspeitosDoQuiz, isEmpty);
      s.dispose();
    });
  });

  group('o que sobrevive ao fechar o app', () {
    test('as respostas voltam inteiras', () {
      final s = AppState();
      for (final p in quiz) {
        s.pickQuiz(p.id, p.opcoes.first.id);
      }
      expect(s.quizDone, isTrue);
      expect(s.quizRespondidas, quiz.length);

      final volta = AppState(snapshot: s.toSnapshot());
      expect(volta.respostasDoQuiz, s.respostasDoQuiz);
      expect(volta.quizDone, isTrue);
      s.dispose();
      volta.dispose();
    });

    test('o quiz só termina com todas respondidas', () {
      final s = AppState();
      for (var i = 0; i < quiz.length - 1; i++) {
        s.pickQuiz(quiz[i].id, quiz[i].opcoes.first.id);
        expect(s.quizDone, isFalse, reason: 'faltando ${quiz.length - 1 - i}');
      }
      s.pickQuiz(quiz.last.id, quiz.last.opcoes.first.id);
      expect(s.quizDone, isTrue);
      s.dispose();
    });
  });
}
