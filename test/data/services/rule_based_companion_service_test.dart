import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/mappers/campus_mapper.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/data/services/rule_based_companion_service.dart';

void main() {
  final service = RuleBasedCompanionService();

  final sessions = [
    Session(
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
    ),
    Session(
      id: 's-006',
      title: 'Fireside with the Chairman: Culture & Long-Term Thinking',
      abstract: '',
      day: 'Day 2',
      startTime: '16:00',
      endTime: '17:00',
      venueId: 'ven-T601',
      trackId: 'trk-05',
      speakerIds: ['spk-001'],
      tags: ['leadership'],
      format: 'Fireside Chat',
      level: 'beginner',
      featured: true,
      capacity: 30,
      building: 'Nagarro Gurgaon Office',
    ),
    Session(
      id: 's-004',
      title: 'Building Agentic Workflows with Cursor',
      abstract: '',
      day: 'Day 1',
      startTime: '14:00',
      endTime: '15:00',
      venueId: 'ven-T602',
      trackId: 'trk-08',
      speakerIds: ['spk-019'],
      tags: ['cursor', 'devex'],
      format: 'Workshop',
      level: 'intermediate',
      featured: true,
      capacity: 100,
      building: 'Nagarro Gurgaon Office',
    ),
    Session(
      id: 's-003',
      title: 'CTO Address: Engineering the Next Decade',
      abstract: '',
      day: 'Day 1',
      startTime: '11:00',
      endTime: '12:00',
      venueId: 'ven-T601',
      trackId: 'trk-04',
      speakerIds: ['spk-003'],
      tags: ['architecture'],
      format: 'Keynote',
      level: 'beginner',
      featured: true,
      capacity: 150,
      building: 'Nagarro Gurgaon Office',
    ),
  ];

  const speakers = [
    Speaker(id: 'spk-002', name: 'Elena Novak', title: 'CEO', tier: 1, bio: ''),
    Speaker(
      id: 'spk-001',
      name: 'Vikram Ashar',
      title: 'Chairman',
      tier: 1,
      bio: '',
    ),
    Speaker(
      id: 'spk-019',
      name: 'Rachel Kim',
      title: 'DevEx',
      tier: 3,
      bio: '',
    ),
    Speaker(
      id: 'spk-003',
      name: 'Dr. Arjun Mehta',
      title: 'CTO',
      tier: 1,
      bio: '',
    ),
  ];

  final venues = [
    const Venue(
      id: 'ven-G01',
      name: 'Reception Hall',
      floor: 'G',
      zone: 'Reception',
      wing: 'central',
      capacity: 200,
      building: 'Nagarro Gurgaon Office',
      landmarks: ['past Reception desk'],
      nearestElevator: 'central',
      stepFree: true,
    ),
    const Venue(
      id: 'ven-T601',
      name: 'Training Room 1',
      floor: '6',
      zone: 'Training',
      wing: 'S',
      capacity: 30,
      building: 'Nagarro Gurgaon Office',
      landmarks: ['past South elevator bank'],
      nearestElevator: 'S',
    ),
  ];

  const amenities = [
    Amenity(
      id: 'am-8-restroom-n',
      type: 'restroom',
      floor: '8',
      wing: 'N',
      label: 'North wing restrooms (ladies)',
    ),
    Amenity(
      id: 'am-8-restroom-s',
      type: 'restroom',
      floor: '8',
      wing: 'S',
      label: 'South wing restrooms (gents)',
    ),
    Amenity(
      id: 'am-5-garden',
      type: 'garden',
      floor: '5',
      wing: 'central',
      label: 'Open Air Garden & Fountain',
    ),
    Amenity(
      id: 'park-2-car',
      type: 'parking_car',
      floor: '2',
      wing: 'central',
      label: '2nd floor car parking',
      capacityTotal: 40,
      capacityAvailable: 12,
      vehicleType: 'car',
    ),
    Amenity(
      id: 'park-2-bike',
      type: 'parking_bike',
      floor: '2',
      wing: 'central',
      label: '2nd floor bike parking',
      capacityTotal: 100,
      capacityAvailable: 67,
      vehicleType: 'bike',
    ),
    Amenity(
      id: 'am-13-quiet',
      type: 'quiet_zone',
      floor: '13',
      wing: 'N',
      label: 'Quiet Terrace Zone',
    ),
  ];

  final campus = campusFromJson({
    'building': 'Nagarro Gurgaon Office',
    'parkingFloors': ['B', 'G', '1', '2', '3', '4'],
    'parkingCapacityPerFloor': {'cars': 40, 'bikes': 100},
    'wellnessFloor': '5',
    'eventFloors': ['G', '6', '7', '8', '9', '10', '11', '12', '13'],
    'restroomConvention': {
      'northWing': 'ladies',
      'southWing': 'gents',
      'disclaimer': 'Per building signage',
    },
    'floor6': {
      'north': ['cafeteria'],
      'south': ['gym'],
    },
    'floors7to13': {
      'podsPerWing': 6,
      'conferenceRoomsPerWing': 4,
      'coffeePerWing': true,
    },
    'verticalMovement': {
      'liftCount': 8,
      'liftLocation': 'central',
      'eventDayLiftMinutes': 5,
      'offPeakLiftMinutes': 3,
      'stairsMinutesPerFloor': 1,
      'preferStairsWhen': {'floorsUpMax': 2, 'floorsDownMax': 3},
    },
  });

  const tracks = [
    Track(id: 'trk-06', name: 'Strategy', tags: ['strategy']),
    Track(id: 'trk-05', name: 'Leadership', tags: ['leadership']),
    Track(id: 'trk-08', name: 'DevEx', tags: ['cursor']),
    Track(id: 'trk-04', name: 'Innovation', tags: ['architecture']),
  ];
  const profile = UserProfile(
    role: AttendeeRole.engineer,
    interests: ['genai', 'cursor'],
    onboardingComplete: true,
  );

  CompanionContext ctx({
    required String query,
    List<Session> planned = const [],
    String? lastReferencedSessionId,
    int Function(Session session)? minutesUntil,
  }) {
    return CompanionContext(
      query: query,
      sessions: sessions,
      speakers: speakers,
      venues: venues,
      tracks: tracks,
      amenities: amenities,
      campus: campus,
      profile: profile,
      plannedSessions: planned,
      lastReferencedSessionId: lastReferencedSessionId,
      minutesUntil: minutesUntil ?? (_) => 25,
    );
  }

  test('CEO keynote query', () {
    final r = service.answer(context: ctx(query: 'What is the CEO keynote?'));
    expect(r.text.toLowerCase(), contains('ceo keynote'));
    expect(r.sessionIds, contains('s-002'));
    expect(r.navigationAction, CompanionNavigationAction.directionsToSession);
  });

  test('Chairman fireside query', () {
    final r = service.answer(
      context: ctx(query: 'Where is the Chairman fireside?'),
    );
    expect(r.text, contains('Training Room 1'));
    expect(r.sessionIds, contains('s-006'));
  });

  test('Cursor/DevEx query', () {
    final r = service.answer(
      context: ctx(query: 'Sessions about Cursor or DevEx'),
    );
    expect(r.sessionIds, contains('s-004'));
  });

  test('CTO Day 1 query', () {
    final r = service.answer(context: ctx(query: 'CTO sessions on Day 1'));
    expect(r.sessionIds, contains('s-003'));
  });

  test('off-topic rejected', () {
    final r = service.answer(context: ctx(query: 'What is the weather today?'));
    expect(r.text, contains('Flo 2026'));
  });

  test('nearest ladies restroom floor 8 uses north wing', () {
    final r = service.answer(
      context: ctx(query: 'Nearest ladies restroom Floor 8'),
    );
    expect(r.text.toLowerCase(), contains('ladies'));
    expect(r.amenityIds, contains('am-8-restroom-n'));
  });

  test('parking query ranks floor availability', () {
    final r = service.answer(context: ctx(query: 'Where can I park my car?'));
    expect(r.text.toLowerCase(), contains('parking'));
    expect(r.text, contains('12/40'));
    expect(r.amenityIds, isNotEmpty);
  });

  test('20 minute break suggests garden when plan empty', () {
    final r = service.answer(
      context: ctx(query: 'I have 20 minutes', planned: const []),
    );
    expect(r.text.toLowerCase(), contains('garden'));
    expect(r.text, contains('Floor 5'));
  });

  test('nearest restroom on floor 8', () {
    final r = service.answer(
      context: ctx(query: 'Nearest restroom on Floor 8'),
    );
    expect(r.text.toLowerCase(), contains('restroom'));
    expect(r.amenityIds, contains('am-8-restroom-n'));
  });

  test('where is my next session uses plan', () {
    final r = service.answer(
      context: ctx(
        query: 'Where is my next session?',
        planned: [sessions[2]],
        minutesUntil: (s) => s.id == 's-004' ? 18 : 0,
      ),
    );
    expect(r.text, contains('Building Agentic Workflows'));
    expect(r.navigationAction, CompanionNavigationAction.directionsToSession);
  });

  test('fix my plan explains conflict tradeoff', () {
    final conflictA = sessions[2];
    final conflictB = Session(
      id: 's-099',
      title: 'Overlap Session',
      abstract: '',
      day: 'Day 1',
      startTime: '14:00',
      endTime: '15:00',
      venueId: 'ven-T601',
      trackId: 'trk-04',
      speakerIds: const [],
      tags: const ['architecture'],
      format: 'Talk',
      level: 'beginner',
      featured: false,
      capacity: 30,
      building: 'Nagarro Gurgaon Office',
    );
    final allSessions = [...sessions, conflictB];
    final r = service.answer(
      context: CompanionContext(
        query: 'fix my plan',
        sessions: allSessions,
        speakers: speakers,
        venues: venues,
        tracks: tracks,
        amenities: amenities,
        campus: campus,
        profile: profile,
        plannedSessions: [conflictA, conflictB],
        conflicts: [PlanConflict(sessionA: conflictA, sessionB: conflictB)],
        minutesUntil: (_) => 30,
      ),
    );
    expect(r.text.toLowerCase(), contains('clash'));
  });
}
