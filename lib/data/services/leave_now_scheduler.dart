import 'dart:async';

import '../models/models.dart';
import 'event_clock_service.dart';
import 'walking_time_estimator.dart';

const String kDefaultFromVenueId = 'ven-G01';
const int kLeaveNowBufferMinutes = 5;

class LeaveNowAlert {
  const LeaveNowAlert({
    required this.session,
    required this.leaveAt,
    required this.sessionStart,
    required this.walkMinutes,
  });

  final Session session;
  final DateTime leaveAt;
  final DateTime sessionStart;
  final int walkMinutes;
}

class LeaveNowScheduler {
  LeaveNowScheduler({
    EventClockService? clock,
    WalkingTimeEstimator? walkEstimator,
    this.bufferMinutes = kLeaveNowBufferMinutes,
    this.onAlert,
  }) : _clock = clock ?? EventClockService(),
       _walkEstimator = walkEstimator ?? WalkingTimeEstimator();

  final EventClockService _clock;
  final WalkingTimeEstimator _walkEstimator;
  final int bufferMinutes;
  final void Function(LeaveNowAlert alert)? onAlert;

  final List<Timer> _timers = [];

  List<LeaveNowAlert> get pending => _pendingAlerts;

  List<LeaveNowAlert> _pendingAlerts = [];

  void scheduleAll({
    required List<Session> planned,
    required List<Venue> venues,
    String? currentDay,
    bool notificationsEnabled = true,
    CampusLayout? campus,
    bool isEventDayMode = false,
    void Function(LeaveNowAlert alert)? onAlert,
  }) {
    cancelAll();
    _pendingAlerts = planAlerts(
      planned: planned,
      venues: venues,
      now: _clock.now(),
      currentDay: currentDay,
      walkEstimator: _walkEstimator,
      campus: campus,
      isEventDayMode: isEventDayMode,
      bufferMinutes: bufferMinutes,
    );

    final handler = onAlert ?? this.onAlert;
    if (!notificationsEnabled || handler == null) return;

    for (final alert in _pendingAlerts) {
      final delay = alert.leaveAt.difference(_clock.now());
      if (delay.isNegative) continue;
      _timers.add(
        Timer(delay, () {
          if (isWithinLeaveWindow(alert, _clock.now())) {
            handler(alert);
          }
        }),
      );
    }
  }

  void cancelAll() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  void dispose() => cancelAll();

  List<LeaveNowAlert> computeAlerts({
    required List<Session> plannedSessions,
    required List<Venue> venues,
    String? currentDay,
    CampusLayout? campus,
    bool isEventDayMode = false,
  }) {
    return planAlerts(
      planned: plannedSessions,
      venues: venues,
      now: _clock.now(),
      currentDay: currentDay ?? _clock.currentDay(),
      walkEstimator: _walkEstimator,
      campus: campus,
      isEventDayMode: isEventDayMode,
      bufferMinutes: bufferMinutes,
    );
  }

  List<LeaveNowAlert> activeAlerts({
    required List<Session> plannedSessions,
    required List<Venue> venues,
    String? currentDay,
    CampusLayout? campus,
    bool isEventDayMode = false,
  }) {
    return computeAlerts(
      plannedSessions: plannedSessions,
      venues: venues,
      currentDay: currentDay,
      campus: campus,
      isEventDayMode: isEventDayMode,
    ).where((alert) => isWithinLeaveWindow(alert, _clock.now())).toList();
  }

  static List<LeaveNowAlert> planAlerts({
    required List<Session> planned,
    required List<Venue> venues,
    required DateTime now,
    String? currentDay,
    WalkingTimeEstimator? walkEstimator,
    CampusLayout? campus,
    bool isEventDayMode = false,
    int bufferMinutes = kLeaveNowBufferMinutes,
  }) {
    final estimator = (walkEstimator ?? WalkingTimeEstimator()).withContext(
      campus: campus,
      isEventDayMode: isEventDayMode,
    );
    final venueById = {for (final v in venues) v.id: v};
    final defaultFrom = venueById[kDefaultFromVenueId];

    final ordered = [...planned]
      ..sort((a, b) {
        final day = a.dayNumber.compareTo(b.dayNumber);
        if (day != 0) return day;
        return a.startTime.compareTo(b.startTime);
      });

    final alerts = <LeaveNowAlert>[];
    Session? previous;

    for (final session in ordered) {
      if (currentDay != null && session.day != currentDay) {
        previous = session;
        continue;
      }

      final sessionStart = _sessionStart(session);
      if (!sessionStart.isAfter(now)) {
        previous = session;
        continue;
      }

      final fromVenue = previous == null
          ? defaultFrom
          : venueById[previous.venueId];
      final toVenue = venueById[session.venueId];
      final walk = estimator.estimate(from: fromVenue, to: toVenue);
      final leaveAt = sessionStart.subtract(
        Duration(minutes: walk.minutes + bufferMinutes),
      );

      if (leaveAt.isAfter(now)) {
        alerts.add(
          LeaveNowAlert(
            session: session,
            leaveAt: leaveAt,
            sessionStart: sessionStart,
            walkMinutes: walk.minutes,
          ),
        );
      }

      previous = session;
    }

    return alerts;
  }

  static bool isWithinLeaveWindow(LeaveNowAlert alert, DateTime now) {
    return !now.isBefore(alert.leaveAt) && now.isBefore(alert.sessionStart);
  }

  static DateTime _sessionStart(Session session) {
    final day = _dayToDate(session.day);
    final parts = session.startTime.split(':');
    return DateTime(
      day.year,
      day.month,
      day.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  static DateTime _dayToDate(String day) {
    return switch (day) {
      'Day 1' => DateTime(2026, 11, 4),
      'Day 2' => DateTime(2026, 11, 5),
      'Day 3' => DateTime(2026, 11, 6),
      _ => DateTime(2026, 11, 4),
    };
  }
}
