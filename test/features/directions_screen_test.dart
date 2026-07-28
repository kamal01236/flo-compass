import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/features/directions/directions_screen.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';

void main() {
  testWidgets('DirectionsScreen shows venue hero and CTAs', (tester) async {
    final event = EventState();
    final plan = PlanState();

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

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: event),
          ChangeNotifierProvider.value(value: plan),
        ],
        child: MaterialApp(home: DirectionsScreen(sessionId: 's-001')),
      ),
    );
    await tester.pump();

    expect(find.text('Floor 7 North Pod 1'), findsOneWidget);
    expect(find.textContaining('North wing'), findsOneWidget);
    expect(find.text('CEO Keynote'), findsOneWidget);
    expect(find.text('Open floor map'), findsOneWidget);
    expect(find.text('Session details'), findsOneWidget);
    expect(find.text('Add to My Plan'), findsOneWidget);

    event.dispose();
  });

  testWidgets('DirectionsScreen shows empty state for unknown session', (
    tester,
  ) async {
    final event = EventState();
    final plan = PlanState();
    event.loading = false;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: event),
          ChangeNotifierProvider.value(value: plan),
        ],
        child: MaterialApp(home: DirectionsScreen(sessionId: 'missing')),
      ),
    );
    await tester.pump();

    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Session not found.'), findsOneWidget);
    expect(find.text('Ask Flo instead'), findsOneWidget);
    handle.dispose();

    event.dispose();
  });
}
