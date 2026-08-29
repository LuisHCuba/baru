import 'package:baru_app/data/app_snapshot.dart';
import 'package:baru_app/data/repositories.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/l10n.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('meta é 25% abaixo da média, arredondada em 15 min', () {
    expect(suggestedGoal(240), 180);
    expect(suggestedGoal(180), 135);
  });

  test('recompensa das sessões', () {
    expect(sessionReward(25), 10);
    expect(sessionReward(50), 25);
    expect(sessionReward(90), 50);
    expect(sessionReward(45), 22);
  });

  test('humor: missing_you ganha de radiant enquanto a desistência é a última '
      'coisa que aconteceu', () {
    // A precedência do §3 não mudou; mudou o que conta como "abandonou hoje".
    // Aqui a pessoa concluiu de manhã e parou uma sessão à tarde: o dia tem
    // sessão completa e uso abaixo da meta — a receita do `radiant` — e ainda
    // assim o bicho sente, porque o último gesto foi sair no meio.
    final hoje = dateOnly(DateTime.now());
    final s = AppState();
    s.usageAccess = true;
    s.usage = 10;
    s.goal = 150;
    s.completedToday = 1;
    s.abandonedToday = true;
    s.sessions = [
      SessionRecord(
        id: 'a',
        at: hoje.add(const Duration(hours: 9)),
        dur: 50,
        completed: true,
        aborted: false,
        reward: 25,
      ),
      SessionRecord(
        id: 'b',
        at: hoje.add(const Duration(hours: 14)),
        dur: 25,
        completed: false,
        aborted: true,
        reward: 0,
      ),
    ];
    expect(s.mood, Mood.missingYou);
  });

  test('o primeiro dia é vazio, e nada no app o preenche sozinho', () {
    // A outra metade deste caso conferia que `resetAll()` semeava 165 folhas,
    // 'lily', 'dock' e uma raiz de 4 dias — o retrato do design, não o de
    // ninguém. O método saiu, e com ele a única forma de o app entregar
    // progresso que não mediu. O que sobra é a afirmação que interessa: sair
    // do onboarding não dá nada de presente.
    final s = AppState();
    expect(s.leaves, 0);
    expect(s.owned, isEmpty);
    s.startCompanionship();
    expect(s.leaves, 0);
    expect(s.owned, isEmpty);
    expect(s.streak, 0);
    expect(s.xp, 0);
    expect(s.sessoesConcluidas, 0);
    expect(s.usage, 0);
    expect(s.week.where((d) => d == WeekDayKind.present), isEmpty);
    expect(s.week.where((d) => d == WeekDayKind.frozen), isEmpty);
  });

  test('refazer onboarding troca o animal sem apagar o habitat', () {
    final s = AppState();
    s.startCompanionship();
    s.leaves = 80;
    s.owned = ['lily'];
    s.species = Species.capybara;
    s.restartOnboarding();
    s.onb = 5;
    s.nextOnb();
    expect(s.screen, AppScreen.paywall);
    expect(s.leaves, 80);
    expect(s.owned, ['lily']);
  });

  test('snapshot json ida e volta', () {
    final s = AppState();
    s.lang = 'es';
    s.leaves = 40;
    s.owned = ['lily'];
    s.species = Species.otter;
    final json = s.toSnapshot().toJson();
    final back = AppSnapshot.fromJson(json);
    expect(back.lang, 'es');
    expect(back.leaves, 40);
    expect(back.owned, ['lily']);
    expect(back.species, Species.otter);
  });

  test('repositório em memória persiste', () async {
    final repos = BaruRepositories.memory();
    await repos.init();
    final s = AppState(repos: repos);
    s.setLang('en');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final loaded = await repos.loadSnapshot();
    expect(loaded, isNotNull);
    expect(loaded!.lang, 'en');
  });

  test('streak no singular e freeze no plural', () {
    final s = AppState();
    // Ancorado na chave, não na frase: a contagem passou a se chamar
    // "raiz", e um teste preso ao texto quebra a cada ajuste de copy sem
    // que nada de comportamento tenha mudado.
    s.streak = 1;
    expect(s.streakText, T('pt').streakOne);
    s.streak = 4;
    expect(s.streakText, T('pt').fill(T('pt').streak, {'n': 4}));
    expect(s.t.freezeNote(1), contains('1'));
    expect(s.t.freezeNote(2), contains('2'));
    expect(s.t.freezeNote(2), isNot(contains('congelamento nesta')));
  });

  test('quiz escolhe a espécie pelos pesos do design', () {
    final s = AppState();
    s.pickQuiz('elemento', 'agua');
    s.pickQuiz('clareza', 'madrugada');
    s.pickQuiz('acalma', 'agua_quente');
    expect(s.resolveSpecies(), Species.capybara);
    s.pickQuiz('elemento', 'fogo');
    s.pickQuiz('clareza', 'tarde');
    s.pickQuiz('acalma', 'companhia');
    expect(s.resolveSpecies(), Species.otter);
  });

  test('pickSpecies mantém nome customizado', () {
    final s = AppState();
    s.species = Species.capybara;
    s.petName = 'Zeca';
    s.pickSpecies(Species.otter);
    expect(s.species, Species.otter);
    expect(s.petName, 'Zeca');
    s.petName = 'Rio';
    s.pickSpecies(Species.owl);
    expect(s.petName, 'Nina');
  });

  test('toggleUsageAccess alterna permissão', () {
    final s = AppState();
    s.usageAccess = true;
    s.toggleUsageAccess();
    expect(s.usageAccess, isFalse);
  });

  test('sem acesso ao uso, humor vem só das sessões', () {
    final s = AppState();
    s.usageAccess = false;
    s.usage = 400;
    s.goal = 90;
    s.completedToday = 0;
    expect(s.mood, Mood.content);
    s.completedToday = 1;
    expect(s.mood, Mood.radiant);
  });

  test('dia sem sessão gasta freeze e mantém streak', () {
    // Data fixa: a faixa é indexada pelo dia da semana, então um teste
    // ancorado em "hoje" passaria ou falharia conforme o dia em que roda.
    final quarta = DateTime(2026, 8, 26);
    final s = AppState();
    s.usageAccess = true;
    s.completedToday = 0;
    s.streak = 3;
    s.freezesLeft = 1;
    s.lastOpenDate = quarta;
    s.todayIndex = weekdayIndex(quarta);
    s.week = freshWeek(quarta);
    s.nextDay();
    expect(s.week[weekdayIndex(quarta)], WeekDayKind.frozen);
    expect(s.freezesLeft, 0);
    expect(s.streak, 4);
  });

  test('segunda-feira é índice 0', () {
    expect(weekdayIndex(DateTime(2026, 8, 24)), 0);
    expect(weekdayIndex(DateTime(2026, 8, 26)), 2);
  });

  test('sessão abortada não dá folhas', () {
    final s = AppState();
    s.leaves = 10;
    s.abandon();
    expect(s.leaves, 10);
    expect(s.aborted, isTrue);
    expect(s.abandonedToday, isTrue);
    expect(s.sessions, isNotEmpty);
    expect(s.sessions.last.aborted, isTrue);
  });
}
