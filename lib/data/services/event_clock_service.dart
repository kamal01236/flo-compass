import '../../config/app_config.dart';
import '../models/models.dart';

class EventClockService {
  EventClockService({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  DateTime? _overrideNow;

  bool get isInDemoMode =>
      AppConfig.eventNow.isNotEmpty || _overrideNow != null;

  void setOverride(DateTime? overrideNow) {
    _overrideNow = overrideNow;
  }

  DateTime now() {
    if (_overrideNow != null) return _overrideNow!;
    if (AppConfig.eventNow.isNotEmpty) {
      final parsed = DateTime.tryParse(AppConfig.eventNow);
      if (parsed != null) return parsed;
    }
    final actual = _clock();
    if (_isInsideEventWindow(actual)) return actual;
    return DateTime(2026, 11, 4, 10, 30);
  }

  String? currentDay() {
    final t = now();
    if (t.year != 2026 || t.month != 11) return null;
    return switch (t.day) {
      4 => 'Day 1',
      5 => 'Day 2',
      6 => 'Day 3',
      _ => null,
    };
  }

  DateTime sessionStart(Session session) => _sessionStart(session);

  int minutesUntil(Session session) {
    return _sessionStart(session).difference(now()).inMinutes;
  }

  bool isHappeningNow(Session session) {
    final t = now();
    final start = _sessionStart(session);
    final end = _sessionEnd(session);
    return !t.isBefore(start) && t.isBefore(end);
  }

  bool isStartingSoon(Session session, {int withinMinutes = 15}) {
    final mins = minutesUntil(session);
    return mins >= 0 && mins <= withinMinutes;
  }

  int minutesRemaining(Session session) {
    return _sessionEnd(session).difference(now()).inMinutes;
  }

  DateTime _sessionStart(Session session) {
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

  DateTime _sessionEnd(Session session) {
    final day = _dayToDate(session.day);
    final parts = session.endTime.split(':');
    return DateTime(
      day.year,
      day.month,
      day.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  DateTime _dayToDate(String day) {
    return switch (day) {
      'Day 1' => DateTime(2026, 11, 4),
      'Day 2' => DateTime(2026, 11, 5),
      'Day 3' => DateTime(2026, 11, 6),
      _ => DateTime(2026, 11, 4),
    };
  }

  bool _isInsideEventWindow(DateTime value) {
    final start = DateTime(2026, 11, 4);
    final endExclusive = DateTime(2026, 11, 7);
    return !value.isBefore(start) && value.isBefore(endExclusive);
  }
}
