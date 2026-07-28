import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/data/services/event_clock_service.dart';
import 'package:flo_compass/features/session_detail/session_detail_screen.dart';
import 'package:flo_compass/features/session_detail/widgets/session_detail_logistics_tab.dart';
import 'package:flo_compass/providers/app_settings_provider.dart';
import 'package:flo_compass/providers/consent_provider.dart';
import 'package:flo_compass/providers/engagement_provider.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/providers/profile_provider.dart';
import 'package:flo_compass/providers/session_qa_provider.dart';
import '../../support/consent_test_helpers.dart';
import '../../support/test_agenda_alerts_provider.dart';
import '../../support/test_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProfileState profile;
  late EventState event;
  late PlanState plan;
  late AppSettingsState appSettings;
  late EngagementState engagement;
  late ConsentState consent;
  late SessionQaState sessionQa;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    consent = await acceptedConsentState();

    profile = ProfileState(prefs: prefs);
    profile.profile = const UserProfile(
      role: AttendeeRole.engineer,
      interests: ['genai'],
      onboardingComplete: true,
    );

    event = EventState(
      eventClockService: EventClockService(
        clock: () => DateTime(2026, 11, 4, 10, 30),
      ),
    );
    event.loading = false;
    event.sessions = [
      const Session(
        id: 's-001',
        title: 'CEO Keynote',
        abstract: 'a',
        day: 'Day 1',
        startTime: '10:00',
        endTime: '11:00',
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
      ),
    ];
    event.venues = [
      const Venue(
        id: 'ven-7N1',
        name: 'Floor 7 North Pod 1',
        floor: '7',
        zone: 'Sitting Area',
        wing: 'N',
        capacity: 25,
        building: 'Nagarro Gurgaon Office',
      ),
    ];
    event.tracks = [
      const Track(
        id: 'trk-01',
        name: 'GenAI',
        tags: ['genai'],
        color: '#10B981',
      ),
    ];
    event.speakers = [
      const Speaker(
        id: 'spk-001',
        name: 'Alex Chen',
        title: 'CTO',
        bio: 'Bio',
        photoAsset: 'assets/images/speakers/spk-001.png',
        tier: 1,
      ),
    ];

    plan = PlanState(prefs: prefs);
    await plan.init();
    appSettings = AppSettingsState(prefs: prefs);
    await appSettings.init();
    engagement = EngagementState(prefs: prefs);
    await engagement.init();
    sessionQa = SessionQaState();
  });

  tearDown(() {
    event.dispose();
  });

  Future<void> pumpSession(
    WidgetTester tester, {
    required String location,
  }) async {
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/session/:id',
          builder: (context, state) =>
              SessionDetailScreen(sessionId: state.pathParameters['id']!),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: profile),
          ChangeNotifierProvider.value(value: event),
          ChangeNotifierProvider.value(value: plan),
          ChangeNotifierProvider.value(value: appSettings),
          testAgendaAlertsProvider(),
          ChangeNotifierProvider.value(value: engagement),
          ChangeNotifierProvider.value(value: consent),
          ChangeNotifierProvider.value(value: sessionQa),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: testLocalizationDelegates,
          supportedLocales: testSupportedLocales,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('focus=qa selects Q&A tab', (tester) async {
    await pumpSession(tester, location: '/session/s-001?focus=qa');

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Logistics'), findsOneWidget);
    expect(find.text('Q&A'), findsWidgets);
    expect(find.byType(SessionDetailScreen), findsOneWidget);
  });

  testWidgets('focus=logistics selects Logistics tab', (tester) async {
    await pumpSession(tester, location: '/session/s-001?focus=logistics');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SessionDetailLogisticsTab), findsOneWidget);
    expect(find.byType(SessionDetailScreen), findsOneWidget);
  });

  testWidgets('default session detail stays on overview tab', (tester) async {
    await pumpSession(tester, location: '/session/s-001');

    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pump();
    expect(find.text('Full abstract'), findsOneWidget);
  });
}
