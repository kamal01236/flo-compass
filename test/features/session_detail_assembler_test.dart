import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/data/services/event_clock_service.dart';
import 'package:flo_compass/data/services/recommendation_service.dart';
import 'package:flo_compass/data/services/session_detail_assembler.dart';
import 'package:flo_compass/data/services/session_stream_resolver.dart';
import 'package:flo_compass/providers/engagement_provider.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/shared/utils/session_capacity.dart';
import 'package:flo_compass/shared/utils/session_time_display.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const session = Session(
    id: 's-001',
    title: 'CEO Keynote',
    abstract: 'Vision for GenAI.',
    day: 'Day 1',
    startTime: '09:00',
    endTime: '10:00',
    venueId: 'ven-7N1',
    trackId: 'trk-01',
    speakerIds: ['spk-001'],
    tags: ['genai'],
    format: 'Keynote',
    level: 'beginner',
    featured: true,
    capacity: 100,
    building: 'Nagarro Gurgaon Office',
    occupancyPercent: 85,
  );

  const overlap = Session(
    id: 's-002',
    title: 'Overlap',
    abstract: 'a',
    day: 'Day 1',
    startTime: '09:30',
    endTime: '10:30',
    venueId: 'ven-7N2',
    trackId: 'trk-01',
    speakerIds: [],
    tags: ['genai'],
    format: 'Panel',
    level: 'beginner',
    featured: false,
    capacity: 50,
    building: 'Nagarro Gurgaon Office',
  );

  test('capacityPresentation thresholds', () {
    expect(capacityPresentation(40).$2, 'Seats available');
    expect(capacityPresentation(75).$2, 'Filling fast');
    expect(capacityPresentation(95).$2, 'Nearly full');
  });

  test('formatSessionTimeDisplay includes IST', () {
    final line = formatSessionTimeDisplay(
      session: session,
      meta: const EventMeta(
        eventName: 'Flo',
        venue: 'Gurgaon',
        timezone: 'Asia/Kolkata',
        slots: [],
        days: [],
      ),
      referenceNow: DateTime(2026, 11, 4, 8, 0),
    );
    expect(line, contains('09:00'));
    expect(line, contains('IST'));
  });

  test('formatSessionTimeDisplay parses IST label from meta string', () {
    final line = formatSessionTimeDisplay(
      session: session,
      meta: const EventMeta(
        eventName: 'Flo',
        venue: 'Gurgaon',
        timezone: 'IST (UTC+05:30) — venue local time',
        slots: [],
        days: [],
      ),
      referenceNow: DateTime(2026, 11, 4, 8, 0),
    );
    expect(line, contains('IST'));
    expect(line, isNot(contains('UTC+05:30')));
  });

  test('findMissedAlternatives prefers same track', () {
    final service = RecommendationService();
    final alt = Session(
      id: 's-alt',
      title: 'Alt',
      abstract: 'a',
      day: 'Day 1',
      startTime: '11:00',
      endTime: '12:00',
      venueId: 'v',
      trackId: 'trk-01',
      speakerIds: [],
      tags: ['cloud'],
      format: 'Talk',
      level: 'beginner',
      featured: false,
      capacity: 20,
      building: 'Nagarro Gurgaon Office',
    );
    final other = Session(
      id: 's-other',
      title: 'Other',
      abstract: 'a',
      day: 'Day 2',
      startTime: '11:00',
      endTime: '12:00',
      venueId: 'v',
      trackId: 'trk-99',
      speakerIds: [],
      tags: ['telecom'],
      format: 'Talk',
      level: 'beginner',
      featured: false,
      capacity: 20,
      building: 'Nagarro Gurgaon Office',
    );
    final result = service.findMissedAlternatives(
      session: session,
      allSessions: [session, alt, other],
    );
    expect(result.first.id, 's-alt');
  });

  test('SessionDetailAssembler detects plan conflict', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final event = EventState(
      eventClockService: EventClockService(
        clock: () => DateTime(2026, 11, 4, 8, 0),
      ),
    );
    event.loading = false;
    event.sessions = [session, overlap];
    event.tracks = const [
      Track(id: 'trk-01', name: 'GenAI', tags: ['genai'], color: '#10B981'),
    ];
    final plan = PlanState(prefs: prefs);
    await plan.init();
    await plan.toggle(overlap.id);
    final engagement = EngagementState(prefs: prefs);
    await engagement.init();

    final assembler = SessionDetailAssembler(clockService: event.clockService);
    final vm = assembler.assemble(
      session: session,
      event: event,
      profile: const UserProfile(
        role: AttendeeRole.engineer,
        interests: ['genai'],
        onboardingComplete: true,
      ),
      plan: plan,
      engagement: engagement,
    );
    expect(vm.planConflicts, isNotEmpty);
    expect(vm.liveState, SessionLiveState.upcoming);
    event.dispose();
  });

  test('SessionStreamResolver returns streamable for keynote', () {
    const resolver = SessionStreamResolver();
    final action = resolver.resolve(session);
    expect(action.isStreamable, isTrue);
    expect(action.url, isNotNull);
  });

  test('streamNudgeFor when nearly full and streamable', () {
    final nudge = streamNudgeFor(occupancyPercent: 95, isStreamable: true);
    expect(nudge?.label, contains('Nearly full'));
    expect(streamNudgeFor(occupancyPercent: 50, isStreamable: true), isNull);
  });

  test('SessionDetailAssembler live states with clock override', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    Future<SessionLiveState> liveAt(DateTime now) {
      final event = EventState(
        eventClockService: EventClockService(clock: () => now),
      );
      event.loading = false;
      event.sessions = [session];
      event.tracks = const [
        Track(id: 'trk-01', name: 'GenAI', tags: ['genai'], color: '#10B981'),
      ];
      final plan = PlanState(prefs: prefs);
      final engagement = EngagementState(prefs: prefs);
      final assembler = SessionDetailAssembler(
        clockService: event.clockService,
      );
      final vm = assembler.assemble(
        session: session,
        event: event,
        profile: const UserProfile(
          role: AttendeeRole.engineer,
          interests: ['genai'],
          onboardingComplete: true,
        ),
        plan: plan,
        engagement: engagement,
      );
      event.dispose();
      return Future.value(vm.liveState);
    }

    expect(
      await liveAt(DateTime(2026, 11, 4, 8, 0)),
      SessionLiveState.upcoming,
    );
    expect(
      await liveAt(DateTime(2026, 11, 4, 8, 50)),
      SessionLiveState.startingSoon,
    );
    expect(await liveAt(DateTime(2026, 11, 4, 9, 15)), SessionLiveState.live);
    expect(await liveAt(DateTime(2026, 11, 4, 11, 0)), SessionLiveState.ended);
  });

  test(
    'SessionDetailAssembler coWatchCount and stream nudge when live',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final nearlyFull = Session(
        id: session.id,
        title: session.title,
        abstract: session.abstract,
        day: session.day,
        startTime: session.startTime,
        endTime: session.endTime,
        venueId: session.venueId,
        trackId: session.trackId,
        speakerIds: session.speakerIds,
        tags: session.tags,
        format: session.format,
        level: session.level,
        featured: session.featured,
        capacity: session.capacity,
        building: session.building,
        occupancyPercent: 95,
      );

      final event = EventState(
        eventClockService: EventClockService(
          clock: () => DateTime(2026, 11, 4, 9, 15),
        ),
      );
      event.loading = false;
      event.sessions = [nearlyFull];
      event.tracks = const [
        Track(id: 'trk-01', name: 'GenAI', tags: ['genai'], color: '#10B981'),
      ];
      final plan = PlanState(prefs: prefs);
      final engagement = EngagementState(prefs: prefs);
      final assembler = SessionDetailAssembler(
        clockService: event.clockService,
      );
      final vm = assembler.assemble(
        session: nearlyFull,
        event: event,
        profile: const UserProfile(
          role: AttendeeRole.engineer,
          interests: ['genai'],
          onboardingComplete: true,
        ),
        plan: plan,
        engagement: engagement,
      );
      expect(vm.liveState, SessionLiveState.live);
      expect(vm.coWatchCount, inInclusiveRange(8, 47));
      expect(vm.showStreamPriority, isTrue);
      expect(vm.streamNudge?.label, contains('Nearly full'));
      event.dispose();
    },
  );

  test('formatSessionTimeDisplay parses IST from flo2026 meta string', () {
    final line = formatSessionTimeDisplay(
      session: session,
      meta: const EventMeta(
        eventName: 'Flo',
        venue: 'Gurgaon',
        timezone: 'IST (UTC+05:30) — venue local time',
        slots: [],
        days: [],
      ),
      referenceNow: DateTime(2026, 11, 4, 8, 0),
    );
    expect(line, contains('IST'));
    expect(line, isNot(contains('UTC+05:30')));
  });
}
