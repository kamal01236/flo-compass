import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/data/services/day_planner_service.dart';

void main() {
  test('returns non conflicting day plan', () {
    final service = DayPlannerService();
    final sessions = [
      Session(
        id: 's-1',
        title: 'A',
        abstract: 'a',
        day: 'Day 1',
        startTime: '09:00',
        endTime: '10:00',
        venueId: 'ven-G01',
        trackId: 'trk-01',
        speakerIds: const ['spk-001'],
        tags: const ['genai'],
        format: 'Keynote',
        level: 'beginner',
        featured: true,
        capacity: 100,
        building: 'Nagarro Gurgaon Office',
      ),
      Session(
        id: 's-2',
        title: 'B',
        abstract: 'a',
        day: 'Day 1',
        startTime: '09:30',
        endTime: '10:30',
        venueId: 'ven-G01',
        trackId: 'trk-02',
        speakerIds: const ['spk-002'],
        tags: const ['mlops'],
        format: 'Workshop',
        level: 'intermediate',
        featured: false,
        capacity: 100,
        building: 'Nagarro Gurgaon Office',
      ),
      Session(
        id: 's-3',
        title: 'C',
        abstract: 'a',
        day: 'Day 1',
        startTime: '10:30',
        endTime: '11:30',
        venueId: 'ven-G01',
        trackId: 'trk-03',
        speakerIds: const ['spk-003'],
        tags: const ['cloud'],
        format: 'Deep Dive',
        level: 'intermediate',
        featured: false,
        capacity: 100,
        building: 'Nagarro Gurgaon Office',
      ),
    ];
    final result = service.buildPlan(
      sessions: sessions,
      speakers: const [],
      tracks: const [],
      profile: const UserProfile(
        role: AttendeeRole.engineer,
        interests: ['genai'],
      ),
      requestedDay: 'Day 1',
    );
    expect(result.sessions.length, greaterThanOrEqualTo(2));
    expect(result.sessions.any((s) => s.id == 's-1'), isTrue);
  });
}
