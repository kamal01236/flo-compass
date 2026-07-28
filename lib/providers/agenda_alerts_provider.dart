import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/models.dart';
import '../data/services/agenda_change_detector.dart';
import '../data/services/agenda_session_fingerprint.dart';
import '../data/services/agenda_snapshot_store.dart';

export '../data/services/agenda_change_detector.dart'
    show AgendaChangeAlert, AgendaChangeReason, AgendaChangeType;

class AgendaAlertsState extends ChangeNotifier {
  AgendaAlertsState({
    SharedPreferences? prefs,
    AgendaSnapshotStore? snapshotStore,
    int maxUnreadAlerts = 20,
  }) : _prefs = prefs,
       _snapshotStore = snapshotStore ?? AgendaSnapshotStore(prefs: prefs),
       _maxUnreadAlerts = maxUnreadAlerts;

  SharedPreferences? _prefs;
  final AgendaSnapshotStore _snapshotStore;
  final int _maxUnreadAlerts;
  static const _alertsKey = 'flo_compass_agenda_unread_alerts';

  List<AgendaChangeAlert> unreadAlerts = [];

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_alertsKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        unreadAlerts = list
            .map((e) => AgendaChangeAlert.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to decode agenda alerts: $e');
        }
        unreadAlerts = [];
      }
    }
    notifyListeners();
  }

  bool hasUnreadForSession(String sessionId) {
    return unreadAlerts.any((a) => a.sessionId == sessionId);
  }

  AgendaChangeAlert? latestUnreadForSession(String sessionId) {
    for (final alert in unreadAlerts) {
      if (alert.sessionId == sessionId) return alert;
    }
    return null;
  }

  Future<void> seedBaseline({
    required List<Session> sessions,
    required Set<String> planSessionIds,
    required Set<String> followedSpeakerIds,
  }) async {
    final watched = watchedAgendaSessionIds(
      sessions: sessions,
      planSessionIds: planSessionIds,
      followedSpeakerIds: followedSpeakerIds,
    );
    final existing = await _snapshotStore.loadAll();
    final byId = {for (final s in sessions) s.id: s};
    final next = Map<String, AgendaSessionFingerprint>.from(existing);
    for (final sessionId in watched) {
      final session = byId[sessionId];
      if (session != null) {
        next[sessionId] = AgendaSessionFingerprint.fromSession(session);
      }
    }
    await _snapshotStore.prune(watched);
    await _snapshotStore.saveAll(next);
    notifyListeners();
  }

  Future<void> scanForChanges({
    required List<Session> sessions,
    required Set<String> planSessionIds,
    required Set<String> followedSpeakerIds,
    required DateTime now,
    required bool alertsEnabled,
  }) async {
    if (!alertsEnabled) return;

    final watched = watchedAgendaSessionIds(
      sessions: sessions,
      planSessionIds: planSessionIds,
      followedSpeakerIds: followedSpeakerIds,
    );
    final previous = await _snapshotStore.loadAll();
    final sessionTitles = {for (final s in sessions) s.id: s.title};
    for (final entry in previous.entries) {
      sessionTitles.putIfAbsent(entry.key, () => entry.value.title);
    }

    final detected = detectChanges(
      currentSessions: sessions,
      watchedSessionIds: watched,
      previousSnapshots: previous,
      planSessionIds: planSessionIds,
      followedSpeakerIds: followedSpeakerIds,
      sessionTitles: sessionTitles,
      now: now,
    );

    final byId = {for (final s in sessions) s.id: s};
    final next = Map<String, AgendaSessionFingerprint>.from(previous);
    for (final sessionId in watched) {
      final session = byId[sessionId];
      if (session != null) {
        next[sessionId] = AgendaSessionFingerprint.fromSession(session);
      } else if (previous.containsKey(sessionId)) {
        next[sessionId] = AgendaSessionFingerprint(
          title: previous[sessionId]!.title,
          venueId: previous[sessionId]!.venueId,
          startTime: previous[sessionId]!.startTime,
          endTime: previous[sessionId]!.endTime,
          day: previous[sessionId]!.day,
          exists: false,
        );
      }
    }
    await _snapshotStore.prune(watched);
    await _snapshotStore.saveAll(next);

    if (detected.isNotEmpty) {
      final merged = <String, AgendaChangeAlert>{
        for (final alert in unreadAlerts) alert.id: alert,
        for (final alert in detected) alert.id: alert,
      };
      unreadAlerts = merged.values.toList()
        ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
      if (unreadAlerts.length > _maxUnreadAlerts) {
        unreadAlerts = unreadAlerts.take(_maxUnreadAlerts).toList();
      }
      await _persistAlerts();
    }

    notifyListeners();
  }

  Future<void> dismiss(String alertId) async {
    unreadAlerts = unreadAlerts.where((a) => a.id != alertId).toList();
    await _persistAlerts();
    notifyListeners();
  }

  Future<void> dismissAll() async {
    unreadAlerts = [];
    await _persistAlerts();
    notifyListeners();
  }

  Future<void> _persistAlerts() async {
    _prefs ??= await SharedPreferences.getInstance();
    final encoded = unreadAlerts.map((a) => a.toJson()).toList();
    await _prefs!.setString(_alertsKey, jsonEncode(encoded));
  }
}
