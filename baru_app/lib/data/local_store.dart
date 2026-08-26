import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_snapshot.dart';

abstract class SnapshotStore {
  Future<void> init();
  Future<AppSnapshot?> load();
  Future<void> save(AppSnapshot snapshot);
  Future<void> clear();
}

class PrefsSnapshotStore implements SnapshotStore {
  SharedPreferences? _prefs;
  static const key = 'baru_snapshot_v1';

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<AppSnapshot?> load() async {
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return AppSnapshot.fromJson(decoded);
      if (decoded is Map) {
        return AppSnapshot.fromJson(Map<String, dynamic>.from(decoded));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(AppSnapshot snapshot) async {
    await _prefs?.setString(key, jsonEncode(snapshot.toJson()));
  }

  @override
  Future<void> clear() async {
    await _prefs?.remove(key);
  }
}

class MemorySnapshotStore implements SnapshotStore {
  AppSnapshot? data;

  @override
  Future<void> init() async {}

  @override
  Future<AppSnapshot?> load() async => data;

  @override
  Future<void> save(AppSnapshot snapshot) async {
    data = snapshot;
  }

  @override
  Future<void> clear() async {
    data = null;
  }
}
