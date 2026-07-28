import 'package:flutter/material.dart';
import '../support/test_agenda_alerts_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/core/routing/app_routes.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/services/event_clock_service.dart';
import 'package:flo_compass/features/discover/discover_screen.dart';
import 'package:flo_compass/features/session_detail/session_detail_screen.dart';
import 'package:flo_compass/features/shell/main_shell.dart';
import 'package:flo_compass/l10n/app_localizations.dart';
import 'package:flo_compass/providers/app_settings_provider.dart';
import 'package:flo_compass/providers/engagement_provider.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/providers/profile_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const session = Session(
    id: 's-001',
    title: 'CEO Keynote',
    abstract: 'a',
    day: 'Day 1',
    startTime: '10:00',
    endTime: '11:00',
    venueId: 'ven-G01',
    trackId: 'trk-01',
    speakerIds: ['spk-001'],
    tags: ['genai'],
    format: 'Keynote',
    level: 'beginner',
    featured: true,
    capacity: 100,
    building: 'Nagarro Gurgaon Office',
  );

  late EventState event;
  late PlanState plan;
  late ProfileState profileState;
  late EngagementState engagement;
  late AppSettingsState appSettings;
  late SharedPreferences prefs;
  late GoRouter router;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    final clock = EventClockService();
    clock.setOverride(DateTime(2026, 11, 4, 10, 30));
    event = EventState(eventClockService: clock);
    event.loading = false;
    event.sessions = [session];
    event.venues = [
      const Venue(
        id: 'ven-G01',
        name: 'Ground Auditorium',
        floor: 'G',
        zone: 'auditorium',
        wing: 'central',
        capacity: 100,
        building: 'Nagarro Gurgaon Office',
      ),
    ];
    event.tracks = [
      const Track(id: 'trk-01', name: 'Generative AI', tags: ['genai']),
    ];
    event.speakers = [
      const Speaker(
        id: 'spk-001',
        name: 'Alex Rivera',
        title: 'CTO',
        tier: 1,
        bio: 'bio',
      ),
    ];
    plan = PlanState(prefs: prefs);
    await plan.init();
    profileState = ProfileState(prefs: prefs);
    await profileState.init();
    engagement = EngagementState(prefs: prefs);
    await engagement.init();
    appSettings = AppSettingsState(prefs: prefs);
    await appSettings.init();
    appSettings.settings = const AppSettings(
      themeMode: AppThemeMode.dark,
      eventDayMode: EventDayMode.off,
    );

    router = GoRouter(
      initialLocation: AppRoutes.discover,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.discover,
                  builder: (context, state) => const DiscoverScreen(),
                ),
                GoRoute(
                  path: '/session/:id',
                  builder: (context, state) {
                    return SessionDetailScreen(
                      sessionId: state.pathParameters['id']!,
                    );
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.companion,
                  builder: (context, state) =>
                      const Scaffold(body: Text('Companion')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.floMeetsRoot,
                  builder: (context, state) =>
                      const Scaffold(body: Text('Meets')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.myPlan,
                  builder: (context, state) =>
                      const Scaffold(body: Text('My Plan')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.profile,
                  builder: (context, state) =>
                      const Scaffold(body: Text('Profile')),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  });

  tearDown(() {
    event.dispose();
  });

  Widget buildApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: event),
        ChangeNotifierProvider.value(value: plan),
        ChangeNotifierProvider.value(value: profileState),
        ChangeNotifierProvider.value(value: engagement),
        ChangeNotifierProvider.value(value: appSettings),
        testAgendaAlertsProvider(),
      ],
      child: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
  }

  testWidgets('Discover tab re-tap pops nested session route to feed', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    router.go('/session/s-001');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(router.state.uri.path, '/session/s-001');
    expect(find.text('CEO Keynote'), findsWidgets);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Discover'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(router.state.uri.path, AppRoutes.discover);
    expect(find.text('Discover'), findsWidgets);
  });

  testWidgets('Discover tab from another branch resets to feed', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    router.go('/session/s-001');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(router.state.uri.path, '/session/s-001');

    await tester.tap(find.text('Ask Flo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(router.state.uri.path, AppRoutes.companion);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Discover'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(router.state.uri.path, AppRoutes.discover);
  });

  testWidgets('Ask Flo from nested session resets to companion root', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    router.go('/session/s-001');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(router.state.uri.path, '/session/s-001');

    await tester.tap(find.text('Ask Flo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(router.state.uri.path, AppRoutes.companion);
    expect(router.state.uri.query, isEmpty);
  });

  testWidgets('Ask Flo re-tap clears query params', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    router.go('/companion?q=Fix%20my%20plan');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(router.state.uri.path, AppRoutes.companion);
    expect(router.state.uri.query, isNotEmpty);

    await tester.tap(find.text('Ask Flo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(router.state.uri.path, AppRoutes.companion);
    expect(router.state.uri.query, isEmpty);
  });

  testWidgets('My Plan from nested session resets to plan root', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    router.go('/session/s-001');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(router.state.uri.path, '/session/s-001');

    await tester.tap(find.text('My Plan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(router.state.uri.path, AppRoutes.myPlan);
  });

  testWidgets('My Plan re-tap stays on plan root', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    router.go(AppRoutes.myPlan);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(router.state.uri.path, AppRoutes.myPlan);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('My Plan'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(router.state.uri.path, AppRoutes.myPlan);
  });
}
