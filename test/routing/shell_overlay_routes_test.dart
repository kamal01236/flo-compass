import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/features/leaderboard/leaderboard_screen.dart';
import 'package:flo_compass/features/session_detail/session_detail_screen.dart';
import 'package:flo_compass/providers/app_settings_provider.dart';
import 'package:flo_compass/providers/engagement_provider.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/providers/profile_provider.dart';
import 'package:flo_compass/providers/consent_provider.dart';
import 'package:flo_compass/routing/app_router.dart';
import '../support/consent_test_helpers.dart';
import '../support/test_agenda_alerts_provider.dart';
import '../support/test_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProfileState profile;
  late EventState event;
  late PlanState plan;
  late AppSettingsState appSettings;
  late EngagementState engagement;
  late ConsentState consent;

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

    event = EventState();
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
    appSettings.settings = const AppSettings(
      themeMode: AppThemeMode.dark,
      eventDayMode: EventDayMode.off,
    );
    engagement = EngagementState(prefs: prefs);
    await engagement.init();
  });

  tearDown(() {
    event.dispose();
  });

  Widget buildApp(GoRouter router) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: profile),
        ChangeNotifierProvider.value(value: event),
        ChangeNotifierProvider.value(value: plan),
        ChangeNotifierProvider.value(value: appSettings),
        testAgendaAlertsProvider(),
        ChangeNotifierProvider.value(value: engagement),
        ChangeNotifierProvider.value(value: consent),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: testLocalizationDelegates,
        supportedLocales: testSupportedLocales,
      ),
    );
  }

  testWidgets('core overlay routes keep bottom NavigationBar', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = createAppRouter(profile, consentState: consent);
    addTearDown(router.dispose);

    await tester.pumpWidget(buildApp(router));

    for (final location in [
      '/session/s-001',
      '/speaker/spk-001',
      '/map?room=ven-7N1',
    ]) {
      router.go(location);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationBar), findsOneWidget);
    }
  });

  testWidgets('/leaderboard stays full-screen without NavigationBar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = createAppRouter(profile, consentState: consent);
    addTearDown(router.dispose);

    router.go('/leaderboard');
    await tester.pumpWidget(buildApp(router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.byType(LeaderboardScreen), findsOneWidget);
    expect(router.state.matchedLocation, '/leaderboard');
    expect(find.text('Mock leaderboard'), findsWidgets);
    expect(find.byType(NavigationBar, skipOffstage: true), findsNothing);
  });

  testWidgets('core overlay deep links bypass onboarding redirect', (
    tester,
  ) async {
    profile.profile = const UserProfile(
      role: AttendeeRole.engineer,
      interests: ['genai'],
      onboardingComplete: false,
    );

    final router = createAppRouter(profile, consentState: consent);
    addTearDown(router.dispose);

    await tester.pumpWidget(buildApp(router));
    router.go('/session/s-001');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(router.state.matchedLocation, '/session/s-001');
    expect(find.byType(SessionDetailScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
