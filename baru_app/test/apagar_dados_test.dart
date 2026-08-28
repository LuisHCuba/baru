import 'package:baru_app/data/app_snapshot.dart';
import 'package:baru_app/data/local_store.dart';
import 'package:baru_app/data/quiz.dart';
import 'package:baru_app/data/repositories.dart';
import 'package:baru_app/data/supabase_gateway.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/data/cofre.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Apagar os próprios dados.
///
/// Isto não existia. "Refazer o onboarding" zerava a tela e deixava sessões,
/// folhas e progresso onde estavam — e no navegador, onde o snapshot mora no
/// `localStorage`, limpar o banco não adiantava: o app reenviava tudo na
/// gravação seguinte.

AppState _cheio(BaruRepositories repos) {
  final s = AppState(repos: repos)..startCompanionship();
  s.leaves = 500;
  s.xp = 900;
  s.sessoesConcluidas = 17;
  s.melhorSequencia = 9;
  s.owned = ['lily', 'rock'];
  s.equipados = {'lily'};
  s.missoesResgatadas = {'foco@2026-08-27'};
  s.marcosResgatados = {'primeiro_foco'};
  for (final p in quiz) {
    s.pickQuiz(p.id, p.opcoes.first.id);
  }
  return s;
}

void main() {
  test('a lista de tabelas cobre tudo o que o app escreve', () {
    // Uma tabela nova no push e ausente aqui vira dado que o usuário não
    // consegue apagar.
    expect(BaruSupabase.tabelasDoUsuario, hasLength(15));
    for (final t in const [
      'baru_progression',
      'baru_inventory_items',
      'baru_onboarding_answers',
      'baru_app_categories',
      'baru_sessions',
      'baru_profiles',
    ]) {
      expect(BaruSupabase.tabelasDoUsuario, contains(t));
    }
  });

  test('o snapshot zerado é mesmo um app recém-instalado', () {
    final z = AppSnapshot.zerado(lang: 'es');
    expect(z.leaves, 0);
    expect(z.xp, 0);
    expect(z.sessoesConcluidas, 0);
    expect(z.owned, isEmpty);
    expect(z.equipados, isEmpty);
    expect(z.missoesResgatadas, isEmpty);
    expect(z.marcosResgatados, isEmpty);
    expect(z.respostasDoQuiz, isEmpty);
    expect(z.companionshipStarted, isFalse);
    expect(z.onb, 0);
    expect(
      z.lang,
      'es',
      reason: 'quem apagou não precisa reescolher a língua do aviso',
    );
  });

  group('apagar de verdade', () {
    test('some com tudo do aparelho e volta ao onboarding', () async {
      final repos = BaruRepositories.memory();
      await repos.init();
      final s = _cheio(repos);
      await repos.saveSnapshot(s.toSnapshot());
      expect((await repos.loadSnapshot())!.leaves, 500);

      final erro = await s.apagaMeusDados();

      expect(erro, isNull, reason: 'sem conta, apagar o local é tudo');
      expect(s.leaves, 0);
      expect(s.xp, 0);
      expect(s.sessoesConcluidas, 0);
      expect(s.owned, isEmpty);
      expect(s.equipados, isEmpty);
      expect(s.missoesResgatadas, isEmpty);
      expect(s.respostasDoQuiz, isEmpty);
      expect(s.companionshipStarted, isFalse);
      expect(s.screen, AppScreen.onb);
      expect(s.onb, 0);
      s.dispose();
    });

    test('a credencial lembrada some junto', () async {
      // Apagar tudo e deixar a senha no cofre seria deixar a porta aberta:
      // o próximo a pegar o aparelho entraria com a digital dele.
      final repos = BaruRepositories.memory();
      await repos.init();
      final s = _cheio(repos);
      final cofre = CofreDeMentira(
        const CredencialLembrada(
          email: 'ana@exemplo.com',
          senha: 'sementeDoBaru7',
          comBiometria: true,
        ),
      );
      s.cofre = cofre;

      await s.apagaMeusDados();

      expect(cofre.atual, isNull);
      expect(cofre.apagamentos, greaterThan(0));
      s.dispose();
    });

    test('o que estava gravado no aparelho não volta sozinho', () async {
      final repos = BaruRepositories.memory();
      await repos.init();
      final s = _cheio(repos);
      await repos.saveSnapshot(s.toSnapshot());

      await s.apagaMeusDados();

      // O `fundeCom` faz o local ganhar nos contadores. Se o snapshot antigo
      // sobrevivesse, ele recolocaria tudo na próxima abertura — foi assim
      // que limpar o banco não adiantou nada.
      final depois = await repos.loadSnapshot();
      expect(
        depois?.leaves ?? 0,
        0,
        reason: 'o snapshot antigo tem de sair do disco, não só da memória',
      );
      expect(depois?.sessoesConcluidas ?? 0, 0);
      s.dispose();
    });

    test('apagar não deixa gravação pendente para ressuscitar o dado',
        () async {
      final repos = BaruRepositories.memory();
      await repos.init();
      final s = _cheio(repos);

      await s.apagaMeusDados();
      // Tempo de sobra para qualquer debounce em voo disparar.
      await Future<void>.delayed(const Duration(milliseconds: 900));

      final depois = await repos.loadSnapshot();
      expect(depois?.leaves ?? 0, 0);
      expect(depois?.xp ?? 0, 0);
      s.dispose();
    });
  });

  test('a chave do snapshot é a que se limpa no navegador', () {
    // No web o `shared_preferences` grava em `localStorage` com o prefixo
    // `flutter.`. Quem for limpar à mão precisa do nome certo.
    expect(PrefsSnapshotStore.key, 'baru_snapshot_v1');
  });
}
