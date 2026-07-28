import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/services/event_clock_service.dart';
import 'package:flo_compass/features/discover/discover_screen.dart';
import 'package:flo_compass/providers/app_settings_provider.dart';
import 'package:flo_compass/providers/engagement_provider.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/providers/profile_provider.dart';
import 'package:flo_compass/shared/theme/app_theme.dart';
import 'package:flo_compass/shared/widgets/now_next_bar.dart';
import '../support/test_localizations.dart';
import 'package:flo_compass/shared/widgets/shared_widgets.dart';
import '../support/test_agenda_alerts_provider.dart';

const _textScale = TextScaler.linear(2.0);

Session _session({
  required String id,
  required String title,
  String startTime = '10:00',
  String endTime = '11:00',
  String venueId = 'ven-7N1',
  String format = 'Talk',
}) {
  return Session(
    id: id,
    title: title,
    abstract:
        'A longer abstract that should wrap cleanly when text scale is doubled for accessibility testing.',
    day: 'Day 1',
    startTime: startTime,
    endTime: endTime,
    venueId: venueId,
    trackId: 'trk-01',
    speakerIds: const ['spk-001'],
    tags: const ['genai'],
    format: format,
    level: 'intermediate',
    featured: false,
    capacity: 50,
    building: 'Nagarro Gurgaon Office',
  );
}

Venue _venue({required String id, String floor = '7', String wing = 'N'}) {
  return Venue(
    id: id,
    name: 'Floor $floor North Pod 1',
    floor: floor,
    zone: 'pod',
    wing: wing,
    capacity: 40,
    building: 'Nagarro Gurgaon Office',
  );
}

Widget _scaled(Widget child) {
  return MediaQuery(
    data: const MediaQueryData(textScaler: _textScale),
    child: MaterialApp(
      localizationsDelegates: testLocalizationDelegates,
      supportedLocales: testSupportedLocales,
      theme: AppTheme.dark,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('empty state remains readable at 1.3x text scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'No sessions',
              message: 'Try clearing filters.',
            ),
          ),
        ),
      ),
    );

    expect(find.text('No sessions'), findsOneWidget);
    expect(find.textContaining('clearing filters'), findsOneWidget);
  });

  testWidgets('NowNextBar has no overflow at 200% text scale', (tester) async {
    final now = DateTime(2026, 11, 4, 10, 30);
    final session = _session(
      id: 's-scale',
      title: 'Platform Keynote with a longer title for scale testing',
    );
    final event =
        EventState(eventClockService: EventClockService(clock: () => now))
          ..sessions = [session]
          ..venues = [_venue(id: session.venueId)];
    final plan = PlanState();

    await tester.pumpWidget(
      _scaled(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: event),
            ChangeNotifierProvider.value(value: plan),
          ],
          child: NowNextBar(nowSession: session, event: event, plan: plan),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Platform Keynote'), findsOneWidget);
    event.dispose();
  });

  testWidgets('SessionCard has no overflow at 200% text scale', (tester) async {
    await tester.pumpWidget(
      _scaled(
        SessionCard(
          title: 'Hands-on lab with a descriptive title for accessibility',
          subtitle: 'Day 1 · 14:00 · Floor 7 North Pod 1 · GenAI track',
          plainEnglishSummary:
              'Hands-on lab about GenAI. Intermediate. 60 minutes.',
          sessionAbstract: 'Full abstract text for expand testing.',
          speakerName: 'Alex Rivera',
          featured: true,
          inPlan: true,
          showSocialProof: true,
          attendeeInterestCount: 42,
          onTogglePlan: () {},
          trailing: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.map_outlined),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Hands-on lab about GenAI'), findsOneWidget);
    expect(find.text('Featured'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
  });

  testWidgets('NowNextBar actions have no overflow at 200% text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 120));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final event = EventState();
    final plan = PlanState();

    await tester.pumpWidget(
      _scaled(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: event),
            ChangeNotifierProvider.value(value: plan),
          ],
          child: MaterialApp(
            localizationsDelegates: testLocalizationDelegates,
            supportedLocales: testSupportedLocales,
            theme: AppTheme.dark,
            home: Scaffold(
              body: NowNextBar(
                event: event,
                plan: plan,
                notificationCount: 0,
                onNotificationsTap: () {},
                onMapTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    event.dispose();
  });

  testWidgets('Discover session list smoke at 200% text scale', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final event = EventState();
    final profile = ProfileState();
    final plan = PlanState(prefs: prefs);
    final engagement = EngagementState(prefs: prefs);
    final appSettings = AppSettingsState(prefs: prefs);

    await plan.init();
    await engagement.init();
    await appSettings.init();
    await appSettings.setShowPlainEnglishCards(true);

    event.loading = false;
    event.sessions = [
      _session(
        id: 's-discover-scale',
        title: 'Discover scale test session with a long readable title',
        format: 'Hands-on lab',
      ),
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
    event.venues = [_venue(id: 'ven-7N1')];
    event.tracks = [
      const Track(id: 'trk-01', name: 'Generative AI', tags: ['genai']),
    ];

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const DiscoverScreen()),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: _textScale),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: event),
            ChangeNotifierProvider.value(value: profile),
            ChangeNotifierProvider.value(value: plan),
            ChangeNotifierProvider.value(value: engagement),
            ChangeNotifierProvider.value(value: appSettings),
            testAgendaAlertsProvider(),
          ],
          child: MaterialApp.router(
            theme: AppTheme.dark,
            localizationsDelegates: testLocalizationDelegates,
            supportedLocales: testSupportedLocales,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Discover scale test'), findsWidgets);
    expect(find.textContaining('Hands-on lab about GenAI'), findsOneWidget);
    event.dispose();
  });
}
