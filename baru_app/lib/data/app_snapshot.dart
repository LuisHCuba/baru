import 'package:uuid/uuid.dart';

import '../models.dart';

/// Estado persistível (local). Não inclui timer em curso, share sheet nem override de debug.
class AppSnapshot {
  const AppSnapshot({
    required this.screen,
    required this.onb,
    required this.lang,
    required this.species,
    required this.q0,
    required this.q1,
    required this.q2,
    required this.leaves,
    required this.streak,
    required this.usage,
    required this.goal,
    required this.avg,
    required this.petName,
    required this.color,
    required this.owned,
    required this.dur,
    required this.completedToday,
    required this.abandonedToday,
    required this.daysAway,
    required this.trial,
    required this.evening,
    required this.missed,
    required this.payPlan,
    required this.usageAccess,
    required this.companionshipStarted,
    required this.week,
    required this.todayIndex,
    required this.freezesLeft,
    required this.trialStartedAt,
    required this.lastOpenDate,
    required this.sessions,
    this.sessionStartedAt,
    this.sessionEndsAt,
    this.sessionDur = 0,
    this.ajustesDeCategoria = const {},
    this.xp = 0,
    this.afeto = 0,
    this.carinhosHoje = 0,
    this.sessoesConcluidas = 0,
    this.melhorSequencia = 0,
    this.diasAbaixoDaMeta = 0,
    this.marcosResgatados = const [],
    this.nivelCelebrado = 1,
    this.minutosDeFocoHoje = 0,
    this.maiorSessaoHoje = 0,
    this.sessoesNaSemana = 0,
    this.minutosNaSemana = 0,
    this.diasAbaixoNaSemana = 0,
    this.missoesResgatadas = const [],
  });

  final AppScreen screen;
  final int onb;
  final String lang;
  final Species species;
  final String? q0;
  final String? q1;
  final String? q2;
  final int leaves;
  final int streak;
  final int usage;
  final int goal;
  final int avg;
  final String petName;
  final int color;
  final List<String> owned;
  final int dur;
  final int completedToday;
  final bool abandonedToday;
  final int daysAway;
  final bool trial;
  final bool evening;
  final bool missed;
  final PayPlan payPlan;
  final bool usageAccess;
  final bool companionshipStarted;
  final List<WeekDayKind> week;
  final int todayIndex;
  final int freezesLeft;
  final DateTime? trialStartedAt;
  final DateTime lastOpenDate;
  final List<SessionRecord> sessions;

  /// Sessão de foco em curso, em relógio de parede. Local por natureza: uma
  /// sessão não continua em outro aparelho, então não vai para o Supabase.
  final DateTime? sessionStartedAt;
  final DateTime? sessionEndsAt;
  final int sessionDur;

  /// Reclassificações de app feitas pelo usuário: pacote -> nome da categoria.
  /// Guardado como texto para o JSON e para as linhas do banco.
  final Map<String, String> ajustesDeCategoria;

  // --- progressão ---------------------------------------------------------
  final int xp;

  /// Afagos completos de todos os tempos — o vínculo.
  final int afeto;

  /// Afagos que já renderam XP hoje.
  final int carinhosHoje;
  final int sessoesConcluidas;
  final int melhorSequencia;
  final int diasAbaixoDaMeta;
  final List<String> marcosResgatados;
  final int nivelCelebrado;

  // --- missões ------------------------------------------------------------
  final int minutosDeFocoHoje;
  final int maiorSessaoHoje;
  final int sessoesNaSemana;
  final int minutosNaSemana;
  final int diasAbaixoNaSemana;
  final List<String> missoesResgatadas;

  Map<String, dynamic> toJson() => {
        'v': 1,
        'screen': screen.name,
        'onb': onb,
        'lang': lang,
        'species': species.name,
        'q0': q0,
        'q1': q1,
        'q2': q2,
        'leaves': leaves,
        'streak': streak,
        'usage': usage,
        'goal': goal,
        'avg': avg,
        'petName': petName,
        'color': color,
        'owned': owned,
        'dur': dur,
        'completedToday': completedToday,
        'abandonedToday': abandonedToday,
        'daysAway': daysAway,
        'trial': trial,
        'evening': evening,
        'missed': missed,
        'payPlan': payPlan.name,
        'usageAccess': usageAccess,
        'companionshipStarted': companionshipStarted,
        'week': week.map((e) => e.name).toList(),
        'todayIndex': todayIndex,
        'freezesLeft': freezesLeft,
        'trialStartedAt': trialStartedAt?.toIso8601String(),
        'lastOpenDate': dayString(lastOpenDate),
        'sessions': sessions.map((e) => e.toJson()).toList(),
        'sessionStartedAt': sessionStartedAt?.toIso8601String(),
        'sessionEndsAt': sessionEndsAt?.toIso8601String(),
        'sessionDur': sessionDur,
        'ajustesDeCategoria': ajustesDeCategoria,
        'xp': xp,
        'afeto': afeto,
        'carinhosHoje': carinhosHoje,
        'sessoesConcluidas': sessoesConcluidas,
        'melhorSequencia': melhorSequencia,
        'diasAbaixoDaMeta': diasAbaixoDaMeta,
        'marcosResgatados': marcosResgatados,
        'nivelCelebrado': nivelCelebrado,
        'minutosDeFocoHoje': minutosDeFocoHoje,
        'maiorSessaoHoje': maiorSessaoHoje,
        'sessoesNaSemana': sessoesNaSemana,
        'minutosNaSemana': minutosNaSemana,
        'diasAbaixoNaSemana': diasAbaixoNaSemana,
        'missoesResgatadas': missoesResgatadas,
      };

  factory AppSnapshot.fromJson(Map<String, dynamic> j) {
    return AppSnapshot(
      screen: parseScreen(j['screen'] as String?),
      onb: (j['onb'] as num?)?.toInt() ?? 0,
      lang: j['lang'] as String? ?? 'pt',
      species: parseSpecies(j['species'] as String?),
      q0: j['q0'] as String?,
      q1: j['q1'] as String?,
      q2: j['q2'] as String?,
      leaves: (j['leaves'] as num?)?.toInt() ?? 0,
      streak: (j['streak'] as num?)?.toInt() ?? 0,
      usage: (j['usage'] as num?)?.toInt() ?? 0,
      goal: (j['goal'] as num?)?.toInt() ?? 180,
      avg: (j['avg'] as num?)?.toInt() ?? 240,
      petName: j['petName'] as String? ?? '',
      color: (j['color'] as num?)?.toInt() ?? 0,
      owned: (j['owned'] as List?)?.map((e) => '$e').toList() ?? const [],
      dur: (j['dur'] as num?)?.toInt() ?? 25,
      completedToday: (j['completedToday'] as num?)?.toInt() ?? 0,
      abandonedToday: j['abandonedToday'] == true,
      daysAway: (j['daysAway'] as num?)?.toInt() ?? 0,
      trial: j['trial'] == true,
      evening: j['evening'] != false,
      missed: j['missed'] != false,
      payPlan: (j['payPlan'] as String?) == 'monthly' ? PayPlan.monthly : PayPlan.annual,
      usageAccess: j['usageAccess'] == true,
      companionshipStarted: j['companionshipStarted'] == true,
      week: parseWeek(j['week']),
      todayIndex: ((j['todayIndex'] as num?)?.toInt() ?? weekdayIndex()).clamp(0, 6),
      freezesLeft: (j['freezesLeft'] as num?)?.toInt() ?? 1,
      trialStartedAt: DateTime.tryParse(j['trialStartedAt'] as String? ?? ''),
      lastOpenDate: parseDay(j['lastOpenDate'] as String?),
      sessions: (j['sessions'] as List?)
              ?.whereType<Map>()
              .map((e) => SessionRecord.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      sessionStartedAt:
          DateTime.tryParse(j['sessionStartedAt'] as String? ?? ''),
      sessionEndsAt: DateTime.tryParse(j['sessionEndsAt'] as String? ?? ''),
      sessionDur: (j['sessionDur'] as num?)?.toInt() ?? 0,
      ajustesDeCategoria: (j['ajustesDeCategoria'] as Map?)?.map(
            (k, v) => MapEntry('$k', '$v'),
          ) ??
          const {},
      xp: (j['xp'] as num?)?.toInt() ?? 0,
      afeto: (j['afeto'] as num?)?.toInt() ?? 0,
      carinhosHoje: (j['carinhosHoje'] as num?)?.toInt() ?? 0,
      sessoesConcluidas: (j['sessoesConcluidas'] as num?)?.toInt() ?? 0,
      melhorSequencia: (j['melhorSequencia'] as num?)?.toInt() ?? 0,
      diasAbaixoDaMeta: (j['diasAbaixoDaMeta'] as num?)?.toInt() ?? 0,
      marcosResgatados:
          (j['marcosResgatados'] as List?)?.map((e) => '$e').toList() ??
              const [],
      nivelCelebrado: (j['nivelCelebrado'] as num?)?.toInt() ?? 1,
      minutosDeFocoHoje: (j['minutosDeFocoHoje'] as num?)?.toInt() ?? 0,
      maiorSessaoHoje: (j['maiorSessaoHoje'] as num?)?.toInt() ?? 0,
      sessoesNaSemana: (j['sessoesNaSemana'] as num?)?.toInt() ?? 0,
      minutosNaSemana: (j['minutosNaSemana'] as num?)?.toInt() ?? 0,
      diasAbaixoNaSemana: (j['diasAbaixoNaSemana'] as num?)?.toInt() ?? 0,
      missoesResgatadas:
          (j['missoesResgatadas'] as List?)?.map((e) => '$e').toList() ??
              const [],
    );
  }

  static String dayString(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime parseDay(String? raw) {
    final p = DateTime.tryParse(raw ?? '');
    if (p != null) return DateTime(p.year, p.month, p.day);
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static AppScreen parseScreen(String? n) {
    for (final s in AppScreen.values) {
      if (s.name == n) {
        if (s == AppScreen.session) return AppScreen.home;
        return s;
      }
    }
    return AppScreen.onb;
  }

  static Species parseSpecies(String? n) {
    for (final s in Species.values) {
      if (s.name == n) return s;
    }
    return Species.capybara;
  }

  AppSnapshot copyWith({
    AppScreen? screen,
    int? onb,
    String? lang,
    Species? species,
    String? q0,
    String? q1,
    String? q2,
    int? leaves,
    int? streak,
    int? usage,
    int? goal,
    int? avg,
    String? petName,
    int? color,
    List<String>? owned,
    int? dur,
    int? completedToday,
    bool? abandonedToday,
    int? daysAway,
    bool? trial,
    bool? evening,
    bool? missed,
    PayPlan? payPlan,
    bool? usageAccess,
    bool? companionshipStarted,
    List<WeekDayKind>? week,
    int? todayIndex,
    int? freezesLeft,
    DateTime? trialStartedAt,
    DateTime? lastOpenDate,
    List<SessionRecord>? sessions,
    DateTime? sessionStartedAt,
    DateTime? sessionEndsAt,
    int? sessionDur,
    Map<String, String>? ajustesDeCategoria,
    int? xp,
    int? afeto,
    int? carinhosHoje,
    int? sessoesConcluidas,
    int? melhorSequencia,
    int? diasAbaixoDaMeta,
    List<String>? marcosResgatados,
    int? nivelCelebrado,
    int? minutosDeFocoHoje,
    int? maiorSessaoHoje,
    int? sessoesNaSemana,
    int? minutosNaSemana,
    int? diasAbaixoNaSemana,
    List<String>? missoesResgatadas,
    bool clearQuiz = false,
    bool clearTrialStart = false,
    bool clearSession = false,
  }) {
    return AppSnapshot(
      screen: screen ?? this.screen,
      onb: onb ?? this.onb,
      lang: lang ?? this.lang,
      species: species ?? this.species,
      q0: clearQuiz ? q0 : (q0 ?? this.q0),
      q1: clearQuiz ? q1 : (q1 ?? this.q1),
      q2: clearQuiz ? q2 : (q2 ?? this.q2),
      leaves: leaves ?? this.leaves,
      streak: streak ?? this.streak,
      usage: usage ?? this.usage,
      goal: goal ?? this.goal,
      avg: avg ?? this.avg,
      petName: petName ?? this.petName,
      color: color ?? this.color,
      owned: owned ?? this.owned,
      dur: dur ?? this.dur,
      completedToday: completedToday ?? this.completedToday,
      abandonedToday: abandonedToday ?? this.abandonedToday,
      daysAway: daysAway ?? this.daysAway,
      trial: trial ?? this.trial,
      evening: evening ?? this.evening,
      missed: missed ?? this.missed,
      payPlan: payPlan ?? this.payPlan,
      usageAccess: usageAccess ?? this.usageAccess,
      companionshipStarted: companionshipStarted ?? this.companionshipStarted,
      week: week ?? this.week,
      todayIndex: todayIndex ?? this.todayIndex,
      freezesLeft: freezesLeft ?? this.freezesLeft,
      trialStartedAt: clearTrialStart ? trialStartedAt : (trialStartedAt ?? this.trialStartedAt),
      lastOpenDate: lastOpenDate ?? this.lastOpenDate,
      sessions: sessions ?? this.sessions,
      sessionStartedAt:
          clearSession ? null : (sessionStartedAt ?? this.sessionStartedAt),
      sessionEndsAt:
          clearSession ? null : (sessionEndsAt ?? this.sessionEndsAt),
      sessionDur: clearSession ? 0 : (sessionDur ?? this.sessionDur),
      ajustesDeCategoria: ajustesDeCategoria ?? this.ajustesDeCategoria,
      xp: xp ?? this.xp,
      afeto: afeto ?? this.afeto,
      carinhosHoje: carinhosHoje ?? this.carinhosHoje,
      sessoesConcluidas: sessoesConcluidas ?? this.sessoesConcluidas,
      melhorSequencia: melhorSequencia ?? this.melhorSequencia,
      diasAbaixoDaMeta: diasAbaixoDaMeta ?? this.diasAbaixoDaMeta,
      marcosResgatados: marcosResgatados ?? this.marcosResgatados,
      nivelCelebrado: nivelCelebrado ?? this.nivelCelebrado,
      minutosDeFocoHoje: minutosDeFocoHoje ?? this.minutosDeFocoHoje,
      maiorSessaoHoje: maiorSessaoHoje ?? this.maiorSessaoHoje,
      sessoesNaSemana: sessoesNaSemana ?? this.sessoesNaSemana,
      minutosNaSemana: minutosNaSemana ?? this.minutosNaSemana,
      diasAbaixoNaSemana: diasAbaixoNaSemana ?? this.diasAbaixoNaSemana,
      missoesResgatadas: missoesResgatadas ?? this.missoesResgatadas,
    );
  }

  static List<WeekDayKind> parseWeek(dynamic raw) {
    if (raw is! List) return freshWeek();
    final out = raw.map((e) {
      final n = '$e';
      for (final k in WeekDayKind.values) {
        if (k.name == n) return k;
      }
      return WeekDayKind.empty;
    }).toList();
    if (out.length != 7) return freshWeek();
    return out;
  }
}

class SessionRecord {
  const SessionRecord({
    required this.id,
    required this.at,
    required this.dur,
    required this.completed,
    required this.aborted,
    required this.reward,
  });

  final String id;
  final DateTime at;
  final int dur;
  final bool completed;
  final bool aborted;
  final int reward;

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': at.toIso8601String(),
        'dur': dur,
        'completed': completed,
        'aborted': aborted,
        'reward': reward,
      };

  factory SessionRecord.fromJson(Map<String, dynamic> j) {
    final at = DateTime.tryParse('${j['at'] ?? ''}') ?? DateTime.now();
    final dur = (j['dur'] as num?)?.toInt() ?? 0;
    final reward = (j['reward'] as num?)?.toInt() ?? 0;
    final completed = j['completed'] == true;
    final rawId = j['id'] as String?;
    return SessionRecord(
      id: (rawId != null && rawId.isNotEmpty)
          ? rawId
          : _legacyId(at, dur, reward, completed),
      at: at,
      dur: dur,
      completed: completed,
      aborted: j['aborted'] == true,
      reward: reward,
    );
  }

  static String _legacyId(DateTime at, int dur, int reward, bool completed) {
    final seed = '${at.toIso8601String()}|$dur|$reward|$completed';
    return const Uuid().v5(Namespace.url.value, seed);
  }
}
