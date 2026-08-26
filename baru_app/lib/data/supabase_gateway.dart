import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';
import 'app_snapshot.dart';
import 'baru_env.dart';
import 'remote_result.dart';
import 'row_codec.dart';

/// Client Supabase: auth email/senha + sync por domínio (tabelas normalizadas).
/// Falha → fallback local com erro visível. Nunca service_role.
class BaruSupabase {
  BaruSupabase._();
  static final BaruSupabase instance = BaruSupabase._();

  static const _codec = BaruRowCodec();
  static const _deviceKey = 'baru_device_id';

  bool _attached = false;
  bool _ready = false;
  String _deviceId = '';
  String? attachError;

  String get url => BaruEnv.supabaseUrl;
  String get anonKey => BaruEnv.supabaseAnonKey;
  bool get supabaseEnabled => BaruEnv.supabaseEnabled;
  bool get attached => _attached;
  bool get ready => _ready;

  SupabaseClient? get _client {
    if (!_attached) return null;
    return Supabase.instance.client;
  }

  bool get hasSession => _client?.auth.currentSession != null;

  bool get isEmailUser {
    final user = _client?.auth.currentUser;
    if (user == null || !hasSession) return false;
    final mail = user.email;
    return mail != null && mail.isNotEmpty;
  }

  String? get currentUserEmail => _client?.auth.currentUser?.email;

  Stream<AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? const Stream.empty();

  Future<void> attach() async {
    if (!supabaseEnabled) return;
    attachError = null;
    try {
      await Supabase.initialize(
        url: url,
        publishableKey: anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
        ),
      );
      _attached = true;
      _deviceId = await _ensureDeviceId();
      await _refreshReady();
    } catch (e, st) {
      attachError = e.toString();
      debugPrint('Baru: supabase indisponível ($e)\n$st');
      _attached = false;
      _ready = false;
    }
  }

  Future<void> _refreshReady() async {
    _ready = isEmailUser;
  }

  void _ensureAttached() {
    if (_client == null) {
      throw const AuthException('Supabase não inicializado');
    }
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    _ensureAttached();
    final resp = await _client!.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    if (resp.session == null) {
      throw const AuthException('email_not_confirmed');
    }
    _deviceId = await _ensureDeviceId();
    await _refreshReady();
    return resp;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    _ensureAttached();
    final resp = await _client!.auth.signUp(
      email: email.trim(),
      password: password,
    );
    _deviceId = await _ensureDeviceId();
    await _refreshReady();
    return resp;
  }

  Future<void> signOut() async {
    await _client?.auth.signOut();
    _ready = false;
  }

  Future<String> _ensureDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    await prefs.setString(_deviceKey, id);
    return id;
  }

  String? get _uid => _client?.auth.currentUser?.id;

  Future<RemotePushResult> pushSnapshot(AppSnapshot snapshot) async {
    if (!_ready) {
      return const RemotePushResult(ok: false, error: 'offline');
    }
    final uid = _uid;
    if (uid == null) {
      return const RemotePushResult(ok: false, error: 'no_session');
    }
    try {
      await pushAccount(snapshot);
      await pushPet(snapshot);
      await pushShop(snapshot);
      await pushSettings(snapshot);
      await pushStreak(snapshot);
      await pushSubscription(snapshot);
      await pushSessions(snapshot.sessions);
      return const RemotePushResult(ok: true);
    } catch (e) {
      debugPrint('Baru: sync remoto falhou ($e)');
      return RemotePushResult(ok: false, error: e.toString());
    }
  }

  Future<void> pushAccount(AppSnapshot snapshot) async {
    final uid = _uid;
    final client = _client;
    if (!_ready || uid == null || client == null) return;
    await client.from('baru_profiles').upsert(
          _codec.profileRow(userId: uid, deviceId: _deviceId, s: snapshot),
        );
    await client.from('baru_onboarding_answers').upsert(
          _codec.onboardingRow(userId: uid, s: snapshot),
        );
  }

  Future<void> pushPet(AppSnapshot snapshot) async {
    final uid = _uid;
    final client = _client;
    if (!_ready || uid == null || client == null) return;
    await client.from('baru_pets').upsert(_codec.petRow(userId: uid, s: snapshot));
  }

  Future<void> pushShop(AppSnapshot snapshot) async {
    final uid = _uid;
    final client = _client;
    if (!_ready || uid == null || client == null) return;
    await client.from('baru_wallets').upsert(
          _codec.walletRow(userId: uid, s: snapshot),
        );
    // Só ids conhecidos da loja: o banco tem CHECK, mas um snapshot
    // corrompido não deveria chegar a montar filtro com lixo dentro.
    final conhecidos = shopItems.map((i) => i.id).toSet();
    final owned = snapshot.owned.where(conhecidos.contains).toSet().toList();

    // Some com o que saiu do inventário numa chamada só, em vez de ler tudo e
    // apagar item a item.
    final apaga =
        client.from('baru_inventory_items').delete().eq('user_id', uid);
    if (owned.isEmpty) {
      await apaga;
    } else {
      final lista = owned.map((id) => '"$id"').join(',');
      await apaga.not('item_id', 'in', '($lista)');
    }

    final rows = _codec.inventoryRows(userId: uid, s: snapshot);
    if (rows.isNotEmpty) {
      // `ignoreDuplicates` preserva o `acquired_at` de quem já estava lá: sem
      // isso, todo push reescrevia a data de compra com "agora" e embaralhava
      // a ordem em que o habitat foi montado.
      await client
          .from('baru_inventory_items')
          .upsert(rows, ignoreDuplicates: true);
    }
  }

  Future<void> pushSettings(AppSnapshot snapshot) async {
    final uid = _uid;
    final client = _client;
    if (!_ready || uid == null || client == null) return;
    await client.from('baru_settings').upsert(
          _codec.settingsRow(userId: uid, s: snapshot),
        );
    await client.from('baru_screen_time').upsert(
          _codec.screenTimeRow(userId: uid, s: snapshot),
        );
  }

  Future<void> pushStreak(AppSnapshot snapshot) async {
    final uid = _uid;
    final client = _client;
    if (!_ready || uid == null || client == null) return;
    await client.from('baru_streaks').upsert(
          _codec.streakRow(userId: uid, s: snapshot),
        );
    await client.from('baru_week_calendar').upsert(
          _codec.weekRows(userId: uid, s: snapshot),
        );
    await client.from('baru_daily_progress').upsert(
          _codec.dailyProgressRow(userId: uid, s: snapshot),
        );
    await client.from('baru_daily_quests').upsert(
          _codec.dailyQuestRows(userId: uid, s: snapshot),
        );
  }

  Future<void> pushSubscription(AppSnapshot snapshot) async {
    final uid = _uid;
    final client = _client;
    if (!_ready || uid == null || client == null) return;
    await client.from('baru_subscriptions').upsert(
          _codec.subscriptionRow(userId: uid, s: snapshot),
        );
  }

  Future<void> pushSessions(List<SessionRecord> sessions) async {
    final uid = _uid;
    final client = _client;
    if (!_ready || uid == null || client == null) return;
    if (sessions.isEmpty) return;
    // Uma chamada, não uma por sessão: o snapshot guarda até 80.
    await client.from('baru_sessions').upsert(
          sessions.map((s) => _codec.sessionRow(userId: uid, s: s)).toList(),
        );
  }

  Future<RemotePullResult> pullSnapshotResult() async {
    if (!_ready) {
      return const RemotePullResult(error: 'offline');
    }
    final uid = _uid;
    final client = _client;
    if (uid == null || client == null) {
      return const RemotePullResult(error: 'no_session');
    }
    try {
      final profile = await client
          .from('baru_profiles')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      if (profile == null) return const RemotePullResult();

      final profileMap = Map<String, dynamic>.from(profile);

      if (profileMap.containsKey('species') || profileMap.containsKey('leaves')) {
        final legacy = await _pullLegacy(uid, profileMap);
        return RemotePullResult(snapshot: legacy);
      }

      final pet = await _maybeSingle('baru_pets', uid);
      final onboarding = await _maybeSingle('baru_onboarding_answers', uid);
      final wallet = await _maybeSingle('baru_wallets', uid);
      final settings = await _maybeSingle('baru_settings', uid);
      final screenTime = await _maybeSingle('baru_screen_time', uid);
      final streak = await _maybeSingle('baru_streaks', uid);
      final daily = await _maybeSingle('baru_daily_progress', uid);
      final subscription = await _maybeSingle('baru_subscriptions', uid);

      final inventoryRaw = await client
          .from('baru_inventory_items')
          .select('item_id')
          .eq('user_id', uid)
          .order('acquired_at');
      final inventory = (inventoryRaw as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final weekRaw = await client
          .from('baru_week_calendar')
          .select('day_index, kind')
          .eq('user_id', uid)
          .order('day_index');
      final week = (weekRaw as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final sessions = await _pullSessions(uid);

      return RemotePullResult(
        snapshot: _codec.fromRows(
          profile: profileMap,
          pet: pet,
          onboarding: onboarding,
          wallet: wallet,
          settings: settings,
          screenTime: screenTime,
          streak: streak,
          daily: daily,
          subscription: subscription,
          inventory: inventory,
          week: week,
          sessions: sessions,
        ),
      );
    } catch (e) {
      debugPrint('Baru: leitura remota falhou ($e)');
      return RemotePullResult(error: e.toString());
    }
  }

  Future<AppSnapshot?> pullSnapshot() async {
    final r = await pullSnapshotResult();
    return r.snapshot;
  }

  Future<AppSnapshot?> _pullLegacy(
    String uid,
    Map<String, dynamic> profile,
  ) async {
    final client = _client!;
    final rawSessions = await client
        .from('baru_sessions')
        .select()
        .eq('user_id', uid)
        .order('started_at');
    final sessions = (rawSessions as List)
        .whereType<Map>()
        .map((e) => _codec.sessionFromRow(Map<String, dynamic>.from(e)))
        .toList();
    return _codec.fromLegacyProfile(profile, sessions);
  }

  Future<Map<String, dynamic>?> _maybeSingle(String table, String uid) async {
    final row = await _client!
        .from(table)
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }

  Future<List<SessionRecord>> _pullSessions(String uid) async {
    final rawSessions = await _client!
        .from('baru_sessions')
        .select()
        .eq('user_id', uid)
        .order('started_at');
    return (rawSessions as List)
        .whereType<Map>()
        .map((e) => _codec.sessionFromRow(Map<String, dynamic>.from(e)))
        .toList();
  }
}
