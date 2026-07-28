import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/shared/utils/event_stage.dart';

Session _session({required String day, required String startTime}) {
  return Session(
    id: 's-1',
    title: 'Opening Keynote',
    abstract: 'a',
    day: day,
    startTime: startTime,
    endTime: '11:00',
    venueId: 'ven-G01',
    trackId: 'trk-01',
    speakerIds: const ['spk-001'],
    tags: const ['genai'],
    format: 'Keynote',
    level: 'beginner',
    featured: true,
    capacity: 100,
    building: 'Nagarro Gurgaon Office',
  );
}

void main() {
  test('resolveStage returns beforeEvent before Nov 4 2026', () {
    expect(
      resolveStage(current: DateTime(2026, 11, 3, 12, 0)),
      EventStage.beforeEvent,
    );
  });

  test('resolveStage returns duringEvent on Day 1', () {
    expect(
      resolveStage(current: DateTime(2026, 11, 4, 10, 0)),
      EventStage.duringEvent,
    );
  });

  test('resolveStage returns afterEvent after Day 3', () {
    expect(
      resolveStage(current: DateTime(2026, 11, 7, 9, 0)),
      EventStage.afterEvent,
    );
  });

  test('firstSessionStart picks earliest session', () {
    final sessions = [
      _session(day: 'Day 2', startTime: '10:00'),
      _session(day: 'Day 1', startTime: '09:00'),
    ];

    final start = firstSessionStart(sessions);
    expect(start, DateTime(2026, 11, 4, 9, 0));
    expect(formatEventStartTitle(start!), 'Event starts Wed at 09:00');
  });
}
