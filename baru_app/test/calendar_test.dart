import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Calendário semanal, streak e congelamento — contrato de produto §7.
///
/// Datas fixas e conhecidas, nunca `DateTime.now()` cru: a semana do Baru é
/// segunda=0 … domingo=6, e um teste que roda em dia diferente do que assume
/// esconde exatamente o bug que estamos travando.
final segunda = DateTime(2026, 8, 24); // weekday 1
final terca = DateTime(2026, 8, 25);
final quarta = DateTime(2026, 8, 26);
final domingo = DateTime(2026, 8, 30); // weekday 7
final segundaSeguinte = DateTime(2026, 8, 31);

AppState _em(DateTime dia, {bool comSessao = true}) {
  final s = AppState();
  s.startCompanionship();
  s.lastOpenDate = dia;
  s.todayIndex = weekdayIndex(dia);
  s.week = freshWeek(dia);
  if (comSessao) s.completedToday = 1;
  return s;
}

void main() {
  test('a base de dias confere com o calendário real', () {
    expect(weekdayIndex(segunda), 0);
    expect(weekdayIndex(quarta), 2);
    expect(weekdayIndex(domingo), 6);
  });

  group('faixa da semana', () {
    test('o dia que fecha com sessão vira presente', () {
      final s = _em(segunda);
      s.applyCalendar(terca);
      expect(s.week[0], WeekDayKind.present);
      expect(s.week[1], WeekDayKind.today);
      expect(s.todayIndex, 1);
    });

    test('a semana zera na virada de domingo para segunda', () {
      // Uso real: abre o app e faz uma sessão todo dia, de segunda a domingo.
      final s = _em(segunda);
      for (var d = terca;
          !d.isAfter(domingo);
          d = d.add(const Duration(days: 1))) {
        s.applyCalendar(d);
        s.completedToday = 1;
      }
      expect(
        s.week.sublist(0, 6),
        everyElement(WeekDayKind.present),
        reason: 'seis dias presentes antes da virada',
      );
      expect(s.week[6], WeekDayKind.today);

      // domingo -> segunda: semana nova
      s.applyCalendar(segundaSeguinte);
      expect(s.todayIndex, 0);
      expect(s.week[0], WeekDayKind.today);
      expect(
        s.week.sublist(1),
        everyElement(WeekDayKind.empty),
        reason: 'a faixa diz "esta semana": marcas da semana passada não podem '
            'sobreviver à virada',
      );
    });

    test('o congelamento recarrega na segunda', () {
      final s = _em(quarta, comSessao: false);
      s.freezesLeft = 1;
      s.applyCalendar(DateTime(2026, 8, 27));
      expect(s.freezesLeft, 0, reason: 'gastou o freeze da semana');
      s.applyCalendar(segundaSeguinte);
      expect(s.freezesLeft, 1, reason: 'recarregou na virada');
    });
  });

  group('todayIndex nunca desanda em relação à data', () {
    test('ausência dentro do teto mantém o índice correto', () {
      final s = _em(segunda);
      final destino = DateTime(2026, 9, 2); // quarta, 9 dias depois
      s.applyCalendar(destino);
      expect(s.todayIndex, weekdayIndex(destino));
      expect(s.week[s.todayIndex], WeekDayKind.today);
    });

    test('ausência acima do teto realinha em vez de ficar à deriva', () {
      final s = _em(segunda);
      final destino = DateTime(2026, 10, 8); // 45 dias depois, quinta
      s.applyCalendar(destino);
      expect(
        s.todayIndex,
        weekdayIndex(destino),
        reason: 'o índice tem de ser o dia da semana real, não '
            'lastOpenDate + passos reconstruídos',
      );
      expect(s.week[s.todayIndex], WeekDayKind.today);
      expect(
        s.week.where((k) => k == WeekDayKind.today).length,
        1,
        reason: 'um único "hoje" na faixa',
      );
    });

    test('snapshot com índice defasado é corrigido ao abrir', () {
      final base = _em(quarta);
      final snap = base.toSnapshot().copyWith(
            lastOpenDate: quarta,
            todayIndex: 5, // veio errado de outro aparelho/fuso
          );
      final s = AppState(snapshot: snap);
      s.applyCalendar(quarta);
      expect(s.todayIndex, weekdayIndex(quarta));
      expect(s.week[weekdayIndex(quarta)], WeekDayKind.today);
      expect(s.week.where((k) => k == WeekDayKind.today).length, 1);
    });
  });

  group('dias sem abrir', () {
    test('abrir todo dia mantém zero', () {
      final s = _em(segunda);
      s.applyCalendar(terca);
      expect(s.daysAway, 0);
    });

    test('abrir duas vezes no mesmo dia mantém zero', () {
      final s = _em(quarta);
      s.applyCalendar(quarta);
      expect(s.daysAway, 0);
    });

    test('pular dois dias aciona missing_you, como manda o contrato', () {
      final s = _em(segunda);
      s.applyCalendar(DateTime(2026, 8, 27)); // 3 dias depois
      expect(s.daysAway, 2);
      expect(s.mood, Mood.missingYou);
    });

    test('um dia pulado ainda não é missing_you', () {
      final s = _em(segunda);
      s.applyCalendar(terca.add(const Duration(days: 1)));
      expect(s.daysAway, 1);
      expect(s.mood, isNot(Mood.missingYou));
    });

    test('ausência de mês conta o mês, não o teto de reconstrução', () {
      final s = _em(segunda);
      s.applyCalendar(DateTime(2026, 10, 8));
      expect(s.daysAway, 44);
      expect(s.mood, Mood.missingYou);
    });
  });

  group('congelamento não é punição', () {
    test('um dia sem sessão gasta freeze e mantém o streak', () {
      final s = _em(quarta, comSessao: false);
      s.streak = 3;
      s.freezesLeft = 1;
      s.applyCalendar(DateTime(2026, 8, 27));
      expect(s.week[weekdayIndex(quarta)], WeekDayKind.frozen);
      expect(s.freezesLeft, 0);
      expect(s.streak, 4);
    });

    test('faltar não tira folhas nem itens em nenhum cenário', () {
      final s = _em(segunda, comSessao: false)
        ..leaves = 120
        ..owned = ['lily', 'rock'];
      s.applyCalendar(DateTime(2026, 10, 8));
      // O que este teste protege é que faltar não **tira** nada. Voltar
      // agora paga um presente de retorno (RD-03), então o número exato
      // deixou de ser a asserção certa: fixá-lo faria o teste falhar por
      // uma recompensa nova em vez de por uma punição, que é o defeito de
      // verdade.
      expect(s.leaves, greaterThanOrEqualTo(120));
      expect(s.owned, ['lily', 'rock']);
    });
  });
}
