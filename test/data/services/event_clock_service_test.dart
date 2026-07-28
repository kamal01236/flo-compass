import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/services/event_clock_service.dart';

void main() {
  test('happening now and starting soon', () {
    final clock = EventClockService(clock: () => DateTime(2026, 11, 4, 10, 5));
    final nowSession = Session(
      id: 's-1',
      title: 'Now',
      abstract: 'a',
      day: 'Day 1',
      startTime: '10:00',
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
    final soonSession = Session(
      id: 's-2',
      title: 'Soon',
      abstract: 'a',
      day: 'Day 1',
      startTime: '10:15',
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
    expect(clock.isHappeningNow(nowSession), isTrue);
    expect(clock.isStartingSoon(soonSession), isTrue);
  });
}
