import 'package:baru_app/data/ranking.dart';
import 'package:baru_app/l10n_ranking.dart';
import 'package:flutter_test/flutter_test.dart';

Set<String> _placeholders(String s) =>
    RegExp(r'\{\w+\}').allMatches(s).map((m) => m.group(0)!).toSet();

void main() {
  group('RankingDaSemana.doMapa', () {
    final mapa = <String, dynamic>{
      'bloqueado': false,
      'atual': true,
      'euFora': false,
      'semana': '2026-11-16',
      'membros': [
        {
          'id': 'a',
          'apelido': 'Ana',
          'papel': 'crianca',
          'eu': false,
          'saudavel': 20,
          'inteligente': 30,
          'forte': 0,
          'total': 50,
          'paginas': 30,
          'minutos': 0,
          'selos': 1,
        },
        {
          'id': 'b',
          'apelido': 'Luis',
          'papel': 'responsavel',
          'eu': true,
          'saudavel': 0,
          'inteligente': 0,
          'forte': 16,
          'total': 16,
          'paginas': 0,
          'minutos': 40,
          'selos': 0,
        },
      ],
      'historico': [
        {'semana': '2026-11-09', 'skill': 'geral', 'id': 'a', 'xp': 30},
      ],
    };

    late RankingDaSemana r;
    setUp(() => r = RankingDaSemana.doMapa(mapa));

    test('lê semana, flags e membros', () {
      expect(r.semana, DateTime(2026, 11, 16));
      expect(r.bloqueado, isFalse);
      expect(r.atual, isTrue);
      expect(r.euFora, isFalse);
      expect(r.membros, hasLength(2));
      expect(r.membros.first.apelido, 'Ana');
      expect(r.membros.last.eu, isTrue);
      expect(r.membros.first.selos, 1);
      expect(r.membros.last.minutos, 40);
    });

    test('lê o histórico de selos', () {
      expect(r.historico, hasLength(1));
      expect(r.historico.first.skill, 'geral');
      expect(r.historico.first.id, 'a');
      expect(r.historico.first.xp, 30);
    });

    test('por(geral) põe Ana na frente', () {
      final ordem = r.por('geral');
      expect(ordem.first.id, 'a');
      expect(ordem.last.id, 'b');
    });

    test('por(forte) põe Luis na frente', () {
      final ordem = r.por('forte');
      expect(ordem.first.id, 'b');
      expect(ordem.first.apelido, 'Luis');
    });

    test('xpDe(geral) é igual ao total', () {
      for (final m in r.membros) {
        expect(m.xpDe('geral'), m.total);
      }
    });

    test('nomeDe devolve o apelido, ou travessão se não existir', () {
      expect(r.nomeDe('a'), 'Ana');
      expect(r.nomeDe('zzz'), '—');
    });
  });

  group('RankingDaSemana.doMapa com mapa bloqueado', () {
    test('zera os totais e marca bloqueado', () {
      final r = RankingDaSemana.doMapa({
        'bloqueado': true,
        'semana': '2026-11-16',
        'membros': [
          {'id': 'a', 'apelido': 'Ana', 'papel': 'crianca', 'eu': false},
        ],
      });
      expect(r.bloqueado, isTrue);
      expect(r.membros.first.total, 0);
      expect(r.membros.first.xpDe('geral'), 0);
    });
  });

  group('textosDoRanking', () {
    final chaves = textosDoRanking['pt']!.keys;

    test('en, es e zh existem', () {
      expect(textosDoRanking.keys, containsAll(['pt', 'en', 'es', 'zh']));
    });

    for (final lang in ['en', 'es', 'zh']) {
      test('$lang tem exatamente as chaves do pt', () {
        expect(textosDoRanking[lang]!.keys.toSet(), chaves.toSet());
      });

      test('$lang mantém os placeholders do pt', () {
        for (final k in chaves) {
          expect(_placeholders(textosDoRanking[lang]![k]!),
              _placeholders(textosDoRanking['pt']![k]!),
              reason: 'chave $k em $lang');
        }
      });

      test('$lang não tem valores vazios', () {
        for (final entry in textosDoRanking[lang]!.entries) {
          expect(entry.value.trim(), isNotEmpty, reason: 'chave ${entry.key}');
        }
      });
    }
  });
}
