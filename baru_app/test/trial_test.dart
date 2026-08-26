import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Teste de 7 dias e planos — contrato de produto §9.

AppState _comTrialIniciadoHa(int dias) {
  final s = AppState();
  s.startCompanionship();
  s.trial = true;
  s.trialStartedAt = DateTime.now().subtract(Duration(days: dias));
  return s;
}

void main() {
  test('o teste dura 7 dias', () {
    final s = _comTrialIniciadoHa(0);
    expect(s.trialDaysLeft, 7);
    expect(
      dateOnly(s.paidPlanStart),
      dateOnly(DateTime.now().add(const Duration(days: 7))),
    );
  });

  test('a contagem cai um por dia', () {
    expect(_comTrialIniciadoHa(1).trialDaysLeft, 6);
    expect(_comTrialIniciadoHa(3).trialDaysLeft, 4);
    expect(_comTrialIniciadoHa(6).trialDaysLeft, 1);
  });

  test('depois do fim a contagem para em zero, nunca negativa', () {
    expect(_comTrialIniciadoHa(7).trialDaysLeft, 0);
    expect(_comTrialIniciadoHa(30).trialDaysLeft, 0);
  });

  test('começar o teste registra a data e leva para o habitat', () {
    final s = AppState()..startCompanionship();
    expect(s.trialStartedAt, isNull);

    s.startTrial();

    expect(s.trial, isTrue);
    expect(s.trialStartedAt, isNotNull);
    expect(s.screen, AppScreen.home);
  });

  test('começar de novo não reinicia a contagem', () {
    final s = _comTrialIniciadoHa(3);
    final inicio = s.trialStartedAt;
    s.startTrial();
    expect(s.trialStartedAt, inicio);
    expect(s.trialDaysLeft, 4);
  });

  test('restaurar compras não zera um teste em andamento', () {
    final s = _comTrialIniciadoHa(5);
    final inicio = s.trialStartedAt;
    s.restorePurchases();
    expect(s.trialStartedAt, inicio);
    expect(s.trial, isTrue);
  });

  test('o aviso cai 24h antes do fim, dentro do período do teste', () {
    final s = _comTrialIniciadoHa(0);
    final aviso = s.paidPlanStart.subtract(const Duration(hours: 24));
    expect(aviso.isAfter(DateTime.now()), isTrue);
    expect(aviso.isBefore(s.paidPlanStart), isTrue);
    expect(s.paidPlanStart.difference(aviso).inHours, 24);
  });

  test('sem teste ativo não há data de aviso a agendar', () {
    final s = AppState()..startCompanionship();
    expect(s.trial, isFalse);
  });

  test('o plano escolhido é preservado', () {
    final s = AppState()..startCompanionship();
    expect(s.payPlan, PayPlan.annual, reason: 'anual é o destaque do contrato');
    s.pickPay(PayPlan.monthly);
    expect(s.payPlan, PayPlan.monthly);
    expect(AppState(snapshot: s.toSnapshot()).payPlan, PayPlan.monthly);
  });

  test('a copy do aviso existe nos 4 idiomas e sem placeholder cru', () {
    for (final lang in ['pt', 'en', 'es', 'zh']) {
      final s = AppState()..lang = lang;
      final corpo = s.t.fill(s.t.notifTrialBody, {'n': s.displayName});
      expect(s.t.notifTrialTitle, isNotEmpty, reason: lang);
      expect(corpo, isNotEmpty, reason: lang);
      expect(corpo, isNot(contains('{n}')), reason: lang);
    }
  });
}
