import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modo família (docs/CONTROLE_PARENTAL.md). Tudo passa pelas funções
/// `baru_familia_*` do banco (migration 20261119000000_baru_familia): as
/// tabelas não são lidas direto, e cada função confere o papel de quem chama.

@immutable
class RegrasDaFamilia {
  const RegrasDaFamilia({
    this.metaMin = 120,
    this.metaFdsMin,
    this.metaHojeMin,
    this.extraHojeMin = 0,
    this.pausaAte,
    this.avisos = avisosPadrao,
    this.horariosSemTela = const [],
    this.pausarAoEstourar = false,
    this.filtroSites = false,
    this.atualizadoEm,
  });

  /// Quais avisos o responsável vê sobre esta criança.
  static const avisosPadrao = {'meta_75': true, 'meta_batida': true, 'meta_passou': true, 'autorizacao': true, 'regras': false};

  factory RegrasDaFamilia.doMapa(Map<dynamic, dynamic> m) => RegrasDaFamilia(
        metaMin: (m['meta_min'] as num?)?.toInt() ?? 120,
        metaFdsMin: (m['meta_fds_min'] as num?)?.toInt(),
        metaHojeMin: (m['meta_hoje'] as num?)?.toInt(),
        extraHojeMin: (m['extra_hoje'] as num?)?.toInt() ?? 0,
        pausaAte: DateTime.tryParse('${m['pausa_ate']}'),
        avisos: {
          ...avisosPadrao,
          for (final e in ((m['avisos'] as Map?) ?? const {}).entries) '${e.key}': e.value == true,
        },
        horariosSemTela: ((m['horarios_sem_tela'] as List?) ?? const [])
            .whereType<Map>()
            .map(HorarioSemTela.doMapa)
            .toList(),
        pausarAoEstourar: m['pausar_ao_estourar'] == true,
        filtroSites: m['filtro_sites'] == true,
        atualizadoEm: DateTime.tryParse('${m['atualizado_em']}'),
      );

  /// Meta dos dias de aula (segunda a sexta).
  final int metaMin;

  /// Meta do fim de semana; nula = igual à dos dias de aula.
  final int? metaFdsMin;

  /// A meta que vale hoje, já com o fim de semana e o tempo extra (vem do banco).
  final int? metaHojeMin;
  final int extraHojeMin;

  /// Tela pausada pelo responsável até este instante (nulo = sem pausa).
  final DateTime? pausaAte;
  final Map<String, bool> avisos;
  final List<HorarioSemTela> horariosSemTela;
  final bool pausarAoEstourar;
  final bool filtroSites;
  final DateTime? atualizadoEm;

  /// Meta de hoje: a do banco, ou calculada aqui quando ele não mandou.
  int metaDe(DateTime dia) =>
      metaHojeMin ?? ((dia.weekday >= 6 ? (metaFdsMin ?? metaMin) : metaMin) + extraHojeMin);

  bool pausadaEm(DateTime t) => pausaAte != null && t.isBefore(pausaAte!);

  /// Algum horário sem tela vale agora?
  HorarioSemTela? horarioAgora(DateTime t) {
    for (final h in horariosSemTela) {
      if (h.vale(t)) return h;
    }
    return null;
  }

  Map<String, Object?> paraSalvar() => {
        'meta_min': metaMin,
        'meta_fds_min': metaFdsMin,
        'horarios_sem_tela': horariosSemTela.map((h) => h.paraMapa()).toList(),
        'pausar_ao_estourar': pausarAoEstourar,
        'filtro_sites': filtroSites,
        'avisos': avisos,
      };

  RegrasDaFamilia copia({
    int? metaMin,
    int? Function()? metaFdsMin,
    List<HorarioSemTela>? horariosSemTela,
    bool? pausarAoEstourar,
    bool? filtroSites,
    Map<String, bool>? avisos,
  }) =>
      RegrasDaFamilia(
        metaMin: metaMin ?? this.metaMin,
        metaFdsMin: metaFdsMin != null ? metaFdsMin() : this.metaFdsMin,
        metaHojeMin: null,
        extraHojeMin: extraHojeMin,
        pausaAte: pausaAte,
        avisos: avisos ?? this.avisos,
        horariosSemTela: horariosSemTela ?? this.horariosSemTela,
        pausarAoEstourar: pausarAoEstourar ?? this.pausarAoEstourar,
        filtroSites: filtroSites ?? this.filtroSites,
        atualizadoEm: atualizadoEm,
      );
}

/// Faixa sem tela, por exemplo dias úteis das 21:00 às 07:00.
@immutable
class HorarioSemTela {
  const HorarioSemTela({required this.dias, required this.inicio, required this.fim, this.nome});

  factory HorarioSemTela.doMapa(Map<dynamic, dynamic> m) => HorarioSemTela(
        nome: (m['nome'] as String?)?.trim().isEmpty ?? true ? null : (m['nome'] as String).trim(),
        dias: ((m['dias'] as List?) ?? const []).map((e) => (e as num).toInt()).toList(),
        inicio: '${m['inicio'] ?? '21:00'}',
        fim: '${m['fim'] ?? '07:00'}',
      );

  /// Dias ISO: 1 = segunda … 7 = domingo.
  final List<int> dias;
  final String inicio;
  final String fim;
  final String? nome;

  Map<String, Object> paraMapa() => {'dias': dias, 'inicio': inicio, 'fim': fim, if (nome != null) 'nome': nome!};

  static int _min(String hhmm) {
    final p = hhmm.split(':');
    return int.parse(p[0]) * 60 + (p.length > 1 ? int.parse(p[1]) : 0);
  }

  /// O momento cai dentro desta faixa? Faixas que viram a meia-noite
  /// (21:00 → 07:00) contam a madrugada como parte do dia em que começaram.
  bool vale(DateTime t) {
    final agora = t.hour * 60 + t.minute;
    final ini = _min(inicio), fimMin = _min(fim);
    if (ini <= fimMin) return dias.contains(t.weekday) && agora >= ini && agora < fimMin;
    if (agora >= ini) return dias.contains(t.weekday);
    final ontem = t.weekday == 1 ? 7 : t.weekday - 1;
    return agora < fimMin && dias.contains(ontem);
  }
}

@immutable
class DiaDaCrianca {
  const DiaDaCrianca({
    required this.dia,
    this.plataforma,
    this.minutos,
    this.limiarMaxMin,
    this.metaMin,
    this.metaBatidaEm,
    this.focos = 0,
    this.pausas = 0,
  });

  factory DiaDaCrianca.doMapa(Map<dynamic, dynamic> m) => DiaDaCrianca(
        dia: DateTime.parse('${m['dia']}'),
        plataforma: m['plataforma'] as String?,
        minutos: (m['minutos'] as num?)?.toInt(),
        limiarMaxMin: (m['limiar_max_min'] as num?)?.toInt(),
        metaMin: (m['meta_min'] as num?)?.toInt(),
        metaBatidaEm: DateTime.tryParse('${m['meta_batida_em']}'),
        focos: (m['focos'] as num?)?.toInt() ?? 0,
        pausas: (m['pausas'] as num?)?.toInt() ?? 0,
      );

  final DateTime dia;
  final String? plataforma;

  /// Android: minutos exatos.
  final int? minutos;

  /// iOS: maior limiar da meta atingido (piso; a Apple não entrega o exato).
  final int? limiarMaxMin;
  final int? metaMin;
  final DateTime? metaBatidaEm;
  final int focos;
  final int pausas;

  /// Uso do dia como dá para saber: exato no Android, "pelo menos" no iOS.
  int get usoMin => minutos ?? limiarMaxMin ?? 0;
  bool get usoExato => minutos != null;
  bool get metaBatida => metaBatidaEm != null;
}

@immutable
class CriancaNaFamilia {
  const CriancaNaFamilia({
    required this.id,
    this.apelido,
    this.plataforma,
    this.especie,
    this.nomeDoBicho,
    this.regras = const RegrasDaFamilia(),
    this.hoje,
    this.semana = const [],
  });

  factory CriancaNaFamilia.doMapa(Map<dynamic, dynamic> m) {
    final bicho = m['bicho'] as Map?;
    final regras = m['regras'] as Map?;
    final hoje = m['hoje'] as Map?;
    return CriancaNaFamilia(
      id: '${m['id']}',
      apelido: m['apelido'] as String?,
      plataforma: m['plataforma'] as String?,
      especie: bicho?['especie'] as String?,
      nomeDoBicho: bicho?['nome'] as String?,
      regras: regras == null ? const RegrasDaFamilia() : RegrasDaFamilia.doMapa(regras),
      hoje: hoje == null ? null : DiaDaCrianca.doMapa(hoje),
      semana: ((m['semana'] as List?) ?? const []).whereType<Map>().map(DiaDaCrianca.doMapa).toList(),
    );
  }

  final String id;
  final String? apelido;
  final String? plataforma;
  final String? especie;
  final String? nomeDoBicho;
  final RegrasDaFamilia regras;
  final DiaDaCrianca? hoje;
  final List<DiaDaCrianca> semana;
}

@immutable
class EventoDaFamilia {
  const EventoDaFamilia({required this.em, required this.tipo, this.criancaId, this.detalhe});

  factory EventoDaFamilia.doMapa(Map<dynamic, dynamic> m) => EventoDaFamilia(
        em: DateTime.parse('${m['em']}'),
        tipo: '${m['tipo']}',
        criancaId: m['crianca_id'] as String?,
        detalhe: m['detalhe'] as Map?,
      );

  final DateTime em;

  /// entrou, saiu, meta_75, meta_batida, meta_passou, regras_mudaram, autorizacao_revogada.
  final String tipo;
  final String? criancaId;
  final Map<dynamic, dynamic>? detalhe;
}

@immutable
class Familia {
  const Familia({
    required this.id,
    required this.nome,
    required this.meuPapel,
    this.responsaveis = const [],
    this.criancas = const [],
    this.apelidosDasCriancas = const [],
    this.eventos = const [],
  });

  factory Familia.doMapa(Map<dynamic, dynamic> m) {
    final papel = '${m['meuPapel']}';
    final criancas = ((m['criancas'] as List?) ?? const []).whereType<Map>().toList();
    final souResponsavel = papel == 'responsavel';
    return Familia(
      id: '${m['id']}',
      nome: '${m['nome']}',
      meuPapel: papel,
      responsaveis: ((m['responsaveis'] as List?) ?? const [])
          .whereType<Map>()
          .map((r) => (r['apelido'] ?? r['email'] ?? '').toString())
          .toList(),
      criancas: souResponsavel ? criancas.map(CriancaNaFamilia.doMapa).toList() : const [],
      apelidosDasCriancas: criancas.map((c) => '${c['apelido'] ?? ''}').toList(),
      eventos: ((m['eventos'] as List?) ?? const []).whereType<Map>().map(EventoDaFamilia.doMapa).toList(),
    );
  }

  final String id;
  final String nome;

  /// `responsavel` ou `crianca`.
  final String meuPapel;
  final List<String> responsaveis;

  /// Só preenchido para o responsável.
  final List<CriancaNaFamilia> criancas;
  final List<String> apelidosDasCriancas;
  final List<EventoDaFamilia> eventos;

  bool get souResponsavel => meuPapel == 'responsavel';
}

@immutable
class MinhaFamilia {
  const MinhaFamilia({this.souCrianca = false, this.minhasRegras, this.familias = const []});

  factory MinhaFamilia.doMapa(Map<dynamic, dynamic> m) {
    final regras = m['minhasRegras'] as Map?;
    return MinhaFamilia(
      souCrianca: m['souCrianca'] == true,
      minhasRegras: regras == null ? null : RegrasDaFamilia.doMapa(regras),
      familias: ((m['familias'] as List?) ?? const []).whereType<Map>().map(Familia.doMapa).toList(),
    );
  }

  static const vazia = MinhaFamilia();

  /// Este aparelho é de uma criança numa família.
  final bool souCrianca;

  /// Regras que valem para esta conta (só se souCrianca).
  final RegrasDaFamilia? minhasRegras;
  final List<Familia> familias;

  bool get souResponsavel => familias.any((f) => f.souResponsavel);
}

/// Código de convite: 6 letras/números, sem os que se confundem (0/O, 1/I).
@immutable
class ConviteDaFamilia {
  const ConviteDaFamilia({required this.codigo, required this.expiraEm, required this.papel});

  factory ConviteDaFamilia.doMapa(Map<dynamic, dynamic> m) => ConviteDaFamilia(
        codigo: '${m['codigo']}',
        expiraEm: DateTime.parse('${m['expiraEm']}'),
        papel: '${m['papel']}',
      );

  final String codigo;
  final DateTime expiraEm;
  final String papel;
}

class FamiliaRepo {
  FamiliaRepo([SupabaseClient? client]) : _fixo = client;

  final SupabaseClient? _fixo;
  SupabaseClient get _c => _fixo ?? Supabase.instance.client;

  Future<MinhaFamilia> minha() async {
    final r = await _c.rpc('baru_familia_minha');
    return r is Map ? MinhaFamilia.doMapa(r) : MinhaFamilia.vazia;
  }

  // ------------------------------------------------ responsável

  Future<String> criar(String nome) async => '${await _c.rpc('baru_familia_criar', params: {'p_nome': nome})}';

  Future<ConviteDaFamilia> convidar(String familiaId, {bool crianca = true, String? apelido}) async {
    final r = await _c.rpc('baru_familia_convidar', params: {
      'p_familia': familiaId,
      'p_papel': crianca ? 'crianca' : 'responsavel',
      'p_apelido': apelido,
    });
    return ConviteDaFamilia.doMapa(r as Map);
  }

  Future<RegrasDaFamilia> definirRegras(
    String criancaId, {
    int? metaMin,
    List<HorarioSemTela>? horarios,
    bool? pausarAoEstourar,
    bool? filtroSites,
  }) async {
    final r = await _c.rpc('baru_familia_definir_regras', params: {
      'p_crianca': criancaId,
      'p_meta_min': metaMin,
      'p_horarios': horarios?.map((h) => h.paraMapa()).toList(),
      'p_pausar': pausarAoEstourar,
      'p_filtro_sites': filtroSites,
    });
    return RegrasDaFamilia.doMapa(r as Map);
  }

  /// Salva as regras de uma vez (meta dos dois tipos de dia, horários,
  /// pausa, filtro e avisos).
  Future<RegrasDaFamilia> salvarRegras(String criancaId, RegrasDaFamilia r) async {
    final res = await _c.rpc('baru_familia_salvar_regras', params: {'p_crianca': criancaId, 'p_regras': r.paraSalvar()});
    return RegrasDaFamilia.doMapa(res as Map);
  }

  /// Minutos a mais só hoje (negativo tira).
  Future<RegrasDaFamilia> tempoExtra(String criancaId, int minutos) async {
    final res = await _c.rpc('baru_familia_tempo_extra', params: {'p_crianca': criancaId, 'p_min': minutos});
    return RegrasDaFamilia.doMapa(res as Map);
  }

  /// Pausa a tela até [ate]; nulo retoma.
  Future<RegrasDaFamilia> pausar(String criancaId, DateTime? ate) async {
    final res = await _c.rpc('baru_familia_pausar', params: {'p_crianca': criancaId, 'p_ate': ate?.toUtc().toIso8601String()});
    return RegrasDaFamilia.doMapa(res as Map);
  }

  Future<void> remover(String familiaId, String userId) =>
      _c.rpc('baru_familia_remover', params: {'p_familia': familiaId, 'p_user': userId});

  // ------------------------------------------------ aparelho da criança

  Future<MinhaFamilia> entrar(String codigo, {required String plataforma}) async {
    final r = await _c.rpc('baru_familia_entrar', params: {'p_codigo': codigo.trim().toUpperCase(), 'p_plataforma': plataforma});
    return MinhaFamilia.doMapa(r as Map);
  }

  /// Android manda [minutos]; iOS manda [limiarMaxMin]. Devolve as regras atuais.
  Future<RegrasDaFamilia?> registrarDia({
    required String plataforma,
    int? minutos,
    int? limiarMaxMin,
    int? focos,
    int? pausas,
  }) async {
    final r = await _c.rpc('baru_familia_registrar_dia', params: {
      'p_plataforma': plataforma,
      'p_minutos': minutos,
      'p_limiar_max_min': limiarMaxMin,
      'p_focos': focos,
      'p_pausas': pausas,
    });
    return r is Map ? RegrasDaFamilia.doMapa(r) : null;
  }

  Future<void> avisarAutorizacao({required bool ativa}) =>
      _c.rpc('baru_familia_avisar_autorizacao', params: {'p_ativa': ativa});
}
