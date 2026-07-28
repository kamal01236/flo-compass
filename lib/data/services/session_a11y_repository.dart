import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SessionA11yInfo {
  const SessionA11yInfo({
    required this.captions,
    required this.hearingLoop,
    this.notes,
  });

  final bool captions;
  final bool hearingLoop;
  final String? notes;

  factory SessionA11yInfo.fromJson(Map<String, dynamic> json) {
    return SessionA11yInfo(
      captions: json['captions'] as bool? ?? false,
      hearingLoop: json['hearingLoop'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }
}

/// Loads `session_a11y.json` once and serves lookups by session id.
class SessionA11yRepository {
  SessionA11yRepository._();

  static final SessionA11yRepository instance = SessionA11yRepository._();

  Map<String, SessionA11yInfo>? _cache;
  Future<Map<String, SessionA11yInfo>>? _loading;

  Future<Map<String, SessionA11yInfo>> loadAll() {
    return _loading ??= _load();
  }

  Future<SessionA11yInfo?> forSession(String sessionId) async {
    final all = await loadAll();
    return all[sessionId];
  }

  Future<Map<String, SessionA11yInfo>> _load() async {
    if (_cache != null) return _cache!;
    final map = <String, SessionA11yInfo>{};
    try {
      final raw = await rootBundle.loadString('assets/data/session_a11y.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final sessions = data['sessions'] as List<dynamic>? ?? [];
      for (final item in sessions) {
        final entry = item as Map<String, dynamic>;
        final id = entry['sessionId'] as String?;
        if (id == null) continue;
        map[id] = SessionA11yInfo.fromJson(entry);
      }
    } catch (_) {
      // Asset optional for non-featured sessions.
    }
    _cache = map;
    return map;
  }

  @visibleForTesting
  void resetForTest() {
    _cache = null;
    _loading = null;
  }
}
