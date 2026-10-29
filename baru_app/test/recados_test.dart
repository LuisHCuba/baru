import 'package:baru_app/data/descanso_retencao.dart';
import 'package:baru_app/data/recados.dart';
import 'package:baru_app/l10n.dart';
import 'package:baru_app/l10n_descanso.dart';
import 'package:baru_app/l10n_widget.dart';
import 'package:flutter_test/flutter_test.dart';

/// Quando chamar e qual recado mandar (pesquisa 26): o horário dos 23,5 h,
/// a escada que termina em silêncio, e o recado que aprende com a pessoa.

ModeloDeRecado _m(String id) =>
    ModeloDeRecado(id, TextoDeLembrete(titulo: id, corpo: id, modelo: id));

void main() {
  final agora = DateTime(2026, 10, 29, 10);

  group('o horário: 23,5 h depois da primeira prática', () {
    test('primeiro foco às 7h40 de hoje: amanhã chama às 7h10… dentro da '
        'janela, 8h', () {
      final h = horaDoConvite(
        primeiraPratica: DateTime(2026, 10, 29, 7, 40),
        agora: agora,
      );
      expect((h.hora, h.minuto), (8, 0));
    });

    test('primeiro foco às 19h25: chama às 18h55', () {
      final h = horaDoConvite(
        primeiraPratica: DateTime(2026, 10, 28, 19, 25),
        agora: agora,
      );
      expect((h.hora, h.minuto), (18, 55));
    });

    test('nunca depois das 21h', () {
      final h = horaDoConvite(
        primeiraPratica: DateTime(2026, 10, 29, 23, 10),
        agora: agora,
      );
      expect((h.hora, h.minuto), (21, 0));
    });

    test('prática de mais de 3 dias atrás não decide: vale o hábito', () {
      final h = horaDoConvite(
        primeiraPratica: DateTime(2026, 10, 20, 7),
        agora: agora,
        habito: const HorarioDoHabito(hora: 15, amostras: 9),
      );
      expect((h.hora, h.minuto), (15, 0));
    });

    test('a primeira prática é o começo do primeiro foco do último dia', () {
      final p = primeiraPraticaDoUltimoDia([
        (at: DateTime(2026, 10, 27, 9), dur: 25, completed: true),
        (at: DateTime(2026, 10, 28, 20), dur: 25, completed: true),
        (at: DateTime(2026, 10, 28, 14, 30), dur: 30, completed: true),
        (at: DateTime(2026, 10, 28, 8), dur: 25, completed: false),
      ]);
      expect(p, DateTime(2026, 10, 28, 14));
    });
  });

  group('a escada: insistência tem fim', () {
    test('um convite por dia até o 6º, a despedida no 7º', () {
      final e = escadaDeConvites(
        agora: agora,
        hora: 18,
        minuto: 30,
        pulaHoje: false,
      );
      expect(e.convites.first, DateTime(2026, 10, 29, 18, 30));
      expect(e.convites.length, 7, reason: 'hoje e mais seis dias');
      expect(e.despedida, DateTime(2026, 11, 5, 18, 30));
      expect(
        e.convites.every((c) => c.isBefore(e.despedida)),
        isTrue,
        reason: 'depois da despedida, silêncio',
      );
    });

    test('dia cumprido não tem convite hoje', () {
      final e = escadaDeConvites(
        agora: agora,
        hora: 18,
        minuto: 0,
        pulaHoje: true,
      );
      expect(e.convites.first, DateTime(2026, 10, 30, 18));
    });

    test('horário de hoje que já passou não dispara atrasado', () {
      final e = escadaDeConvites(
        agora: agora,
        hora: 9,
        minuto: 0,
        pulaHoje: false,
      );
      expect(e.convites.first, DateTime(2026, 10, 30, 9));
    });
  });

  group('o recado aprende (bandit do paper, no aparelho)', () {
    test('agendar a semana não repete o mesmo texto em dias seguidos', () {
      final h = HistoricoDeRecados();
      final modelos = [_m('a'), _m('b'), _m('c')];
      final dias = [for (var d = 1; d <= 6; d++) agora.add(Duration(days: d))];
      final escolha = h.escolhe(modelos, dias).map((m) => m.id).toList();
      for (var i = 1; i < escolha.length; i++) {
        expect(escolha[i], isNot(escolha[i - 1]));
      }
      expect(escolha.toSet().length, 3, reason: 'todos têm vez');
    });

    test('o que tocou e foi aberto em até 3 h conta como acerto', () {
      final h = HistoricoDeRecados(
        pendentes: [
          RecadoAgendado('a', DateTime(2026, 10, 29, 8)),
          RecadoAgendado('b', DateTime(2026, 10, 28, 8)),
          RecadoAgendado('c', DateTime(2026, 10, 30, 8)),
        ],
      );
      h.fecha(agora);
      expect(h.contas['a']!.acertos, 1);
      expect(h.contas['b']!.envios, 1);
      expect(h.contas['b']!.acertos, 0, reason: 'abriu um dia depois');
      expect(h.contas['c'], isNull, reason: 'não tocou: vai ser reagendado');
      expect(h.pendentes, isEmpty);
    });

    test('com dados, o que funciona ganha; sem recência, nada se repete à '
        'toa', () {
      final h = HistoricoDeRecados(
        contas: {
          'bom': ContaDoModelo(
            envios: 20,
            acertos: 14,
            ultimoUso: agora.subtract(const Duration(days: 30)),
          ),
          'ruim': ContaDoModelo(
            envios: 20,
            acertos: 2,
            ultimoUso: agora.subtract(const Duration(days: 30)),
          ),
        },
      );
      expect(h.escolhe([_m('ruim'), _m('bom')], [agora]).single.id, 'bom');
    });

    test('a penalidade de recência cai pela metade em 15 dias', () {
      final h = HistoricoDeRecados(
        contas: {'a': ContaDoModelo(envios: 0, acertos: 0, ultimoUso: agora)},
      );
      final hoje = h.nota('a', agora);
      final daqui15 = h.nota('a', agora.add(const Duration(days: 15)));
      expect(0.5 - hoje, closeTo(HistoricoDeRecados.gama, 1e-9));
      expect(0.5 - daqui15, closeTo(HistoricoDeRecados.gama / 2, 1e-6));
    });

    test('o caderno sobrevive a ida e volta pelo disco', () {
      final h = HistoricoDeRecados(
        contas: {'a': ContaDoModelo(envios: 3, acertos: 1, ultimoUso: agora)},
        pendentes: [RecadoAgendado('b', agora)],
      );
      final de = HistoricoDeRecados.fromJsonString(h.toJsonString());
      expect(de.contas['a']!.envios, 3);
      expect(de.contas['a']!.ultimoUso, agora);
      expect(de.pendentes.single.modelo, 'b');
      expect(HistoricoDeRecados.fromJsonString('{lixo').contas, isEmpty);
    });
  });

  group('os textos', () {
    test('cinco convites, cada um com id próprio, nos quatro idiomas', () {
      for (final lang in ['pt', 'en', 'es', 'zh']) {
        final m = modelosDoConvite(
          T(lang),
          nomeDoPet: 'Baru',
          minutosDeDescanso: 40,
        );
        expect(m.length, 5);
        expect(m.map((x) => x.id).toSet().length, 5);
        for (final x in m) {
          expect(x.texto.modelo, x.id);
          expect('${x.texto.titulo}${x.texto.corpo}', isNot(contains('{')));
        }
      }
    });

    test('a despedida avisa que para, sem culpa', () {
      final d = despedidaDosLembretes(T('pt'), nomeDoPet: 'Baru');
      expect(d.modelo, 'despedida');
      expect(d.corpo, contains('Baru'));
      expect(d.corpo.toLowerCase(), isNot(contains('desist')));
    });

    test('as frases do widget existem nos quatro idiomas', () {
      garanteTextosDoWidget();
      final chaves = textosDoWidget['pt']!.keys.toSet();
      for (final lang in ['pt', 'en', 'es', 'zh']) {
        expect(textosDoWidget[lang]!.keys.toSet(), chaves);
        for (final v in textosDoWidget[lang]!.values) {
          expect(v.trim(), isNotEmpty);
        }
      }
    });
  });
}
