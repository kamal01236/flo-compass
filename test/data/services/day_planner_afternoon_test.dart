import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/data/services/conflict_detector.dart';
import 'package:flo_compass/data/services/day_planner_service.dart';
import 'package:flo_compass/data/services/event_clock_service.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/domain/inputs/day_planner_context.dart';
import 'package:flo_compass/providers/profile_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Session afternoonSession({
    required String id,
    required String start,
    required String end,
    List<String> tags = const ['genai'],
  }) {
    return Session(
      id: id,
      title: 'Afternoon $id',
      abstract: 'test',
      day: 'Day 1',
      startTime: start,
      endTime: end,
      venueId: 'ven-G01',
      trackId: 'trk-01',
      speakerIds: const ['spk-001'],
      tags: tags,
      format: 'Deep Dive',
      level: 'intermediate',
      featured: false,
      capacity: 40,
      building: 'Nagarro Gurgaon Office',
    );
  }

  EventState buildEvent(List<Session> sessions) {
    final event = EventState(
      eventClockService: EventClockService(
        clock: () => DateTime(2026, 11, 4, 10, 0),
      ),
    );
    event
      ..loading = false
      ..sessions = sessions
      ..speakers = const [
        Speaker(
          id: 'spk-001',
          name: 'Test Speaker',
          title: 'Engineer',
          tier: 4,
          bio: '',
        ),
      ]
      ..tracks = const [
        Track(id: 'trk-01', name: 'GenAI', tags: ['genai']),
      ];
    return event;
  }

  test(
    'buildAfternoon returns conflict-free sessions in 13:00-17:00 window',
    () {
      final morning = afternoonSession(
        id: 's-am',
        start: '09:00',
        end: '10:00',
        tags: const ['cloud'],
      );
      final slotA = afternoonSession(id: 's-a', start: '13:00', end: '14:00');
      final slotB = afternoonSession(id: 's-b', start: '14:00', end: '15:00');
      final slotC = afternoonSession(id: 's-c', start: '15:00', end: '16:00');
      final slotD = afternoonSession(id: 's-d', start: '16:00', end: '17:00');
      final overlap = afternoonSession(
        id: 's-overlap',
        start: '13:30',
        end: '14:30',
      );

      final event = buildEvent([morning, slotA, slotB, slotC, slotD, overlap]);
      final plan = PlanState(conflictDetector: ConflictDetector());
      final profile = ProfileState()
        ..profile = const UserProfile(
          role: AttendeeRole.engineer,
          interests: ['genai'],
          onboardingComplete: true,
        );

      final result = DayPlannerService().buildAfternoon(
        DayPlannerContext(
          day: 'Day 1',
          plannedSessionIds: plan.sessionIds,
          sessions: event.sessions,
          speakers: event.speakers,
          tracks: event.tracks,
          profile: profile.profile,
          currentTime: event.currentTime,
          behaviorSnapshot: event.behaviorSnapshot,
        ),
      );

      expect(result, isNotEmpty);
      for (final session in result) {
        final start = _minutes(session.startTime);
        final end = _minutes(session.endTime);
        expect(start, greaterThanOrEqualTo(13 * 60));
        expect(end, lessThanOrEqualTo(17 * 60));
      }

      final combined = [...plan.plannedSessions(event.sessions), ...result];
      expect(ConflictDetector().findConflicts(combined), isEmpty);
    },
  );

  test('buildAfternoon skips already planned afternoon slots', () async {
    SharedPreferences.setMockInitialValues({
      'flo_compass_plan': ['s-a'],
    });

    final slotA = afternoonSession(id: 's-a', start: '13:00', end: '14:00');
    final slotB = afternoonSession(id: 's-b', start: '14:00', end: '15:00');
    final slotC = afternoonSession(id: 's-c', start: '15:00', end: '16:00');

    final event = buildEvent([slotA, slotB, slotC]);
    final plan = PlanState(conflictDetector: ConflictDetector());
    await plan.init();

    final result = DayPlannerService().buildAfternoon(
      DayPlannerContext(
        day: 'Day 1',
        plannedSessionIds: plan.sessionIds,
        sessions: event.sessions,
        speakers: event.speakers,
        tracks: event.tracks,
        profile: UserProfile.empty,
        currentTime: event.currentTime,
        behaviorSnapshot: event.behaviorSnapshot,
      ),
    );

    expect(result.any((session) => session.id == 's-a'), isFalse);
    expect(result.map((s) => s.id), contains('s-b'));
  });
}

int _minutes(String time) {
  final parts = time.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}
