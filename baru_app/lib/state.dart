import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import 'data/app_snapshot.dart';
import 'data/baru_env.dart';
import 'data/repositories.dart';
import 'data/supabase_gateway.dart';
import 'l10n.dart';
import 'models.dart';
import 'services/notification_service.dart';
import 'services/usage_service.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class AppState extends ChangeNotifier {
  AppState({
    this.repos,
    AppSnapshot? snapshot,
    this.onSyncError,
    this.onUserMessage,
  }) {
    if (snapshot != null) {
      _applySnapshot(snapshot);
    }
    applyCalendar(DateTime.now(), persist: false);
  }

  final BaruRepositories? repos;
  final void Function(String message)? onSyncError;
  final void Function(String message)? onUserMessage;

  bool _pendingOnbUsageAdvance = false;
  bool _usageTogglePending = false;

  /// Bônus de +15 folhas por fechar o dia abaixo da meta (contrato de produto §5).
  static const underGoalBonus = 15;

  /// Bônus já creditados que ainda não viraram aviso na tela. Não vai para o
  /// snapshot: as folhas já estão em [leaves], isto é só o recado pendente.
  int pendingUnderGoalBonus = 0;

  AppScreen screen = AppScreen.onb;
  int onb = 0;
  String lang = 'pt';
  Species species = Species.capybara;
  String? q0;
  String? q1;
  String? q2;
  int leaves = 0;
  int streak = 0;
  int usage = 0;
  int goal = 180;
  int avg = 240;
  String petName = '';
  int color = 0;
  List<String> owned = [];
  int dur = 25;
  int remaining = 0;
  bool running = false;
  bool confirming = false;
  int completedToday = 0;
  bool abandonedToday = false;
  int daysAway = 0;
  int reward = 0;
  bool aborted = false;
  Mood? overrideMood;
  bool trial = false;
  bool evening = true;
  bool missed = true;
  bool sharing = false;
  PayPlan payPlan = PayPlan.annual;
  bool debugFast = kDebugMode;
  bool usageAccess = false;
  bool companionshipStarted = false;
  List<WeekDayKind> week = freshWeek();
  int todayIndex = weekdayIndex();
  int freezesLeft = 1;
  DateTime? trialStartedAt;
  DateTime lastOpenDate = dateOnly(DateTime.now());
  List<SessionRecord> sessions = [];

  Timer? _timer;
  Timer? _saveTimer;
  int _syncMask = 0;

  static const _syncPet = 1;
  static const _syncShop = 2;
  static const _syncSession = 4;
  static const _syncSettings = 8;
  static const _syncTrial = 16;
  static const _syncAll =
      _syncPet | _syncShop | _syncSession | _syncSettings | _syncTrial;

  void _markSync(int mask) => _syncMask |= mask;

  T get t => T(lang);

  bool get canSignOut =>
      BaruEnv.supabaseEnabled && BaruSupabase.instance.isEmailUser;

  Future<void> signOut() async {
    if (!canSignOut) return;
    await BaruSupabase.instance.signOut();
    await repos?.clearSnapshot();
  }

  String get displayName =>
      petName.isEmpty ? petNames[species]! : petName;

  String get moodKey {
    switch (mood) {
      case Mood.radiant:
        return 'radiant';
      case Mood.content:
        return 'content';
      case Mood.neutral:
        return 'neutral';
      case Mood.sleepy:
        return 'sleepy';
      case Mood.missingYou:
        return 'missing_you';
    }
  }

  String get speciesKey => species.name;

  Mood get mood {
    if (overrideMood != null) return overrideMood!;
    if (abandonedToday || daysAway >= 2) return Mood.missingYou;
    if (!usageAccess) {
      return completedToday >= 1 ? Mood.radiant : Mood.content;
    }
    if (usage < goal && completedToday >= 1) return Mood.radiant;
    if (usage < goal || completedToday >= 1) return Mood.content;
    if (usage <= goal * 1.2) return Mood.neutral;
    return Mood.sleepy;
  }

  Activity get activity {
    switch (mood) {
      case Mood.sleepy:
      case Mood.neutral:
        return Activity.nap;
      case Mood.radiant:
        return Activity.swim;
      case Mood.content:
        return Activity.graze;
      case Mood.missingYou:
        return Activity.idle;
    }
  }

  bool get showTabs =>
      screen == AppScreen.home ||
      screen == AppScreen.report ||
      screen == AppScreen.shop ||
      screen == AppScreen.profile;

  bool get quizDone => q0 != null && q1 != null && q2 != null;

  bool get underGoal => usage < goal;
  bool get onGoal => usage == goal;
  bool get overGoal => usage > goal;

  bool get underGoalQuestDone => usageAccess && usage < goal;

  int get trialDaysLeft {
    final paid = dateOnly(paidPlanStart);
    final today = dateOnly(DateTime.now());
    final n = paid.difference(today).inDays;
    if (n < 0) return 0;
    if (n > 7) return 7;
    return n;
  }

  DateTime get paidPlanStart {
    final start = dateOnly(trialStartedAt ?? DateTime.now());
    return start.add(const Duration(days: 7));
  }

  String get streakText => t.streakLabel(streak);

  String get usageShortLabel {
    if (onGoal) return t.usageEven;
    if (underGoal) return t.fill(t.usageLeft, {'x': fmt(goal - usage)});
    return t.fill(t.usageOver, {'x': fmt(usage - goal)});
  }

  String get usageVerdict {
    if (onGoal) return t.repEven;
    if (underGoal) return t.fill(t.repUnder, {'x': fmt(goal - usage)});
    return t.fill(t.repOver, {'x': fmt(usage - goal)});
  }

  ShopItemDef? get nextItem {
    final pending = shopItems.where((i) => !owned.contains(i.id)).toList()
      ..sort((a, b) => a.price.compareTo(b.price));
    return pending.isEmpty ? null : pending.first;
  }

  String fmt(int min) => fmtMinutes(min, lang);

  Species resolveSpecies() {
    final score = {
      Species.capybara: 0,
      Species.otter: 0,
      Species.tortoise: 0,
      Species.owl: 0,
    };
    final answers = [q0, q1, q2];
    for (var i = 0; i < 3; i++) {
      final idx = t.quizO[i].indexOf(answers[i] ?? '');
      if (idx >= 0) {
        quizWeights[i][idx].forEach((k, v) {
          score[k] = score[k]! + v;
        });
      }
    }
    return score.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  void go(AppScreen next) {
    screen = next;
    confirming = false;
    notifyListeners();
  }

  void setLang(String id) {
    lang = id;
    if (screen == AppScreen.onb && onb == 2) {
      q0 = null;
      q1 = null;
      q2 = null;
    }
    _markSync(_syncSettings);
    notifyListeners();
  }

  void pickQuiz(int q, String label) {
    if (q == 0) q0 = label;
    if (q == 1) q1 = label;
    if (q == 2) q2 = label;
    _markSync(_syncPet);
    notifyListeners();
  }

  void nextOnb() {
    if (onb >= 5) {
      if (!companionshipStarted) startCompanionship();
      go(AppScreen.paywall);
      return;
    }
    if (onb == 2) {
      onb = 3;
      species = resolveSpecies();
      petName = petNames[species]!;
      _markSync(_syncPet | _syncSettings);
      notifyListeners();
      return;
    }
    if (onb == 3) {
      final cleaned = petName.trim();
      petName = cleaned.isEmpty ? petNames[species]! : cleaned;
      onb = 4;
      goal = suggestedGoal(avg);
      _markSync(_syncPet | _syncSettings);
      notifyListeners();
      return;
    }
    onb += 1;
    notifyListeners();
  }

  Future<void> initPlatformServices() async {
    if (kIsWeb) return;
    await BaruNotifications.instance.init();
    await syncPermissionsFromOs(notify: false);
  }

  /// Sincroniza toggles com permissões reais do SO e atualiza tempo de tela.
  Future<void> syncPermissionsFromOs({bool notify = true}) async {
    if (kIsWeb) return;

    var changed = false;
    final osUsage = await UsageService.instance.hasUsageAccess();
    if (usageAccess != osUsage) {
      usageAccess = osUsage;
      _markSync(_syncSettings);
      changed = true;
    }

    if (osUsage) {
      final mins = await UsageService.instance.todayScreenTimeMinutes();
      if (mins != null && mins != usage) {
        usage = mins;
        overrideMood = null;
        _markSync(_syncSettings);
        changed = true;
      }
    }

    if (_pendingOnbUsageAdvance || _usageTogglePending) {
      _finishUsagePermissionFlow(osUsage);
      changed = true;
    }

    await _syncNotificationSchedules();

    if (notify && changed) notifyListeners();
  }

  void _finishUsagePermissionFlow(bool osUsage) {
    if (_pendingOnbUsageAdvance) {
      _pendingOnbUsageAdvance = false;
      if (osUsage) {
        onUserMessage?.call(t.permUsageGranted);
        nextOnb();
      } else {
        onUserMessage?.call(t.permUsageDenied);
      }
      return;
    }
    if (_usageTogglePending) {
      _usageTogglePending = false;
      if (osUsage) {
        onUserMessage?.call(t.permUsageGranted);
      } else {
        onUserMessage?.call(t.permUsageDenied);
      }
    }
  }

  Future<void> _refreshUsageFromOs({bool notify = true}) async {
    final mins = await UsageService.instance.todayScreenTimeMinutes();
    if (mins == null) return;
    if (mins != usage) {
      usage = mins;
      overrideMood = null;
      _markSync(_syncSettings);
      if (notify) notifyListeners();
    }
  }

  Future<void> _syncNotificationSchedules() async {
    await BaruNotifications.instance.syncSchedules(
      evening: evening,
      missed: missed,
      eveningTitle: t.notifEveningTitle,
      eveningBody: t.fill(t.notifEveningBody, {'n': displayName}),
      missedTitle: t.notifMissedTitle,
      missedBody: t.fill(t.notifMissedBody, {'n': displayName}),
      daysAway: daysAway,
    );
  }

  /// Onboarding passo 6 — abre fluxo nativo; só avança se o SO conceder.
  Future<void> requestUsageAccessFromOnboarding() async {
    if (kIsWeb) {
      skipUsage();
      return;
    }
    if (!UsageService.instance.platformSupportsUsage) {
      onUserMessage?.call(t.permIosLimit);
      await UsageService.instance.requestUsageAccess();
      return;
    }
    _pendingOnbUsageAdvance = true;
    await UsageService.instance.requestUsageAccess();
  }

  void skipUsage() {
    _pendingOnbUsageAdvance = false;
    usageAccess = false;
    _markSync(_syncSettings);
    nextOnb();
  }

  Future<void> requestUsageAccessFromSettings() async {
    if (kIsWeb) return;
    if (!UsageService.instance.platformSupportsUsage) {
      onUserMessage?.call(t.permIosLimit);
      await UsageService.instance.requestUsageAccess();
      return;
    }
    if (await UsageService.instance.hasUsageAccess()) {
      setUsageAccess(true);
      await _refreshUsageFromOs();
      return;
    }
    _usageTogglePending = true;
    await UsageService.instance.requestUsageAccess();
  }

  /// Primeiro dia real: habitat vazio, sem folhas herdadas do snapshot do design.
  void startCompanionship() {
    companionshipStarted = true;
    leaves = 0;
    streak = 0;
    usage = 0;
    completedToday = 0;
    owned = [];
    abandonedToday = false;
    daysAway = 0;
    todayIndex = weekdayIndex();
    week = freshWeek();
    freezesLeft = 1;
    reward = 0;
    aborted = false;
    overrideMood = null;
    sharing = false;
    sessions = [];
    lastOpenDate = dateOnly(DateTime.now());
    _markSync(_syncShop | _syncSession);
  }

  void setName(String value) {
    petName = value.length > 18 ? value.substring(0, 18) : value;
    _markSync(_syncPet);
    notifyListeners();
  }

  void setColor(int i) {
    color = i.clamp(0, 3);
    _markSync(_syncPet);
    notifyListeners();
  }

  /// Troca o animal nos ajustes. Nome customizado fica; o padrão do design muda.
  void pickSpecies(Species s) {
    if (species == s) return;
    final current = petName.trim();
    final wasDefault = current.isEmpty || current == petNames[species];
    species = s;
    if (wasDefault) {
      petName = petNames[s]!;
    }
    _markSync(_syncPet);
    notifyListeners();
  }

  void setUsageAccess(bool value) {
    usageAccess = value;
    _markSync(_syncSettings);
    notifyListeners();
  }

  Future<void> toggleUsageAccess() async {
    if (kIsWeb) return;
    if (usageAccess) {
      setUsageAccess(false);
      return;
    }
    await requestUsageAccessFromSettings();
  }

  void pickAvg(int value) {
    avg = value;
    goal = suggestedGoal(value);
    _markSync(_syncSettings);
    notifyListeners();
  }

  void pickGoal(int value) {
    goal = value;
    _markSync(_syncSettings);
    notifyListeners();
  }

  void pickDur(int value) {
    dur = value;
    _markSync(_syncSettings);
    notifyListeners();
  }

  void startTrial() {
    trial = true;
    trialStartedAt ??= DateTime.now();
    _markSync(_syncTrial | _syncSettings);
    go(AppScreen.home);
  }

  void pickPay(PayPlan plan) {
    payPlan = plan;
    _markSync(_syncTrial);
    notifyListeners();
  }

  void restartOnboarding() {
    screen = AppScreen.onb;
    onb = 0;
    q0 = null;
    q1 = null;
    q2 = null;
    notifyListeners();
  }

  void openShare() {
    sharing = true;
    notifyListeners();
  }

  void closeShare() {
    sharing = false;
    notifyListeners();
  }

  Future<void> toggleEvening() async {
    if (kIsWeb) {
      onUserMessage?.call(t.notifWebUnsupported);
      return;
    }
    final turningOn = !evening;
    if (turningOn) {
      final ok = await BaruNotifications.instance.ensurePermission();
      if (!ok) {
        onUserMessage?.call(t.notifDenied);
        return;
      }
    }
    evening = !evening;
    _markSync(_syncSettings);
    await _syncNotificationSchedules();
    notifyListeners();
  }

  Future<void> toggleMissed() async {
    if (kIsWeb) {
      onUserMessage?.call(t.notifWebUnsupported);
      return;
    }
    final turningOn = !missed;
    if (turningOn) {
      final ok = await BaruNotifications.instance.ensurePermission();
      if (!ok) {
        onUserMessage?.call(t.notifDenied);
        return;
      }
    }
    missed = !missed;
    _markSync(_syncSettings);
    await _syncNotificationSchedules();
    notifyListeners();
  }

  void buy(ShopItemDef item) {
    if (owned.contains(item.id) || leaves < item.price) return;
    leaves -= item.price;
    owned = [...owned, item.id];
    _markSync(_syncShop);
    notifyListeners();
  }

  void startSession() {
    _timer?.cancel();
    remaining = dur * 60;
    running = true;
    confirming = false;
    overrideMood = null;
    screen = AppScreen.session;
    notifyListeners();
    const interval = Duration(seconds: 1);
    final step = debugFast ? 60 : 1;
    _timer = Timer.periodic(interval, (_) => _tick(step));
  }

  void _tick(int step) {
    if (confirming) return;
    final next = remaining - step;
    if (next <= 0) {
      _timer?.cancel();
      final gained = sessionReward(dur);
      remaining = 0;
      running = false;
      screen = AppScreen.result;
      aborted = false;
      reward = gained;
      leaves += gained;
      if (completedToday == 0) streak += 1;
      completedToday += 1;
      overrideMood = null;
      _logSession(completed: true, gained: gained);
      _markSync(_syncSession | _syncShop);
      notifyListeners();
    } else {
      remaining = next;
      notifyListeners();
    }
  }

  void askQuit() {
    confirming = true;
    notifyListeners();
  }

  void resume() {
    confirming = false;
    notifyListeners();
  }

  void abandon() {
    _timer?.cancel();
    screen = AppScreen.result;
    aborted = true;
    reward = 0;
    abandonedToday = true;
    running = false;
    confirming = false;
    overrideMood = null;
    _logSession(completed: false, gained: 0);
    _markSync(_syncSession);
    notifyListeners();
  }

  void _logSession({required bool completed, required int gained}) {
    sessions = [
      ...sessions,
      SessionRecord(
        id: const Uuid().v4(),
        at: DateTime.now(),
        dur: dur,
        completed: completed,
        aborted: !completed,
        reward: gained,
      ),
    ];
    if (sessions.length > 80) {
      sessions = sessions.sublist(sessions.length - 80);
    }
  }

  void forceMood(Mood? m) {
    overrideMood = overrideMood == m ? null : m;
    notifyListeners();
  }

  void setHabitat(String key) {
    owned = List<String>.from(habitats[key]!);
    notifyListeners();
  }

  void setSpecies(Species s) {
    species = s;
    petName = '';
    notifyListeners();
  }

  void usageUp() {
    usage += 30;
    overrideMood = null;
    _markSync(_syncSettings);
    notifyListeners();
  }

  void usageDown() {
    usage = (usage - 30).clamp(0, 9999);
    overrideMood = null;
    _markSync(_syncSettings);
    notifyListeners();
  }

  /// Debug: simula amanhã chegando com o usuário ausente.
  void nextDay() {
    final de = dateOnly(lastOpenDate);
    final para = de.add(const Duration(days: 1));
    _advanceDay(de: de, para: para, debugUsage: true);
    lastOpenDate = para;
    if (completedToday == 0) daysAway += 1;
    _markSync(_syncSession);
    notifyListeners();
  }

  /// Fecha o dia [de] e abre o dia [para].
  ///
  /// Os índices da semana saem da **data**, não de um contador incrementado:
  /// um contador desanda em relação ao calendário na primeira ausência longa,
  /// e o ponto de "hoje" passa a apontar o dia errado.
  ///
  /// [creditBonus] só vale para o dia que tem medição real de tempo de tela —
  /// o primeiro de um avanço. Nos dias seguintes de uma ausência longa o
  /// `usage` é sintético (zero), e pagar bônus por eles seria inventar dado.
  void _advanceDay({
    required DateTime de,
    required DateTime para,
    required bool debugUsage,
    bool creditBonus = true,
  }) {
    if (creditBonus && _closedUnderGoal) {
      leaves += underGoalBonus;
      pendingUnderGoalBonus += 1;
      _markSync(_syncShop);
    }

    final iDe = weekdayIndex(de);
    final iPara = weekdayIndex(para);

    week = List<WeekDayKind>.from(week);
    if (completedToday >= 1) {
      week[iDe] = WeekDayKind.present;
    } else if (freezesLeft > 0) {
      // O congelamento absorve a falta: a presença continua contando.
      week[iDe] = WeekDayKind.frozen;
      freezesLeft -= 1;
      streak += 1;
    } else {
      week[iDe] = WeekDayKind.empty;
      streak = 0;
    }

    // Segunda-feira abre uma semana nova: a faixa mostra "esta semana", então
    // as marcas da semana anterior não podem sobreviver à virada.
    if (iPara == 0) {
      week = List<WeekDayKind>.filled(7, WeekDayKind.empty);
      freezesLeft = 1;
    }

    todayIndex = iPara;
    week[iPara] = WeekDayKind.today;
    usage = debugUsage && usageAccess ? 40 : 0;
    completedToday = 0;
    abandonedToday = false;
    overrideMood = null;
  }

  /// O dia que está fechando terminou abaixo da meta?
  ///
  /// Exige permissão de uso: sem ela não há tempo de tela para comparar, e o
  /// app não inventa um bônus. Exige também companheirismo começado, para o
  /// bônus não cair antes do onboarding terminar.
  bool get _closedUnderGoal =>
      companionshipStarted && usageAccess && usage < goal;

  /// Teto de dias reconstruídos um a um num único avanço. Acima disso não há
  /// o que reconstruir com fidelidade — o calendário é realinhado à data real.
  static const maxDiasReconstruidos = 21;

  void applyCalendar(DateTime now, {bool persist = true}) {
    final today = dateOnly(now);
    final desde = dateOnly(lastOpenDate);
    var cursor = desde;
    var steps = 0;
    while (cursor.isBefore(today) && steps < maxDiasReconstruidos) {
      final proximo = cursor.add(const Duration(days: 1));
      _advanceDay(
        de: cursor,
        para: proximo,
        debugUsage: false,
        creditBonus: steps == 0,
      );
      cursor = proximo;
      steps += 1;
    }

    if (cursor.isBefore(today)) {
      // Ausência maior que o teto: reconstruir dia a dia não agrega nada.
      // Realinha a faixa com a data real em vez de deixar o índice à deriva.
      week = List<WeekDayKind>.filled(7, WeekDayKind.empty);
      freezesLeft = 1;
      streak = 0;
      todayIndex = weekdayIndex(today);
      week[todayIndex] = WeekDayKind.today;
      steps += 1;
    } else {
      _alinhaHoje(today);
    }

    // "Dias sem abrir" é um fato da data, não um contador que se acumula.
    daysAway = today.difference(desde).inDays - 1;
    if (daysAway < 0) daysAway = 0;

    lastOpenDate = today;
    if (persist && steps > 0) {
      _markSync(_syncSession);
      flushPendingNotices();
      notifyListeners();
    }
  }

  /// Garante que o ponto de "hoje" caia no dia da semana real.
  ///
  /// Um snapshot pode chegar com o índice defasado — vindo de outro aparelho,
  /// de outro fuso, ou de uma versão antiga que incrementava o contador em vez
  /// de derivá-lo da data. Sem isto, a faixa da semana marca o dia errado e o
  /// erro só cresce.
  void _alinhaHoje(DateTime today) {
    final idx = weekdayIndex(today);
    if (todayIndex == idx && week[idx] == WeekDayKind.today) return;
    week = List<WeekDayKind>.from(week);
    if (week[todayIndex] == WeekDayKind.today) {
      week[todayIndex] = WeekDayKind.empty;
    }
    todayIndex = idx;
    week[idx] = WeekDayKind.today;
  }

  /// Mostra os avisos que ficaram pendentes de um avanço de calendário.
  ///
  /// Existe porque o primeiro avanço acontece no construtor, antes de haver
  /// árvore de widgets para receber um SnackBar; `BaruApp` chama isto no
  /// primeiro frame.
  void flushPendingNotices() {
    if (pendingUnderGoalBonus <= 0) return;
    pendingUnderGoalBonus = 0;
    onUserMessage?.call(t.fill(t.bonusUnderGoal, {'k': underGoalBonus}));
  }

  void grantLeaves() {
    leaves += 200;
    _markSync(_syncShop);
    notifyListeners();
  }

  void resetAll() {
    leaves = 165;
    owned = ['lily', 'dock'];
    usage = 96;
    goal = 150;
    avg = 240;
    streak = 4;
    completedToday = 1;
    abandonedToday = false;
    daysAway = 0;
    overrideMood = null;
    trial = false;
    trialStartedAt = null;
    usageAccess = true;
    companionshipStarted = true;
    week = List<WeekDayKind>.from(weekPattern);
    todayIndex = 5;
    freezesLeft = 1;
    notifyListeners();
  }

  void restorePurchases() {
    trial = true;
    trialStartedAt ??= DateTime.now();
    _markSync(_syncTrial);
    go(AppScreen.home);
  }

  void toggleDebugFast() {
    debugFast = !debugFast;
    notifyListeners();
  }

  AppSnapshot toSnapshot() {
    final persistScreen =
        screen == AppScreen.session ? AppScreen.home : screen;
    return AppSnapshot(
      screen: persistScreen,
      onb: onb,
      lang: lang,
      species: species,
      q0: q0,
      q1: q1,
      q2: q2,
      leaves: leaves,
      streak: streak,
      usage: usage,
      goal: goal,
      avg: avg,
      petName: petName,
      color: color,
      owned: List<String>.from(owned),
      dur: dur,
      completedToday: completedToday,
      abandonedToday: abandonedToday,
      daysAway: daysAway,
      trial: trial,
      evening: evening,
      missed: missed,
      payPlan: payPlan,
      usageAccess: usageAccess,
      companionshipStarted: companionshipStarted,
      week: List<WeekDayKind>.from(week),
      todayIndex: todayIndex,
      freezesLeft: freezesLeft,
      trialStartedAt: trialStartedAt,
      lastOpenDate: lastOpenDate,
      sessions: List<SessionRecord>.from(sessions),
    );
  }

  void _applySnapshot(AppSnapshot s) {
    screen = s.screen == AppScreen.session ? AppScreen.home : s.screen;
    onb = s.onb;
    lang = s.lang;
    species = s.species;
    q0 = s.q0;
    q1 = s.q1;
    q2 = s.q2;
    leaves = s.leaves;
    streak = s.streak;
    usage = s.usage;
    goal = s.goal;
    avg = s.avg;
    petName = s.petName;
    color = s.color;
    owned = List<String>.from(s.owned);
    dur = s.dur;
    completedToday = s.completedToday;
    abandonedToday = s.abandonedToday;
    daysAway = s.daysAway;
    trial = s.trial;
    evening = s.evening;
    missed = s.missed;
    payPlan = s.payPlan;
    usageAccess = s.usageAccess;
    companionshipStarted = s.companionshipStarted;
    week = List<WeekDayKind>.from(s.week);
    todayIndex = s.todayIndex;
    freezesLeft = s.freezesLeft;
    trialStartedAt = s.trialStartedAt;
    lastOpenDate = s.lastOpenDate;
    sessions = List<SessionRecord>.from(s.sessions);
  }

  void _schedulePersist() {
    if (repos == null) return;
    if (screen == AppScreen.session && running) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 280), _persistNow);
  }

  Future<void> _persistNow() async {
    final r = repos;
    if (r == null) return;
    final snap = toSnapshot();
    await r.saveSnapshot(snap);
    final mask = _syncMask == 0 ? _syncAll : _syncMask;
    _syncMask = 0;
    try {
      if (mask & _syncPet != 0) await r.pet.pushRemote();
      if (mask & _syncShop != 0) await r.shop.pushRemote();
      if (mask & _syncSettings != 0) await r.settings.pushRemote();
      if (mask & _syncSession != 0) await r.sessions.pushRemote();
      if (mask & _syncTrial != 0) await r.trial.pushRemote();
    } catch (_) {
      onSyncError?.call(t.syncFail);
    }
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    _schedulePersist();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _saveTimer?.cancel();
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope não encontrado');
    return scope!.notifier!;
  }
}
