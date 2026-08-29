import '../models.dart';
import 'app_snapshot.dart';

/// Os contadores das missões do dia e da semana, refeitos das sessões.
///
/// Não é uma linha de banco: é o resultado de uma conta. Ver
/// [BaruRowCodec.contadoresDe] para o porquê de não serem colunas.
class ContadoresDoPeriodo {
  const ContadoresDoPeriodo({
    this.minutosHoje = 0,
    this.maiorSessaoHoje = 0,
    this.sessoesNaSemana = 0,
    this.minutosNaSemana = 0,
  });

  final int minutosHoje;
  final int maiorSessaoHoje;
  final int sessoesNaSemana;
  final int minutosNaSemana;
}

/// Mapeia [AppSnapshot] ↔ tabelas normalizadas do domínio Baru.
class BaruRowCodec {
  const BaruRowCodec();

  String _nowIso() => DateTime.now().toUtc().toIso8601String();

  /// A meia-noite local de [d]. O dia é a unidade de quase toda missão.
  static DateTime _diaDe(DateTime d) => DateTime(d.year, d.month, d.day);

  /// A segunda-feira da semana de [d].
  ///
  /// Subtrai pelo campo `day` em vez de `Duration(days: n)` porque duração é
  /// tempo absoluto: num dia de mudança de horário de verão, tirar "7 × 24 h"
  /// cai numa hora antes ou depois da meia-noite e a semana anda um dia.
  /// O construtor de [DateTime] normaliza dia fora da faixa, então
  /// `DateTime(2026, 8, -2)` é julho e continua sendo meia-noite local.
  static DateTime segundaDe(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  /// Recalcula os contadores das missões diárias e semanais das sessões.
  ///
  /// **Por que estes quatro não ganharam coluna.** Cada um é uma soma sobre
  /// `baru_sessions`, que já sobe inteira. Uma coluna para cada seria um
  /// segundo registro do mesmo fato — e dois registros do mesmo fato divergem
  /// na primeira sessão que suba sem o contador (ou o contrário), sem que
  /// ninguém perceba até a missão pagar errado. O que **não** é derivável,
  /// `diasAbaixoNaSemana`, ganhou coluna: ele depende do tempo de tela de
  /// cada dia fechado, e o app só guarda o agregado do dia corrente.
  ///
  /// A janela é a do relógio de **quem lê**, não a de quem gravou. É isso que
  /// faz o contador zerar sozinho na virada do dia e na segunda-feira, sem
  /// depender de o outro aparelho ter empurrado o zero.
  ///
  /// Sessão abortada não entra: o que o quadro de missões mede é foco
  /// concluído, e `_concluiSessao` é o único lugar que incrementa no app.
  static ContadoresDoPeriodo contadoresDe(
    List<SessionRecord> sessions, {
    DateTime? agora,
  }) {
    final hoje = _diaDe(agora ?? DateTime.now());
    final segunda = segundaDe(hoje);
    final domingo = DateTime(segunda.year, segunda.month, segunda.day + 6);
    var minutosHoje = 0;
    var maiorHoje = 0;
    var sessoesSemana = 0;
    var minutosSemana = 0;
    for (final s in sessions) {
      if (!s.completed) continue;
      // O remoto devolve o instante em UTC; a missão é do dia local de quem
      // focou. Sem o `toLocal`, quem está a leste de Greenwich perde as
      // sessões da madrugada e quem está a oeste ganha as de amanhã.
      final dia = _diaDe(s.at.toLocal());
      if (dia.isBefore(segunda) || dia.isAfter(domingo)) continue;
      sessoesSemana += 1;
      minutosSemana += s.dur;
      if (dia == hoje) {
        minutosHoje += s.dur;
        if (s.dur > maiorHoje) maiorHoje = s.dur;
      }
    }
    return ContadoresDoPeriodo(
      minutosHoje: minutosHoje,
      maiorSessaoHoje: maiorHoje,
      sessoesNaSemana: sessoesSemana,
      minutosNaSemana: minutosSemana,
    );
  }

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

  Map<String, dynamic> progressionRow({
    required String userId,
    required AppSnapshot s,
  }) {
    return {
      'user_id': userId,
      'xp': s.xp,
      'nivel_celebrado': s.nivelCelebrado,
      'afeto': s.afeto,
      'carinhos_hoje': s.carinhosHoje,
      'marcos_resgatados': s.marcosResgatados,
      'missoes_resgatadas': s.missoesResgatadas,
      'sessoes_concluidas': s.sessoesConcluidas,
      'melhor_sequencia': s.melhorSequencia,
      'dias_abaixo_da_meta': s.diasAbaixoDaMeta,
      'dias_abaixo_na_semana': s.diasAbaixoNaSemana,
      // O carimbo da semana a que o contador pertence. Sem ele o número da
      // semana passada continuaria valendo na segunda-feira: a zeragem
      // acontece no aparelho e **não** marca sincronização, então o remoto
      // segue com o valor velho até a próxima gravação por outro motivo.
      'semana_de': AppSnapshot.dayString(segundaDe(s.lastOpenDate)),
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
      'sexo': s.sexo.name,
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
      // O mapa inteiro num jsonb: pergunta nova não pede migração.
      'respostas': s.respostasDoQuiz,
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
            'equipped': s.equipados.contains(itemId),
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
      'evening_hour': s.eveningHour,
      'evening_minute': s.eveningMinute,
      'missed_notif': s.missed,
      'usage_access': s.usageAccess,
      'default_duration_min': s.dur,
      // Preferência de som. Estava no snapshot local e em lugar nenhum do
      // banco: quem desligava o som reinstalava o app e o som voltava.
      'som': s.som,
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

  Map<String, dynamic> subscriptionRow({
    required String userId,
    required AppSnapshot s,
  }) {
    return {
      'user_id': userId,
      'trial_active': s.trial,
      'pay_plan': s.payPlan.name,
      // `toUtc` antes do ISO, e não o instante local cru: sem fuso na string,
      // o Postgres lê o horário como se fosse UTC e o trial começa às 12h
      // para quem começou às 9h. `timestamptz` guarda instante, não relógio
      // de parede.
      'trial_started_at': s.trialStartedAt?.toUtc().toIso8601String(),
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
      // Mesma razão do `trial_started_at`: `DateTime.now()` é local e o ISO
      // dele sai **sem** fuso. O Postgres então assume UTC, e a sessão das 9h
      // volta como 6h — o suficiente para cair no dia anterior e sumir das
      // missões do dia.
      'started_at': s.at.toUtc().toIso8601String(),
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
    Map<String, dynamic>? progresso,
    List<Map<String, dynamic>> inventory = const [],
    List<Map<String, dynamic>> week = const [],
    List<SessionRecord> sessions = const [],
    List<Map<String, dynamic>> appCategories = const [],
    DateTime? agora,
  }) {
    final weekKinds = _weekFromRows(week, streak?['today_index']);
    final quando = agora ?? DateTime.now();
    final contadores = contadoresDe(sessions, agora: quando);
    return AppSnapshot(
      screen: AppSnapshot.parseScreen(profile['screen'] as String?),
      onb: (profile['onb'] as num?)?.toInt() ?? 0,
      lang: profile['lang'] as String? ?? 'pt',
      species: AppSnapshot.parseSpecies(pet?['species'] as String?),
      q0: onboarding?['q0'] as String?,
      q1: onboarding?['q1'] as String?,
      q2: onboarding?['q2'] as String?,
      respostasDoQuiz: {
        for (final e
            in (onboarding?['respostas'] as Map? ?? const {}).entries)
          '${e.key}': '${e.value}',
      },
      leaves: (wallet?['leaves'] as num?)?.toInt() ?? 0,
      streak: (streak?['streak'] as num?)?.toInt() ?? 0,
      usage: (screenTime?['usage_min'] as num?)?.toInt() ?? 0,
      goal: (screenTime?['goal_min'] as num?)?.toInt() ?? 180,
      avg: (screenTime?['avg_min'] as num?)?.toInt() ?? 240,
      petName: pet?['pet_name'] as String? ?? '',
      color: (pet?['coat'] as num?)?.toInt() ?? 0,
      sexo: AppSnapshot.parseSexo(pet?['sexo'] as String?),
      eveningHour: (settings?['evening_hour'] as num?)?.toInt() ?? 21,
      eveningMinute: (settings?['evening_minute'] as num?)?.toInt() ?? 0,
      owned: inventory.map((e) => '${e['item_id']}').toList(),
      equipados: _equipadosDe(inventory),
      dur: (settings?['default_duration_min'] as num?)?.toInt() ?? 25,
      completedToday: (daily?['completed_sessions'] as num?)?.toInt() ?? 0,
      abandonedToday: daily?['abandoned_today'] == true,
      daysAway: (streak?['days_away'] as num?)?.toInt() ?? 0,
      trial: subscription?['trial_active'] == true,
      evening: settings?['evening_notif'] != false,
      // Coluna ausente cai no padrão do app, igual a `evening` e `missed`:
      // contra um banco atrasado o som fica ligado, que é o padrão de quem
      // nunca mexeu — nunca desligado por acidente.
      som: settings?['som'] != false,
      missed: settings?['missed_notif'] != false,
      payPlan: (subscription?['pay_plan'] as String?) == 'monthly'
          ? PayPlan.monthly
          : PayPlan.annual,
      usageAccess: settings?['usage_access'] == true,
      companionshipStarted: profile['companionship_started'] == true,
      xp: (progresso?['xp'] as num?)?.toInt() ?? 0,
      nivelCelebrado: (progresso?['nivel_celebrado'] as num?)?.toInt() ?? 1,
      afeto: (progresso?['afeto'] as num?)?.toInt() ?? 0,
      carinhosHoje: (progresso?['carinhos_hoje'] as num?)?.toInt() ?? 0,
      marcosResgatados:
          (progresso?['marcos_resgatados'] as List?)
                  ?.map((e) => '$e')
                  .toList() ??
              const [],
      missoesResgatadas:
          (progresso?['missoes_resgatadas'] as List?)
                  ?.map((e) => '$e')
                  .toList() ??
              const [],
      sessoesConcluidas:
          (progresso?['sessoes_concluidas'] as num?)?.toInt() ?? 0,
      melhorSequencia:
          (progresso?['melhor_sequencia'] as num?)?.toInt() ?? 0,
      diasAbaixoDaMeta:
          (progresso?['dias_abaixo_da_meta'] as num?)?.toInt() ?? 0,
      diasAbaixoNaSemana: _diasAbaixoNaSemana(progresso, quando),
      // Os quatro contadores de missão saem da conta sobre as sessões, não de
      // coluna. Ver [contadoresDe].
      minutosDeFocoHoje: contadores.minutosHoje,
      maiorSessaoHoje: contadores.maiorSessaoHoje,
      sessoesNaSemana: contadores.sessoesNaSemana,
      minutosNaSemana: contadores.minutosNaSemana,
      week: weekKinds,
      todayIndex: ((streak?['today_index'] as num?)?.toInt() ?? weekdayIndex())
          .clamp(0, 6),
      freezesLeft: (streak?['freezes_left'] as num?)?.toInt() ?? 1,
      // `toLocal` porque o remoto devolve `+00:00` e todo o resto do app
      // compara com `DateTime.now()`, que é local. Sem isso a contagem dos 7
      // dias de teste erra pelo tamanho do fuso.
      trialStartedAt:
          DateTime.tryParse('${subscription?['trial_started_at'] ?? ''}')
              ?.toLocal(),
      lastOpenDate: AppSnapshot.parseDay('${profile['last_open_date'] ?? ''}'),
      sessions: sessions,
      ajustesDeCategoria: {
        for (final r in appCategories)
          '${r['package_name']}': '${r['category']}',
      },
    );
  }

  /// O que está em uso, distinguindo "não está" de "o banco não sabe".
  ///
  /// Nenhuma linha trazendo a chave `equipped` significa banco sem a
  /// migration 11 (ou leitura que não pediu a coluna): o remoto não tem
  /// **opinião** sobre o que está em uso, e a lista tem de voltar vazia para
  /// que `AppSnapshot.fundeCom` mantenha a do aparelho. Devolver "tudo em
  /// uso" seria uma opinião inventada — e, como remoto não-vazio ganha do
  /// local, ela desfaria toda peça que o usuário tivesse tirado.
  ///
  /// Com a coluna presente, `null` continua valendo por "em uso": é o
  /// `default true` da migration, que existe para não esvaziar o habitat de
  /// quem comprou quando comprar era o mesmo que colocar.
  static List<String> _equipadosDe(List<Map<String, dynamic>> inventory) {
    final temColuna = inventory.any((e) => e.containsKey('equipped'));
    if (!temColuna) return const [];
    return inventory
        .where((e) => e['equipped'] != false)
        .map((e) => '${e['item_id']}')
        .toList();
  }

  /// `dias_abaixo_na_semana` só vale para a semana que o carimbou.
  ///
  /// O contador zera na segunda-feira **dentro do aparelho**, e essa zeragem
  /// não marca sincronização — o remoto segue com o número da semana passada
  /// até a próxima gravação por outro motivo. Sem conferir o carimbo, a
  /// semana nova começaria com a missão semanal meio cumprida de graça.
  ///
  /// Carimbo ausente (banco antes da migração) devolve zero em vez de
  /// arriscar: um número sem semana não é afirmação sobre nenhuma.
  static int _diasAbaixoNaSemana(
    Map<String, dynamic>? progresso,
    DateTime agora,
  ) {
    final n = (progresso?['dias_abaixo_na_semana'] as num?)?.toInt() ?? 0;
    if (n <= 0) return 0;
    final semana = DateTime.tryParse('${progresso?['semana_de'] ?? ''}');
    if (semana == null) return 0;
    return _diaDe(semana) == segundaDe(agora) ? n : 0;
  }

  /// Compat: perfil monolítico legado (pré-migration 005).
  AppSnapshot fromLegacyProfile(
    Map<String, dynamic> row,
    List<SessionRecord> sessions, {
    DateTime? agora,
  }) {
    // O perfil legado não tem coluna de contador nenhuma, mas tem as sessões
    // — e é delas que os quatro saem de qualquer jeito.
    final contadores = contadoresDe(sessions, agora: agora);
    return AppSnapshot(
      minutosDeFocoHoje: contadores.minutosHoje,
      maiorSessaoHoje: contadores.maiorSessaoHoje,
      sessoesNaSemana: contadores.sessoesNaSemana,
      minutosNaSemana: contadores.minutosNaSemana,
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
