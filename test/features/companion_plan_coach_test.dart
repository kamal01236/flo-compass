import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/data/services/rule_based_companion_service.dart';

void main() {
  final service = RuleBasedCompanionService();

  const ceoKeynote = Session(
    id: 's-002',
    title: 'CEO Keynote: Nagarro in the Age of AI',
    abstract: '',
    day: 'Day 1',
    startTime: '10:00',
    endTime: '11:00',
    venueId: 'ven-G01',
    trackId: 'trk-06',
    speakerIds: ['spk-002'],
    tags: ['ceo_vision'],
    format: 'Keynote',
    level: 'beginner',
    featured: true,
    capacity: 200,
    building: 'Nagarro Gurgaon Office',
  );

  const overlap = Session(
    id: 's-099',
    title: 'Overlap Session',
    abstract: '',
    day: 'Day 1',
    startTime: '10:00',
    endTime: '11:00',
    venueId: 'ven-T601',
    trackId: 'trk-04',
    speakerIds: [],
    tags: ['architecture'],
    format: 'Talk',
    level: 'beginner',
    featured: false,
    capacity: 30,
    building: 'Nagarro Gurgaon Office',
  );

  const profile = UserProfile(
    role: AttendeeRole.engineer,
    interests: ['ceo_vision'],
    onboardingComplete: true,
  );

  const remoteProfile = UserProfile(
    role: AttendeeRole.engineer,
    interests: ['ceo_vision'],
    attendanceMode: AttendanceMode.remote,
    onboardingComplete: true,
  );

  test('resolve plan conflict query names keep and skip sessions', () {
    final response = service.answer(
      context: CompanionContext(
        query: 'Resolve plan conflict for CEO Keynote',
        sessions: [ceoKeynote, overlap],
        speakers: const [],
        venues: const [],
        tracks: const [],
        amenities: const [],
        profile: profile,
        plannedSessions: [ceoKeynote, overlap],
        lastReferencedSessionId: 's-002',
        conflicts: [PlanConflict(sessionA: ceoKeynote, sessionB: overlap)],
        minutesUntil: (_) => 30,
      ),
    );

    expect(response.text.toLowerCase(), contains('clash'));
    expect(response.sessionIds, containsAll(['s-002', 's-099']));
    expect(response.text, contains('CEO Keynote'));
    expect(response.text, contains('Overlap Session'));
    expect(response.referencedSessionId, 's-002');
  });

  test('remote profile gets stream hint for streamable conflict session', () {
    final response = service.answer(
      context: CompanionContext(
        query: 'Fix my plan conflicts',
        sessions: [ceoKeynote, overlap],
        speakers: const [],
        venues: const [],
        tracks: const [],
        amenities: const [],
        profile: remoteProfile,
        plannedSessions: [ceoKeynote, overlap],
        conflicts: [PlanConflict(sessionA: ceoKeynote, sessionB: overlap)],
        minutesUntil: (_) => 30,
      ),
    );

    expect(response.text.toLowerCase(), contains('stream'));
  });
}
