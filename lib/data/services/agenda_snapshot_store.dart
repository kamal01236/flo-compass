import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'agenda_session_fingerprint.dart';

class AgendaSnapshotStore {
  AgendaSnapshotStore({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _key = 'flo_compass_agenda_snapshots';

  Future<Map<String, AgendaSessionFingerprint>> loadAll() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (id, value) => MapEntry(
        id,
        AgendaSessionFingerprint.fromJson(value as Map<String, dynamic>),
      ),
    );
  }

  Future<void> saveAll(Map<String, AgendaSessionFingerprint> snapshots) async {
    _prefs ??= await SharedPreferences.getInstance();
    final encoded = snapshots.map((id, fp) => MapEntry(id, fp.toJson()));
    await _prefs!.setString(_key, jsonEncode(encoded));
  }

  Future<void> set(
    String sessionId,
    AgendaSessionFingerprint fingerprint,
  ) async {
    final all = await loadAll();
    all[sessionId] = fingerprint;
    await saveAll(all);
  }

  Future<void> remove(String sessionId) async {
    final all = await loadAll();
    if (all.remove(sessionId) != null) {
      await saveAll(all);
    }
  }

  Future<void> prune(Set<String> keepSessionIds) async {
    final all = await loadAll();
    all.removeWhere((id, _) => !keepSessionIds.contains(id));
    await saveAll(all);
  }
}
