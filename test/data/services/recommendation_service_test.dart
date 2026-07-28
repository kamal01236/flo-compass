import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/data/services/behavior_signal_service.dart';
import 'package:flo_compass/data/services/event_clock_service.dart';
import 'package:flo_compass/data/services/recommendation_service.dart';
import 'package:flo_compass/domain/inputs/recommendation_context.dart';
import 'package:flo_compass/providers/context_adapters.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/providers/profile_provider.dart';

RecommendationContext _recCtx(
  ProfileState profile,
  PlanState plan,
  EventState event,
) => buildRecommendationContext(profile: profile, plan: plan, event: event);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  final service = RecommendationService();

  final cursorSession = Session(
    id: 's-004',
    title: 'Building Agentic Workflows with Cursor',
    abstract: 'test',
    day: 'Day 1',
    startTime: '14:00',
    endTime: '15:00',
    venueId: 'ven-T602',
    trackId: 'trk-08',
    speakerIds: ['spk-019'],
    tags: ['cursor', 'devex', 'genai'],
    format: 'Workshop',
    level: 'intermediate',
    featured: true,
    capacity: 100,
    building: 'Nagarro Gurgaon Office',
  );

  final chairmanSession = Session(
    id: 's-006',
    title: 'Fireside with the Chairman',
    abstract: 'test',
    day: 'Day 2',
    startTime: '16:00',
    endTime: '17:00',
    venueId: 'ven-T601',
    trackId: 'trk-05',
    speakerIds: ['spk-001'],
    tags: ['leadership', 'strategy', 'culture'],
    format: 'Fireside Chat',
    level: 'beginner',
    featured: true,
    capacity: 30,
    building: 'Nagarro Gurgaon Office',
  );

  final filler = Session(
    id: 's-999',
    title: 'Generic Talk',
    abstract: 'test',
    day: 'Day 3',
    startTime: '09:00',
    endTime: '10:00',
    venueId: 'ven-7N1',
    trackId: 'trk-02',
    speakerIds: ['spk-050'],
    tags: ['data_mesh'],
    format: 'Deep Dive',
    level: 'intermediate',
    featured: false,
    capacity: 40,
    building: 'Nagarro Gurgaon Office',
  );

  final speakers = [
    const Speaker(
      id: 'spk-019',
      name: 'Rachel Kim',
      title: 'Senior Director, DevEx',
      tier: 3,
      bio: '',
    ),
    const Speaker(
      id: 'spk-001',
      name: 'Vikram Ashar',
      title: 'Chairman',
      tier: 1,
      bio: '',
    ),
  ];

  final tracks = [
    const Track(
      id: 'trk-08',
      name: 'Developer Experience',
      tags: ['devex', 'cursor'],
    ),
    const Track(
      id: 'trk-05',
      name: 'Leadership & Culture',
      tags: ['leadership', 'culture'],
    ),
  ];

  test(
    'engineer with GenAI+Cursor interests ranks Cursor session in top 5',
    () {
      final profile = UserProfile(
        role: AttendeeRole.engineer,
        interests: ['genai', 'cursor'],
        onboardingComplete: true,
      );
      final ranked = service.rankSessions(
        sessions: [filler, cursorSession, chairmanSession],
        speakers: speakers,
        tracks: tracks,
        profile: profile,
      );
      final top5 = ranked.take(5).map((s) => s.session.id).toList();
      expect(top5, contains('s-004'));
      expect(ranked.first.session.id, 's-004');
    },
  );

  test(
    'executive with leadership interests ranks Chairman fireside in top 5',
    () {
      final profile = UserProfile(
        role: AttendeeRole.executive,
        interests: ['leadership', 'strategy'],
        onboardingComplete: true,
      );
      final ranked = service.rankSessions(
        sessions: [filler, cursorSession, chairmanSession],
        speakers: speakers,
        tracks: tracks,
        profile: profile,
      );
      final top5 = ranked.take(5).map((s) => s.session.id).toList();
      expect(top5, contains('s-006'));
    },
  );

  test('empty interests still returns featured sessions first', () {
    final profile = UserProfile(
      role: AttendeeRole.guest,
      interests: [],
      onboardingComplete: true,
    );
    final ranked = service.rankSessions(
      sessions: [filler, cursorSession, chairmanSession],
      speakers: speakers,
      tracks: tracks,
      profile: profile,
    );
    expect(ranked.first.session.featured, isTrue);
  });

  test('tie-break prefers featured then earlier day then lower id', () {
    final profile = UserProfile(
      role: AttendeeRole.guest,
      interests: [],
      onboardingComplete: true,
    );
    Session tieSession(String id, String day) => Session(
      id: id,
      title: 'Tie $id',
      abstract: 'test',
      day: day,
      startTime: '09:00',
      endTime: '10:00',
      venueId: 'ven-7N1',
      trackId: 'trk-02',
      speakerIds: const [],
      tags: const [],
      format: 'Deep Dive',
      level: 'intermediate',
      featured: true,
      capacity: 40,
      building: 'Nagarro Gurgaon Office',
    );
    final day1 = tieSession('s-009', 'Day 1');
    final day2 = tieSession('s-010', 'Day 2');
    final ranked = service.rankSessions(
      sessions: [day2, day1],
      speakers: speakers,
      tracks: tracks,
      profile: profile,
    );
    expect(ranked.first.session.id, 's-009');
    expect(ranked.last.session.id, 's-010');
  });

  test('match reasons include interest overlap', () {
    final profile = UserProfile(
      role: AttendeeRole.engineer,
      interests: ['cursor', 'devex', 'genai'],
      onboardingComplete: true,
    );
    final ranked = service.rankSessions(
      sessions: [cursorSession],
      speakers: speakers,
      tracks: tracks,
      profile: profile,
    );
    expect(ranked.first.matchReasons.join(' '), contains('interests'));
  });

  test('behavior snapshot adds explored-similar reason at 2+ track views', () {
    final profile = UserProfile(
      role: AttendeeRole.guest,
      interests: [],
      onboardingComplete: true,
    );
    const behavior = BehaviorSnapshot(
      trackViews: {'trk-08': 2},
      tagViews: {},
      bookmarksByTrack: {},
      positiveTagSignals: {},
    );
    final ranked = service.rankSessions(
      sessions: [cursorSession],
      speakers: speakers,
      tracks: tracks,
      profile: profile,
      behaviorSnapshot: behavior,
    );
    expect(
      ranked.first.matchReasons,
      contains('Because you explored similar sessions'),
    );
  });

  group('pickSurprise', () {
    test('excludes bookmarked and attended sessions', () async {
      final event = _FakeEventState(
        sessions: [cursorSession, chairmanSession, filler],
        speakers: speakers,
        tracks: tracks,
      );
      final profile = ProfileState()
        ..profile = UserProfile(
          role: AttendeeRole.engineer,
          interests: ['genai', 'cursor'],
          onboardingComplete: true,
        );
      final plan = PlanState();
      SharedPreferences.setMockInitialValues({
        'flo_compass_plan': ['s-004'],
      });
      await plan.init();

      final pick = service.pickSurprise(
        _recCtx(profile, plan, event),
        attendedSessionIds: {chairmanSession.id},
      );

      expect(pick, isNotNull);
      expect(pick!.id, filler.id);
    });

    test('prefers unseen tracks over viewed tracks', () {
      final viewed = Session(
        id: 's-viewed',
        title: 'Viewed track',
        abstract: 'test',
        day: 'Day 1',
        startTime: '14:00',
        endTime: '15:00',
        venueId: 'ven-T602',
        trackId: 'trk-08',
        speakerIds: const ['spk-019'],
        tags: const ['genai'],
        format: 'Workshop',
        level: 'intermediate',
        featured: false,
        capacity: 100,
        building: 'Nagarro Gurgaon Office',
      );
      final unseen = Session(
        id: 's-unseen',
        title: 'Unseen track',
        abstract: 'test',
        day: 'Day 1',
        startTime: '14:00',
        endTime: '15:00',
        venueId: 'ven-7N1',
        trackId: 'trk-02',
        speakerIds: const ['spk-050'],
        tags: const ['genai'],
        format: 'Deep Dive',
        level: 'intermediate',
        featured: false,
        capacity: 40,
        building: 'Nagarro Gurgaon Office',
      );
      final event = _FakeEventState(
        sessions: [viewed, unseen],
        speakers: speakers,
        tracks: tracks,
        behavior: const BehaviorSnapshot(
          trackViews: {'trk-08': 3},
          tagViews: {},
          bookmarksByTrack: {},
          positiveTagSignals: {},
        ),
      );
      final profile = ProfileState()
        ..profile = const UserProfile(
          role: AttendeeRole.engineer,
          interests: ['genai'],
          onboardingComplete: true,
        );

      final pick = service.pickSurprise(_recCtx(profile, PlanState(), event));
      expect(pick?.id, 's-unseen');
    });
  });

  group('pickFloPickHero', () {
    test('prefers happening now with interest overlap', () {
      final live = Session(
        id: 's-live',
        title: 'Live GenAI',
        abstract: 'test',
        day: 'Day 1',
        startTime: '10:00',
        endTime: '11:00',
        venueId: 'ven-T602',
        trackId: 'trk-08',
        speakerIds: const ['spk-019'],
        tags: const ['genai', 'cursor'],
        format: 'Workshop',
        level: 'intermediate',
        featured: true,
        capacity: 100,
        building: 'Nagarro Gurgaon Office',
      );
      final event = _FakeEventState(
        sessions: [live, cursorSession],
        speakers: speakers,
        tracks: tracks,
        happeningNowIds: {'s-live'},
        currentDay: 'Day 1',
      );
      final profile = ProfileState()
        ..profile = const UserProfile(
          role: AttendeeRole.engineer,
          interests: ['genai'],
          onboardingComplete: true,
        );

      final pick = service.pickFloPickHero(
        _recCtx(profile, PlanState(), event),
      );
      expect(pick?.id, 's-live');
    });
  });
}

class _FakeEventState extends EventState {
  _FakeEventState({
    required List<Session> sessions,
    required List<Speaker> speakers,
    required List<Track> tracks,
    BehaviorSnapshot? behavior,
    Set<String> happeningNowIds = const {},
    String? currentDay,
  }) : _sessions = sessions,
       _speakers = speakers,
       _tracks = tracks,
       _behavior = behavior,
       _happeningNowIds = happeningNowIds,
       _currentDay = currentDay,
       super(
         eventClockService: EventClockService(
           clock: () => DateTime(2026, 11, 4, 10, 30),
         ),
       ) {
    loading = false;
    this.sessions = _sessions;
    this.speakers = _speakers;
    this.tracks = _tracks;
  }

  final List<Session> _sessions;
  final List<Speaker> _speakers;
  final List<Track> _tracks;
  final BehaviorSnapshot? _behavior;
  final Set<String> _happeningNowIds;
  final String? _currentDay;

  @override
  BehaviorSnapshot? get behaviorSnapshot => _behavior;

  @override
  String? get currentDay => _currentDay ?? super.currentDay;

  @override
  List<Session> happeningNow() => _sessions
      .where((session) => _happeningNowIds.contains(session.id))
      .toList();
}
