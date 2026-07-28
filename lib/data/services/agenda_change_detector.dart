import '../models/models.dart';
import 'agenda_session_fingerprint.dart';

enum AgendaChangeType { roomChanged, timeChanged, cancelled }

enum AgendaChangeReason { inPlan, followedSpeaker }

class AgendaChangeAlert {
  const AgendaChangeAlert({
    required this.id,
    required this.sessionId,
    required this.title,
    required this.type,
    required this.detectedAt,
    required this.reason,
    this.previousVenueId,
    this.newVenueId,
    this.previousStart,
    this.newStart,
    this.previousDay,
    this.newDay,
  });

  final String id;
  final String sessionId;
  final String title;
  final AgendaChangeType type;
  final DateTime detectedAt;
  final AgendaChangeReason reason;
  final String? previousVenueId;
  final String? newVenueId;
  final String? previousStart;
  final String? newStart;
  final String? previousDay;
  final String? newDay;

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'title': title,
    'type': type.name,
    'detectedAt': detectedAt.toIso8601String(),
    'reason': reason.name,
    if (previousVenueId != null) 'previousVenueId': previousVenueId,
    if (newVenueId != null) 'newVenueId': newVenueId,
    if (previousStart != null) 'previousStart': previousStart,
    if (newStart != null) 'newStart': newStart,
    if (previousDay != null) 'previousDay': previousDay,
    if (newDay != null) 'newDay': newDay,
  };

  factory AgendaChangeAlert.fromJson(Map<String, dynamic> json) {
    return AgendaChangeAlert(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      title: json['title'] as String,
      type: AgendaChangeType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => AgendaChangeType.timeChanged,
      ),
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      reason: AgendaChangeReason.values.firstWhere(
        (r) => r.name == json['reason'],
        orElse: () => AgendaChangeReason.inPlan,
      ),
      previousVenueId: json['previousVenueId'] as String?,
      newVenueId: json['newVenueId'] as String?,
      previousStart: json['previousStart'] as String?,
      newStart: json['newStart'] as String?,
      previousDay: json['previousDay'] as String?,
      newDay: json['newDay'] as String?,
    );
  }
}

Set<String> watchedAgendaSessionIds({
  required List<Session> sessions,
  required Set<String> planSessionIds,
  required Set<String> followedSpeakerIds,
}) {
  final watched = <String>{...planSessionIds};
  if (followedSpeakerIds.isEmpty) return watched;
  for (final session in sessions) {
    if (session.speakerIds.any(followedSpeakerIds.contains)) {
      watched.add(session.id);
    }
  }
  return watched;
}

List<AgendaChangeAlert> detectChanges({
  required List<Session> currentSessions,
  required Set<String> watchedSessionIds,
  required Map<String, AgendaSessionFingerprint> previousSnapshots,
  required Set<String> planSessionIds,
  required Set<String> followedSpeakerIds,
  required Map<String, String> sessionTitles,
  required DateTime now,
}) {
  final byId = {for (final s in currentSessions) s.id: s};
  final alerts = <AgendaChangeAlert>[];

  for (final sessionId in watchedSessionIds) {
    final previous = previousSnapshots[sessionId];
    if (previous == null) continue;

    final current = byId[sessionId];
    final reason = _reasonFor(
      sessionId: sessionId,
      session: current,
      planSessionIds: planSessionIds,
      followedSpeakerIds: followedSpeakerIds,
    );
    if (reason == null) continue;

    if (current == null) {
      if (previous.exists) {
        alerts.add(
          AgendaChangeAlert(
            id: _alertId(sessionId, AgendaChangeType.cancelled, now),
            sessionId: sessionId,
            title: previous.title.isNotEmpty ? previous.title : sessionId,
            type: AgendaChangeType.cancelled,
            detectedAt: now,
            reason: reason,
            previousVenueId: previous.venueId,
            previousStart: previous.startTime,
            previousDay: previous.day,
          ),
        );
      }
      continue;
    }

    final currentFp = AgendaSessionFingerprint.fromSession(current);
    if (previous.matchesSchedule(currentFp)) continue;

    if (previous.venueId != currentFp.venueId) {
      alerts.add(
        AgendaChangeAlert(
          id: _alertId(sessionId, AgendaChangeType.roomChanged, now),
          sessionId: sessionId,
          title: current.title,
          type: AgendaChangeType.roomChanged,
          detectedAt: now,
          reason: reason,
          previousVenueId: previous.venueId,
          newVenueId: currentFp.venueId,
          previousStart: previous.startTime,
          newStart: currentFp.startTime,
          previousDay: previous.day,
          newDay: currentFp.day,
        ),
      );
      continue;
    }

    if (previous.startTime != currentFp.startTime ||
        previous.endTime != currentFp.endTime ||
        previous.day != currentFp.day) {
      alerts.add(
        AgendaChangeAlert(
          id: _alertId(sessionId, AgendaChangeType.timeChanged, now),
          sessionId: sessionId,
          title: current.title,
          type: AgendaChangeType.timeChanged,
          detectedAt: now,
          reason: reason,
          previousVenueId: previous.venueId,
          newVenueId: currentFp.venueId,
          previousStart: previous.startTime,
          newStart: currentFp.startTime,
          previousDay: previous.day,
          newDay: currentFp.day,
        ),
      );
    }
  }

  return alerts;
}

AgendaChangeReason? _reasonFor({
  required String sessionId,
  required Session? session,
  required Set<String> planSessionIds,
  required Set<String> followedSpeakerIds,
}) {
  final inPlan = planSessionIds.contains(sessionId);
  final followed =
      session != null && session.speakerIds.any(followedSpeakerIds.contains);
  if (inPlan) return AgendaChangeReason.inPlan;
  if (followed) return AgendaChangeReason.followedSpeaker;
  return null;
}

String _alertId(String sessionId, AgendaChangeType type, DateTime now) {
  return '$sessionId-${type.name}-${now.millisecondsSinceEpoch}';
}
