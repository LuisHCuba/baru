import 'package:baru_app/data/familia.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MinhaFamilia.doMapa', () {
    test('responsável vê o dia de cada criança', () {
      final m = MinhaFamilia.doMapa({
        'souCrianca': false,
        'minhasRegras': null,
        'familias': [
          {
            'id': 'f1',
            'nome': 'Casa',
            'meuPapel': 'responsavel',
            'responsaveis': [
              {'id': 'p1', 'apelido': null, 'email': 'pai@exemplo.com'},
            ],
            'criancas': [
              {
                'id': 'c1',
                'apelido': 'Nina',
                'plataforma': 'ios',
                'bicho': {'especie': 'owl', 'nome': 'Coruja'},
                'regras': {'meta_min': 60, 'horarios_sem_tela': [], 'pausar_ao_estourar': true, 'filtro_sites': false},
                'hoje': {'dia': '2026-11-18', 'plataforma': 'ios', 'minutos': null, 'limiar_max_min': 60, 'meta_batida_em': '2026-11-18T20:00:00Z', 'focos': 2, 'pausas': 1},
                'semana': [],
              },
            ],
            'eventos': [
              {'em': '2026-11-18T20:00:00Z', 'tipo': 'meta_batida', 'crianca_id': 'c1', 'detalhe': {'uso': 60}},
            ],
          },
        ],
      });
      expect(m.souResponsavel, isTrue);
      final c = m.familias.single.criancas.single;
      expect(c.regras.metaMin, 60);
      expect(c.regras.pausarAoEstourar, isTrue);
      expect(c.hoje!.usoMin, 60);
      expect(c.hoje!.usoExato, isFalse);
      expect(c.hoje!.metaBatida, isTrue);
      expect(m.familias.single.eventos.single.tipo, 'meta_batida');
      expect(m.familias.single.responsaveis.single, 'pai@exemplo.com');
    });

    test('criança vê só os apelidos e as próprias regras', () {
      final m = MinhaFamilia.doMapa({
        'souCrianca': true,
        'minhasRegras': {'meta_min': 90},
        'familias': [
          {'id': 'f1', 'nome': 'Casa', 'meuPapel': 'crianca', 'responsaveis': [], 'criancas': [{'apelido': 'Nina'}], 'eventos': null},
        ],
      });
      expect(m.souCrianca, isTrue);
      expect(m.minhasRegras!.metaMin, 90);
      expect(m.familias.single.criancas, isEmpty);
      expect(m.familias.single.apelidosDasCriancas, ['Nina']);
    });
  });

  group('RegrasDaFamilia', () {
    test('meta de hoje: fim de semana e extra', () {
      final r = RegrasDaFamilia.doMapa({'meta_min': 60, 'meta_fds_min': 120, 'extra_hoje': 30});
      expect(r.metaDe(DateTime(2026, 11, 18)), 90); // quarta: 60 + 30
      expect(r.metaDe(DateTime(2026, 11, 21)), 150); // sábado: 120 + 30
      expect(RegrasDaFamilia.doMapa({'meta_min': 60, 'meta_hoje': 75}).metaDe(DateTime(2026, 11, 21)), 75);
    });

    test('pausa e horário de agora', () {
      final r = RegrasDaFamilia.doMapa({
        'pausa_ate': '2026-11-18T22:00:00Z',
        'horarios_sem_tela': [
          {'nome': 'Escola', 'dias': [1, 2, 3, 4, 5], 'inicio': '07:30', 'fim': '12:00'},
        ],
      });
      expect(r.pausadaEm(DateTime.utc(2026, 11, 18, 21)), isTrue);
      expect(r.pausadaEm(DateTime.utc(2026, 11, 18, 23)), isFalse);
      expect(r.horarioAgora(DateTime(2026, 11, 18, 9))?.nome, 'Escola');
      expect(r.horarioAgora(DateTime(2026, 11, 18, 13)), isNull);
    });

    test('avisos: o que veio por cima do padrão', () {
      final r = RegrasDaFamilia.doMapa({'avisos': {'meta_75': false}});
      expect(r.avisos['meta_75'], isFalse);
      expect(r.avisos['meta_batida'], isTrue);
    });

    test('o que vai para o banco', () {
      final r = RegrasDaFamilia.doMapa({'meta_min': 90}).copia(metaFdsMin: () => 150, avisos: {'regras': true});
      final m = r.paraSalvar();
      expect(m['meta_min'], 90);
      expect(m['meta_fds_min'], 150);
      expect((m['avisos'] as Map)['regras'], isTrue);
      expect(r.copia(metaFdsMin: () => null).paraSalvar()['meta_fds_min'], isNull);
    });
  });

  group('HorarioSemTela.vale', () {
    const noite = HorarioSemTela(dias: [1, 2, 3, 4, 5], inicio: '21:00', fim: '07:00');

    test('segunda 22h vale', () => expect(noite.vale(DateTime(2026, 11, 16, 22)), isTrue));
    test('terça 6h vale (madrugada da segunda)', () => expect(noite.vale(DateTime(2026, 11, 17, 6)), isTrue));
    test('segunda 6h não vale (madrugada do domingo)', () => expect(noite.vale(DateTime(2026, 11, 16, 6)), isFalse));
    test('sábado 22h não vale', () => expect(noite.vale(DateTime(2026, 11, 21, 22)), isFalse));
    test('meio da tarde não vale', () => expect(noite.vale(DateTime(2026, 11, 17, 15)), isFalse));

    test('faixa no mesmo dia', () {
      const escola = HorarioSemTela(dias: [1, 2, 3, 4, 5], inicio: '07:30', fim: '12:00');
      expect(escola.vale(DateTime(2026, 11, 17, 9)), isTrue);
      expect(escola.vale(DateTime(2026, 11, 17, 12)), isFalse);
    });
  });
}
