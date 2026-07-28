import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/domain/entities/event_day.dart';
import 'package:flo_compass/domain/entities/event_meta.dart';
import 'package:flo_compass/domain/entities/session.dart';
import 'package:flo_compass/shared/utils/session_capacity.dart';
import 'package:flo_compass/shared/utils/session_time_display.dart';

void main() {
  group('session_capacity', () {
    test('maps occupancy bands', () {
      expect(capacityPresentation(40).$2, 'Seats available');
      expect(capacityPresentation(75).$2, 'Filling fast');
      expect(capacityPresentation(95).$2, 'Nearly full');
    });
  });

  group('session_time_display', () {
    const session = Session(
      id: 's-001',
      title: 'CEO Keynote',
      abstract: 'a',
      day: 'Day 1',
      startTime: '09:00',
      endTime: '10:00',
      venueId: 'ven-1',
      trackId: 'trk-01',
      speakerIds: [],
      tags: [],
      format: 'Keynote',
      level: 'beginner',
      featured: true,
      capacity: 100,
      building: 'Nagarro Gurgaon Office',
    );

    test('formats IST line for Day 1 09:00', () {
      const meta = EventMeta(
        eventName: 'Flo',
        venue: 'Gurgaon',
        timezone: 'Asia/Kolkata',
        slots: ['09:00'],
        days: [
          EventDay(
            id: 'Day 1',
            name: 'Day 1',
            date: '2026-11-04',
            description: 'Day one',
          ),
        ],
      );

      final line = formatSessionTimeDisplay(
        session: session,
        meta: meta,
        referenceNow: DateTime(2026, 11, 4, 8, 0),
      );

      expect(line, contains('09:00 IST'));
      expect(line, contains('·'));
    });
  });
}
