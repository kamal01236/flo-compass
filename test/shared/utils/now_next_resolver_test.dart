import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/services/event_clock_service.dart';
import 'package:flo_compass/shared/utils/now_next_resolver.dart';

Session _session({
  required String id,
  required String startTime,
  required String endTime,
  String day = 'Day 1',
  String venueId = 'ven-G01',
}) {
  return Session(
    id: id,
    title: 'Session $id',
    abstract: 'abstract',
    day: day,
    startTime: startTime,
    endTime: endTime,
    venueId: venueId,
    trackId: 'trk-01',
    speakerIds: const ['spk-001'],
    tags: const ['genai'],
    format: 'Talk',
    level: 'beginner',
    featured: false,
    capacity: 50,
    building: 'Nagarro Gurgaon Office',
  );
}

({int Function(Session) minutesUntil, int Function(Session) minutesRemaining})
_clockFns(DateTime now) {
  final clock = EventClockService(clock: () => now);
  return (
    minutesUntil: clock.minutesUntil,
    minutesRemaining: clock.minutesRemaining,
  );
}

void main() {
  group('resolveNowNext', () {
    test('returns NOW for first in-progress planned session', () {
      final now = DateTime(2026, 11, 4, 10, 30);
      final inProgress = _session(
        id: 's-now',
        startTime: '10:00',
        endTime: '11:00',
      );
      final upcoming = _session(
        id: 's-next',
        startTime: '11:00',
        endTime: '12:00',
      );
      final fns = _clockFns(now);

      final result = resolveNowNext(
        planned: [inProgress, upcoming],
        minutesUntil: fns.minutesUntil,
        minutesRemaining: fns.minutesRemaining,
      );

      expect(result.now?.id, 's-now');
      expect(result.next, isNull);
      expect(result.displaySession?.id, 's-now');
    });

    test('returns NEXT earliest upcoming when nothing in progress', () {
      final now = DateTime(2026, 11, 4, 9, 45);
      final first = _session(id: 's-1', startTime: '10:00', endTime: '11:00');
      final second = _session(id: 's-2', startTime: '11:00', endTime: '12:00');
      final fns = _clockFns(now);

      final result = resolveNowNext(
        planned: [second, first],
        minutesUntil: fns.minutesUntil,
        minutesRemaining: fns.minutesRemaining,
      );

      expect(result.now, isNull);
      expect(result.next?.id, 's-1');
      expect(result.displaySession?.id, 's-1');
    });

    test('falls back to happeningNow when plan is empty', () {
      final now = DateTime(2026, 11, 4, 10, 30);
      final live = _session(id: 's-live', startTime: '10:00', endTime: '11:00');
      final fns = _clockFns(now);

      final result = resolveNowNext(
        planned: const [],
        minutesUntil: fns.minutesUntil,
        minutesRemaining: fns.minutesRemaining,
        liveFallback: [live],
      );

      expect(result.now?.id, 's-live');
      expect(result.next, isNull);
      expect(result.displaySession?.id, 's-live');
    });

    test('returns empty when plan empty and nothing live', () {
      final now = DateTime(2026, 11, 4, 8, 0);
      _session(id: 's-later', startTime: '10:00', endTime: '11:00');
      final fns = _clockFns(now);

      final result = resolveNowNext(
        planned: const [],
        minutesUntil: fns.minutesUntil,
        minutesRemaining: fns.minutesRemaining,
      );

      expect(result.now, isNull);
      expect(result.next, isNull);
      expect(result.displaySession, isNull);
    });

    test('returns empty when planned sessions are all past', () {
      final now = DateTime(2026, 11, 4, 14, 0);
      final past = _session(id: 's-past', startTime: '10:00', endTime: '11:00');
      final fns = _clockFns(now);

      final result = resolveNowNext(
        planned: [past],
        minutesUntil: fns.minutesUntil,
        minutesRemaining: fns.minutesRemaining,
      );

      expect(result.now, isNull);
      expect(result.next, isNull);
      expect(result.displaySession, isNull);
    });
  });
}
