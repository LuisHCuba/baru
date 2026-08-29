import 'package:baru_app/data/progressao.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// XP, nível e trilha.
///
/// A regra que atravessa tudo aqui: **nada conquistado é retirado**. Nível não
/// cai, marco não se perde, e prêmio de marco é pago uma vez só — pagar duas
/// seria imprimir dinheiro.

AppState _conta() => AppState()..startCompanionship();

void main() {
  group('curva de nível', () {
    test('começa no nível 1 com zero XP', () {
      expect(Balanco.nivelPara(0), 1);
    });

    test('os primeiros níveis são rápidos e depois a curva abre', () {
      final primeiro = Balanco.xpParaSubirDe(1);
      final quinto = Balanco.xpParaSubirDe(5);
      final decimo = Balanco.xpParaSubirDe(10);
      expect(primeiro, lessThan(quinto));
      expect(quinto, lessThan(decimo));
    });

    test('o XP acumulado bate com a soma dos degraus', () {
      var soma = 0;
      for (var n = 1; n <= 8; n++) {
        expect(Balanco.xpAcumuladoPara(n), soma);
        soma += Balanco.xpParaSubirDe(n);
      }
    });

    test('o nível sobe exatamente no XP do degrau', () {
      for (var n = 2; n <= 12; n++) {
        final exato = Balanco.xpAcumuladoPara(n);
        expect(Balanco.nivelPara(exato), n, reason: 'nível $n');
        expect(Balanco.nivelPara(exato - 1), n - 1, reason: 'nível $n - 1 XP');
      }
    });

    test('o progresso no nível vai de 0 a 1 e não estoura', () {
      for (final xp in [0, 5, 39, 40, 41, 200, 5000]) {
        final p = Balanco.progressoNoNivel(xp);
        expect(p, inInclusiveRange(0, 1), reason: 'xp $xp');
      }
    });

    test('há teto: no nível máximo a barra fica cheia', () {
      expect(Balanco.nivelPara(999999), Balanco.nivelMaximo);
      expect(Balanco.progressoNoNivel(999999), 1);
      expect(Balanco.faltaParaProximoNivel(999999), 0);
    });
  });

  group('XP por ação', () {
    test('sessão longa vale mais que a soma de curtas', () {
      expect(Balanco.xpDeSessao(90), greaterThan(Balanco.xpDeSessao(25) * 3));
    });

    test('a tabela do balanceamento é a do contrato', () {
      expect(Balanco.xpDeSessao(25), 12);
      expect(Balanco.xpDeSessao(50), 30);
      expect(Balanco.xpDeSessao(90), 60);
    });
  });

  group('a trilha', () {
    test('os marcos estão em ordem crescente de esforço por tipo', () {
      for (final tipo in TipoDeMarco.values) {
        final alvos =
            trilha.where((m) => m.tipo == tipo).map((m) => m.alvo).toList();
        final ordenado = [...alvos]..sort();
        expect(alvos, ordenado, reason: 'marcos de ${tipo.name} fora de ordem');
      }
    });

    test('todo marco tem id único e alguma recompensa', () {
      final ids = trilha.map((m) => m.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'id repetido');
      for (final m in trilha) {
        expect(m.recompensa.vazia, isFalse, reason: '${m.id} não dá nada');
      }
    });

    test('toda espécie fora da capivara se desbloqueia pela trilha', () {
      // Antes esta era uma lista de sete nomes escrita à mão, e uma lista
      // assim só sabe reclamar do que já existe: acrescentar espécie ao
      // `enum` sem marco nenhum passava por ela sem ruído. Agora o alvo é
      // derivado — **todo** valor do `enum` fora a capivara tem de ser
      // entregue por algum degrau.
      //
      // A capivara fica de fora porque é o piso: é ela que a conta recebe
      // antes do quiz, e o quiz troca a espécie em vez de conquistá-la.
      final porMarco =
          trilha.map((m) => m.recompensa.especie).whereType<Species>().toSet();
      expect(
        porMarco,
        Species.values.toSet()..remove(Species.capybara),
      );
    });

    test('conta nova tem o primeiro marco como próximo passo', () {
      final s = _conta();
      expect(s.proximoMarco?.id, 'primeiro_foco');
      expect(s.nivel, 1);
    });

    test('a espécie do quiz está sempre disponível', () {
      final s = _conta()..species = Species.owl;
      expect(s.especiesLiberadas, contains(Species.owl));
    });

    test('espécie extra só aparece depois do marco', () {
      final s = _conta();
      expect(s.especiesLiberadas.contains(Species.otter), isFalse);
      // A lontra é o passo 7. Cinco sessões cumprem o critério **dele**, mas
      // a corrente ainda precisa dos seis de trás — por isso a conta fecha
      // também o dia abaixo da meta, o nível 3 e os três dias seguidos.
      s.sessoesConcluidas = 5;
      s.diasAbaixoDaMeta = 3;
      s.melhorSequencia = 3;
      s.xp = Balanco.xpAcumuladoPara(3);
      s.ganhaXp(1);
      expect(s.especiesLiberadas.contains(Species.otter), isTrue);
    });

    test('o estágio do habitat sobe com os marcos e nunca desce', () {
      final s = _conta();
      expect(s.estagioDoHabitat, 1);
      // O igarapé é o prêmio do passo 3 (nível 3). Os passos 1 e 2 vêm antes.
      s.sessoesConcluidas = 1;
      s.diasAbaixoDaMeta = 1;
      s.xp = Balanco.xpAcumuladoPara(3);
      s.ganhaXp(0);
      expect(s.estagioDoHabitat, 2);
      // Mesmo perdendo a sequência atual, o estágio permanece.
      s.streak = 0;
      expect(s.estagioDoHabitat, 2);
    });
  });

  group('resgate de marco', () {
    test('alcançar um marco credita as folhas dele', () {
      final s = _conta()..leaves = 0;
      final marco = trilha.firstWhere((m) => m.id == 'primeiro_foco');
      s.sessoesConcluidas = 1;
      s.ganhaXp(1);
      expect(s.leaves, marco.recompensa.folhas);
    });

    test('o mesmo marco nunca paga duas vezes', () {
      final s = _conta()..leaves = 0;
      s.sessoesConcluidas = 1;
      s.ganhaXp(1);
      final depoisDoPrimeiro = s.leaves;
      s.ganhaXp(1);
      s.ganhaXp(1);
      s.sessoesConcluidas = 2;
      s.ganhaXp(1);
      expect(s.leaves, depoisDoPrimeiro);
    });

    test('o resgate sobrevive ao snapshot: não paga de novo ao reabrir', () {
      final s = _conta()..leaves = 0;
      s.sessoesConcluidas = 1;
      s.ganhaXp(1);
      final pago = s.leaves;

      final reaberto = AppState(snapshot: s.toSnapshot());
      expect(reaberto.leaves, pago);
      reaberto.ganhaXp(1);
      expect(reaberto.leaves, pago, reason: 'reabrir não é conquistar de novo');
    });

    test('vários marcos de uma vez são todos creditados', () {
      final s = _conta()..leaves = 0;
      s.sessoesConcluidas = 5;
      s.diasAbaixoDaMeta = 1;
      s.ganhaXp(Balanco.xpAcumuladoPara(3));

      final esperado = trilha
          .where((m) => s.progresso.alcancou(m))
          .fold<int>(0, (a, m) => a + m.recompensa.folhas);
      expect(s.leaves, esperado);
      expect(s.marcosACelebrar.length, greaterThan(1));
    });
  });

  group('o fluxo real credita XP', () {
    test('sessão concluída dá XP de sessão e de presença', () {
      final s = _conta()
        ..debugFast = false
        ..dur = 50;
      s.startSession();
      s.sessionEndsAt = DateTime.now().subtract(const Duration(seconds: 1));
      s.reconcileSession();

      expect(
        s.xp,
        Balanco.xpDeSessao(50) + Balanco.xpPorDiaDeSequencia,
        reason: 'a primeira sessão do dia também inicia a presença',
      );
      expect(s.sessoesConcluidas, 1);
      s.dispose();
    });

    test('fechar o dia abaixo da meta dá XP', () {
      final s = _conta()
        ..usageAccess = true
        ..usage = 40
        ..goal = 150;
      final antes = s.xp;
      s.nextDay();
      expect(s.xp, greaterThan(antes));
      expect(s.diasAbaixoDaMeta, 1);
    });

    test('desistir não tira XP nem nível', () {
      final s = _conta()..debugFast = false;
      s.xp = 300;
      final nivelAntes = s.nivel;
      s.startSession();
      s.abandon();
      expect(s.xp, 300);
      expect(s.nivel, nivelAntes);
      s.dispose();
    });

    test('a melhor sequência não cai quando a atual cai', () {
      final s = _conta();
      s.streak = 6;
      s.melhorSequencia = 6;
      s.completedToday = 0;
      s.freezesLeft = 0;
      s.nextDay(); // perde a sequência
      expect(s.streak, 0);
      expect(s.melhorSequencia, 6, reason: 'marco conquistado não se perde');
    });
  });

  group('celebração', () {
    test('subir de nível fica pendente até ser mostrado', () {
      final s = _conta();
      expect(s.temCelebracaoPendente, isFalse);
      s.ganhaXp(Balanco.xpParaSubirDe(1));
      expect(s.subiuDeNivel, isTrue);
      expect(s.temCelebracaoPendente, isTrue);

      s.celebrou();
      expect(s.subiuDeNivel, isFalse);
    });

    test('o nível é celebrado antes do marco', () {
      final s = _conta();
      s.sessoesConcluidas = 1;
      s.ganhaXp(Balanco.xpParaSubirDe(1));
      expect(s.subiuDeNivel, isTrue);
      expect(s.marcosACelebrar, isNotEmpty);

      s.celebrou(); // consome o nível
      expect(s.subiuDeNivel, isFalse);
      expect(s.marcosACelebrar, isNotEmpty, reason: 'o marco ainda espera');

      s.celebrou(); // consome o marco
      expect(s.marcosACelebrar, isEmpty);
      expect(s.temCelebracaoPendente, isFalse);
    });

    test('celebrar não muda folhas nem XP', () {
      final s = _conta();
      s.sessoesConcluidas = 1;
      s.ganhaXp(50);
      final folhas = s.leaves;
      final xp = s.xp;
      while (s.temCelebracaoPendente) {
        s.celebrou();
      }
      expect(s.leaves, folhas);
      expect(s.xp, xp);
    });
  });
}
