import 'package:baru_app/data/descanso_do_dia.dart';
import 'package:baru_app/data/missoes.dart';
import 'package:flutter_test/flutter_test.dart';

/// A missão do descanso.
///
/// O que se prova aqui é a regra, não a existência das classes: que o tempo
/// em outro app **não** vira descanso, que a fuga longa rompe a tentativa,
/// que a barra nunca anda para trás, e que nada disso depende de um `Timer`
/// vivo — porque durante um descanso bem-sucedido o app está morto.
///
/// Nada aqui impede a pessoa de sair (ADR-016). Tudo aqui mede.

/// Uma tentativa começada às 10h de um dia qualquer.
final _inicio = DateTime(2026, 8, 28, 10);

LeituraDoDescanso _le({
  required int minutosDepois,
  int telaNoInicio = 0,
  int telaAgora = 0,
  Duration noProprioApp = Duration.zero,
}) =>
    leDescanso(
      comecouEm: _inicio,
      agora: _inicio.add(Duration(minutes: minutosDepois)),
      minutosDeTelaNoInicio: telaNoInicio,
      minutosDeTelaAgora: telaAgora,
      noProprioApp: noProprioApp,
    );

void main() {
  group('o relógio do descanso', () {
    test('quarenta minutos com o telefone parado cumprem a missão', () {
      final l = _le(minutosDepois: 40);
      expect(l.minutos, 40);
      expect(l.fase, FaseDoDescanso.completo);
    });

    test('o tempo em outro app não vira descanso', () {
      // Quarenta minutos de relógio, dez deles no TikTok.
      final l = _le(minutosDepois: 40, telaAgora: 10);
      expect(
        l.minutos,
        30,
        reason: 'o progresso para de correr enquanto a pessoa está fora',
      );
      expect(l.minutosDeFuga, 10);
      expect(l.fase, isNot(FaseDoDescanso.completo));
    });

    test('a fuga além da tolerância rompe a tentativa, mesmo batendo o alvo',
        () {
      // Sessenta minutos de relógio, dez fora: sobram cinquenta, acima do
      // alvo. Não vale — o descanso pedido é contínuo.
      final l = _le(minutosDepois: 60, telaAgora: 10);
      expect(l.minutos, 50);
      expect(l.fase, FaseDoDescanso.rompido);
      expect(l.completo, isFalse);
    });

    test('uma olhada curta não rompe nada', () {
      final l = _le(minutosDepois: 45, telaAgora: 2);
      expect(l.fase, FaseDoDescanso.completo);
      expect(l.minutos, 43);
    });

    test('olhar o próprio Baru não conta como descanso — e não rompe', () {
      final l = _le(
        minutosDepois: 40,
        noProprioApp: const Duration(minutes: 10),
      );
      expect(
        l.minutos,
        30,
        reason: 'a tela do Baru também é tela: não se descansa olhando ela',
      );
      expect(
        l.fase,
        FaseDoDescanso.emAndamento,
        reason: 'conferir quanto falta não pode acabar com o que se confere',
      );
      expect(l.minutosDeFuga, 0);
    });

    test('a virada do dia expira a tentativa', () {
      final l = leDescanso(
        comecouEm: DateTime(2026, 8, 28, 23, 50),
        agora: DateTime(2026, 8, 29, 0, 30),
        minutosDeTelaNoInicio: 0,
        minutosDeTelaAgora: 0,
      );
      expect(l.fase, FaseDoDescanso.expirado);
      expect(l.valeContar, isFalse);
    });

    test('contador de tela andando para trás não dá descanso de graça', () {
      // Acontece quando a janela de medição muda. Sem o piso em zero, a
      // subtração de um número negativo **somaria** descanso.
      final l = _le(minutosDepois: 30, telaNoInicio: 40, telaAgora: 5);
      expect(l.minutos, 30);
      expect(l.minutosDeFuga, 0);
    });

    test('relógio andando para trás não vira descanso negativo', () {
      final l = leDescanso(
        comecouEm: _inicio,
        agora: _inicio.subtract(const Duration(minutes: 20)),
        minutosDeTelaNoInicio: 0,
        minutosDeTelaAgora: 0,
      );
      expect(l.descansado, Duration.zero);
      expect(l.minutos, isNonNegative);
    });

    test('tela maior que o relógio não estoura o descanso para baixo', () {
      final l = _le(minutosDepois: 10, telaAgora: 90);
      expect(l.descansado, Duration.zero);
      expect(l.minutosDeFuga, 10);
    });
  });

  group('o melhor do dia só sobe', () {
    test('uma tentativa pior não apaga uma melhor', () {
      var melhor = Duration.zero;
      melhor = melhorDescanso(melhor, _le(minutosDepois: 32));
      expect(melhor, const Duration(minutes: 32));

      // Tentativa nova, curta: o melhor não recua.
      melhor = melhorDescanso(melhor, _le(minutosDepois: 5));
      expect(
        melhor,
        const Duration(minutes: 32),
        reason: 'decaimento de progresso é proibido pelo contrato §1',
      );
    });

    test('tentativa expirada não entra na conta', () {
      final expirada = leDescanso(
        comecouEm: DateTime(2026, 8, 28, 23, 50),
        agora: DateTime(2026, 8, 29, 3),
        minutosDeTelaNoInicio: 0,
        minutosDeTelaAgora: 0,
      );
      expect(
        melhorDescanso(const Duration(minutes: 10), expirada),
        const Duration(minutes: 10),
        reason: 'o contador de tela zerou no meio: o número não descreve nada',
      );
    });
  });

  group('a missão', () {
    MissaoDoDescanso comMelhor(
      int minutos, {
      LeituraDoDescanso? emCurso,
      bool resgatada = false,
      bool permissao = true,
    }) =>
        MissaoDoDescanso(
          melhorDoDia: Duration(minutes: minutos),
          emCurso: emCurso,
          resgatada: resgatada,
          temPermissaoDeUso: permissao,
        );

    test('a barra mostra o melhor do dia, não a tentativa atual', () {
      // Trinta e dois minutos conquistados, e agora uma tentativa de cinco.
      final m = comMelhor(32, emCurso: _le(minutosDepois: 5));
      expect(m.progresso, 32);
      expect(m.fracao, greaterThan(0.7));
    });

    test('o alvo batido deixa a missão resgatável, uma vez só', () {
      final m = comMelhor(40);
      expect(m.concluida, isTrue);
      expect(m.estado, EstadoDaMissao.concluida);
      expect(m.resgatavel, isTrue);

      final paga = comMelhor(40, resgatada: true);
      expect(paga.resgatavel, isFalse);
      expect(paga.estado, EstadoDaMissao.resgatada);
    });

    test('sem acesso ao uso vira convite, nunca missão impossível', () {
      final m = comMelhor(40, permissao: false);
      expect(m.estado, EstadoDaMissao.precisaPermissao);
      expect(
        m.resgatavel,
        isFalse,
        reason: 'nada se paga por um número que não foi medido',
      );
    });

    test('o progresso nunca passa do alvo', () {
      expect(comMelhor(90).progresso, comMelhor(90).alvo);
      expect(comMelhor(90).fracao, 1.0);
    });

    test('a chave de resgate carrega o dia: resgatar ontem não resgata hoje',
        () {
      final ontem = MissaoDoDescanso.chaveDeResgate(DateTime(2026, 8, 27));
      final hoje = MissaoDoDescanso.chaveDeResgate(DateTime(2026, 8, 28));
      expect(ontem, isNot(hoje));
      expect(hoje, 'descanso@2026-08-28');
      expect(
        MissaoDoDescanso.chaveDeResgate(DateTime(2026, 8, 28, 23, 59)),
        hoje,
        reason: 'a hora não entra na chave; o dia sim',
      );
    });

    test('a chave não colide com a de nenhuma missão do pool', () {
      final dia = DateTime(2026, 8, 28);
      final doPool = [
        for (final d in [...poolDiario, ...poolSemanal])
          QuadroDeMissoes.chaveDeResgate(d, dia),
      ];
      expect(doPool, isNot(contains(MissaoDoDescanso.chaveDeResgate(dia))));
    });

    test('paga mais que a missão diária mais cara do pool', () {
      final maiorDoPool =
          poolDiario.map((d) => d.folhas).reduce((a, b) => a > b ? a : b);
      expect(
        const DefinicaoDoDescanso().folhas,
        greaterThan(maiorDoPool),
        reason: 'é a missão principal do dia, não mais uma',
      );
    });

    test('é fixa: não depende de cair no sorteio do dia', () {
      // O sorteio determinístico (ADR-010) escolhe três de sete. A missão
      // principal não pode ficar de fora num dia azarado.
      final ids = [...poolDiario, ...poolSemanal].map((d) => d.id);
      expect(ids, isNot(contains(Descanso.id)));
      expect(const MissaoDoDescanso().id, Descanso.id);
    });
  });
}
