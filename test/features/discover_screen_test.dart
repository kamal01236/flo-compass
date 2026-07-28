import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/data/services/event_clock_service.dart';
import 'package:flo_compass/shared/widgets/shared_widgets.dart';
import 'package:flo_compass/features/discover/discover_screen.dart';
import 'package:flo_compass/providers/app_settings_provider.dart';
import 'package:flo_compass/providers/engagement_provider.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/providers/profile_provider.dart';
import '../support/test_agenda_alerts_provider.dart';
import '../support/test_localizations.dart';

void main() {
  testWidgets('DiscoverScreen shows loading then session list', (tester) async {
    final event = EventState();
    final profile = ProfileState();
    final plan = PlanState();
    final engagement = EngagementState();
    final appSettings = AppSettingsState();
    appSettings.settings = const AppSettings(
      themeMode: AppThemeMode.dark,
      eventDayMode: EventDayMode.off,
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
        child: MaterialApp(
          localizationsDelegates: testLocalizationDelegates,
          supportedLocales: testSupportedLocales,
          home: const DiscoverScreen(),
        ),
      ),
    );

    expect(find.byType(SessionSkeletonCard), findsWidgets);
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
    event.notifyListeners();
    await tester.pump();

    expect(find.byType(SessionCard), findsOneWidget);
    event.dispose();
  });

  testWidgets('shows session card before learning paths section', (
    tester,
  ) async {
    final event = EventState();
    final profile = ProfileState();
    final plan = PlanState();
    final engagement = EngagementState();
    final appSettings = AppSettingsState();
    appSettings.settings = const AppSettings(
      themeMode: AppThemeMode.dark,
      eventDayMode: EventDayMode.off,
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
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

    event.loading = false;
    event.sessions = List.generate(
      4,
      (index) => Session(
        id: 's-00$index',
        title: 'Session $index',
        abstract: 'a',
        day: 'Day 1',
        startTime: '10:00',
        endTime: '11:00',
        venueId: 'ven-G01',
        trackId: 'trk-01',
        speakerIds: const ['spk-001'],
        tags: const ['genai'],
        format: 'Talk',
        level: 'beginner',
        featured: false,
        capacity: 50,
        building: 'Nagarro Gurgaon Office',
      ),
    );
    event.learningPaths = [
      const LearningPath(
        id: 'lp-1',
        title: 'Cloud Foundations',
        description: 'desc',
        sessionIds: ['s-000'],
      ),
    ];
    event.notifyListeners();
    await tester.pump();

    final sessionCardFinder = find.byType(SessionCard).first;
    final learningPathsFinder = find.text('Learning paths');
    expect(sessionCardFinder, findsOneWidget);
    expect(learningPathsFinder, findsOneWidget);
    expect(
      tester.getTopLeft(sessionCardFinder).dy,
      lessThan(tester.getTopLeft(learningPathsFinder).dy),
    );
    event.dispose();
  });

  testWidgets('hides Happening now strip before first session starts', (
    tester,
  ) async {
    final now = DateTime(2026, 11, 4, 9, 0);
    final event = EventState(
      eventClockService: EventClockService(clock: () => now),
    );
    final profile = ProfileState();
    final plan = PlanState();
    final engagement = EngagementState();
    final appSettings = AppSettingsState();

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
    event.notifyListeners();
    await tester.pump();

    expect(find.text('Happening now'), findsNothing);
    event.dispose();
  });

  testWidgets('shows Personalize button instead of inline preference chips', (
    tester,
  ) async {
    final event = EventState();
    final profile = ProfileState();
    final plan = PlanState();
    final engagement = EngagementState();
    final appSettings = AppSettingsState();

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
    event.notifyListeners();
    await tester.pump();

    expect(find.textContaining('Personalize ·'), findsOneWidget);
    expect(find.byType(SegmentedButton<RecommendationMode>), findsNothing);
    expect(find.text('Clear all'), findsNothing);
    event.dispose();
  });
}
