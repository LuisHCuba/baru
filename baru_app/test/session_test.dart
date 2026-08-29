import 'package:baru_app/data/app_snapshot.dart';
import 'package:baru_app/data/progressao.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// A primeira sessão da conta também destrava o primeiro marco da trilha.
int get _premioDoPrimeiroFoco =>
    trilha.firstWhere((m) => m.id == 'primeiro_foco').recompensa.folhas;

/// Sessão de foco — o caminho core do produto.
///
/// A premissa do app é "largue o telefone". Isso significa que a sessão passa
/// a maior parte do tempo com o app em background ou morto: um contador que
/// só anda enquanto a tela está acesa perde exatamente a sessão que deu certo.
/// Quem conta o tempo aqui é o relógio de parede, não o `Timer`.

AppState _base({int leaves = 0, int dur = 25}) {
  final s = AppState();
  s.startCompanionship();
  s.debugFast = false;
  s.leaves = leaves;
  s.dur = dur;
  return s;
}

/// Snapshot de um app que foi morto com uma sessão em andamento.
AppSnapshot _comSessao({
  required DateTime termina,
  int sessionDur = 25,
  int leaves = 0,
  DateTime? ultimaAbertura,
}) {
  final s = _base(leaves: leaves);
  final dia = ultimaAbertura ?? DateTime.now();
  s.lastOpenDate = dateOnly(dia);
  s.todayIndex = weekdayIndex(dia);
  s.week = freshWeek(dia);
  return s.toSnapshot().copyWith(
        sessionStartedAt:
            termina.subtract(Duration(minutes: sessionDur == 0 ? 25 : sessionDur)),
        sessionEndsAt: termina,
        sessionDur: sessionDur,
      );
}

void main() {
  group('a sessão é medida pelo relógio, não por tiques', () {
    test('começar marca o fim em tempo real', () {
      final s = _base(dur: 50);
      final antes = DateTime.now();
      s.startSession();

      expect(s.sessionEndsAt, isNotNull);
      expect(s.sessionDur, 50);
      final segundos = s.sessionEndsAt!.difference(antes).inSeconds;
      expect(segundos, closeTo(50 * 60, 2));
      s.dispose();
    });

    test('o modo debug comprime o relógio, não a contagem', () {
      final s = _base(dur: 25)..debugFast = true;
      final antes = DateTime.now();
      s.startSession();

      final segundos = s.sessionEndsAt!.difference(antes).inSeconds;
      expect(segundos, closeTo(25, 2), reason: '25 min viram 25 s');
      expect(
        s.remaining,
        25 * 60,
        reason: 'a tela continua mostrando 25:00',
      );
      s.dispose();
    });

    test('a sessão em curso vai para o snapshot', () {
      final s = _base(dur: 25);
      s.startSession();
      final snap = s.toSnapshot();

      expect(snap.sessionEndsAt, s.sessionEndsAt);
      expect(snap.sessionDur, 25);
      expect(
        AppSnapshot.fromJson(snap.toJson()).sessionEndsAt,
        isNotNull,
        reason: 'tem de sobreviver à serialização — é o que permite retomar',
      );
      s.dispose();
    });
  });

  group('app morto no meio da sessão', () {
    test('volta para a sessão se ainda houver tempo', () {
      final snap = _comSessao(
        termina: DateTime.now().add(const Duration(minutes: 10)),
      );
      final s = AppState(snapshot: snap)..debugFast = false;

      expect(s.screen, AppScreen.session);
      expect(s.running, isTrue);
      expect(s.remaining, closeTo(600, 5));
      s.dispose();
    });

    test('conclui e paga se o tempo acabou com o app fechado', () {
      final snap = _comSessao(
        termina: DateTime.now().subtract(const Duration(minutes: 3)),
        sessionDur: 50,
        leaves: 10,
      );
      final s = AppState(snapshot: snap);

      expect(
        s.leaves,
        10 + sessionReward(50) + _premioDoPrimeiroFoco,
        reason: 'o usuário cumpriu o tempo longe do telefone, que é o pedido '
            'do app — a sessão conta, e ela é a primeira da trilha',
      );
      expect(s.screen, AppScreen.result);
      expect(s.aborted, isFalse);
      expect(s.completedToday, 1);
      expect(s.sessionEndsAt, isNull, reason: 'não pode pagar duas vezes');
      s.dispose();
    });

    test('reabrir de novo não paga a mesma sessão outra vez', () {
      final snap = _comSessao(
        termina: DateTime.now().subtract(const Duration(minutes: 3)),
        leaves: 10,
      );
      final s = AppState(snapshot: snap);
      final depoisDoCredito = s.leaves;

      final s2 = AppState(snapshot: s.toSnapshot());
      expect(s2.leaves, depoisDoCredito);
      s.dispose();
      s2.dispose();
    });

    test('sessão que terminou ontem conta como presença de ontem', () {
      final ontem = dateOnly(DateTime.now().subtract(const Duration(days: 1)));
      final snap = _comSessao(
        termina: ontem.add(const Duration(hours: 21)),
        ultimaAbertura: ontem,
        leaves: 0,
      );
      final s = AppState(snapshot: snap);

      expect(s.leaves, sessionReward(25) + _premioDoPrimeiroFoco);
      expect(
        s.week[weekdayIndex(ontem)],
        WeekDayKind.present,
        reason: 'a sessão foi de ontem; o dia de ontem fecha presente',
      );
      expect(
        s.screen,
        isNot(AppScreen.result),
        reason: 'tela de resultado sobre um dia que já passou seria estranha',
      );
      expect(s.completedToday, 0, reason: 'hoje começa do zero');
      s.dispose();
    });

    test('snapshot corrompido é descartado em vez de premiado', () {
      final snap = _comSessao(
        termina: DateTime.now().subtract(const Duration(minutes: 3)),
        sessionDur: 0,
        leaves: 10,
      );
      final s = AppState(snapshot: snap);

      expect(s.leaves, 10);
      expect(s.sessionEndsAt, isNull);
      s.dispose();
    });
  });

  group('volta do background', () {
    test('conclui a sessão cujo tempo passou enquanto estava fora', () {
      final s = _base(leaves: 5, dur: 25);
      s.startSession();
      // Simula o tempo passando com o app suspenso.
      s.sessionStartedAt =
          DateTime.now().subtract(const Duration(minutes: 25));
      s.sessionEndsAt = DateTime.now().subtract(const Duration(seconds: 1));

      s.reconcileSession();

      expect(s.leaves, 5 + sessionReward(25) + _premioDoPrimeiroFoco);
      expect(s.screen, AppScreen.result);
      expect(s.running, isFalse);
      s.dispose();
    });

    test('recalcula o restante quando ainda há tempo', () {
      final s = _base(dur: 90);
      s.startSession();
      s.remaining = 999999; // como se o contador tivesse congelado
      s.sessionStartedAt = DateTime.now().subtract(const Duration(minutes: 60));
      s.sessionEndsAt = DateTime.now().add(const Duration(minutes: 30));

      s.reconcileSession();

      expect(s.remaining, closeTo(1800, 5));
      expect(s.running, isTrue);
      s.dispose();
    });

    test('sem sessão em curso não faz nada', () {
      final s = _base(leaves: 40);
      s.reconcileSession();
      expect(s.leaves, 40);
      expect(s.screen, isNot(AppScreen.result));
      s.dispose();
    });
  });

  group('a desistência não custa o dia inteiro', () {
    // O defeito relatado do campo: "quando o pet está triste por uma
    // interrupção, ele não está voltando a ficar bem depois de um intervalo
    // de sucesso". Era verdade — `abandonedToday` só era limpo na virada do
    // dia, e a precedência do humor lia esse campo cru. Parar uma sessão às
    // nove da manhã deixava o bicho triste até a meia-noite por mais que a
    // pessoa focasse depois: punição de dia inteiro, que o contrato §1
    // proíbe ("abandonar uma sessão = sem recompensa, nada mais").
    //
    // O ciclo inteiro passa pelas mesmas chamadas que a tela faz — nada de
    // plantar flag — porque é aí que o defeito morava.
    AppState diaComPermissao() {
      final s = _base(dur: 25);
      s.usageAccess = true;
      s.usage = 10;
      s.goal = 150;
      return s;
    }

    void concluiUmaSessao(AppState s) {
      s.startSession();
      s.sessionEndsAt = DateTime.now().subtract(const Duration(seconds: 1));
      s.reconcileSession();
    }

    test('desistir entristece, e concluir depois traz o bicho de volta', () {
      final s = diaComPermissao();
      expect(s.mood, isNot(Mood.missingYou), reason: 'o dia começou limpo');

      s.startSession();
      s.abandon();
      expect(
        s.mood,
        Mood.missingYou,
        reason: 'parar no meio tem de aparecer na cena — é o que o gesto diz',
      );

      concluiUmaSessao(s);

      expect(
        s.mood,
        isNot(Mood.missingYou),
        reason: 'o intervalo de sucesso devolve o bicho',
      );
      expect(
        s.mood,
        Mood.radiant,
        reason: 'uso abaixo da meta e uma sessão completa: a regra do §3',
      );
      expect(
        s.abandonedToday,
        isTrue,
        reason: 'o fato do dia continua registrado — o que sarou foi o humor, '
            'e o relatório e a sincronização dependem dele',
      );
      s.dispose();
    });

    test('parar de novo depois de concluir entristece de novo', () {
      // O outro lado da regra: a cura não é um perdão de uma vez por dia. O
      // bicho reage ao último gesto, e o próximo foco terminado o traz de
      // volta outra vez.
      final s = diaComPermissao();
      concluiUmaSessao(s);
      expect(s.mood, Mood.radiant);

      s.startSession();
      s.abandon();
      expect(s.mood, Mood.missingYou);

      concluiUmaSessao(s);
      expect(s.mood, Mood.radiant);
      s.dispose();
    });

    test('a ausência de dois dias não é curada por uma sessão', () {
      // A cura é só da desistência. Sumir dois dias é outro fato, ele
      // continua na primeira linha da precedência, e a fala dele diz o
      // número de dias — nada disso muda aqui.
      final s = diaComPermissao();
      s.daysAway = 3;
      concluiUmaSessao(s);
      expect(s.mood, Mood.missingYou);
      s.dispose();
    });
  });

  group('desistir', () {
    test('não deixa sessão fantasma para ser retomada', () {
      final s = _base(leaves: 40);
      s.startSession();
      s.abandon();

      expect(
        s.sessionEndsAt,
        isNull,
        reason: 'é o fim nulo que marca "sem sessão em curso"',
      );

      final s2 = AppState(snapshot: s.toSnapshot());
      expect(s2.screen, isNot(AppScreen.session));
      expect(s2.leaves, 40, reason: 'desistir não tira nem dá folhas');
      s.dispose();
      s2.dispose();
    });

    test('registra a sessão abandonada com a duração real', () {
      final s = _base(dur: 90);
      s.startSession();
      s.dur = 25; // o usuário mexeu no chip depois de começar
      s.abandon();

      expect(s.sessions.last.aborted, isTrue);
      expect(s.sessions.last.reward, 0);
      expect(
        s.sessions.last.dur,
        90,
        reason: 'vale a duração com que a sessão começou',
      );
      s.dispose();
    });
  });

  test('mudar o chip de duração não altera a sessão em andamento', () {
    final s = _base(dur: 25);
    s.startSession();
    final fim = s.sessionEndsAt;

    s.pickDur(90);

    expect(s.sessionEndsAt, fim);
    expect(s.sessionDur, 25);
    s.dispose();
  });
}
