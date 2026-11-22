import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Uma pessoa no ranking semanal do laço (só totais; os registros são privados).
@immutable
class PosicaoNoRanking {
  const PosicaoNoRanking({required this.id, required this.apelido, required this.papel, required this.eu,
      this.saudavel = 0, this.inteligente = 0, this.forte = 0, this.total = 0, this.paginas = 0, this.minutos = 0, this.selos = 0});

  factory PosicaoNoRanking.doMapa(Map<dynamic, dynamic> m) {
    int n(String k) => (m[k] as num?)?.toInt() ?? 0;
    return PosicaoNoRanking(
      id: '${m['id']}',
      apelido: '${m['apelido'] ?? '—'}',
      papel: '${m['papel'] ?? ''}',
      eu: m['eu'] == true,
      saudavel: n('saudavel'),
      inteligente: n('inteligente'),
      forte: n('forte'),
      total: n('total'),
      paginas: n('paginas'),
      minutos: n('minutos'),
      selos: n('selos'),
    );
  }

  final String id;
  final String apelido;
  final String papel;
  final bool eu;
  final int saudavel, inteligente, forte, total, paginas, minutos, selos;

  /// XP da skill pedida ('geral' é o total).
  int xpDe(String skill) => switch (skill) {
        'saudavel' => saudavel,
        'inteligente' => inteligente,
        'forte' => forte,
        _ => total,
      };
}

@immutable
class SeloDaSemana {
  const SeloDaSemana({required this.semana, required this.skill, required this.id, required this.xp});
  factory SeloDaSemana.doMapa(Map<dynamic, dynamic> m) => SeloDaSemana(
        semana: DateTime.tryParse('${m['semana']}') ?? DateTime(2000),
        skill: '${m['skill']}',
        id: '${m['id']}',
        xp: (m['xp'] as num?)?.toInt() ?? 0,
      );
  final DateTime semana;
  final String skill;
  final String id;
  final int xp;
}

@immutable
class RankingDaSemana {
  const RankingDaSemana({required this.semana, this.bloqueado = false, this.atual = true, this.euFora = false,
      this.membros = const [], this.historico = const []});

  factory RankingDaSemana.doMapa(Map<dynamic, dynamic> m) => RankingDaSemana(
        semana: DateTime.tryParse('${m['semana']}') ?? DateTime.now(),
        bloqueado: m['bloqueado'] == true,
        atual: m['atual'] != false,
        euFora: m['euFora'] == true,
        membros: ((m['membros'] as List?) ?? const []).whereType<Map>().map(PosicaoNoRanking.doMapa).toList(),
        historico: ((m['historico'] as List?) ?? const []).whereType<Map>().map(SeloDaSemana.doMapa).toList(),
      );

  final DateTime semana;
  final bool bloqueado;
  final bool atual;
  final bool euFora;
  final List<PosicaoNoRanking> membros;
  final List<SeloDaSemana> historico;

  /// Ordenado pela skill pedida, maior XP primeiro (empate: ordem de entrada).
  List<PosicaoNoRanking> por(String skill) {
    final l = [...membros];
    l.sort((a, b) => b.xpDe(skill).compareTo(a.xpDe(skill)));
    return l;
  }

  String nomeDe(String id) => membros.firstWhere((m) => m.id == id,
      orElse: () => const PosicaoNoRanking(id: '', apelido: '—', papel: '', eu: false)).apelido;
}

class RankingRepo {
  RankingRepo([SupabaseClient? c]) : _c = c ?? Supabase.instance.client;
  final SupabaseClient _c;

  Future<RankingDaSemana> daSemana(String laco, {DateTime? semana}) async {
    final r = await _c.rpc('baru_ranking_semanal', params: {
      'p_familia': laco,
      if (semana != null) 'p_semana': '${semana.year}-${'${semana.month}'.padLeft(2, '0')}-${'${semana.day}'.padLeft(2, '0')}',
    });
    return RankingDaSemana.doMapa(r is Map ? r : const {});
  }

  Future<void> participar(String laco, bool participa) async =>
      _c.rpc('baru_ranking_participar', params: {'p_familia': laco, 'p_participa': participa});
}
