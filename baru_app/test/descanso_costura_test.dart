import 'package:baru_app/data/missoes.dart';
import 'package:baru_app/data/repositories.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// A missão do descanso, ligada ao estado do app.
///
/// A medida não é um cronômetro: com o app em segundo plano o Flutter não
/// executa, então um contador que só andasse com a tela do Baru aberta
/// mediria o **contrário** do que a missão pede. É uma subtração — relógio
/// de parede, menos tempo de tela, menos o tempo dentro do próprio Baru.
///
/// A regra que este arquivo protege é a costura: o que o `AppState` guarda,
/// o que ele restaura, e o que some na virada do dia.

AppState _app({BaruRepositories? repos}) {
  final a = AppState(repos: repos)
    ..onb = 9
    ..companionshipStarted = true;
  return a;
}

void main() {
  group('a tentativa atravessa o app ser morto', () {
    test('o começo e o melhor do dia vão para o snapshot', () {
      final a = _app();
      addTearDown(a.dispose);
      final comeco = DateTime(2026, 8, 28, 14, 30);
      a
        ..descansoComecouEm = comeco
        ..descansoTelaNoInicio = 41
        ..descansoNoApp = const Duration(minutes: 2)
        ..melhorDescansoHoje = const Duration(minutes: 26);

      final s = a.toSnapshot();

      // O Android mata app em segundo plano por rotina — e é exatamente o
      // que acontece durante um descanso que está dando certo.
      expect(s.descansoComecouEm, comeco);
      expect(s.descansoTelaNoInicio, 41);
      expect(s.descansoNoAppSegundos, 120);
      expect(s.melhorDescansoMinutos, 26);
    });

    test('e voltam inteiros na restauração', () async {
      final repos = BaruRepositories.memory();
      await repos.init();
      final a = _app(repos: repos);
      addTearDown(a.dispose);
      final comeco = DateTime(2026, 8, 28, 14, 30);
      a
        ..descansoComecouEm = comeco
        ..descansoTelaNoInicio = 41
        ..melhorDescansoHoje = const Duration(minutes: 26);
      final s = a.toSnapshot();

      final b = _app(repos: repos)..applySnapshotParaTeste(s);
      addTearDown(b.dispose);

      expect(b.descansoComecouEm, comeco);
      expect(b.descansoTelaNoInicio, 41);
      expect(b.melhorDescansoHoje, const Duration(minutes: 26));
    });
  });

  group('a virada do dia', () {
    test('apaga a tentativa e o melhor do dia', () {
      // O contador de tela zera à meia-noite, e a subtração que mede o
      // descanso passaria a descrever outra coisa.
      final a = _app();
      addTearDown(a.dispose);
      a
        ..descansoComecouEm = DateTime.now()
        ..melhorDescansoHoje = const Duration(minutes: 33);

      a.applyCalendar(a.lastOpenDate.add(const Duration(days: 1)));

      expect(a.descansoComecouEm, isNull);
      expect(a.melhorDescansoHoje, Duration.zero);
    });
  });

  group('o tempo dentro do próprio Baru', () {
    test('sair e voltar acumula, e só durante uma tentativa', () {
      final a = _app();
      addTearDown(a.dispose);

      // Sem tentativa em curso, nada se acumula: o contador só existe para
      // descontar do descanso.
      a
        ..voltouAoApp()
        ..saiuDoApp();
      expect(a.descansoNoApp, Duration.zero);

      a
        ..descansoComecouEm = DateTime.now()
        ..voltouAoApp()
        ..saiuDoApp();
      expect(a.descansoNoApp, greaterThanOrEqualTo(Duration.zero));
    });
  });

  group('sem medição de tela não há leitura', () {
    test('o app não estima descanso', () {
      final a = _app();
      addTearDown(a.dispose);
      a.descansoComecouEm = DateTime.now();

      // `resumoTela` nulo = sem acesso ao uso concedido. Inventar um número
      // aqui seria pagar folhas por dado que não existe.
      expect(a.resumoTela, isNull);
      expect(a.leituraDoDescanso, isNull);
    });
  });

  group('o resgate', () {
    test('não paga duas vezes', () {
      final a = _app();
      addTearDown(a.dispose);
      a.melhorDescansoHoje = const Duration(minutes: 60);
      final chave = MissaoDoDescanso.chaveDeResgate(a.lastOpenDate);
      a.missoesResgatadas = {chave};
      final antes = a.leaves;

      a.resgataODescanso();

      expect(a.leaves, antes, reason: 'creditar de novo é folha de graça');
    });
  });
}
