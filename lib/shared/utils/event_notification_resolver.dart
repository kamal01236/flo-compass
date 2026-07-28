import '../../data/models/models.dart';
import '../../data/services/agenda_change_detector.dart';
import '../../data/services/leave_now_scheduler.dart';

class SessionNotificationAlert {
  const SessionNotificationAlert({
    required this.session,
    required this.isFollowing,
    required this.isInPlan,
  });

  final Session session;
  final bool isFollowing;
  final bool isInPlan;
}

class EventNotificationSnapshot {
  const EventNotificationSnapshot({
    required this.sessionAlerts,
    required this.leaveNowAlerts,
    this.agendaChangeAlerts = const [],
  });

  final List<SessionNotificationAlert> sessionAlerts;
  final List<LeaveNowAlert> leaveNowAlerts;
  final List<AgendaChangeAlert> agendaChangeAlerts;

  int get count =>
      sessionAlerts.length + leaveNowAlerts.length + agendaChangeAlerts.length;
}

List<SessionNotificationAlert> buildSessionAlerts({
  required List<Session> startingSoon30,
  required List<Session> startingSoon20,
  required List<String> plannedSessionIds,
  required List<String> followedSpeakerIds,
  required int Function(Session session) minutesUntil,
}) {
  final followed = followedSpeakerIds.toSet();
  final inPlan = plannedSessionIds.toSet();
  final byId = <String, SessionNotificationAlert>{};

  for (final session in startingSoon30) {
    final isFollowing = session.speakerIds.any(followed.contains);
    final isInPlan = inPlan.contains(session.id);
    if (!isFollowing && !isInPlan) continue;
    byId[session.id] = SessionNotificationAlert(
      session: session,
      isFollowing: isFollowing,
      isInPlan: isInPlan,
    );
  }

  for (final session in startingSoon20) {
    byId.putIfAbsent(
      session.id,
      () => SessionNotificationAlert(
        session: session,
        isFollowing: session.speakerIds.any(followed.contains),
        isInPlan: inPlan.contains(session.id),
      ),
    );
  }

  final alerts = byId.values.toList()
    ..sort((a, b) {
      int rank(SessionNotificationAlert item) {
        if (item.isFollowing && item.isInPlan) return 0;
        if (item.isFollowing) return 1;
        return 2;
      }

      final rankCmp = rank(a).compareTo(rank(b));
      if (rankCmp != 0) return rankCmp;
      return minutesUntil(a.session).compareTo(minutesUntil(b.session));
    });
  return alerts.take(6).toList();
}

EventNotificationSnapshot resolveEventNotifications({
  required List<Session> sessionsStartingSoon30,
  required List<Session> sessionsStartingSoon20,
  required List<Session> plannedSessions,
  required List<String> followedSpeakerIds,
  required List<Venue> venues,
  required int Function(Session session) minutesUntil,
  required DateTime now,
  String? currentDay,
  List<AgendaChangeAlert> agendaChangeAlerts = const [],
  bool agendaChangeAlertsEnabled = true,
}) {
  final sessionAlerts = buildSessionAlerts(
    startingSoon30: sessionsStartingSoon30,
    startingSoon20: sessionsStartingSoon20,
    plannedSessionIds: plannedSessions.map((s) => s.id).toList(),
    followedSpeakerIds: followedSpeakerIds,
    minutesUntil: minutesUntil,
  );
  final leaveNowAlerts =
      LeaveNowScheduler.planAlerts(
            planned: plannedSessions,
            venues: venues,
            now: now,
            currentDay: currentDay,
          )
          .where((alert) => LeaveNowScheduler.isWithinLeaveWindow(alert, now))
          .toList();

  final agendaAlerts = agendaChangeAlertsEnabled
      ? (List<AgendaChangeAlert>.from(agendaChangeAlerts)
          ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt)))
      : <AgendaChangeAlert>[];

  return EventNotificationSnapshot(
    agendaChangeAlerts: agendaAlerts,
    sessionAlerts: sessionAlerts,
    leaveNowAlerts: leaveNowAlerts,
  );
}
