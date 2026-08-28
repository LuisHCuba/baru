import 'package:baru_app/data/progressao.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/data/descanso_retencao.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Economia de folhas — contrato de produto §5.
///
/// Regra central que se aplica a tudo aqui: o usuário **nunca perde folhas**.
/// Qualquer teste que exija saldo caindo está errado por definição.
AppState _pronto({
  required bool usageAccess,
  required int usage,
  int goal = 150,
  int leaves = 0,
  List<String>? mensagens,
}) {
  final s = AppState(onUserMessage: mensagens?.add);
  s.startCompanionship();
  s.usageAccess = usageAccess;
  s.usage = usage;
  s.goal = goal;
  s.leaves = leaves;
  return s;
}

void main() {
  group('recompensa por sessão', () {
    test('segue a tabela do contrato', () {
      expect(sessionReward(25), 10);
      expect(sessionReward(50), 25);
      expect(sessionReward(90), 50);
    });

    test('duração livre é floor(min * 0,5)', () {
      expect(sessionReward(45), 22);
      expect(sessionReward(30), 15);
      expect(sessionReward(1), 0);
    });
  });

  group('bônus de fechar abaixo da meta', () {
    test('credita +15 na virada do dia', () {
      final s = _pronto(usageAccess: true, usage: 96, goal: 150, leaves: 40);
      s.nextDay();
      // O primeiro dia abaixo da meta também destrava um marco da trilha, e o
      // prêmio dele cai junto.
      final marco = trilha.firstWhere((m) => m.id == 'primeiro_dia_abaixo');
      expect(
        s.leaves,
        40 + AppState.underGoalBonus + marco.recompensa.folhas,
      );
    });

    test('não credita se o dia fechou acima da meta', () {
      final s = _pronto(usageAccess: true, usage: 200, goal: 150, leaves: 40);
      s.nextDay();
      expect(s.leaves, 40);
    });

    test('não credita em cima da meta — a regra é abaixo', () {
      final s = _pronto(usageAccess: true, usage: 150, goal: 150, leaves: 40);
      s.nextDay();
      expect(s.leaves, 40);
    });

    test('sem permissão de uso não há bônus: não há o que medir', () {
      final s = _pronto(usageAccess: false, usage: 0, goal: 150, leaves: 40);
      s.nextDay();
      expect(s.leaves, 40);
    });

    test('não credita antes do onboarding terminar', () {
      final s = AppState()
        ..usageAccess = true
        ..usage = 10
        ..goal = 150
        ..leaves = 0;
      expect(s.companionshipStarted, isFalse);
      s.nextDay();
      expect(s.leaves, 0);
    });

    test('ausência longa paga no máximo um bônus, não um por dia', () {
      final s = _pronto(usageAccess: true, usage: 20, goal: 150, leaves: 0);
      s.lastOpenDate = dateOnly(
        DateTime.now().subtract(const Duration(days: 12)),
      );
      s.applyCalendar(DateTime.now());
      final marco = trilha.firstWhere((m) => m.id == 'primeiro_dia_abaixo');
      // O presente de retorno (RD-03) entra aqui também: doze dias fora
      // atravessam a régua dele. Somá-lo mantém a asserção sobre o que este
      // teste existe para proteger — o bônus da meta é pago **uma vez**, e
      // não um por dia de ausência.
      final volta = avaliaVolta(
        diasFora: 11,
        hoje: dateOnly(DateTime.now()),
        jaCreditadas: const {},
      );
      expect(
        s.leaves,
        AppState.underGoalBonus +
            marco.recompensa.folhas +
            (volta?.folhas ?? 0),
        reason: 'dias sem o app têm usage sintético em 0 — pagar por eles '
            'seria inventar medição; só o primeiro conta, e ele destrava o '
            'marco da trilha uma única vez',
      );
    });

    test('caminho real: snapshot de ontem credita ao abrir o app', () {
      final ontem = dateOnly(DateTime.now().subtract(const Duration(days: 1)));
      final base = _pronto(usageAccess: true, usage: 60, goal: 150, leaves: 25);
      final snap = base.toSnapshot();

      final avisos = <String>[];
      final aoAbrir = AppState(
        snapshot: snap.copyWith(lastOpenDate: ontem),
        onUserMessage: avisos.add,
      );

      final marco = trilha.firstWhere((m) => m.id == 'primeiro_dia_abaixo');
      expect(
        aoAbrir.leaves,
        25 + AppState.underGoalBonus + marco.recompensa.folhas,
      );
      expect(avisos, isEmpty, reason: 'ainda não há árvore de widgets');
      aoAbrir.flushPendingNotices();
      expect(avisos.length, 1, reason: 'o aviso sai no primeiro frame');
    });

    test('o aviso sai uma vez e some depois de mostrado', () {
      final avisos = <String>[];
      final s = _pronto(
        usageAccess: true,
        usage: 20,
        goal: 150,
        mensagens: avisos,
      );
      s.nextDay();
      s.flushPendingNotices();
      s.flushPendingNotices();
      expect(avisos.length, 1);
      expect(avisos.single, contains('${AppState.underGoalBonus}'));
    });

    test('o aviso sai no idioma do usuário', () {
      for (final lang in ['pt', 'en', 'es', 'zh']) {
        final avisos = <String>[];
        final s = _pronto(
          usageAccess: true,
          usage: 20,
          goal: 150,
          mensagens: avisos,
        )..lang = lang;
        s.nextDay();
        s.flushPendingNotices();
        expect(avisos.single, isNotEmpty, reason: 'aviso vazio em $lang');
        expect(
          avisos.single,
          isNot(contains('{k}')),
          reason: 'placeholder cru em $lang',
        );
      }
    });
  });

  group('loja', () {
    test('comprar desconta o preço e entrega o item', () {
      final s = _pronto(usageAccess: false, usage: 0, leaves: 100);
      final lily = shopItems.firstWhere((i) => i.id == 'lily');
      s.buy(lily);
      expect(s.leaves, 100 - lily.price);
      expect(s.owned, contains('lily'));
    });

    test('sem folhas suficientes nada acontece — sem saldo negativo', () {
      final s = _pronto(usageAccess: false, usage: 0, leaves: 10);
      final bridge = shopItems.firstWhere((i) => i.id == 'bridge');
      s.buy(bridge);
      expect(s.leaves, 10);
      expect(s.owned, isEmpty);
    });

    test('comprar duas vezes não cobra duas vezes', () {
      final s = _pronto(usageAccess: false, usage: 0, leaves: 100);
      final lily = shopItems.firstWhere((i) => i.id == 'lily');
      s.buy(lily);
      final depois = s.leaves;
      s.buy(lily);
      expect(s.leaves, depois);
      expect(s.owned.where((i) => i == 'lily').length, 1);
    });
  });

  group('sem punição', () {
    test('abandonar não tira folhas nem itens', () {
      final s = _pronto(usageAccess: true, usage: 20, leaves: 80)
        ..owned = ['lily', 'dock'];
      s.startSession();
      s.abandon();
      expect(s.leaves, 80);
      expect(s.owned, ['lily', 'dock']);
      expect(s.reward, 0);
    });

    test('um dia acima da meta não tira folhas', () {
      final s = _pronto(usageAccess: true, usage: 400, goal: 150, leaves: 80);
      s.nextDay();
      expect(s.leaves, 80);
    });

    test('faltar um dia não tira folhas nem itens', () {
      final s = _pronto(usageAccess: false, usage: 0, leaves: 80)
        ..owned = ['lily'];
      s.completedToday = 0;
      s.nextDay();
      s.nextDay();
      s.nextDay();
      expect(s.leaves, 80);
      expect(s.owned, ['lily']);
    });
  });

  group('meta e nível', () {
    test('meta sugerida é 25% abaixo da média, em passos de 15 min', () {
      expect(suggestedGoal(240), 180);
      expect(suggestedGoal(180), 135);
      expect(suggestedGoal(300), 225);
      expect(suggestedGoal(360), 270);
    });

    test('nível do habitat é 1 + itens/3', () {
      int nivel(int itens) => 1 + itens ~/ 3;
      expect(nivel(0), 1);
      expect(nivel(2), 1);
      expect(nivel(3), 2);
      expect(nivel(8), 3);
    });

    test('os preços dos objetos de cena são os do contrato', () {
      // A loja ganhou roupas, cenários e uma segunda leva de objetos de
      // cena; a curva dos **oito do contrato** não pode ter mudado junto.
      // Por isso a lista é fixada por id e não pela ordem de `itensDeCena`,
      // que agora tem mais gente dentro.
      const doContrato = [
        'lily',
        'bamboo',
        'rock',
        'dock',
        'lantern',
        'tree',
        'boat',
        'bridge',
      ];
      expect(
        [for (final id in doContrato) itemPorId(id)!.price],
        [40, 70, 110, 150, 190, 240, 300, 400],
      );

      // E as pontas da curva continuam sendo as do contrato: nenhum item
      // novo pode ser mais barato que a primeira compra da vida do usuário
      // nem mais caro que a ponte, que é o prêmio do fim.
      final precos = itensDeCena.map((i) => i.price);
      expect(precos.reduce((a, b) => a < b ? a : b), 40);
      expect(precos.reduce((a, b) => a > b ? a : b), 400);
    });

    test('roupa é mais barata que objeto de cena, e cenário é mais caro', () {
      // Roupa é o que se troca todo dia; objeto de cena é conquista; cenário
      // é o mundo. A curva tem de refletir isso ou a loja não tem ritmo.
      final roupas = shopItems
          .where((i) => i.categoria == CategoriaDeItem.roupa)
          .map((i) => i.price);
      final cenarios = shopItems
          .where((i) => i.categoria == CategoriaDeItem.cenario)
          .map((i) => i.price);
      expect(roupas.reduce((a, b) => a > b ? a : b), lessThan(150));
      expect(cenarios.reduce((a, b) => a < b ? a : b), greaterThanOrEqualTo(200));
    });

    test('nenhum item é de graça', () {
      for (final i in shopItems) {
        expect(i.price, greaterThan(0), reason: i.id);
      }
    });
  });
}
