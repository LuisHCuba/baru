import '../models.dart';
import 'app_snapshot.dart';

/// Mapeia [AppSnapshot] ↔ tabelas normalizadas do domínio Baru.
class BaruRowCodec {
  const BaruRowCodec();

  String _nowIso() => DateTime.now().toUtc().toIso8601String();

  Map<String, dynamic> profileRow({
    required String userId,
    required String deviceId,
    required AppSnapshot s,
  }) {
    return {
      'user_id': userId,
      'device_id': deviceId,
      'screen': s.screen.name,
      'onb': s.onb,
      'lang': s.lang,
      'companionship_started': s.companionshipStarted,
      'last_open_date': AppSnapshot.dayString(s.lastOpenDate),
      'updated_at': _nowIso(),
    };
  }

  Map<String, dynamic> petRow({
    required String userId,
    required AppSnapshot s,
  }) {
    return {
      'user_id': userId,
      'species': s.species.name,
      'pet_name': s.petName,
      'coat': s.color,
      'updated_at': _nowIso(),
    };
  }

  Map<String, dynamic> onboardingRow({
    required String userId,
    required AppSnapshot s,
  }) {
    return {
      'user_id': userId,
      'q0': s.q0,
      'q1': s.q1,
      'q2': s.q2,
      'updated_at': _nowIso(),
    };
  }

  Map<String, dynamic> walletRow({
    required String userId,
    required AppSnapshot s,
  }) {
    return {
      'user_id': userId,
      'leaves': s.leaves,
      'updated_at': _nowIso(),
    };
  }

  /// `acquired_at` só vale para linha nova — o push usa `ignoreDuplicates`,
  /// então a data original de quem já está no inventário é preservada.
  List<Map<String, dynamic>> inventoryRows({
    required String userId,
    required AppSnapshot s,
  }) {
    final now = _nowIso();
    return s.owned
        .map(
          (itemId) => {
            'user_id': userId,
            'item_id': itemId,
            'acquired_at': now,
          },
        )
        .toList();
  }

  Map<String, dynamic> settingsRow({
    required String userId,
    required AppSnapshot s,
  }) {
    return {
      'user_id': userId,
      'evening_notif': s.evening,
      'missed_notif': s.missed,
      'usage_access': s.usageAccess,
      'default_duration_min': s.dur,
      'updated_at': _nowIso(),
    };
  }

  Map<String, dynamic> screenTimeRow({
    required String userId,
    required AppSnapshot s,
  }) {
    return {
      'user_id': userId,
      'usage_min': s.usage,
      'goal_min': s.goal,
      'avg_min': s.avg,
      'updated_at': _nowIso(),
    };
  }

  Map<String, dynamic> streakRow({
    required String userId,
    required AppSnapshot s,
  }) {
    return {
      'user_id': userId,
      'streak': s.streak,
      'today_index': s.todayIndex,
      'freezes_left': s.freezesLeft,
      'days_away': s.daysAway,
      'updated_at': _nowIso(),
    };
  }

  List<Map<String, dynamic>> weekRows({
    required String userId,
    required AppSnapshot s,
  }) {
    return List<Map<String, dynamic>>.generate(
      7,
      (i) => {
        'user_id': userId,
        'day_index': i,
        'kind': s.week[i].name,
      },
    );
  }

  Map<String, dynamic> dailyProgressRow({
    required String userId,
    required AppSnapshot s,
  }) {
    return {
      'user_id': userId,
      'completed_sessions': s.completedToday,
      'abandoned_today': s.abandonedToday,
      'updated_at': _nowIso(),
    };
  }

  List<Map<String, dynamic>> dailyQuestRows({
    required String userId,
    required AppSnapshot s,
  }) {
    final questDate = AppSnapshot.dayString(s.lastOpenDate);
    final now = _nowIso();
    final focusDone = s.completedToday >= 1;
    final underGoal = s.usageAccess && s.usage < s.goal;
    return [
      {
        'user_id': userId,
        'quest_date': questDate,
        'quest_key': 'focus_session',
        'completed': focusDone,
        'completed_at': focusDone ? now : null,
      },
      {
        'user_id': userId,
        'quest_date': questDate,
        'quest_key': 'under_goal',
        'completed': underGoal,
        'completed_at': underGoal ? now : null,
      },
    ];
  }

  Map<String, dynamic> subscriptionRow({
    required String userId,
    required AppSnapshot s,
  }) {
    return {
      'user_id': userId,
      'trial_active': s.trial,
      'pay_plan': s.payPlan.name,
      'trial_started_at': s.trialStartedAt?.toIso8601String(),
      'updated_at': _nowIso(),
    };
  }

  List<Map<String, dynamic>> appCategoryRows({
    required String userId,
    required AppSnapshot s,
  }) {
    final now = _nowIso();
    return s.ajustesDeCategoria.entries
        .map(
          (e) => {
            'user_id': userId,
            'package_name': e.key,
            'category': e.value,
            'updated_at': now,
          },
        )
        .toList();
  }

  Map<String, dynamic> sessionRow({
    required String userId,
    required SessionRecord s,
  }) {
    return {
      'id': s.id,
      'user_id': userId,
      'started_at': s.at.toIso8601String(),
      'duration_min': s.dur,
      'completed': s.completed,
      'aborted': s.aborted,
      'reward': s.reward,
    };
  }

  AppSnapshot fromRows({
    required Map<String, dynamic> profile,
    Map<String, dynamic>? pet,
    Map<String, dynamic>? onboarding,
    Map<String, dynamic>? wallet,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? screenTime,
    Map<String, dynamic>? streak,
    Map<String, dynamic>? daily,
    Map<String, dynamic>? subscription,
    List<Map<String, dynamic>> inventory = const [],
    List<Map<String, dynamic>> week = const [],
    List<SessionRecord> sessions = const [],
    List<Map<String, dynamic>> appCategories = const [],
  }) {
    final weekKinds = _weekFromRows(week, streak?['today_index']);
    return AppSnapshot(
      screen: AppSnapshot.parseScreen(profile['screen'] as String?),
      onb: (profile['onb'] as num?)?.toInt() ?? 0,
      lang: profile['lang'] as String? ?? 'pt',
      species: AppSnapshot.parseSpecies(pet?['species'] as String?),
      q0: onboarding?['q0'] as String?,
      q1: onboarding?['q1'] as String?,
      q2: onboarding?['q2'] as String?,
      leaves: (wallet?['leaves'] as num?)?.toInt() ?? 0,
      streak: (streak?['streak'] as num?)?.toInt() ?? 0,
      usage: (screenTime?['usage_min'] as num?)?.toInt() ?? 0,
      goal: (screenTime?['goal_min'] as num?)?.toInt() ?? 180,
      avg: (screenTime?['avg_min'] as num?)?.toInt() ?? 240,
      petName: pet?['pet_name'] as String? ?? '',
      color: (pet?['coat'] as num?)?.toInt() ?? 0,
      owned: inventory.map((e) => '${e['item_id']}').toList(),
      dur: (settings?['default_duration_min'] as num?)?.toInt() ?? 25,
      completedToday: (daily?['completed_sessions'] as num?)?.toInt() ?? 0,
      abandonedToday: daily?['abandoned_today'] == true,
      daysAway: (streak?['days_away'] as num?)?.toInt() ?? 0,
      trial: subscription?['trial_active'] == true,
      evening: settings?['evening_notif'] != false,
      missed: settings?['missed_notif'] != false,
      payPlan: (subscription?['pay_plan'] as String?) == 'monthly'
          ? PayPlan.monthly
          : PayPlan.annual,
      usageAccess: settings?['usage_access'] == true,
      companionshipStarted: profile['companionship_started'] == true,
      week: weekKinds,
      todayIndex: ((streak?['today_index'] as num?)?.toInt() ?? weekdayIndex())
          .clamp(0, 6),
      freezesLeft: (streak?['freezes_left'] as num?)?.toInt() ?? 1,
      trialStartedAt:
          DateTime.tryParse('${subscription?['trial_started_at'] ?? ''}'),
      lastOpenDate: AppSnapshot.parseDay('${profile['last_open_date'] ?? ''}'),
      sessions: sessions,
      ajustesDeCategoria: {
        for (final r in appCategories)
          '${r['package_name']}': '${r['category']}',
      },
    );
  }

  /// Compat: perfil monolítico legado (pré-migration 005).
  AppSnapshot fromLegacyProfile(
    Map<String, dynamic> row,
    List<SessionRecord> sessions,
  ) {
    return AppSnapshot(
      screen: AppSnapshot.parseScreen(row['screen'] as String?),
      onb: (row['onb'] as num?)?.toInt() ?? 0,
      lang: row['lang'] as String? ?? 'pt',
      species: AppSnapshot.parseSpecies(row['species'] as String?),
      q0: row['q0'] as String?,
      q1: row['q1'] as String?,
      q2: row['q2'] as String?,
      leaves: (row['leaves'] as num?)?.toInt() ?? 0,
      streak: (row['streak'] as num?)?.toInt() ?? 0,
      usage: (row['usage_min'] as num?)?.toInt() ?? 0,
      goal: (row['goal_min'] as num?)?.toInt() ?? 180,
      avg: (row['avg_min'] as num?)?.toInt() ?? 240,
      petName: row['pet_name'] as String? ?? '',
      color: (row['coat'] as num?)?.toInt() ?? 0,
      owned: _strList(row['owned']),
      dur: (row['dur'] as num?)?.toInt() ?? 25,
      completedToday: (row['completed_today'] as num?)?.toInt() ?? 0,
      abandonedToday: row['abandoned_today'] == true,
      daysAway: (row['days_away'] as num?)?.toInt() ?? 0,
      trial: row['trial'] == true,
      evening: row['evening'] != false,
      missed: row['missed'] != false,
      payPlan: (row['pay_plan'] as String?) == 'monthly'
          ? PayPlan.monthly
          : PayPlan.annual,
      usageAccess: row['usage_access'] == true,
      companionshipStarted: row['companionship_started'] == true,
      week: AppSnapshot.parseWeek(row['week']),
      todayIndex: ((row['today_index'] as num?)?.toInt() ?? weekdayIndex())
          .clamp(0, 6),
      freezesLeft: (row['freezes_left'] as num?)?.toInt() ?? 1,
      trialStartedAt: DateTime.tryParse('${row['trial_started_at'] ?? ''}'),
      lastOpenDate: AppSnapshot.parseDay('${row['last_open_date'] ?? ''}'),
      sessions: sessions,
    );
  }

  SessionRecord sessionFromRow(Map<String, dynamic> row) {
    return SessionRecord.fromJson({
      'id': row['id'],
      'at': row['started_at'],
      'dur': row['duration_min'],
      'completed': row['completed'],
      'aborted': row['aborted'],
      'reward': row['reward'],
    });
  }

  List<WeekDayKind> _weekFromRows(
    List<Map<String, dynamic>> rows,
    dynamic todayIndexRaw,
  ) {
    if (rows.isEmpty) return freshWeek();
    final byIndex = <int, WeekDayKind>{};
    for (final row in rows) {
      final idx = (row['day_index'] as num?)?.toInt();
      if (idx == null || idx < 0 || idx > 6) continue;
      byIndex[idx] = _parseWeekKind(row['kind'] as String?);
    }
    if (byIndex.length != 7) return freshWeek();
    return List<WeekDayKind>.generate(7, (i) => byIndex[i] ?? WeekDayKind.empty);
  }

  WeekDayKind _parseWeekKind(String? raw) {
    for (final k in WeekDayKind.values) {
      if (k.name == raw) return k;
    }
    return WeekDayKind.empty;
  }

  List<String> _strList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => '$e').toList();
  }
}
