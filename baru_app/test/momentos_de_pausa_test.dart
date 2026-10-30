import 'package:baru_app/data/momentos_de_pausa.dart';
import 'package:baru_app/data/recados.dart';
import 'package:baru_app/data/tempo_de_tela.dart';
import 'package:baru_app/l10n.dart';
import 'package:baru_app/l10n_pausas.dart';
import 'package:baru_app/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// As pausas ao longo do dia: o perfil de uso, os momentos de pico e a
/// fadiga de quem ignora.

const _feed = 'com.zhiliaoapp.musically';
const _musica = 'com.spotify.music';

bool _conta(String pacote) => pacote != _musica;

IntervaloDeUso _uso(DateTime inicio, int minutos, [String pacote = _feed]) =>
    IntervaloDeUso(
      pacote: pacote,
      inicio: inicio,
      fim: inicio.add(Duration(minutes: minutos)),
    );

/// Uma quinta-feira, às 8h.
final _agora = DateTime(2026, 10, 29, 8);

/// O mesmo uso em cada um dos [dias] dias antes de [_agora].
List<IntervaloDeUso> _todoDia(
  int dias,
  List<({int hora, int minuto, int duracao})> trechos,
) => [
  for (var d = 1; d <= dias; d++)
    for (final t in trechos)
      _uso(
        DateTime(_agora.year, _agora.month, _agora.day - d, t.hora, t.minuto),
        t.duracao,
      ),
];

void main() {
  group('o perfil', () {
    test('reparte o trecho que atravessa a virada da hora', () {
      final p = perfilDeUso(
        [_uso(DateTime(2026, 10, 28, 21, 50), 30)],
        conta: _conta,
        agora: _agora,
      );
      final ontem = DateTime(2026, 10, 28);
      expect(p.dias, 1);
      expect(p.mediaNaHora(21, ontem), closeTo(10, 0.01));
      expect(p.mediaNaHora(22, ontem), closeTo(20, 0.01));
    });

    test('hoje não entra, e o que não conta para a meta também não', () {
      final p = perfilDeUso(
        [
          _uso(DateTime(2026, 10, 29, 7), 40),
          _uso(DateTime(2026, 10, 28, 13), 40, _musica),
        ],
        conta: _conta,
        agora: _agora,
      );
      expect(p.vazio, isTrue);
    });

    test('os dias contam do primeiro dia com uso, não da janela inteira', () {
      final p = perfilDeUso(
        _todoDia(3, [(hora: 13, minuto: 0, duracao: 30)]),
        conta: _conta,
        agora: _agora,
      );
      expect(p.dias, 3);
      expect(p.mediaNaHora(13, DateTime(2026, 10, 28)), closeTo(30, 0.01));
    });

    test('maratona: trechos colados somando 20 min, na hora em que começou',
        () {
      final ontem = DateTime(2026, 10, 28);
      final p = perfilDeUso(
        [
          // 22h05 a 22h17, olha uma mensagem, volta às 22h18 até 22h30.
          _uso(DateTime(2026, 10, 28, 22, 5), 12),
          _uso(DateTime(2026, 10, 28, 22, 18), 12),
          // 15h: dez minutos picados com folga grande não são maratona.
          _uso(DateTime(2026, 10, 28, 15), 5),
          _uso(DateTime(2026, 10, 28, 15, 20), 5),
        ],
        conta: _conta,
        agora: _agora,
      );
      expect(p.maratonasNaHora(22, ontem), 1);
      expect(p.maratonasNaHora(15, ontem), 0);
    });

    test('dia útil e fim de semana têm perfis separados', () {
      // De sexta (23) a quarta (28): seis dias, sábado e domingo entre eles.
      final usos = [
        for (var d = 23; d <= 28; d++)
          if (DateTime(2026, 10, d).weekday >= DateTime.saturday)
            _uso(DateTime(2026, 10, d, 10), 50)
          else
            _uso(DateTime(2026, 10, d, 20), 50),
      ];
      final p = perfilDeUso(usos, conta: _conta, agora: _agora);
      expect(p.diasUteis, 4);
      expect(p.diasFimDeSemana, 2);
      final sabado = DateTime(2026, 10, 31);
      final sexta = DateTime(2026, 10, 30);
      expect(p.mediaNaHora(10, sabado), closeTo(50, 0.01));
      expect(p.mediaNaHora(20, sabado), 0);
      expect(p.mediaNaHora(20, sexta), closeTo(50, 0.01));
      expect(p.mediaNaHora(10, sexta), 0);
    });
  });

  group('os momentos', () {
    final perfil = perfilDeUso(
      _todoDia(7, [
        (hora: 7, minuto: 0, duracao: 40), // antes da janela
        (hora: 12, minuto: 30, duracao: 25),
        (hora: 13, minuto: 0, duracao: 15),
        (hora: 17, minuto: 0, duracao: 12),
        (hora: 21, minuto: 30, duracao: 30),
        (hora: 23, minuto: 0, duracao: 60), // hora de dormir
      ]),
      conta: _conta,
      agora: _agora,
    );
    final hoje = DateTime(2026, 10, 29);

    List<int> horas(List<MomentoDePausa> m) => [for (final x in m) x.quando.hour];

    test('as horas de pico, a três horas uma da outra, dentro da janela', () {
      final m = momentosDePausa(perfil, dia: hoje, agora: _agora);
      expect(horas(m), [12, 17, 21]);
      expect(m.every((x) => x.quando.minute == 15), isTrue);
      expect(m.first.minutosNaHora, 25);
    });

    test('sem uso, sem pausa', () {
      final vazio = perfilDeUso(const [], conta: _conta, agora: _agora);
      expect(momentosDePausa(vazio, dia: hoje, agora: _agora), isEmpty);
    });

    test('hora com pouco uso não é pico', () {
      final pouco = perfilDeUso(
        _todoDia(7, [(hora: 15, minuto: 0, duracao: 4)]),
        conta: _conta,
        agora: _agora,
      );
      expect(momentosDePausa(pouco, dia: hoje, agora: _agora), isEmpty);
    });

    test('nada que já passou, nada antes do limite', () {
      final tarde = DateTime(2026, 10, 29, 14);
      expect(horas(momentosDePausa(perfil, dia: hoje, agora: tarde)), [17, 21]);
      expect(
        horas(
          momentosDePausa(
            perfil,
            dia: hoje,
            agora: _agora,
            naoAntesDe: DateTime(2026, 10, 29, 18),
          ),
        ),
        [21],
      );
    });

    test('longe dos outros recados', () {
      final m = momentosDePausa(
        perfil,
        dia: hoje,
        agora: _agora,
        ocupados: [DateTime(2026, 10, 29, 21)],
      );
      expect(horas(m), [12, 17]);
    });

    test('o teto', () {
      final m = momentosDePausa(perfil, dia: hoje, agora: _agora, maximo: 1);
      expect(horas(m), [21]);
    });

    test('a hora ignorada cede lugar', () {
      final caderno = HistoricoDeRecados();
      for (var d = 0; d < 4; d++) {
        caderno.pendentes = [
          RecadoAgendado('pausa1', DateTime(2026, 10, 20 + d, 21, 15)),
        ];
        // Abriu o app só no dia seguinte: a pausa foi ignorada.
        caderno.fecha(DateTime(2026, 10, 21 + d, 10));
      }
      expect(caderno.receptividadeDaHora(21), lessThan(0.5));
      // Sem o caderno, a única pausa do dia seria a das 21h, a hora de mais
      // uso; com quatro chamadas ignoradas ali, ela vai para o almoço.
      final m = momentosDePausa(
        perfil,
        dia: hoje,
        agora: _agora,
        maximo: 1,
        receptividade: caderno.receptividadeDaHora,
      );
      expect(horas(m), [12]);
    });
  });

  group('o caderno', () {
    test('abrir o app logo depois da pausa conta como acerto da hora', () {
      final c = HistoricoDeRecados(
        pendentes: [RecadoAgendado('pausa2', DateTime(2026, 10, 28, 13, 15))],
      );
      c.fecha(DateTime(2026, 10, 28, 13, 40));
      expect(c.horasDaPausa[13]!.acertos, 1);
      expect(c.receptividadeDaHora(13), greaterThan(1));
      // E sobrevive à gravação.
      final lido = HistoricoDeRecados.fromJsonString(c.toJsonString());
      expect(lido.horasDaPausa[13]!.envios, 1);
      expect(lido.horasDaPausa[13]!.acertos, 1);
    });

    test('recado que não é pausa não mexe nas horas', () {
      final c = HistoricoDeRecados(
        pendentes: [RecadoAgendado('convite1', DateTime(2026, 10, 28, 17))],
      );
      c.fecha(DateTime(2026, 10, 28, 17, 30));
      expect(c.horasDaPausa, isEmpty);
    });

    test('seis pausas ignoradas: passa a chamar menos', () {
      final c = HistoricoDeRecados();
      for (var d = 0; d < 6; d++) {
        c.pendentes = [
          RecadoAgendado('pausa1', DateTime(2026, 10, 10 + d, 12 + d, 15)),
        ];
        c.fecha(DateTime(2026, 10, 11 + d, 9));
      }
      expect(c.pausasIgnoradas, isTrue);
    });

    test('caderno antigo, sem horas, continua abrindo', () {
      final c = HistoricoDeRecados.fromJsonString('{"c":{},"p":[]}');
      expect(c.horasDaPausa, isEmpty);
      expect(c.receptividadeDaHora(12), 1);
    });
  });

  group('os textos', () {
    final momentos = [
      MomentoDePausa(quando: DateTime(2026, 10, 29, 12, 15), minutosNaHora: 25),
      MomentoDePausa(quando: DateTime(2026, 10, 29, 17, 15), minutosNaHora: 12),
      MomentoDePausa(quando: DateTime(2026, 10, 29, 21, 15), minutosNaHora: 30),
    ];

    for (final lang in ['pt', 'en', 'es', 'zh']) {
      test('$lang: completos, sem chave à vista e sem repetir no dia', () {
        final t = T(lang);
        final textos = textosDasPausasDoDia(
          t,
          nomeDoPet: 'Baru',
          momentos: momentos,
          historico: HistoricoDeRecados(),
        );
        expect(textos, hasLength(3));
        for (final x in textos) {
          expect('${x.titulo} ${x.corpo}', isNot(contains('{')));
          expect(x.titulo, isNot(startsWith('pausa')));
          expect(x.modelo, startsWith(HistoricoDeRecados.prefixoDaPausa));
        }
        expect({for (final x in textos) x.modelo}, hasLength(3));
        expect(t.canalNomePausa, isNot('canalNomePausa'));
      });
    }

    test('o recado do padrão diz a hora e os minutos do momento', () {
      final modelos = modelosDaPausa(
        T('pt'),
        nomeDoPet: 'Baru',
        momento: momentos.last,
      );
      expect(modelos.first.texto.corpo, contains('21h'));
      expect(modelos.first.texto.corpo, contains('30 min'));
    });
  });

  test('o canal das pausas desce do topo', () {
    expect(
      BaruNotifications.canaisDeRecado,
      contains(BaruNotifications.canalPausa),
    );
    expect(
      BaruNotifications.importanciaDo(BaruNotifications.canalPausa),
      BaruNotifications.importanciaDo(BaruNotifications.canalConvite),
    );
  });
}
