import '../../core/config/event_dates.dart';
import '../../data/models/models.dart';

enum EventStage { beforeEvent, duringEvent, afterEvent }

/// Resolves whether the app is before, during, or after Flo 2026.
EventStage resolveStage({
  required DateTime current,
  DateTime? eventStart,
  DateTime? eventEnd,
}) {
  final start = eventStart ?? EventDates.eventStart;
  final endExclusive = eventEnd ?? EventDates.eventEndExclusive;

  if (current.isBefore(start)) return EventStage.beforeEvent;
  if (!current.isBefore(endExclusive)) return EventStage.afterEvent;
  return EventStage.duringEvent;
}

/// Earliest session start across loaded sessions (falls back to Day 1 09:00).
DateTime? firstSessionStart(List<Session> sessions) {
  if (sessions.isEmpty) return null;

  final ordered = [...sessions]
    ..sort((a, b) {
      final dayCompare = a.dayNumber.compareTo(b.dayNumber);
      if (dayCompare != 0) return dayCompare;
      return a.startTime.compareTo(b.startTime);
    });

  final first = ordered.first;
  final day = EventDates.dateForDay(first.day);
  final parts = first.startTime.split(':');
  return DateTime(
    day.year,
    day.month,
    day.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String formatEventStartTitle(DateTime start) {
  final weekday = _weekdays[start.weekday - 1];
  final hour = start.hour.toString().padLeft(2, '0');
  final minute = start.minute.toString().padLeft(2, '0');
  return 'Event starts $weekday at $hour:$minute';
}
