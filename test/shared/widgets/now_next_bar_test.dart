import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/services/event_clock_service.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/shared/theme/app_theme.dart';
import 'package:flo_compass/shared/widgets/now_next_bar.dart';
import '../../support/test_localizations.dart';

Session _session({
  required String id,
  required String title,
  required String startTime,
  required String endTime,
  String venueId = 'ven-7N1',
}) {
  return Session(
    id: id,
    title: title,
    abstract: 'abstract',
    day: 'Day 1',
    startTime: startTime,
    endTime: endTime,
    venueId: venueId,
    trackId: 'trk-01',
    speakerIds: const ['spk-001'],
    tags: const ['genai'],
    format: 'Talk',
    level: 'beginner',
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

void main() {
  testWidgets('renders title and NOW countdown', (tester) async {
    final now = DateTime(2026, 11, 4, 10, 30);
    final session = _session(
      id: 's-1',
      title: 'Platform Keynote',
      startTime: '10:00',
      endTime: '11:00',
    );
    final event =
        EventState(eventClockService: EventClockService(clock: () => now))
          ..sessions = [session]
          ..venues = [_venue(id: session.venueId)];
    final plan = PlanState();

    await tester.pumpWidget(
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
            body: NowNextBar(nowSession: session, event: event, plan: plan),
          ),
        ),
      ),
    );

    expect(find.text('Platform Keynote'), findsOneWidget);
    expect(find.text('Ends in 30m'), findsOneWidget);
    expect(find.text('NOW'), findsOneWidget);
    expect(find.textContaining('Floor 7'), findsOneWidget);
    event.dispose();
  });

  testWidgets('renders NEXT countdown label', (tester) async {
    final now = DateTime(2026, 11, 4, 9, 45);
    final session = _session(
      id: 's-2',
      title: 'AI Ops Panel',
      startTime: '10:00',
      endTime: '11:00',
    );
    final event =
        EventState(eventClockService: EventClockService(clock: () => now))
          ..sessions = [session]
          ..venues = [_venue(id: session.venueId)];
    final plan = PlanState();

    await tester.pumpWidget(
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
            body: NowNextBar(nextSession: session, event: event, plan: plan),
          ),
        ),
      ),
    );

    expect(find.text('AI Ops Panel'), findsOneWidget);
    expect(find.text('Starts in 15m'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);
    event.dispose();
  });

  testWidgets('renders Tomorrow countdown for distant NEXT session', (
    tester,
  ) async {
    final now = DateTime(2026, 11, 3, 12, 30);
    final session = _session(
      id: 's-far',
      title: 'Cloud Platform Reliability',
      startTime: '11:00',
      endTime: '12:00',
    );
    final clock = EventClockService(clock: () => now)..setOverride(now);
    final event = EventState(eventClockService: clock)
      ..sessions = [session]
      ..venues = [_venue(id: session.venueId)];
    final plan = PlanState();

    await tester.pumpWidget(
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
            body: NowNextBar(nextSession: session, event: event, plan: plan),
          ),
        ),
      ),
    );

    expect(find.text('Tomorrow · 11:00'), findsOneWidget);
    event.dispose();
  });

  testWidgets('renders Floor G Central chip for central wing venue', (
    tester,
  ) async {
    final now = DateTime(2026, 11, 4, 9, 45);
    final session = _session(
      id: 's-central',
      title: 'Ground Auditorium',
      startTime: '10:00',
      endTime: '11:00',
      venueId: 'ven-G01',
    );
    final event =
        EventState(eventClockService: EventClockService(clock: () => now))
          ..sessions = [session]
          ..venues = [_venue(id: 'ven-G01', floor: 'G', wing: 'central')];
    final plan = PlanState();

    await tester.pumpWidget(
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
            body: NowNextBar(nextSession: session, event: event, plan: plan),
          ),
        ),
      ),
    );

    expect(find.textContaining('Floor G · Central'), findsOneWidget);
    event.dispose();
  });

  testWidgets('tap invokes directions callback', (tester) async {
    final now = DateTime(2026, 11, 4, 10, 30);
    final session = _session(
      id: 's-3',
      title: 'Tap Target Session',
      startTime: '10:00',
      endTime: '11:00',
    );
    final event =
        EventState(eventClockService: EventClockService(clock: () => now))
          ..sessions = [session]
          ..venues = [_venue(id: session.venueId)];
    final plan = PlanState();
    var tapped = false;

    await tester.pumpWidget(
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
              nowSession: session,
              event: event,
              plan: plan,
              onDirectionsTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(NowNextBar));
    await tester.pump();
    expect(tapped, isTrue);
    event.dispose();
  });

  testWidgets('exposes Semantics liveRegion for countdown', (tester) async {
    final now = DateTime(2026, 11, 4, 10, 30);
    final session = _session(
      id: 's-4',
      title: 'Accessible Session',
      startTime: '10:00',
      endTime: '11:00',
    );
    final event =
        EventState(eventClockService: EventClockService(clock: () => now))
          ..sessions = [session]
          ..venues = [_venue(id: session.venueId)];
    final plan = PlanState();

    await tester.pumpWidget(
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
            body: NowNextBar(nowSession: session, event: event, plan: plan),
          ),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.text('Ends in 30m'));
    expect(semantics.label, contains('Accessible Session'));
    // ignore: deprecated_member_use
    expect(semantics.hasFlag(SemanticsFlag.isLiveRegion), isTrue);

    final barSemantics = tester.getSemantics(find.byType(NowNextBar));
    // ignore: deprecated_member_use
    expect(barSemantics.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(barSemantics.label, contains('Directions to Accessible Session'));
    event.dispose();
  });

  testWidgets('shows compact map and bell when no display session', (
    tester,
  ) async {
    final event = EventState();
    final plan = PlanState();

    await tester.pumpWidget(
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
    );

    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(find.text('NOW'), findsNothing);
    expect(find.text('NEXT'), findsNothing);
    event.dispose();
  });

  testWidgets('returns shrink when no display session or trailing actions', (
    tester,
  ) async {
    final event = EventState();
    final plan = PlanState();

    await tester.pumpWidget(
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
            body: NowNextBar(event: event, plan: plan),
          ),
        ),
      ),
    );

    expect(find.byType(NowNextBar), findsOneWidget);
    expect(find.text('NOW'), findsNothing);
    expect(find.text('NEXT'), findsNothing);
    event.dispose();
  });
}
