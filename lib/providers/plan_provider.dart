import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/models.dart';
import '../data/services/audit_log_service.dart';
import '../data/services/conflict_detector.dart';
import 'ops_config_provider.dart';

class PlanMergeResult {
  const PlanMergeResult({required this.importedCount, required this.newCount});

  final int importedCount;
  final int newCount;
}

class PlanState extends ChangeNotifier {
  PlanState({SharedPreferences? prefs, ConflictDetector? conflictDetector})
    : _prefs = prefs,
      _conflictDetector = conflictDetector ?? ConflictDetector();

  SharedPreferences? _prefs;
  final ConflictDetector _conflictDetector;

  static const _key = 'flo_compass_plan';
  final Set<String> _sessionIds = {};

  Set<String> get sessionIds => Set.unmodifiable(_sessionIds);

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _sessionIds
      ..clear()
      ..addAll(_prefs!.getStringList(_key) ?? []);
    notifyListeners();
  }

  bool isInPlan(String sessionId) => _sessionIds.contains(sessionId);

  Future<void> toggle(String sessionId) async {
    final previous = Set<String>.from(_sessionIds);
    if (_sessionIds.contains(sessionId)) {
      _sessionIds.remove(sessionId);
    } else {
      _sessionIds.add(sessionId);
    }
    final saved = await _persistIds();
    if (saved) {
      notifyListeners();
      await recordAudit(
        action: AuditActions.planToggle,
        entityType: 'plan',
        entityId: sessionId,
        metadata: {'inPlan': _sessionIds.contains(sessionId)},
      );
    } else {
      _sessionIds
        ..clear()
        ..addAll(previous);
    }
  }

  List<Session> plannedSessions(List<Session> all) {
    return all.where((s) => _sessionIds.contains(s.id)).toList()..sort((a, b) {
      final day = a.dayNumber.compareTo(b.dayNumber);
      if (day != 0) return day;
      return a.startTime.compareTo(b.startTime);
    });
  }

  static List<String> _dedupeIds(Iterable<String> ids) {
    final seen = <String>{};
    final unique = <String>[];
    for (final id in ids) {
      if (seen.add(id)) unique.add(id);
    }
    return unique;
  }

  Future<PlanMergeResult> mergeSessions(Iterable<String> ids) async {
    _prefs ??= await SharedPreferences.getInstance();
    final previous = Set<String>.from(_sessionIds);
    final uniqueIds = _dedupeIds(ids);
    var newCount = 0;
    for (final id in uniqueIds) {
      if (_sessionIds.add(id)) newCount++;
    }
    if (await _persistIds()) {
      notifyListeners();
    } else {
      _sessionIds
        ..clear()
        ..addAll(previous);
    }
    return PlanMergeResult(importedCount: uniqueIds.length, newCount: newCount);
  }

  Future<PlanMergeResult> replaceSessions(Iterable<String> ids) async {
    _prefs ??= await SharedPreferences.getInstance();
    final previous = Set<String>.from(_sessionIds);
    final uniqueIds = _dedupeIds(ids);
    _sessionIds
      ..clear()
      ..addAll(uniqueIds);
    if (await _persistIds()) {
      notifyListeners();
    } else {
      _sessionIds
        ..clear()
        ..addAll(previous);
    }
    return PlanMergeResult(
      importedCount: uniqueIds.length,
      newCount: uniqueIds.length,
    );
  }

  Future<int> addSessions(List<String> ids, List<Session> all) async {
    final previous = Set<String>.from(_sessionIds);
    final sessionsById = {for (final session in all) session.id: session};
    final planned = plannedSessions(all);
    var added = 0;
    for (final id in ids) {
      if (_sessionIds.contains(id)) continue;
      final session = sessionsById[id];
      if (session == null) continue;
      final candidate = [...planned, session];
      if (_conflictDetector.findConflicts(candidate).isNotEmpty) continue;
      _sessionIds.add(id);
      planned.add(session);
      added++;
    }
    if (added > 0) {
      if (await _persistIds()) {
        notifyListeners();
      } else {
        _sessionIds
          ..clear()
          ..addAll(previous);
      }
    }
    return added;
  }

  Future<void> clear() async {
    _prefs ??= await SharedPreferences.getInstance();
    _sessionIds.clear();
    await _prefs!.remove(_key);
    notifyListeners();
    await recordAudit(action: AuditActions.planClear, entityType: 'plan');
  }

  Future<bool> _persistIds() async {
    _prefs ??= await SharedPreferences.getInstance();
    try {
      await _prefs!.setStringList(_key, _sessionIds.toList());
      return true;
    } catch (_) {
      return false;
    }
  }

  List<PlanConflict> conflicts(List<Session> all) {
    return _conflictDetector.findConflicts(plannedSessions(all));
  }
}
