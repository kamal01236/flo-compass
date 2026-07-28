import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
import '../../support/test_agenda_alerts_provider.dart';
import '../../support/test_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('event-day off AppBar shows bell and unified sort menu', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final clock = EventClockService();
    clock.setOverride(DateTime(2026, 11, 4, 10, 30));
    final event = EventState(eventClockService: clock);
    event.loading = false;
    event.sessions = [
      const Session(
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
      ),
    ];
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

    final profile = ProfileState(prefs: prefs);
    final plan = PlanState(prefs: prefs);
    final engagement = EngagementState(prefs: prefs);
    final appSettings = AppSettingsState(prefs: prefs);

    await profile.init();
    await plan.init();
    await engagement.init();
    await appSettings.init();
    appSettings.settings = const AppSettings(
      themeMode: AppThemeMode.dark,
      eventDayMode: EventDayMode.off,
    );

    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
        child: MaterialApp(
          localizationsDelegates: testLocalizationDelegates,
          supportedLocales: testSupportedLocales,
          home: const DiscoverScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Sort:'), findsNothing);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(find.byIcon(Icons.sort), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'genai');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byIcon(Icons.clear), findsOneWidget);
    expect(find.text('Clear all'), findsNothing);

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();

    expect(find.text('Relevance'), findsOneWidget);
    expect(find.text('Soonest'), findsOneWidget);

    event.dispose();
  });
}
