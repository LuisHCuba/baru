import 'package:baru_app/data/app_snapshot.dart';
import 'package:baru_app/data/repositories.dart';
import 'package:baru_app/models.dart';
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

  test('humor: missing_you ganha de radiant', () {
    final s = AppState();
    s.usageAccess = true;
    s.usage = 10;
    s.goal = 150;
    s.completedToday = 1;
    s.abandonedToday = true;
    expect(s.mood, Mood.missingYou);
  });

  test('onboarding zera o habitat; snapshot 165 é só reset de debug', () {
    final s = AppState();
    expect(s.leaves, 0);
    expect(s.owned, isEmpty);
    s.startCompanionship();
    expect(s.leaves, 0);
    expect(s.owned, isEmpty);
    s.resetAll();
    expect(s.leaves, 165);
    expect(s.owned, ['lily', 'dock']);
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
    s.streak = 1;
    expect(s.streakText, '1 dia presente');
    s.streak = 4;
    expect(s.streakText, '4 dias presente');
    expect(s.t.freezeNote(1), contains('1'));
    expect(s.t.freezeNote(2), contains('2'));
    expect(s.t.freezeNote(2), isNot(contains('congelamento nesta')));
  });

  test('quiz escolhe a espécie pelos pesos do design', () {
    final s = AppState();
    s.pickQuiz(0, 'Água');
    s.pickQuiz(1, 'De madrugada');
    s.pickQuiz(2, 'Água quente');
    expect(s.resolveSpecies(), Species.capybara);
    s.pickQuiz(0, 'Fogo');
    s.pickQuiz(1, 'À tarde');
    s.pickQuiz(2, 'Boa companhia');
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
    final s = AppState();
    s.usageAccess = true;
    s.completedToday = 0;
    s.streak = 3;
    s.freezesLeft = 1;
    s.todayIndex = 2;
    s.nextDay();
    expect(s.week[2], WeekDayKind.frozen);
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
