import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/features/discover/discover_screen.dart';
import 'package:flo_compass/providers/app_settings_provider.dart';
import 'package:flo_compass/providers/engagement_provider.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/providers/profile_provider.dart';
import '../support/test_agenda_alerts_provider.dart';
import '../support/test_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('swipe bookmark adds session and undo removes it', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final event = EventState();
    final profile = ProfileState();
    final plan = PlanState(prefs: prefs);
    final engagement = EngagementState(prefs: prefs);
    final appSettings = AppSettingsState(prefs: prefs);

    await plan.init();
    await engagement.init();
    await appSettings.init();

    event.loading = false;
    event.sessions = [
      const Session(
        id: 's-swipe',
        title: 'Swipe Test Session',
        abstract: 'a',
        day: 'Day 1',
        startTime: '14:00',
        endTime: '15:00',
        venueId: 'ven-G01',
        trackId: 'trk-01',
        speakerIds: ['spk-001'],
        tags: ['genai'],
        format: 'Talk',
        level: 'beginner',
        featured: false,
        capacity: 40,
        building: 'Nagarro Gurgaon Office',
      ),
    ];
    event.speakers = [
      const Speaker(
        id: 'spk-001',
        name: 'Alex Rivera',
        title: 'CTO',
        tier: 1,
        bio: 'bio',
        photoAsset: 'assets/images/speakers/spk-001.png',
      ),
    ];

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const DiscoverScreen()),
        GoRoute(
          path: '/session/:id',
          builder: (context, state) =>
              Scaffold(body: Text('Session ${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: event),
          ChangeNotifierProvider.value(value: profile),
          ChangeNotifierProvider.value(value: plan),
          ChangeNotifierProvider.value(value: engagement),
          ChangeNotifierProvider.value(value: appSettings),
          testAgendaAlertsProvider(),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: testLocalizationDelegates,
          supportedLocales: testSupportedLocales,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Dismissible), findsOneWidget);
    expect(plan.isInPlan('s-swipe'), isFalse);

    await tester.ensureVisible(find.byType(Dismissible));
    await tester.pump();
    await tester.drag(
      find.byType(Dismissible),
      const Offset(-500, 0),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(plan.isInPlan('s-swipe'), isTrue);
    expect(find.text('Undo'), findsOneWidget);

    final undoAction = tester.widget<SnackBarAction>(
      find.byType(SnackBarAction),
    );
    undoAction.onPressed();
    await tester.pumpAndSettle();

    expect(plan.isInPlan('s-swipe'), isFalse);

    event.dispose();
  });
}
