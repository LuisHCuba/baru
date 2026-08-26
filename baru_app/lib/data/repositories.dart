import '../models.dart';
import 'app_snapshot.dart';
import 'local_store.dart';
import 'remote_result.dart';
import 'supabase_gateway.dart';

/// Repositórios: local sempre; remoto por domínio se Supabase ready.
class BaruRepositories {
  /// Os repositórios são injetáveis para que o teste possa simular falha de
  /// rede por domínio — o caminho em que a sincronização mais erra.
  BaruRepositories(
    this.store, {
    PetRepository? pet,
    SessionRepository? sessions,
    ShopRepository? shop,
    SettingsRepository? settings,
    TrialRepository? trial,
  })  : pet = pet ?? LocalPetRepository(store),
        sessions = sessions ?? LocalSessionRepository(store),
        shop = shop ?? LocalShopRepository(store),
        settings = settings ?? LocalSettingsRepository(store),
        trial = trial ?? LocalTrialRepository(store);

  final SnapshotStore store;
  final PetRepository pet;
  final SessionRepository sessions;
  final ShopRepository shop;
  final SettingsRepository settings;
  final TrialRepository trial;

  static BaruRepositories local() => BaruRepositories(PrefsSnapshotStore());
  static BaruRepositories memory() => BaruRepositories(MemorySnapshotStore());

  Future<void> init() => store.init();
  Future<AppSnapshot?> loadSnapshot() => store.load();
  Future<void> saveSnapshot(AppSnapshot snapshot) => store.save(snapshot);
  Future<void> clearSnapshot() => store.clear();

  Future<void> pushRemote(AppSnapshot snapshot) =>
      BaruSupabase.instance.pushSnapshot(snapshot);

  Future<AppSnapshot?> pullRemote() => BaruSupabase.instance.pullSnapshot();

  Future<RemotePullResult> pullRemoteResult() =>
      BaruSupabase.instance.pullSnapshotResult();
}

abstract class PetRepository {
  Future<void> saveLocal({
    required Species species,
    required String name,
    required int coat,
    required int leaves,
  });
  Future<void> pullRemote();
  Future<void> pushRemote();
}

abstract class SessionRepository {
  Future<void> appendLocal(SessionRecord record);
  Future<void> pullRemote();
  Future<void> pushRemote();
}

abstract class ShopRepository {
  Future<void> saveOwnedLocal(List<String> owned, int leaves);
  Future<void> pullRemote();
  Future<void> pushRemote();
}

abstract class SettingsRepository {
  Future<void> saveLocal({
    required String lang,
    required int goal,
    required int avg,
    required bool evening,
    required bool missed,
    required bool usageAccess,
  });
  Future<void> pullRemote();
  Future<void> pushRemote();
}

abstract class TrialRepository {
  Future<void> saveLocal({
    required bool active,
    required PayPlan plan,
    required DateTime? startedAt,
  });
  Future<void> pullRemote();
  Future<void> pushRemote();
}

Future<void> _syncPull(SnapshotStore store) async {
  final remote = await BaruSupabase.instance.pullSnapshot();
  if (remote != null) await store.save(remote);
}

Future<AppSnapshot?> _current(SnapshotStore store) => store.load();

class LocalPetRepository implements PetRepository {
  LocalPetRepository(this._store);
  final SnapshotStore _store;

  @override
  Future<void> saveLocal({
    required Species species,
    required String name,
    required int coat,
    required int leaves,
  }) async {
    final cur = await _store.load();
    if (cur == null) return;
    await _store.save(
      cur.copyWith(species: species, petName: name, color: coat, leaves: leaves),
    );
  }

  @override
  Future<void> pullRemote() async => _syncPull(_store);

  @override
  Future<void> pushRemote() async {
    final snap = await _current(_store);
    if (snap == null) return;
    await BaruSupabase.instance.pushPet(snap);
    await BaruSupabase.instance.pushShop(snap);
  }
}

class LocalSessionRepository implements SessionRepository {
  LocalSessionRepository(this._store);
  final SnapshotStore _store;

  @override
  Future<void> appendLocal(SessionRecord record) async {
    final cur = await _store.load();
    if (cur == null) return;
    final next = [...cur.sessions, record];
    final trimmed = next.length > 80 ? next.sublist(next.length - 80) : next;
    await _store.save(cur.copyWith(sessions: trimmed));
  }

  @override
  Future<void> pullRemote() async => _syncPull(_store);

  @override
  Future<void> pushRemote() async {
    final snap = await _current(_store);
    if (snap == null) return;
    await BaruSupabase.instance.pushSessions(snap.sessions);
    await BaruSupabase.instance.pushStreak(snap);
  }
}

class LocalShopRepository implements ShopRepository {
  LocalShopRepository(this._store);
  final SnapshotStore _store;

  @override
  Future<void> saveOwnedLocal(List<String> owned, int leaves) async {
    final cur = await _store.load();
    if (cur == null) return;
    await _store.save(cur.copyWith(owned: owned, leaves: leaves));
  }

  @override
  Future<void> pullRemote() async => _syncPull(_store);

  @override
  Future<void> pushRemote() async {
    final snap = await _current(_store);
    if (snap == null) return;
    await BaruSupabase.instance.pushShop(snap);
  }
}

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._store);
  final SnapshotStore _store;

  @override
  Future<void> saveLocal({
    required String lang,
    required int goal,
    required int avg,
    required bool evening,
    required bool missed,
    required bool usageAccess,
  }) async {
    final cur = await _store.load();
    if (cur == null) return;
    await _store.save(
      cur.copyWith(
        lang: lang,
        goal: goal,
        avg: avg,
        evening: evening,
        missed: missed,
        usageAccess: usageAccess,
      ),
    );
  }

  @override
  Future<void> pullRemote() async => _syncPull(_store);

  @override
  Future<void> pushRemote() async {
    final snap = await _current(_store);
    if (snap == null) return;
    await BaruSupabase.instance.pushSettings(snap);
    await BaruSupabase.instance.pushAccount(snap);
  }
}

class LocalTrialRepository implements TrialRepository {
  LocalTrialRepository(this._store);
  final SnapshotStore _store;

  @override
  Future<void> saveLocal({
    required bool active,
    required PayPlan plan,
    required DateTime? startedAt,
  }) async {
    final cur = await _store.load();
    if (cur == null) return;
    await _store.save(
      cur.copyWith(
        trial: active,
        payPlan: plan,
        trialStartedAt: startedAt,
        clearTrialStart: startedAt == null,
      ),
    );
  }

  @override
  Future<void> pullRemote() async => _syncPull(_store);

  @override
  Future<void> pushRemote() async {
    final snap = await _current(_store);
    if (snap == null) return;
    await BaruSupabase.instance.pushSubscription(snap);
  }
}
