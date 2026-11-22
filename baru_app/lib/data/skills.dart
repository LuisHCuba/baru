import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// As três skills do pet. XP e nível vêm sempre do servidor.
enum Skill { saudavel, inteligente, forte }

@immutable
class EstadoDaSkill {
  const EstadoDaSkill({required this.skill, required this.xp, required this.nivel, required this.xpDoNivel, required this.xpProximo, required this.hoje});

  factory EstadoDaSkill.doMapa(Map<dynamic, dynamic> m) => EstadoDaSkill(
        skill: Skill.values.firstWhere((s) => s.name == m['skill'], orElse: () => Skill.saudavel),
        xp: (m['xp'] as num?)?.toInt() ?? 0,
        nivel: (m['nivel'] as num?)?.toInt() ?? 1,
        xpDoNivel: (m['xpDoNivel'] as num?)?.toInt() ?? 0,
        xpProximo: (m['xpProximo'] as num?)?.toInt() ?? 100,
        hoje: (m['hoje'] as num?)?.toInt() ?? 0,
      );

  final Skill skill;
  final int xp;
  final int nivel;
  final int xpDoNivel;
  final int xpProximo;
  final int hoje;

  /// Quanto falta (0..1) para o próximo nível.
  double get progresso {
    final faixa = xpProximo - xpDoNivel;
    return faixa <= 0 ? 0 : ((xp - xpDoNivel) / faixa).clamp(0.0, 1.0);
  }
}

@immutable
class RegistroDeHabito {
  const RegistroDeHabito({required this.id, required this.skill, required this.atividade, required this.quantidade, required this.unidade, this.distanciaKm, required this.dia, required this.xp, required this.editavel});

  factory RegistroDeHabito.doMapa(Map<dynamic, dynamic> m) => RegistroDeHabito(
        id: (m['id'] as num).toInt(),
        skill: Skill.values.firstWhere((s) => s.name == m['skill'], orElse: () => Skill.saudavel),
        atividade: '${m['atividade']}',
        quantidade: (m['quantidade'] as num?)?.toDouble() ?? 0,
        unidade: '${m['unidade']}',
        distanciaKm: (m['distanciaKm'] as num?)?.toDouble(),
        dia: DateTime.tryParse('${m['dia']}') ?? DateTime.now(),
        xp: (m['xp'] as num?)?.toInt() ?? 0,
        editavel: m['editavel'] == true,
      );

  final int id;
  final Skill skill;
  final String atividade;
  final double quantidade;
  final String unidade;
  final double? distanciaKm;
  final DateTime dia;
  final int xp;
  final bool editavel;
}

@immutable
class MinhasSkills {
  const MinhasSkills({this.skills = const [], this.registros = const [], this.tetoDiario = 200});

  factory MinhasSkills.doMapa(Map<dynamic, dynamic> m) => MinhasSkills(
        skills: ((m['skills'] as List?) ?? const []).whereType<Map>().map(EstadoDaSkill.doMapa).toList(),
        registros: ((m['registros'] as List?) ?? const []).whereType<Map>().map(RegistroDeHabito.doMapa).toList(),
        tetoDiario: (m['tetoDiario'] as num?)?.toInt() ?? 200,
      );

  static const vazio = MinhasSkills();

  final List<EstadoDaSkill> skills;
  final List<RegistroDeHabito> registros;
  final int tetoDiario;

  EstadoDaSkill de(Skill s) => skills.firstWhere((x) => x.skill == s,
      orElse: () => EstadoDaSkill(skill: s, xp: 0, nivel: 1, xpDoNivel: 0, xpProximo: 100, hoje: 0));
}

class SkillsRepo {
  SkillsRepo([SupabaseClient? c]) : _c = c ?? Supabase.instance.client;
  final SupabaseClient _c;

  MinhasSkills _de(dynamic r) => r is Map ? MinhasSkills.doMapa(r) : MinhasSkills.vazio;

  Future<MinhasSkills> minhas() async => _de(await _c.rpc('baru_minhas_skills'));

  Future<MinhasSkills> registra({required Skill skill, required String atividade, required double quantidade, required String unidade, double? distanciaKm}) async =>
      _de(await _c.rpc('baru_registra_habito', params: {
        'p_skill': skill.name,
        'p_atividade': atividade,
        'p_quantidade': quantidade,
        'p_unidade': unidade,
        'p_distancia_km': distanciaKm,
      }));

  Future<MinhasSkills> edita(int id, double quantidade, {double? distanciaKm}) async =>
      _de(await _c.rpc('baru_edita_habito', params: {'p_id': id, 'p_quantidade': quantidade, 'p_distancia_km': distanciaKm}));

  Future<MinhasSkills> apaga(int id) async => _de(await _c.rpc('baru_apaga_habito', params: {'p_id': id}));

  /// Dia dentro da meta de tela: 20 XP de Saudável (uma vez por dia; o servidor ignora repetições).
  Future<MinhasSkills> saudavelDeHoje() async => _de(await _c.rpc('baru_saudavel_do_dia'));
}
