// Notificações que não mentem e não cansam (item 12; laudo 01, §9 e U14–U16).
import 'package:baru_app/data/descanso_retencao.dart';
import 'package:baru_app/l10n.dart';
import 'package:baru_app/l10n_descanso.dart';
import 'package:baru_app/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('o plano do dia', () {
    test('dia cumprido é silêncio: o convite pula hoje', () {
      final plano = planoDeLembretes(
        habito: const HorarioDoHabito(hora: 19, amostras: 9),
        descansoFeitoHoje: false,
        presenteHoje: true,
        risco: avaliaRaizEmRisco(
          dias: 6,
          presenteHoje: true,
          congelamentos: 0,
        ),
        relatorioLigado: false,
        horaDoRelatorio: 21,
      );
      expect(plano.where((l) => l.tipo == TipoDeLembrete.raizEmRisco), isEmpty);
      for (final l in plano) {
        expect(l.pulaHoje, isTrue, reason: '$l');
      }
    });

    test('na configuração padrão (sem hábito, relatório às 21h) o convite '
        'existe, e a raiz nunca cai no minuto do relatório', () {
      // Reauditoria da Onda 2, N2: o convite das 19h não cabia a três horas
      // do relatório e nunca era agendado.
      final calmo = planoDeLembretes(
        habito: null,
        descansoFeitoHoje: false,
        risco: null,
        relatorioLigado: true,
        horaDoRelatorio: 21,
      );
      expect(calmo.map((l) => l.tipo), [TipoDeLembrete.descanso]);
      final emRisco = planoDeLembretes(
        habito: null,
        descansoFeitoHoje: false,
        risco: avaliaRaizEmRisco(dias: 6, presenteHoje: false, congelamentos: 0),
        relatorioLigado: true,
        horaDoRelatorio: 21,
      );
      final raiz =
          emRisco.firstWhere((l) => l.tipo == TipoDeLembrete.raizEmRisco);
      expect(raiz.hora, isNot(21));
      expect(
        emRisco.map((l) => l.tipo),
        containsAll([TipoDeLembrete.raizEmRisco, TipoDeLembrete.descanso]),
      );
    });

    test('nenhum lembrete fora de 8h–21h, qualquer que seja o hábito', () {
      for (var h = 0; h < 24; h++) {
        final plano = planoDeLembretes(
          habito: HorarioDoHabito(hora: h, amostras: 9),
          descansoFeitoHoje: false,
          risco: avaliaRaizEmRisco(
            dias: 4,
            presenteHoje: false,
            congelamentos: 0,
          ),
          relatorioLigado: false,
          horaDoRelatorio: 21,
        );
        for (final l in plano) {
          expect(l.hora, inInclusiveRange(8, 21), reason: 'hábito às ${h}h: $l');
        }
      }
    });
  });

  group('os textos', () {
    final t = T('pt');

    test('o convite muda de um dia para o outro', () {
      final titulos = <String>{
        for (var d = 0; d < 3; d++)
          textosDosLembretes(
            t,
            nomeDoPet: 'Nina',
            minutosDeDescanso: 40,
            dia: DateTime(2026, 10, 26 + d),
          )[TipoDeLembrete.descanso]!
              .titulo,
      };
      expect(titulos, hasLength(3));
    });

    test('o recado de volta não cobra (N3) e o do marco diz quem quebra (N4)',
        () {
      for (final lang in ['pt', 'en', 'es', 'zh']) {
        final t = T(lang);
        final volta = '${t.notifMissedTitle} ${t.notifMissedBody}'.toLowerCase();
        for (final cobranca in ['falta', 'missed', 'echo de menos', '想你']) {
          expect(volta, isNot(contains(cobranca)), reason: lang);
        }
        final marco = t.raizRiscoMarco;
        for (final ambiguo in ['Ela quebra', 'They break', 'Se rompe', '它会']) {
          expect(marco, isNot(contains(ambiguo)), reason: lang);
        }
      }
    });

    test('o aviso de amanhã sem número não afirma tamanho de raiz', () {
      final texto = textoDeAmanhaSemNumero(t, nomeDoPet: 'Nina');
      expect('${texto.titulo} ${texto.corpo}', isNot(matches(RegExp(r'\d'))));
    });

    test('nenhum texto de lembrete fica com placeholder cru, nos 4 idiomas',
        () {
      for (final lang in ['pt', 'en', 'es', 'zh']) {
        final tl = T(lang);
        for (var d = 0; d < 5; d++) {
          final m = textosDosLembretes(
            tl,
            nomeDoPet: 'Nina',
            minutosDeDescanso: 40,
            dia: DateTime(2026, 10, 26 + d),
            risco: avaliaRaizEmRisco(
              dias: 9,
              presenteHoje: false,
              congelamentos: d.isEven ? 0 : 1,
              proximoMarco: 14,
            ),
          );
          for (final x in m.values) {
            expect('${x.titulo} ${x.corpo}', isNot(contains('{')),
                reason: '$lang dia $d');
          }
        }
        for (final nome in nomesDosCanais(tl).values) {
          expect(nome, isNotEmpty);
        }
      }
    });
  });

  group('canais e rotas', () {
    test('um canal por tipo, nenhum é o da sessão', () {
      final canais = BaruNotifications.canaisDeRecado;
      expect(canais.toSet(), hasLength(canais.length));
      expect(canais, isNot(contains(BaruNotifications.canalSessao)));
      expect(canais, isNot(contains(BaruNotifications.canalAntigo)));
      expect(nomesDosCanais(T('pt')).keys.toSet(), canais.toSet());
    });

    test('o toque leva à rota; antes do app ligar, ela espera', () {
      final n = BaruNotifications.instance;
      final abertas = <String>[];
      n.aoAbrirRota = null;
      n.recebeRota(BaruNotifications.rotaMissoes);
      expect(abertas, isEmpty);
      n.aoAbrirRota = abertas.add;
      expect(abertas, [BaruNotifications.rotaMissoes]);
      n.recebeRota(BaruNotifications.rotaRelatorio);
      expect(abertas, [BaruNotifications.rotaMissoes, BaruNotifications.rotaRelatorio]);
      n.aoAbrirRota = null;
    });
  });
}
