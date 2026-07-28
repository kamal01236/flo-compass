import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/data/services/event_clock_service.dart';
import 'package:flo_compass/data/services/micro_agenda_service.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final clock = EventClockService(clock: () => DateTime(2026, 11, 4, 9, 45));
  final service = MicroAgendaService(clockService: clock);

  final sessions = [
    const Session(
      id: 's-planned',
      title: 'Planned Soon',
      abstract: '',
      day: 'Day 1',
      startTime: '10:00',
      endTime: '11:00',
      venueId: 'ven-1',
      trackId: 'trk-01',
      speakerIds: [],
      tags: ['genai'],
      format: 'Talk',
      level: 'beginner',
      featured: false,
      capacity: 30,
      building: 'Nagarro Gurgaon Office',
    ),
    const Session(
      id: 's-later',
      title: 'Later Today',
      abstract: '',
      day: 'Day 1',
      startTime: '14:00',
      endTime: '15:00',
      venueId: 'ven-2',
      trackId: 'trk-01',
      speakerIds: [],
      tags: ['genai'],
      format: 'Talk',
      level: 'beginner',
      featured: true,
      capacity: 30,
      building: 'Nagarro Gurgaon Office',
    ),
    const Session(
      id: 's-far',
      title: 'Tomorrow',
      abstract: '',
      day: 'Day 2',
      startTime: '10:00',
      endTime: '11:00',
      venueId: 'ven-3',
      trackId: 'trk-01',
      speakerIds: [],
      tags: ['genai'],
      format: 'Talk',
      level: 'beginner',
      featured: false,
      capacity: 30,
      building: 'Nagarro Gurgaon Office',
    ),
  ];

  late EventState event;
  late PlanState plan;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    event = EventState(eventClockService: clock);
    event.loading = false;
    event.sessions = sessions;
    event.tracks = const [
      Track(id: 'trk-01', name: 'GenAI', tags: ['genai'], color: '#10B981'),
    ];

    plan = PlanState(prefs: prefs);
    await plan.init();
    await plan.toggle('s-planned');
  });

  test('returns planned sessions within 120 minute window first', () async {
    final profile = const UserProfile(
      role: AttendeeRole.engineer,
      interests: ['genai'],
      onboardingComplete: true,
    );

    final upcoming = service.nextTwoHours(
      event: event,
      plan: plan,
      profile: profile,
    );

    expect(upcoming.map((s) => s.id), contains('s-planned'));
    expect(upcoming.map((s) => s.id), isNot(contains('s-far')));
    expect(upcoming.first.id, 's-planned');
  });
}
