import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/features/directions/directions_screen.dart';
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
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
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

  testWidgets('/directions?session= opens DirectionsScreen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = createAppRouter(profile, consentState: consent);
    addTearDown(router.dispose);

    await tester.pumpWidget(buildApp(router));
    router.go('/directions?session=s-001');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.byType(DirectionsScreen), findsOneWidget);
    expect(find.text('Floor 7 North Pod 1'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('/directions without session redirects to discover', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = createAppRouter(profile, consentState: consent);
    addTearDown(router.dispose);

    await tester.pumpWidget(buildApp(router));
    router.go('/directions');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(router.state.matchedLocation, '/discover');
    expect(find.byType(DirectionsScreen), findsNothing);
  });
}
