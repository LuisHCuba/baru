import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Humor, atividade e quiz — contrato de produto §3 e §4.
///
/// A tabela do contrato, em ordem estrita:
///   missing_you > radiant > content > neutral > sleepy

AppState _pet({
  bool usageAccess = true,
  int usage = 0,
  int goal = 100,
  int completedToday = 0,
  bool abandonedToday = false,
  int daysAway = 0,
}) {
  final s = AppState();
  s.startCompanionship();
  s.usageAccess = usageAccess;
  s.usage = usage;
  s.goal = goal;
  s.completedToday = completedToday;
  s.abandonedToday = abandonedToday;
  s.daysAway = daysAway;
  return s;
}

void main() {
  group('a tabela de humor do contrato', () {
    test('missing_you: abandonou uma sessão hoje', () {
      expect(_pet(abandonedToday: true).mood, Mood.missingYou);
    });

    test('missing_you: dois dias ou mais sem abrir', () {
      expect(_pet(daysAway: 2).mood, Mood.missingYou);
      expect(_pet(daysAway: 9).mood, Mood.missingYou);
      expect(_pet(daysAway: 1).mood, isNot(Mood.missingYou));
    });

    test('radiant: abaixo da meta E uma sessão completa', () {
      expect(_pet(usage: 50, goal: 100, completedToday: 1).mood, Mood.radiant);
    });

    test('content: abaixo da meta, sem sessão', () {
      expect(_pet(usage: 50, goal: 100).mood, Mood.content);
    });

    test('content: acima da meta, mas com sessão', () {
      expect(_pet(usage: 300, goal: 100, completedToday: 1).mood, Mood.content);
    });

    test('neutral: até 20% acima da meta, sem sessão', () {
      expect(_pet(usage: 100, goal: 100).mood, Mood.neutral);
      expect(_pet(usage: 120, goal: 100).mood, Mood.neutral);
    });

    test('sleepy: mais de 20% acima da meta, sem sessão', () {
      expect(_pet(usage: 121, goal: 100).mood, Mood.sleepy);
      expect(_pet(usage: 900, goal: 100).mood, Mood.sleepy);
    });
  });

  group('a precedência é estrita', () {
    test('missing_you ganha de radiant', () {
      final s = _pet(usage: 10, goal: 100, completedToday: 1)
        ..abandonedToday = true;
      expect(s.mood, Mood.missingYou);
    });

    test('missing_you ganha até de sleepy', () {
      expect(_pet(usage: 900, goal: 100, daysAway: 3).mood, Mood.missingYou);
    });

    test('radiant ganha de content quando as duas condições valem', () {
      expect(_pet(usage: 10, goal: 100, completedToday: 1).mood, Mood.radiant);
    });
  });

  group('recusar a permissão é caminho suportado, não degradado', () {
    test('sem permissão o humor vem só das sessões', () {
      expect(_pet(usageAccess: false, usage: 9999).mood, Mood.content);
      expect(
        _pet(usageAccess: false, usage: 9999, completedToday: 1).mood,
        Mood.radiant,
      );
    });

    test('sem permissão o pet nunca fica sleepy nem neutral', () {
      for (final uso in [0, 100, 500, 9999]) {
        final humor = _pet(usageAccess: false, usage: uso, goal: 100).mood;
        expect(humor, isNot(Mood.sleepy), reason: 'uso $uso');
        expect(humor, isNot(Mood.neutral), reason: 'uso $uso');
      }
    });

    test('mas ainda pode sentir falta', () {
      expect(_pet(usageAccess: false, daysAway: 3).mood, Mood.missingYou);
    });
  });

  group('atividade derivada do humor', () {
    test('o mapa do contrato', () {
      final esperado = {
        Mood.sleepy: Activity.nap,
        Mood.neutral: Activity.nap,
        Mood.radiant: Activity.swim,
        Mood.content: Activity.graze,
        Mood.missingYou: Activity.idle,
      };
      for (final entrada in esperado.entries) {
        final s = _pet()..overrideMood = entrada.key;
        expect(s.activity, entrada.value, reason: entrada.key.name);
      }
    });

    test('todo humor tem atividade e legenda nos 4 idiomas', () {
      for (final humor in Mood.values) {
        for (final lang in ['pt', 'en', 'es', 'zh']) {
          final s = _pet()
            ..overrideMood = humor
            ..lang = lang;
          expect(s.activity, isNotNull);
          expect(s.t.moodCap(s.moodKey), isNotEmpty, reason: '$humor/$lang');
          expect(s.t.moodSub(s.moodKey), isNotEmpty, reason: '$humor/$lang');
        }
      }
    });
  });

  group('quiz do animal interior', () {
    Species responde(int opcao) {
      final s = AppState();
      for (var q = 0; q < 3; q++) {
        s.pickQuiz(q, s.t.quizO[q][opcao]);
      }
      return s.resolveSpecies();
    }

    test('cada coluna de respostas leva a uma espécie estável', () {
      expect(responde(0), Species.capybara);
      expect(responde(1), Species.otter);
      expect(responde(2), Species.owl);
      expect(responde(3), Species.tortoise);
    });

    test('as quatro espécies do quiz são alcançáveis', () {
      // O quiz decide **quem você é** entre as quatro de origem. As outras
      // quatro se conquistam na trilha e nunca saem daqui.
      final alcancadas = {for (var i = 0; i < 4; i++) responde(i)};
      expect(alcancadas, {
        Species.capybara,
        Species.otter,
        Species.tortoise,
        Species.owl,
      });
    });

    test('o quiz nunca devolve uma espécie que se conquista', () {
      const daTrilha = {
        Species.axolotl,
        Species.penguin,
        Species.cat,
        Species.fox,
      };
      for (var i = 0; i < 4; i++) {
        expect(daTrilha.contains(responde(i)), isFalse);
      }
    });

    test('o resultado é o mesmo nos 4 idiomas', () {
      for (var opcao = 0; opcao < 4; opcao++) {
        final especies = <Species>{};
        for (final lang in ['pt', 'en', 'es', 'zh']) {
          final s = AppState()..lang = lang;
          for (var q = 0; q < 3; q++) {
            s.pickQuiz(q, s.t.quizO[q][opcao]);
          }
          especies.add(s.resolveSpecies());
        }
        expect(
          especies.length,
          1,
          reason: 'opção $opcao deu espécies diferentes por idioma: $especies',
        );
      }
    });

    test('trocar de idioma no passo do quiz limpa as respostas', () {
      // As respostas são guardadas como rótulos traduzidos, então manter as
      // antigas depois de trocar o idioma quebraria a correspondência.
      final s = AppState()
        ..go(AppScreen.onb)
        ..onb = 2;
      s.pickQuiz(0, s.t.quizO[0][1]);
      expect(s.q0, isNotNull);

      s.setLang('en');

      expect(s.q0, isNull);
      expect(s.quizDone, isFalse);
    });

    test('o quiz só termina com as três respostas', () {
      final s = AppState();
      expect(s.quizDone, isFalse);
      s.pickQuiz(0, s.t.quizO[0][0]);
      s.pickQuiz(1, s.t.quizO[1][0]);
      expect(s.quizDone, isFalse);
      s.pickQuiz(2, s.t.quizO[2][0]);
      expect(s.quizDone, isTrue);
    });
  });

  group('nome e espécie do pet', () {
    test('cada espécie tem o nome padrão do contrato', () {
      expect(petNames[Species.capybara], 'Baru');
      expect(petNames[Species.otter], 'Rio');
      expect(petNames[Species.tortoise], 'Toco');
      expect(petNames[Species.owl], 'Nina');
    });

    test('trocar de espécie mantém um nome escolhido pelo usuário', () {
      final s = AppState()
        ..species = Species.capybara
        ..setName('Pipoca');
      s.pickSpecies(Species.owl);
      expect(s.displayName, 'Pipoca');
    });

    test('trocar de espécie atualiza um nome que ainda era o padrão', () {
      final s = AppState()
        ..species = Species.capybara
        ..setName('Baru');
      s.pickSpecies(Species.owl);
      expect(s.displayName, 'Nina');
    });

    test('o nome tem teto de 18 caracteres', () {
      final s = AppState()..setName('a' * 40);
      expect(s.petName.length, 18);
    });
  });

  group('formatação de minutos por idioma', () {
    test('pt e es usam min, en usa m, zh usa 分', () {
      expect(fmtMinutes(45, 'pt'), '45min');
      expect(fmtMinutes(45, 'en'), '45m');
      expect(fmtMinutes(45, 'es'), '45min');
      expect(fmtMinutes(45, 'zh'), '45分');
    });

    test('horas cheias não mostram minutos', () {
      expect(fmtMinutes(120, 'pt'), '2h');
      expect(fmtMinutes(120, 'zh'), '2小时');
    });

    test('horas com resto mostram os dois', () {
      expect(fmtMinutes(150, 'pt'), '2h 30min');
      expect(fmtMinutes(150, 'en'), '2h 30m');
      expect(fmtMinutes(150, 'zh'), '2小时30分');
    });
  });
}
