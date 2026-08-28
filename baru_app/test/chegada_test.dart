import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// A chegada do dia ganha cena.
///
/// Abrir o app é o gesto que o Baru mais espera, e passava em silêncio.

AppState _app() {
  final a = AppState()
    ..onb = 9
    ..companionshipStarted = true;
  return a;
}

void main() {
  test('virar o dia marca a chegada para celebrar', () {
    final s = _app();
    addTearDown(s.dispose);
    s.chegadaACelebrar = false;

    s.applyCalendar(s.lastOpenDate.add(const Duration(days: 1)));

    expect(s.chegadaACelebrar, isTrue);
    expect(s.temCelebracaoPendente, isTrue);
  });

  test('abrir de novo no mesmo dia não recomeça a festa', () {
    // Voltar do background não pode virar interrupção.
    final s = _app();
    addTearDown(s.dispose);
    s.applyCalendar(s.lastOpenDate.add(const Duration(days: 1)));
    s.celebrou();
    expect(s.chegadaACelebrar, isFalse);

    s.applyCalendar(s.lastOpenDate);

    expect(s.chegadaACelebrar, isFalse);
  });

  test('quem ainda não tem companheiro não é saudado', () {
    final s = AppState()..onb = 0;
    addTearDown(s.dispose);

    s.applyCalendar(s.lastOpenDate.add(const Duration(days: 1)));

    expect(s.chegadaACelebrar, isFalse);
  });

  test('conquista real vem antes da saudação', () {
    final s = _app();
    addTearDown(s.dispose);
    s.applyCalendar(s.lastOpenDate.add(const Duration(days: 1)));
    s.nivelCelebrado = 0;
    s.xp = 100000;

    expect(s.subiuDeNivel, isTrue);
    s.celebrou();
    expect(
      s.chegadaACelebrar,
      isTrue,
      reason: 'a saudação espera a vez; o nível é a conquista maior',
    );
    s.celebrou();
    expect(s.chegadaACelebrar, isFalse);
  });
}
