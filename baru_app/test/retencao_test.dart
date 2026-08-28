import 'package:baru_app/data/descanso_do_dia.dart';
import 'package:baru_app/data/descanso_retencao.dart';
import 'package:baru_app/data/missoes.dart';
import 'package:baru_app/l10n.dart';
import 'package:baru_app/l10n_descanso.dart';
import 'package:baru_app/services/notification_service.dart';
import 'package:baru_app/widgets/raiz.dart';
import 'package:flutter_test/flutter_test.dart';

/// Retenção diária.
///
/// O que se prova aqui é o julgamento: que o lembrete sai do comportamento
/// da pessoa e não de um número escolhido no projeto, que a raiz é avisada
/// **antes** de quebrar, que quem volta é recebido, e que nada disso pode
/// virar três notificações no mesmo dia.

final _agora = DateTime(2026, 8, 28, 12); // sexta

List<DateTime> _sessoesAs(int hora, {required int quantas, int desdeDias = 1}) {
  return [
    for (var i = 0; i < quantas; i++)
      DateTime(2026, 8, 28).subtract(Duration(days: desdeDias + i)).add(
            Duration(hours: hora),
          ),
  ];
}

void main() {
  group('RD-01 — o lembrete no horário do hábito', () {
    test('sem evidência não inventa horário', () {
      expect(horarioDoHabito(const [], agora: _agora), isNull);
      expect(
        horarioDoHabito(_sessoesAs(20, quantas: 3), agora: _agora),
        isNull,
        reason: 'três sessões não são um hábito; chutar seria estimar',
      );
    });

    test('acha a hora que a pessoa realmente usa', () {
      final h = horarioDoHabito(_sessoesAs(20, quantas: 6), agora: _agora);
      expect(h, isNotNull);
      expect(h!.hora, 20);
      expect(h.amostras, 6);
    });

    test('o hábito recente ganha do antigo', () {
      // Doze sessões às 8h, mas todas de duas semanas atrás; cinco às 21h
      // nos últimos dias. Quem mudou de rotina não pode continuar sendo
      // chamado na rotina velha.
      final usos = [
        ..._sessoesAs(8, quantas: 12, desdeDias: 15),
        ..._sessoesAs(21, quantas: 5, desdeDias: 1),
      ];
      expect(horarioDoHabito(usos, agora: _agora)!.hora, 21);
    });

    test('ignora o que está fora da janela e o que vem do futuro', () {
      final antigo = [
        for (var i = 0; i < 30; i++)
          DateTime(2026, 6, 1).add(Duration(days: i, hours: 7)),
      ];
      expect(horarioDoHabito(antigo, agora: _agora), isNull);

      final futuro = [
        ..._sessoesAs(19, quantas: 5),
        for (var i = 0; i < 40; i++)
          DateTime(2026, 9, 10).add(Duration(days: i, hours: 3)),
      ];
      expect(
        horarioDoHabito(futuro, agora: _agora)!.hora,
        19,
        reason: 'relógio mexido não pode envenenar o histograma',
      );
    });

    test('no empate fica a hora mais tarde', () {
      final usos = [
        ..._sessoesAs(9, quantas: 4),
        ..._sessoesAs(19, quantas: 4),
      ];
      expect(
        horarioDoHabito(usos, agora: _agora)!.hora,
        19,
        reason: 'um lembrete às 19h ainda deixa a noite para agir',
      );
    });
  });

  group('RD-02 — a raiz avisada antes de quebrar', () {
    test('quem já apareceu hoje não ouve nada', () {
      expect(
        avaliaRaizEmRisco(dias: 12, presenteHoje: true, congelamentos: 0),
        isNull,
      );
    });

    test('raiz que ainda não existe não corre risco', () {
      expect(
        avaliaRaizEmRisco(dias: 0, presenteHoje: false, congelamentos: 0),
        isNull,
      );
    });

    test('sem congelamento é quebra; com congelamento é a rede', () {
      final quebra =
          avaliaRaizEmRisco(dias: 12, presenteHoje: false, congelamentos: 0)!;
      expect(quebra.grau, GrauDoRisco.quebra);
      expect(quebra.vaiQuebrar, isTrue);

      final rede =
          avaliaRaizEmRisco(dias: 12, presenteHoje: false, congelamentos: 1)!;
      expect(rede.grau, GrauDoRisco.congelamento);
      expect(
        rede.vaiQuebrar,
        isFalse,
        reason: 'dizer que quebra a quem tem congelamento seria mentira',
      );
    });

    test('a véspera de um marco da raiz é reconhecida', () {
      // 12 dias: o próximo galho nasce aos 14 (RaizViva.marcos).
      final perto = avaliaRaizEmRisco(
        dias: 12,
        presenteHoje: false,
        congelamentos: 0,
        proximoMarco: RaizViva.proximoMarco(12),
      )!;
      expect(perto.proximoMarco, 14);
      expect(perto.faltaParaOMarco, 2);
      expect(perto.vesperaDeMarco, isTrue);

      final longe = avaliaRaizEmRisco(
        dias: 31,
        presenteHoje: false,
        congelamentos: 0,
        proximoMarco: RaizViva.proximoMarco(31),
      )!;
      expect(longe.proximoMarco, 60);
      expect(longe.vesperaDeMarco, isFalse);
    });

    test('o aviso cai depois do hábito e antes de a noite acabar', () {
      expect(horaDoAvisoDaRaiz(null), 21);
      expect(
        horaDoAvisoDaRaiz(const HorarioDoHabito(hora: 20, amostras: 9)),
        21,
        reason: 'avisar antes do hábito é cobrar de quem ainda ia aparecer',
      );
      expect(
        horaDoAvisoDaRaiz(const HorarioDoHabito(hora: 8, amostras: 9)),
        19,
        reason: 'ninguém é avisado às 9h de que a noite pode dar errado',
      );
      expect(
        horaDoAvisoDaRaiz(const HorarioDoHabito(hora: 23, amostras: 9)),
        22,
        reason: 'uma sessão curta ainda precisa caber antes da meia-noite',
      );
    });
  });

  group('RD-03 — recompensa por voltar', () {
    test('um dia fora é uma semana normal, não uma ausência', () {
      expect(avaliaVolta(diasFora: 1, hoje: _agora), isNull);
      expect(avaliaVolta(diasFora: 0, hoje: _agora), isNull);
    });

    test('quem sumiu três dias volta com presente e com rede', () {
      final v = avaliaVolta(diasFora: 3, hoje: _agora)!;
      expect(v.folhas, 25);
      expect(
        v.devolveCongelamento,
        isTrue,
        reason: 'voltar sem rede é voltar para a segunda desistência',
      );
    });

    test('a escala sobe com a ausência', () {
      int folhas(int d) => avaliaVolta(diasFora: d, hoje: _agora)!.folhas;
      expect(folhas(2), lessThan(folhas(3)));
      expect(folhas(3), lessThan(folhas(9)));
    });

    test('não paga duas vezes no mesmo dia', () {
      final v = avaliaVolta(diasFora: 4, hoje: _agora)!;
      expect(
        avaliaVolta(diasFora: 4, hoje: _agora, jaCreditadas: {v.chave}),
        isNull,
      );
      expect(v.chave, 'volta@2026-08-28');
    });

    test('a chave não colide com a de missão nenhuma', () {
      final v = avaliaVolta(diasFora: 4, hoje: _agora)!;
      expect(v.chave, isNot(MissaoDoDescanso.chaveDeResgate(_agora)));
      for (final d in [...poolDiario, ...poolSemanal]) {
        expect(v.chave, isNot(QuadroDeMissoes.chaveDeResgate(d, _agora)));
      }
    });
  });

  group('D-03 — insistência sem virar praga', () {
    const habito = HorarioDoHabito(hora: 19, amostras: 10);

    RaizEmRisco risco({bool congelamento = false}) => avaliaRaizEmRisco(
          dias: 12,
          presenteHoje: false,
          congelamentos: congelamento ? 1 : 0,
        )!;

    test('um dia tranquilo tem um recado só', () {
      final plano = planoDeLembretes(
        habito: habito,
        descansoFeitoHoje: false,
        risco: null,
        relatorioLigado: false,
        horaDoRelatorio: 21,
      );
      expect(plano.length, 1);
      expect(plano.single.tipo, TipoDeLembrete.descanso);
      expect(plano.single.hora, 19);
    });

    test('nunca passa do teto do dia', () {
      final plano = planoDeLembretes(
        habito: const HorarioDoHabito(hora: 9, amostras: 10),
        descansoFeitoHoje: false,
        risco: risco(),
        relatorioLigado: false,
        horaDoRelatorio: 21,
      );
      expect(plano.length, lessThanOrEqualTo(2));
    });

    test('o relatório da noite ocupa o horário: o descanso cede', () {
      final plano = planoDeLembretes(
        habito: const HorarioDoHabito(hora: 20, amostras: 10),
        descansoFeitoHoje: false,
        risco: null,
        relatorioLigado: true,
        horaDoRelatorio: 21,
      );
      expect(
        plano,
        isEmpty,
        reason: 'duas notificações a uma hora de distância é a terceira do dia',
      );
    });

    test('a raiz que vai quebrar entra mesmo colada no relatório', () {
      final plano = planoDeLembretes(
        habito: const HorarioDoHabito(hora: 20, amostras: 10),
        descansoFeitoHoje: false,
        risco: risco(),
        relatorioLigado: true,
        horaDoRelatorio: 21,
      );
      expect(plano.map((l) => l.tipo), contains(TipoDeLembrete.raizEmRisco));
    });

    test('a raiz absorvida pelo congelamento cede o horário', () {
      final plano = planoDeLembretes(
        habito: const HorarioDoHabito(hora: 20, amostras: 10),
        descansoFeitoHoje: false,
        risco: risco(congelamento: true),
        relatorioLigado: true,
        horaDoRelatorio: 21,
      );
      expect(
        plano.map((l) => l.tipo),
        isNot(contains(TipoDeLembrete.raizEmRisco)),
        reason: 'nada se perde hoje: não vale uma segunda buzinada',
      );
    });

    test('quem já descansou hoje só é chamado amanhã', () {
      final plano = planoDeLembretes(
        habito: habito,
        descansoFeitoHoje: true,
        risco: null,
        relatorioLigado: false,
        horaDoRelatorio: 21,
      );
      final l = plano.single;
      expect(l.pulaHoje, isTrue);
      expect(l.repeteTodoDia, isTrue);
    });

    test('o plano sai em ordem de horário', () {
      final plano = planoDeLembretes(
        habito: const HorarioDoHabito(hora: 9, amostras: 10),
        descansoFeitoHoje: false,
        risco: risco(),
        relatorioLigado: false,
        horaDoRelatorio: 21,
      );
      expect(plano.length, 2);
      expect(plano.first.hora, lessThan(plano.last.hora));
    });
  });

  group('o agendamento', () {
    LembreteDoDia as(int hora, {bool pula = false}) => LembreteDoDia(
          tipo: TipoDeLembrete.descanso,
          hora: hora,
          minuto: 0,
          repeteTodoDia: true,
          pulaHoje: pula,
        );

    test('um horário ainda à frente é hoje', () {
      expect(
        BaruNotifications.proximaOcorrencia(as(19), _agora),
        DateTime(2026, 8, 28, 19),
      );
    });

    test('um horário que já passou vai para amanhã, não dispara agora', () {
      expect(
        BaruNotifications.proximaOcorrencia(as(9), _agora),
        DateTime(2026, 8, 29, 9),
        reason: 'notificação atrasada é a que ensina a ignorar notificação',
      );
    });

    test('pular hoje empurra para amanhã mesmo com o horário à frente', () {
      expect(
        BaruNotifications.proximaOcorrencia(as(19, pula: true), _agora),
        DateTime(2026, 8, 29, 19),
      );
    });

    test('os ids novos não colidem com os que já existiam', () {
      final ids = {
        BaruNotifications.sessaoId,
        BaruNotifications.sessaoFimId,
        BaruNotifications.descansoId,
        BaruNotifications.raizHojeId,
        BaruNotifications.raizAmanhaId,
      };
      expect(ids.length, 5);
    });
  });

  group('a copy', () {
    setUp(garanteTextosDoDescanso);

    test('existe nos quatro idiomas, sem buraco de tradução', () {
      final chaves = textosDoDescanso['pt']!.keys.toSet();
      for (final lang in ['pt', 'en', 'es', 'zh']) {
        expect(
          textosDoDescanso[lang]!.keys.toSet(),
          chaves,
          reason: 'paridade de chaves em $lang',
        );
        for (final entrada in textosDoDescanso[lang]!.entries) {
          expect(entrada.value.trim(), isNotEmpty, reason: '$lang/${entrada.key}');
        }
      }
    });

    test('as chaves não sequestram nada do catálogo principal', () {
      // O catálogo principal ganha: uma chave repetida aqui seria texto
      // morto, e o defeito só apareceria como "a frase não mudou".
      final t = T('pt');
      for (final chave in textosDoDescanso['pt']!.keys) {
        expect(
          t.s(chave),
          textosDoDescanso['pt']![chave],
          reason: '$chave já existe em l10n.dart',
        );
      }
    });

    test('nenhum {campo} sobra depois de preenchido', () {
      for (final lang in ['pt', 'en', 'es', 'zh']) {
        final t = T(lang);
        final m = MissaoDoDescanso(
          melhorDoDia: const Duration(minutes: 12),
          emCurso: leDescanso(
            comecouEm: DateTime(2026, 8, 28, 10),
            agora: DateTime(2026, 8, 28, 10, 30),
            minutosDeTelaNoInicio: 0,
            minutosDeTelaAgora: 8,
          ),
          temPermissaoDeUso: true,
        );
        final textos = textosDosLembretes(
          t,
          nomeDoPet: 'Baru',
          minutosDeDescanso: 40,
          risco: avaliaRaizEmRisco(
            dias: 12,
            presenteHoje: false,
            congelamentos: 0,
            proximoMarco: RaizViva.proximoMarco(12),
          ),
        );
        final frases = [
          tituloDoDescanso(t, m),
          comoDoDescanso(t),
          recadoDoDescanso(t, m),
          recadoDaVolta(t, avaliaVolta(diasFora: 4, hoje: _agora)!),
          for (final texto in textos.values) ...[texto.titulo, texto.corpo],
        ];
        for (final f in frases) {
          expect(f, isNotEmpty, reason: lang);
          expect(f, isNot(contains('{')), reason: '$lang: $f');
        }
      }
    });

    test('a perda é dita quando a pessoa volta de outro app (D-02)', () {
      final t = T('pt');
      final fugiu = MissaoDoDescanso(
        melhorDoDia: const Duration(minutes: 22),
        emCurso: leDescanso(
          comecouEm: DateTime(2026, 8, 28, 10),
          agora: DateTime(2026, 8, 28, 10, 30),
          minutosDeTelaNoInicio: 0,
          minutosDeTelaAgora: 2,
        ),
        temPermissaoDeUso: true,
      );
      expect(recadoDoDescanso(t, fugiu), contains('2 min'));

      final tranquilo = MissaoDoDescanso(
        melhorDoDia: const Duration(minutes: 22),
        emCurso: leDescanso(
          comecouEm: DateTime(2026, 8, 28, 10),
          agora: DateTime(2026, 8, 28, 10, 30),
          minutosDeTelaNoInicio: 0,
          minutosDeTelaAgora: 0,
        ),
        temPermissaoDeUso: true,
      );
      expect(
        recadoDoDescanso(t, tranquilo),
        isNot(recadoDoDescanso(t, fugiu)),
        reason: 'sem esta diferença, escapar não custa nada visível',
      );
    });

    test('sem permissão a missão fala de permissão, não de progresso', () {
      final t = T('pt');
      const sem = MissaoDoDescanso(temPermissaoDeUso: false);
      expect(recadoDoDescanso(t, sem), t.descansoSemUso);
    });

    test('o aviso do congelamento não diz que a raiz vai quebrar', () {
      final t = T('pt');
      final rede = textosDosLembretes(
        t,
        nomeDoPet: 'Baru',
        minutosDeDescanso: 40,
        risco: avaliaRaizEmRisco(
          dias: 12,
          presenteHoje: false,
          congelamentos: 1,
        ),
      )[TipoDeLembrete.raizEmRisco]!;
      expect(rede.titulo, t.raizCongelaTitulo);
    });
  });
}
