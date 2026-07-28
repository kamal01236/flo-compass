import '../../data/models/models.dart';

class NowNextResult {
  const NowNextResult({this.now, this.next, this.displaySession});

  final Session? now;
  final Session? next;
  final Session? displaySession;
}

/// Resolves NOW / NEXT sessions for the event-day bar.
///
/// Order: planned in-progress → earliest upcoming planned → unplanned live
/// fallback (empty plan only) → empty.
NowNextResult resolveNowNext({
  required List<Session> planned,
  required int Function(Session session) minutesUntil,
  required int Function(Session session) minutesRemaining,
  List<Session> liveSessions = const [],
  List<Session> liveFallback = const [],
}) {
  final live = liveSessions.isNotEmpty ? liveSessions : liveFallback;
  if (planned.isEmpty) {
    if (live.isEmpty) {
      return const NowNextResult();
    }
    final fallback = live.first;
    return NowNextResult(now: fallback, displaySession: fallback);
  }

  final ordered = [...planned]
    ..sort((a, b) {
      final day = a.dayNumber.compareTo(b.dayNumber);
      if (day != 0) return day;
      return a.startTime.compareTo(b.startTime);
    });

  Session? now;
  for (final session in ordered) {
    if (_isHappeningNow(session, minutesUntil, minutesRemaining)) {
      now = session;
      break;
    }
  }

  Session? next;
  if (now == null) {
    for (final session in ordered) {
      if (minutesUntil(session) > 0) {
        next = session;
        break;
      }
    }
  }

  final displaySession = now ?? next;
  return NowNextResult(now: now, next: next, displaySession: displaySession);
}

bool _isHappeningNow(
  Session session,
  int Function(Session) minutesUntil,
  int Function(Session) minutesRemaining,
) {
  return minutesUntil(session) <= 0 && minutesRemaining(session) > 0;
}
