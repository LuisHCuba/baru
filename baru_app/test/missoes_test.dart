import 'package:baru_app/data/missoes.dart';
import 'package:baru_app/data/progressao.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Missões.
///
/// Duas regras atravessam tudo aqui: **toda recompensa anunciada é creditada
/// de verdade**, e **resgatar duas vezes não paga duas vezes**. A primeira é a
/// dívida que este turno veio pagar; a segunda é o que impede a correção de
/// virar uma impressora de folhas.

const quadro = QuadroDeMissoes();

List<Missao> _missoes({
  DateTime? dia,
  String conta = 'alguem@exemplo.com',
  ContadoresDeMissao contadores = const ContadoresDeMissao(),
  Set<String> resgatadas = const {},
}) =>
    quadro.doDia(
      dia: dia ?? DateTime(2026, 8, 27),
      conta: conta,
      contadores: contadores,
      resgatadas: resgatadas,
    );

AppState _conta() => AppState()..startCompanionship();

void main() {
  group('sorteio determinístico', () {
    test('mesmo dia e mesma conta dão sempre as mesmas missões', () {
      final a = _missoes().map((m) => m.id).toList();
      final b = _missoes().map((m) => m.id).toList();
      expect(a, b, reason: 'aparelho diferente não pode dar missão diferente');
    });

    test('dias diferentes dão missões diferentes', () {
      final hoje = _missoes(dia: DateTime(2026, 8, 27)).map((m) => m.id).toSet();
      final outro =
          _missoes(dia: DateTime(2026, 9, 3)).map((m) => m.id).toSet();
      expect(hoje, isNot(outro));
    });

    test('contas diferentes não recebem a mesma sequência todo dia', () {
      final diferentes = <bool>[];
      for (var d = 1; d <= 14; d++) {
        final dia = DateTime(2026, 9, d);
        final a = _missoes(dia: dia, conta: 'a@x.com').map((m) => m.id).toSet();
        final b = _missoes(dia: dia, conta: 'b@x.com').map((m) => m.id).toSet();
        diferentes.add(a != b);
      }
      expect(diferentes.where((x) => x).length, greaterThan(3));
    });

    test('são três diárias e duas semanais', () {
      final m = _missoes();
      expect(
        m.where((x) => x.ritmo == RitmoDaMissao.diaria).length,
        QuadroDeMissoes.quantasDiarias,
      );
      expect(
        m.where((x) => x.ritmo == RitmoDaMissao.semanal).length,
        QuadroDeMissoes.quantasSemanais,
      );
    });

    test('não repete a mesma missão no mesmo dia', () {
      final ids = _missoes().map((m) => m.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('a semanal só muda na virada da semana', () {
      String semanais(DateTime d) =>
          (_missoes(dia: d).where((m) => m.ritmo == RitmoDaMissao.semanal))
              .map((m) => m.id)
              .join(',');
      // Quinta e sexta da mesma semana.
      expect(semanais(DateTime(2026, 8, 27)), semanais(DateTime(2026, 8, 28)));
      // Segunda seguinte.
      expect(
        semanais(DateTime(2026, 8, 27)),
        isNot(semanais(DateTime(2026, 8, 31))),
      );
    });
  });

  group('anatomia da missão', () {
    test('toda missão tem alvo, folhas e XP', () {
      for (final d in [...poolDiario, ...poolSemanal]) {
        expect(d.alvo, greaterThan(0), reason: d.id);
        expect(d.folhas, greaterThan(0), reason: d.id);
        expect(d.xp, greaterThan(0), reason: d.id);
      }
    });

    test('o progresso vai de 0 a 1 e não estoura', () {
      final m = _missoes(
        contadores: const ContadoresDeMissao(sessoesHoje: 99, minutosHoje: 999),
      );
      for (final x in m) {
        expect(x.fracao, inInclusiveRange(0, 1), reason: x.id);
      }
    });

    test('missão que depende de permissão fica indisponível sem ela', () {
      final semUso = _missoes(
        contadores: const ContadoresDeMissao(temPermissaoDeUso: false),
      );
      for (final m in semUso.where((x) => x.definicao.precisaDeUso)) {
        expect(m.estado, EstadoDaMissao.precisaPermissao, reason: m.id);
        expect(m.resgatavel, isFalse);
      }
    });

    test('a de tempo dispersivo enche enquanto o usuário NÃO gasta', () {
      final d = poolDiario.firstWhere((x) => x.id == 'pouco_dispersivo');
      const q = QuadroDeMissoes();
      // Zero minutos dispersivos = missão completa.
      expect(
        q.progressoDe(d, const ContadoresDeMissao(dispersivoHoje: 0)),
        d.alvo,
      );
      // Estourou o teto = zero.
      expect(
        q.progressoDe(d, ContadoresDeMissao(dispersivoHoje: d.alvo + 30)),
        0,
      );
    });

    test('sem medição, a de dispersivo não inventa progresso', () {
      final d = poolDiario.firstWhere((x) => x.id == 'pouco_dispersivo');
      const q = QuadroDeMissoes();
      expect(q.progressoDe(d, const ContadoresDeMissao()), 0);
    });
  });

  group('resgate', () {
    test('missão concluída credita folhas e XP', () {
      final s = _conta()..leaves = 0;
      s.completedToday = 3;
      s.minutosDeFocoHoje = 200;

      final alvo = s.missoes.firstWhere((m) => m.resgatavel);
      final folhasAntes = s.leaves;
      final xpAntes = s.xp;
      s.resgataMissao(alvo);

      expect(s.leaves, folhasAntes + alvo.folhas);
      expect(s.xp, greaterThanOrEqualTo(xpAntes + alvo.xp));
    });

    test('resgatar duas vezes não paga duas vezes', () {
      final s = _conta()..leaves = 0;
      s.completedToday = 5;
      s.minutosDeFocoHoje = 400;

      final alvo = s.missoes.firstWhere((m) => m.resgatavel);
      s.resgataMissao(alvo);
      final depois = s.leaves;
      s.resgataMissao(alvo);
      // E também com uma cópia recém-lida do quadro.
      final decopia = s.missoes.firstWhere((m) => m.id == alvo.id);
      s.resgataMissao(decopia);

      expect(s.leaves, depois, reason: 'toque duplo não pode imprimir folhas');
    });

    test('missão não concluída não paga', () {
      final s = _conta()..leaves = 0;
      final naoFeita = s.missoes.firstWhere((m) => !m.concluida);
      s.resgataMissao(naoFeita);
      expect(s.leaves, 0);
    });

    test('o resgate sobrevive ao snapshot', () {
      final s = _conta()..leaves = 0;
      s.completedToday = 3;
      s.minutosDeFocoHoje = 200;
      final alvo = s.missoes.firstWhere((m) => m.resgatavel);
      s.resgataMissao(alvo);
      final pago = s.leaves;

      final reaberto = AppState(snapshot: s.toSnapshot());
      final mesma = reaberto.missoes.firstWhere((m) => m.id == alvo.id);
      expect(mesma.resgatada, isTrue);
      reaberto.resgataMissao(mesma);
      expect(reaberto.leaves, pago);
    });

    test('a chave de resgate inclui o período: ontem não resgata hoje', () {
      final d = poolDiario.first;
      final ontem = QuadroDeMissoes.chaveDeResgate(d, DateTime(2026, 8, 26));
      final hoje = QuadroDeMissoes.chaveDeResgate(d, DateTime(2026, 8, 27));
      expect(ontem, isNot(hoje));
    });

    test('a semanal usa a semana, não o dia', () {
      final d = poolSemanal.first;
      final quinta = QuadroDeMissoes.chaveDeResgate(d, DateTime(2026, 8, 27));
      final sexta = QuadroDeMissoes.chaveDeResgate(d, DateTime(2026, 8, 28));
      final segunda = QuadroDeMissoes.chaveDeResgate(d, DateTime(2026, 8, 31));
      expect(quinta, sexta);
      expect(quinta, isNot(segunda));
    });
  });

  group('os contadores vêm do evento de domínio', () {
    test('concluir uma sessão alimenta os contadores do dia e da semana', () {
      final s = _conta()
        ..debugFast = false
        ..dur = 50;
      s.startSession();
      s.sessionEndsAt = DateTime.now().subtract(const Duration(seconds: 1));
      s.reconcileSession();

      expect(s.completedToday, 1);
      expect(s.minutosDeFocoHoje, 50);
      expect(s.maiorSessaoHoje, 50);
      expect(s.sessoesNaSemana, 1);
      expect(s.minutosNaSemana, 50);
      s.dispose();
    });

    test('a virada do dia expira as diárias sem punir', () {
      final s = _conta()..leaves = 100;
      s.completedToday = 2;
      s.minutosDeFocoHoje = 90;
      s.maiorSessaoHoje = 50;

      s.nextDay();

      expect(s.minutosDeFocoHoje, 0);
      expect(s.maiorSessaoHoje, 0);
      expect(s.completedToday, 0);
      expect(s.leaves, greaterThanOrEqualTo(100), reason: 'expirar não pune');
    });

    test('a semana só zera na segunda', () {
      final s = _conta();
      s.lastOpenDate = DateTime(2026, 8, 27); // quinta
      s.todayIndex = 3;
      s.sessoesNaSemana = 4;
      s.minutosNaSemana = 180;

      s.applyCalendar(DateTime(2026, 8, 28)); // sexta
      expect(s.sessoesNaSemana, 4, reason: 'ainda é a mesma semana');

      s.applyCalendar(DateTime(2026, 8, 31)); // segunda
      expect(s.sessoesNaSemana, 0);
      expect(s.minutosNaSemana, 0);
    });
  });

  group('o balanceamento fecha', () {
    test('missão semanal paga mais que diária', () {
      final maiorDiaria =
          poolDiario.map((d) => d.folhas).reduce((a, b) => a > b ? a : b);
      final menorSemanal =
          poolSemanal.map((d) => d.folhas).reduce((a, b) => a < b ? a : b);
      expect(menorSemanal, greaterThan(maiorDiaria));
    });

    test('o XP de missão vem da tabela única de balanceamento', () {
      for (final d in poolDiario) {
        expect(d.xp, Balanco.xpMissaoDiaria, reason: d.id);
      }
      for (final d in poolSemanal) {
        expect(d.xp, Balanco.xpMissaoSemanal, reason: d.id);
      }
    });

    test('um dia perfeito de missões não estoura a economia', () {
      // Três diárias + duas semanais no melhor caso.
      final maxDia = poolDiario.map((d) => d.folhas).toList()
        ..sort((a, b) => b.compareTo(a));
      final total = maxDia.take(3).fold<int>(0, (a, b) => a + b);
      final itemMaisCaro = 400;
      expect(
        total,
        lessThan(itemMaisCaro ~/ 4),
        reason: 'um dia não pode comprar o item mais caro da loja',
      );
    });
  });


  group('a tela não mente sobre o estado', () {
    // Montadas direto da definição: o estado não pode depender de qual missão
    // o sorteio do dia calhou de escolher.
    Missao comProgresso(int progresso, {bool resgatada = false}) => Missao(
          definicao: poolDiario.firstWhere((d) => d.id == 'dois_focos'),
          progresso: progresso,
          resgatada: resgatada,
          disponivel: true,
        );

    test('missão em andamento não é "concluída"', () {
      final m = comProgresso(1);
      expect(m.estado, EstadoDaMissao.emProgresso);
      expect(m.concluida, isFalse);
      expect(m.resgatavel, isFalse);
      expect(m.fracao, 0.5);
    });

    test('missão no alvo fica resgatável', () {
      final m = comProgresso(2);
      expect(m.estado, EstadoDaMissao.concluida);
      expect(m.resgatavel, isTrue);
    });

    test('passar do alvo continua resgatável e a barra não estoura', () {
      final m = comProgresso(9);
      expect(m.resgatavel, isTrue);
      expect(m.fracao, 1);
    });

    test('resgatada deixa de ser resgatável', () {
      final m = comProgresso(2, resgatada: true);
      expect(m.estado, EstadoDaMissao.resgatada);
      expect(m.resgatavel, isFalse);
    });

    test('no quadro do dia, resgatável é exatamente quem bateu o alvo', () {
      final ms = _missoes(
        contadores: const ContadoresDeMissao(
          sessoesHoje: 1,
          minutosHoje: 200,
          temPermissaoDeUso: true,
          dispersivoHoje: 10,
        ),
      );
      for (final m in ms.where((x) => x.disponivel)) {
        expect(
          m.resgatavel,
          m.progresso >= m.alvo,
          reason: '${m.id}: ${m.progresso}/${m.alvo}',
        );
      }
    });
  });
}