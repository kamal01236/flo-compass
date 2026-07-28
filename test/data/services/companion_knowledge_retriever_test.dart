import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/data/services/companion_knowledge_retriever.dart';

void main() {
  final retriever = CompanionKnowledgeRetriever();

  final sessions = [
    Session(
      id: 's-002',
      title: 'CEO Fireside: Nagarro Unfiltered — The Next Five Years',
      abstract: 'CEO discusses strategy',
      day: 'Day 1',
      startTime: '10:00',
      endTime: '11:00',
      venueId: 'ven-G01',
      trackId: 'trk-06',
      speakerIds: ['spk-002'],
      tags: ['ceo_vision'],
      format: 'Fireside Chat',
      level: 'beginner',
      featured: true,
      capacity: 500,
      building: 'Nagarro Gurgaon Office',
    ),
    Session(
      id: 's-003',
      title: 'CTO Masterclass: Engineering at the Edge of Now',
      abstract: '',
      day: 'Day 1',
      startTime: '11:00',
      endTime: '12:00',
      venueId: 'ven-T601',
      trackId: 'trk-03',
      speakerIds: ['spk-003'],
      tags: ['architecture'],
      format: 'Keynote',
      level: 'beginner',
      featured: true,
      capacity: 150,
      building: 'Nagarro Gurgaon Office',
    ),
  ];

  final venues = [
    const Venue(
      id: 'ven-G01',
      name: 'Reception and Welcome Hall',
      floor: 'G',
      zone: 'Reception',
      wing: 'central',
      capacity: 500,
      building: 'Nagarro Gurgaon Office',
    ),
    const Venue(
      id: 'ven-8S3',
      name: 'Floor 8 South Pod 3',
      floor: '8',
      zone: 'Sitting Area',
      wing: 'S',
      capacity: 20,
      building: 'Nagarro Gurgaon Office',
    ),
  ];

  final amenities = [
    const Amenity(
      id: 'am-8-restroom-s',
      type: 'restroom',
      floor: '8',
      wing: 'S',
      label: 'Floor 8 South Restrooms',
    ),
    const Amenity(
      id: 'am-6-coffee',
      type: 'coffee',
      floor: '6',
      wing: 'N',
      label: 'Community Cafeteria',
      venueId: 'ven-C601',
    ),
  ];

  final meta = EventMeta(
    eventName: 'Flo 2026',
    venue: 'Nagarro Gurgaon Office',
    timezone: 'IST',
    slots: const ['09:00', '10:00'],
    days: const [],
    floorStories: const {'8': 'Pod rooms on both wings'},
  );

  final profile = UserProfile(
    role: AttendeeRole.engineer,
    interests: const ['ceo_vision', 'cursor'],
    onboardingComplete: true,
  );

  CompanionContext baseContext({
    required String query,
    List<Session> planned = const [],
    int Function(Session)? minutesUntil,
  }) {
    return CompanionContext(
      query: query,
      sessions: sessions,
      speakers: const [],
      venues: venues,
      tracks: const [],
      amenities: amenities,
      navigationHints: const [],
      meta: meta,
      profile: profile,
      plannedSessions: planned,
      currentDay: 'Day 1',
      minutesUntil: minutesUntil ?? (_) => 30,
    );
  }

  test('retrieves CEO fireside for demo query', () {
    final pack = retriever.retrieve(baseContext(query: 'CEO fireside'));
    expect(pack.sessions.any((s) => s.id == 's-002'), isTrue);
  });

  test('retrieves Floor 8 restroom amenity', () {
    final pack = retriever.retrieve(
      baseContext(query: 'nearest restroom on Floor 8'),
    );
    expect(pack.amenities.any((a) => a.id == 'am-8-restroom-s'), isTrue);
  });

  test('includes plan snapshot for next session query', () {
    final pack = retriever.retrieve(
      baseContext(
        query: 'where is my next session',
        planned: [sessions[1]],
        minutesUntil: (s) => s.id == 's-003' ? 18 : 0,
      ),
    );
    expect(pack.planSnapshot?.nextSession?.id, 's-003');
    expect(pack.planSnapshot?.minutesUntilNext, 18);
  });

  test('plan my day returns featured sessions in default pack', () {
    final pack = retriever.retrieve(baseContext(query: 'plan my day'));
    expect(pack.sessions, isNotEmpty);
    expect(pack.sessions.every((s) => s.featured), isTrue);
  });
}
