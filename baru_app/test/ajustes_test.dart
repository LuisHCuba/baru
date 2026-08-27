import 'package:baru_app/l10n.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/theme.dart';
import 'package:flutter_test/flutter_test.dart';

/// Meta editável, horário do relatório e sexo do companheiro.
///
/// Os três eram constantes: a meta vinha de quatro chips fixos, o relatório
/// da noite estava escrito `21` no código, e o app chamava toda companheira
/// de "ele".

void main() {
  group('a meta', () {
    test('sobe e desce em passos, e para nos limites', () {
      final s = AppState()..pickGoal(120);
      s.ajustaMeta(1);
      expect(s.goal, 120 + metaPasso);
      s.ajustaMeta(-2);
      expect(s.goal, 120 - metaPasso);

      s.pickGoal(metaMinima);
      s.ajustaMeta(-5);
      expect(s.goal, metaMinima, reason: 'meta de 5 min não é meta');

      s.pickGoal(metaMaxima);
      s.ajustaMeta(5);
      expect(s.goal, metaMaxima);
      s.dispose();
    });

    test('aceita valores fora dos quatro chips antigos', () {
      final s = AppState()..pickGoal(75);
      expect(s.goal, 75, reason: 'antes só dava 90, 120, 150 ou 180');
      expect(goalOptions.contains(75), isFalse);
      s.dispose();
    });

    test('a meta escolhida sobrevive ao snapshot', () {
      final s = AppState()..pickGoal(255);
      expect(AppState(snapshot: s.toSnapshot()).goal, 255);
      s.dispose();
    });
  });

  group('o horário do relatório', () {
    test('deixa de ser 21h fixo e é guardado', () {
      final s = AppState();
      expect(s.eveningHour, 21, reason: 'o padrão continua o de antes');
      s.setEveningTime(19, 30);
      expect(s.eveningHour, 19);
      expect(s.eveningMinute, 30);

      final volta = AppState(snapshot: s.toSnapshot());
      expect(volta.eveningHour, 19);
      expect(volta.eveningMinute, 30);
      s.dispose();
      volta.dispose();
    });

    test('hora impossível é presa na faixa', () {
      final s = AppState()..setEveningTime(30, 99);
      expect(s.eveningHour, 23);
      expect(s.eveningMinute, 59);
      s.dispose();
    });
  });

  group('o sexo do companheiro', () {
    test('começa não dito e é guardado', () {
      final s = AppState();
      expect(s.sexo, Sexo.naoDito);
      s.setSexo(Sexo.femea);
      expect(AppState(snapshot: s.toSnapshot()).sexo, Sexo.femea);
      s.dispose();
    });

    test('muda o pronome da frase, em pt e es', () {
      for (final lang in ['pt', 'es']) {
        final macho = AppState()
          ..lang = lang
          ..setSexo(Sexo.macho);
        final femea = AppState()
          ..lang = lang
          ..setSexo(Sexo.femea);

        final a = macho.frase(macho.t.moodSub('missing_you'));
        final b = femea.frase(femea.t.moodSub('missing_you'));

        expect(a, isNot(b), reason: 'em $lang isto é gramática, não enfeite');
        expect(a, isNot(contains('{')), reason: lang);
        expect(b, isNot(contains('{')), reason: lang);
        macho.dispose();
        femea.dispose();
      }
    });

    test('nenhum idioma deixa placeholder de pronome na tela', () {
      const chaves = ['content', 'sleepy', 'missing_you'];
      for (final lang in ['pt', 'en', 'es', 'zh']) {
        for (final sexo in Sexo.values) {
          final s = AppState()
            ..lang = lang
            ..setSexo(sexo);
          for (final k in chaves) {
            final texto = s.frase(s.t.moodSub(k));
            expect(texto, isNot(contains('{')), reason: '$lang/$k/${sexo.name}');
            expect(texto.trim(), isNotEmpty);
          }
          expect(s.frase(s.t.vinculoTeto), isNot(contains('{')));
          expect(s.frase(s.t.resLostSub), isNot(contains('{')));
          s.dispose();
        }
      }
    });
  });

  group('as pelagens', () {
    test('cada espécie tem a própria paleta, e nenhuma repete a outra', () {
      final vistas = <Species, List<int>>{};
      for (final e in Species.values) {
        final p = AppColors.coatDe(e);
        expect(p, isNotEmpty);
        vistas[e] = p.map((c) => c.toARGB32()).toList();
      }
      expect(
        vistas[Species.tortoise],
        isNot(vistas[Species.capybara]),
        reason: 'tartaruga marrom não existe',
      );
      expect(vistas[Species.otter], isNot(vistas[Species.owl]));
    });

    test('a tartaruga é verde, não marrom', () {
      for (final c in AppColors.coatDe(Species.tortoise)) {
        expect(
          c.g,
          greaterThan(c.b),
          reason: 'verde tem mais verde que azul',
        );
        expect(
          c.g,
          greaterThanOrEqualTo(c.r - 0.02),
          reason: 'e não pode ter mais vermelho que verde, senão é marrom',
        );
      }
    });

    test('o índice guardado nunca estoura a paleta da espécie', () {
      for (final e in Species.values) {
        for (var i = -3; i < 12; i++) {
          expect(() => AppColors.pelagemDe(e, i), returnsNormally);
        }
      }
    });
  });

  group('a carteira', () {
    test('só monta lançamento do que o app realmente guardou', () {
      final s = AppState()..startCompanionship();
      final snap = s.toSnapshot();
      final t = T('pt');
      expect(t.folhasNota, isNotEmpty, reason: 'a nota de honestidade existe');
      expect(snap.owned, isEmpty);
      s.dispose();
    });
  });
}
