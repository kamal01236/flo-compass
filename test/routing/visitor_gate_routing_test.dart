import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/core/routing/app_routes.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/models/networking_card.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/data/services/networking_card_share_service.dart';
import 'package:flo_compass/features/connect/connect_card_screen.dart';
import 'package:flo_compass/features/consent/privacy_consent_screen.dart';
import 'package:flo_compass/features/onboarding/onboarding_screen.dart';
import 'package:flo_compass/providers/app_settings_provider.dart';
import 'package:flo_compass/providers/consent_provider.dart';
import 'package:flo_compass/providers/engagement_provider.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/flo_meets_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/providers/profile_provider.dart';
import '../support/test_agenda_alerts_provider.dart';
import 'package:flo_compass/routing/app_router.dart';
import '../support/test_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProfileState profile;
  late EventState event;
  late PlanState plan;
  late AppSettingsState appSettings;
  late EngagementState engagement;
  late ConsentState consent;
  late String connectToken;
  late FloMeetsState floMeets;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    consent = ConsentState();
    await consent.init();

    profile = ProfileState(prefs: prefs);
    profile.profile = const UserProfile(
      role: AttendeeRole.engineer,
      interests: [],
      onboardingComplete: false,
    );

    event = EventState();
    event.loading = false;

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
    floMeets = FloMeetsState(prefs: prefs);
    await floMeets.init();

    const card = NetworkingCard(
      enabled: true,
      displayName: 'Jordan Lee',
      jobTitle: 'Engineering Manager',
      company: 'Flo Demo Co',
      email: ShareField(value: 'jordan@example.com', visible: true),
    );
    connectToken = NetworkingCardShareService().encode(card);
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
        ChangeNotifierProvider.value(value: floMeets),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: testLocalizationDelegates,
        supportedLocales: testSupportedLocales,
      ),
    );
  }

  testWidgets('connect public bypasses consent redirect', (tester) async {
    final router = createAppRouter(profile, consentState: consent);
    addTearDown(router.dispose);

    router.go(AppRoutes.connectPublic(connectToken));
    await tester.pumpWidget(buildApp(router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(router.state.matchedLocation, AppRoutes.connectPublic(connectToken));
    expect(find.byType(ConnectCardScreen), findsOneWidget);
    expect(find.byType(PrivacyConsentScreen), findsNothing);
  });

  testWidgets('discover requires consent with returnTo preserved', (
    tester,
  ) async {
    final router = createAppRouter(profile, consentState: consent);
    addTearDown(router.dispose);

    await tester.pumpWidget(buildApp(router));
    router.go(AppRoutes.discover);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(router.state.matchedLocation, AppRoutes.consent);
    expect(
      router.state.uri.queryParameters[AppRoutes.returnToQuery],
      AppRoutes.discover,
    );
    expect(find.byType(PrivacyConsentScreen), findsOneWidget);
  });

  testWidgets('consent accept returns to returnTo destination', (tester) async {
    final router = createAppRouter(profile, consentState: consent);
    addTearDown(router.dispose);

    final connectPath = AppRoutes.connectPublic(connectToken);
    await tester.pumpWidget(buildApp(router));
    router.go(
      '${AppRoutes.consent}?${AppRoutes.returnToQuery}=${Uri.encodeComponent(connectPath)}',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.ensureVisible(find.text('Accept and continue'));
    await tester.tap(find.text('Accept and continue'));
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, connectPath);
    expect(find.byType(ConnectCardScreen), findsOneWidget);
  });

  testWidgets('get Flo Compass flow goes consent then onboarding', (
    tester,
  ) async {
    final router = createAppRouter(profile, consentState: consent);
    addTearDown(router.dispose);

    router.go(AppRoutes.connectPublic(connectToken));
    await tester.pumpWidget(buildApp(router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    router.go(AppRoutes.discover);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(router.state.matchedLocation, AppRoutes.consent);
    expect(find.byType(PrivacyConsentScreen), findsOneWidget);

    await tester.ensureVisible(find.text('Accept and continue'));
    await tester.tap(find.text('Accept and continue'));
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, AppRoutes.onboarding);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Welcome to Flo Compass'), findsOneWidget);
  });

  testWidgets('session deep link bypasses consent when not accepted', (
    tester,
  ) async {
    final router = createAppRouter(profile, consentState: consent);
    addTearDown(router.dispose);

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

    router.go('/session/s-001');
    await tester.pumpWidget(buildApp(router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(router.state.matchedLocation, '/session/s-001');
    expect(find.byType(PrivacyConsentScreen), findsNothing);
  });
}
