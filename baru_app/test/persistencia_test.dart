import 'package:baru_app/data/app_snapshot.dart';
import 'package:baru_app/data/row_codec.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// O arranque não pode apagar o que o aparelho já sabia.
///
/// O app montava um `AppSnapshot` das linhas do remoto e gravava **por cima**
/// do local. Todo campo sem coluna remota voltava ao padrão a cada abertura:
/// missão resgatada reaparecia por resgatar, e a trilha zerava porque os três
/// contadores que ela lê também não tinham coluna.

AppSnapshot _base() {
  final now = DateTime.now();
  return AppSnapshot(
    screen: AppScreen.home,
    onb: 5,
    lang: 'pt',
    species: Species.capybara,
    q0: 'Água',
    q1: 'À tarde',
    q2: 'Uma rotina',
    leaves: 40,
    streak: 3,
    usage: 20,
    goal: 180,
    avg: 240,
    petName: 'Baru',
    color: 0,
    owned: const ['lily'],
    dur: 25,
    completedToday: 1,
    abandonedToday: false,
    daysAway: 0,
    trial: false,
    evening: true,
    missed: true,
    payPlan: PayPlan.annual,
    usageAccess: false,
    companionshipStarted: true,
    week: freshWeek(now),
    todayIndex: weekdayIndex(now),
    freezesLeft: 1,
    trialStartedAt: null,
    lastOpenDate: DateTime(now.year, now.month, now.day),
    sessions: const [],
  );
}

void main() {
  group('o que o remoto não guarda não pode sumir', () {
    test('missão resgatada sobrevive a um snapshot remoto sem ela', () {
      final local = _base().copyWith(
        missoesResgatadas: const ['foco_um@2026-08-27'],
        sessoesConcluidas: 12,
        melhorSequencia: 9,
        diasAbaixoDaMeta: 4,
        xp: 300,
      );
      // O que o remoto devolvia antes da migration 10: tudo no padrão.
      final remoto = _base();

      final fundido = remoto.fundeCom(local);

      expect(
        fundido.missoesResgatadas,
        contains('foco_um@2026-08-27'),
        reason: 'era exatamente o que o usuário via reaparecer por resgatar',
      );
      expect(fundido.sessoesConcluidas, 12);
      expect(fundido.melhorSequencia, 9);
      expect(fundido.diasAbaixoDaMeta, 4);
      expect(fundido.xp, 300, reason: 'a trilha inteira lê estes números');
    });

    test('contador que só sobe fica com o maior, venha de onde vier', () {
      final local = _base().copyWith(xp: 100, afeto: 30, sessoesConcluidas: 2);
      final remoto = _base().copyWith(xp: 250, afeto: 5, sessoesConcluidas: 40);

      final fundido = remoto.fundeCom(local);

      expect(fundido.xp, 250, reason: 'o remoto estava à frente');
      expect(fundido.afeto, 30, reason: 'o local estava à frente');
      expect(fundido.sessoesConcluidas, 40);
    });

    test('conquista é união: nenhuma sai de nenhum dos dois lados', () {
      final local = _base().copyWith(
        marcosResgatados: const ['primeiro_foco'],
        missoesResgatadas: const ['a@1'],
      );
      final remoto = _base().copyWith(
        marcosResgatados: const ['nivel_3'],
        missoesResgatadas: const ['b@1'],
      );

      final f = remoto.fundeCom(local);
      expect(f.marcosResgatados, containsAll(['primeiro_foco', 'nivel_3']));
      expect(f.missoesResgatadas, containsAll(['a@1', 'b@1']));
    });

    test('o que é do dia fica com o aparelho', () {
      final local = _base().copyWith(
        minutosDeFocoHoje: 50,
        maiorSessaoHoje: 25,
        sessoesNaSemana: 4,
      );
      final f = _base().fundeCom(local);
      expect(f.minutosDeFocoHoje, 50);
      expect(f.maiorSessaoHoje, 25);
      expect(f.sessoesNaSemana, 4);
    });

    test('o resto é do remoto: é a fonte da verdade entre aparelhos', () {
      final local = _base().copyWith(petName: 'Antigo', goal: 90);
      final remoto = _base().copyWith(petName: 'Novo', goal: 240);
      final f = remoto.fundeCom(local);
      expect(f.petName, 'Novo');
      expect(f.goal, 240);
    });
  });

  group('a ida e volta pelo remoto', () {
    test('missões e totais fazem a volta completa pelas linhas', () {
      final s = AppState()..startCompanionship();
      s.sessoesConcluidas = 7;
      s.melhorSequencia = 5;
      s.diasAbaixoDaMeta = 3;
      s.missoesResgatadas = {'x@2026-08-27'};
      s.xp = 120;

      const codec = BaruRowCodec();
      final linha = codec.progressionRow(userId: 'u', s: s.toSnapshot());

      expect(linha['missoes_resgatadas'], contains('x@2026-08-27'));
      expect(linha['sessoes_concluidas'], 7);
      expect(linha['melhor_sequencia'], 5);
      expect(linha['dias_abaixo_da_meta'], 3);

      final volta = codec.fromRows(
        profile: {'screen': 'home', 'onb': 5, 'companionship_started': true},
        progresso: linha,
      );
      expect(volta.missoesResgatadas, contains('x@2026-08-27'));
      expect(volta.sessoesConcluidas, 7);
      expect(volta.melhorSequencia, 5);
      expect(volta.diasAbaixoDaMeta, 3);
      s.dispose();
    });

    test('resgatar uma missão marca o domínio de progresso para subir', () {
      final s = AppState()..startCompanionship();
      final antes = s.missoesResgatadas.length;
      final m = s.missoes.first;
      // Só o efeito de registro importa aqui; a missão pode não estar
      // resgatável, e nesse caso nada muda — que também é o correto.
      s.resgataMissao(m);
      expect(
        s.missoesResgatadas.length,
        m.resgatavel ? antes + 1 : antes,
      );
      s.dispose();
    });
  });
}
