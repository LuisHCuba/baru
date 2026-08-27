import 'package:baru_app/services/notification_service.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

/// A sessão de foco existe fora do app.
///
/// A parte que não dá para testar aqui é a entrega pelo sistema operacional —
/// isso precisa de aparelho. O que **dá** para testar, e é onde os erros
/// moram, é a configuração da notificação e o ciclo de vida dela no estado:
/// se ela é fixa, se conta até o instante certo, e se some quando a sessão
/// acaba.

AndroidNotificationDetails _androidDaSessao(DateTime fim) =>
    BaruNotifications.detalhesDaSessao(
      terminaEm: fim,
      rotuloDesistir: 'Desistir',
    ).android!;

void main() {
  group('como a sessão aparece na barra', () {
    final fim = DateTime(2026, 8, 27, 15, 30);

    test('é fixa: não some ao deslizar nem vira histórico', () {
      final a = _androidDaSessao(fim);
      expect(a.ongoing, isTrue);
      expect(a.autoCancel, isFalse);
    });

    test('a contagem regressiva é desenhada pelo Android', () {
      final a = _androidDaSessao(fim);
      expect(
        a.usesChronometer,
        isTrue,
        reason: 'se fosse o app atualizando, a contagem parava com ele',
      );
      expect(a.chronometerCountDown, isTrue);
      expect(
        a.when,
        fim.millisecondsSinceEpoch,
        reason: 'conta até o fim real da sessão',
      );
    });

    test('é silenciosa: foco não é interrupção', () {
      final a = _androidDaSessao(fim);
      expect(a.playSound, isFalse);
      expect(a.enableVibration, isFalse);
      expect(a.importance, Importance.low);
      expect(a.onlyAlertOnce, isTrue);
    });

    test('traz a ação de desistir', () {
      final a = _androidDaSessao(fim);
      expect(a.actions, isNotNull);
      expect(a.actions!.length, 1);
      expect(a.actions!.single.id, BaruNotifications.acaoDesistir);
      expect(a.actions!.single.title, 'Desistir');
    });

    test('no iOS não estoura banner nem som', () {
      final ios = BaruNotifications.detalhesDaSessao(
        terminaEm: fim,
        rotuloDesistir: 'x',
      ).iOS!;
      expect(ios.presentSound, isFalse);
      expect(ios.presentBanner, isFalse);
    });

    test('usa canal próprio, separado dos lembretes', () {
      expect(_androidDaSessao(fim).channelId, BaruNotifications.canalSessao);
      expect(
        BaruNotifications.canalSessao,
        isNot(BaruNotifications.canalLembretes),
        reason: 'a sessão é silenciosa; os lembretes tocam',
      );
    });

    test('os ids não colidem com os dos lembretes', () {
      final ids = {BaruNotifications.sessaoId, BaruNotifications.sessaoFimId};
      expect(ids.length, 2);
      expect(BaruNotifications.sessaoId, greaterThan(1003));
    });

    test('sessão já vencida não vale anunciar', () {
      final agora = DateTime(2026, 8, 27, 16);
      expect(BaruNotifications.valeAnunciar(fim, agora), isFalse);
      expect(
        BaruNotifications.valeAnunciar(agora.add(const Duration(minutes: 1)), agora),
        isTrue,
      );
    });
  });

  group('o ciclo de vida no estado', () {
    AppState emSessao() {
      final s = AppState()
        ..startCompanionship()
        ..debugFast = false
        ..dur = 25;
      s.startSession();
      return s;
    }

    test('começar uma sessão marca o instante de término', () {
      final s = emSessao();
      expect(s.sessionEndsAt, isNotNull);
      expect(s.sessionEndsAt!.isAfter(DateTime.now()), isTrue);
      s.dispose();
    });

    test('desistir encerra a sessão — nada fica pendente na barra', () {
      final s = emSessao();
      s.abandon();
      expect(
        s.sessionEndsAt,
        isNull,
        reason: 'é o fim nulo que faz o app parar de anunciar a sessão',
      );
      s.dispose();
    });

    test('concluir encerra a sessão', () {
      final s = emSessao();
      s.sessionEndsAt = DateTime.now().subtract(const Duration(seconds: 1));
      s.reconcileSession();
      expect(s.sessionEndsAt, isNull);
      s.dispose();
    });

    test('desistir pela barra age no app, não só some da notificação', () {
      final s = emSessao();
      // O mesmo callback que o app registra no plugin.
      void aoDesistir() {
        if (s.sessionEndsAt != null) s.abandon();
      }

      aoDesistir();
      expect(s.aborted, isTrue);

      // Tocar de novo não faz nada: não há sessão.
      final folhas = s.leaves;
      final sessoes = s.sessions.length;
      aoDesistir();
      expect(s.leaves, folhas);
      expect(s.sessions.length, sessoes, reason: 'nada dispara duas vezes');
      s.dispose();
    });

    test('a copy da notificação existe nos 4 idiomas', () {
      for (final lang in ['pt', 'en', 'es', 'zh']) {
        final s = AppState()..lang = lang;
        final titulo = s.t.fill(s.t.notifSessaoTitulo, {'n': s.displayName});
        final fim = s.t.fill(s.t.notifFimCorpo, {'m': 25, 'k': 10});
        for (final texto in [
          titulo,
          s.t.notifSessaoCorpo,
          s.t.notifSessaoDesistir,
          s.t.notifFimTitulo,
          fim,
        ]) {
          expect(texto, isNotEmpty, reason: lang);
          expect(texto, isNot(contains('{')), reason: lang);
        }
      }
    });
  });
}
