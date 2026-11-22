import 'package:flutter_test/flutter_test.dart';

import 'package:baru_app/data/skills.dart';
import 'package:baru_app/l10n_skills.dart';

void main() {
  final amostra = <dynamic, dynamic>{
    'skills': [
      {'skill': 'inteligente', 'xp': 150, 'nivel': 2, 'xpDoNivel': 100, 'xpProximo': 300, 'hoje': 30},
    ],
    'registros': [
      {
        'id': 1,
        'skill': 'forte',
        'atividade': 'corrida',
        'quantidade': 30,
        'unidade': 'minutos',
        'distanciaKm': 5,
        'dia': '2026-11-22',
        'xp': 12,
        'editavel': true,
      },
    ],
    'tetoDiario': 200,
  };

  group('MinhasSkills.doMapa', () {
    test('lê skills, registros e teto diário', () {
      final m = MinhasSkills.doMapa(amostra);

      expect(m.skills, hasLength(1));
      final s = m.skills.single;
      expect(s.skill, Skill.inteligente);
      expect(s.xp, 150);
      expect(s.nivel, 2);
      expect(s.xpDoNivel, 100);
      expect(s.xpProximo, 300);
      expect(s.hoje, 30);

      expect(m.registros, hasLength(1));
      final r = m.registros.single;
      expect(r.id, 1);
      expect(r.skill, Skill.forte);
      expect(r.atividade, 'corrida');
      expect(r.quantidade, 30);
      expect(r.unidade, 'minutos');
      expect(r.distanciaKm, 5);
      expect(r.dia, DateTime.parse('2026-11-22'));
      expect(r.xp, 12);
      expect(r.editavel, isTrue);

      expect(m.tetoDiario, 200);
    });

    test('mapa vazio usa valores padrão', () {
      final m = MinhasSkills.doMapa(<dynamic, dynamic>{});
      expect(m.skills, isEmpty);
      expect(m.registros, isEmpty);
      expect(m.tetoDiario, 200);
    });
  });

  group('EstadoDaSkill.progresso', () {
    test('é 0.25 para a amostra (150 entre 100 e 300)', () {
      final s = MinhasSkills.doMapa(amostra).de(Skill.inteligente);
      expect(s.progresso, closeTo(0.25, 1e-9));
    });

    test('fica limitado entre 0 e 1', () {
      const abaixo = EstadoDaSkill(skill: Skill.forte, xp: 50, nivel: 2, xpDoNivel: 100, xpProximo: 300, hoje: 0);
      const acima = EstadoDaSkill(skill: Skill.forte, xp: 999, nivel: 2, xpDoNivel: 100, xpProximo: 300, hoje: 0);
      expect(abaixo.progresso, 0);
      expect(acima.progresso, 1);
    });

    test('é 0 quando xpProximo == xpDoNivel', () {
      const s = EstadoDaSkill(skill: Skill.saudavel, xp: 150, nivel: 2, xpDoNivel: 100, xpProximo: 100, hoje: 0);
      expect(s.progresso, 0);
    });
  });

  group('MinhasSkills.de', () {
    test('habilidade ausente volta nível 1 com 0 XP', () {
      final s = MinhasSkills.doMapa(amostra).de(Skill.saudavel);
      expect(s.skill, Skill.saudavel);
      expect(s.xp, 0);
      expect(s.nivel, 1);
      expect(s.xpDoNivel, 0);
      expect(s.xpProximo, 100);
      expect(s.hoje, 0);
    });
  });

  group('textosDasSkills', () {
    final placeholder = RegExp(r'\{[^}]+\}');

    List<String> marcadores(String texto) => placeholder.allMatches(texto).map((m) => m.group(0)!).toList()..sort();

    test('en, es e zh têm todas as chaves de pt', () {
      final chaves = textosDasSkills['pt']!.keys.toSet();
      for (final idioma in ['en', 'es', 'zh']) {
        expect(textosDasSkills.containsKey(idioma), isTrue, reason: 'falta o bloco $idioma');
        expect(textosDasSkills[idioma]!.keys.toSet(), chaves, reason: 'chaves diferentes em $idioma');
      }
    });

    test('placeholders batem com pt em cada chave', () {
      final pt = textosDasSkills['pt']!;
      for (final idioma in ['en', 'es', 'zh']) {
        final traducao = textosDasSkills[idioma]!;
        for (final chave in pt.keys) {
          expect(marcadores(traducao[chave]!), marcadores(pt[chave]!), reason: 'placeholders diferentes em $idioma/$chave');
        }
      }
    });

    test('nenhum texto traduzido está vazio', () {
      for (final bloco in textosDasSkills.values) {
        for (final entrada in bloco.entries) {
          expect(entrada.value.trim(), isNotEmpty, reason: entrada.key);
        }
      }
    });
  });
}
