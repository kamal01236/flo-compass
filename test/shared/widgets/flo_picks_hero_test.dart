import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/shared/widgets/flo_picks_hero.dart';

void main() {
  testWidgets('FloPicksHero is hidden when session is null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FloPicksHero(session: null))),
    );

    expect(find.byType(FloPicksHero), findsOneWidget);
    expect(find.text('Flo Picks'), findsNothing);
    expect(tester.getSize(find.byType(FloPicksHero)).height, 0);
  });

  testWidgets('FloPicksHero shows content when candidate exists', (
    tester,
  ) async {
    const session = Session(
      id: 's-004',
      title: 'Live Lab: Ship an Agentic Cursor Workflow',
      abstract: 'test',
      day: 'Day 1',
      startTime: '14:00',
      endTime: '15:00',
      venueId: 'ven-T602',
      trackId: 'trk-08',
      speakerIds: ['spk-019'],
      tags: ['cursor', 'genai'],
      format: 'Live Lab',
      level: 'intermediate',
      featured: true,
      capacity: 60,
      building: 'Nagarro Gurgaon Office',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => EventState()),
          ChangeNotifierProvider(create: (_) => PlanState()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: FloPicksHero(session: session)),
        ),
      ),
    );

    expect(find.text('Flo Picks'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Ask about this'), findsOneWidget);
  });

  testWidgets('FloPicksHero shows Build my afternoon when enabled', (
    tester,
  ) async {
    const session = Session(
      id: 's-004',
      title: 'Live Lab: Ship an Agentic Cursor Workflow',
      abstract: 'test',
      day: 'Day 1',
      startTime: '14:00',
      endTime: '15:00',
      venueId: 'ven-T602',
      trackId: 'trk-08',
      speakerIds: ['spk-019'],
      tags: ['cursor', 'genai'],
      format: 'Live Lab',
      level: 'intermediate',
      featured: true,
      capacity: 60,
      building: 'Nagarro Gurgaon Office',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => EventState()),
          ChangeNotifierProvider(create: (_) => PlanState()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: FloPicksHero(session: session, showBuildAfternoon: true),
          ),
        ),
      ),
    );

    expect(find.text('Build my afternoon'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNWidgets(3));
  });

  testWidgets('FloPicksHero hides Build my afternoon by default', (
    tester,
  ) async {
    const session = Session(
      id: 's-004',
      title: 'Live Lab',
      abstract: 'test',
      day: 'Day 1',
      startTime: '14:00',
      endTime: '15:00',
      venueId: 'ven-T602',
      trackId: 'trk-08',
      speakerIds: ['spk-019'],
      tags: ['cursor'],
      format: 'Live Lab',
      level: 'intermediate',
      featured: true,
      capacity: 60,
      building: 'Nagarro Gurgaon Office',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => EventState()),
          ChangeNotifierProvider(create: (_) => PlanState()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: FloPicksHero(session: session)),
        ),
      ),
    );

    expect(find.text('Build my afternoon'), findsNothing);
    expect(find.byType(OutlinedButton), findsNWidgets(2));
  });

  testWidgets('FloPicksHero mobile shows Add, Open, and More menu', (
    tester,
  ) async {
    const session = Session(
      id: 's-004',
      title: 'Live Lab',
      abstract: 'test',
      day: 'Day 1',
      startTime: '14:00',
      endTime: '15:00',
      venueId: 'ven-T602',
      trackId: 'trk-08',
      speakerIds: ['spk-019'],
      tags: ['cursor'],
      format: 'Live Lab',
      level: 'intermediate',
      featured: true,
      capacity: 60,
      building: 'Nagarro Gurgaon Office',
    );

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => EventState()),
          ChangeNotifierProvider(create: (_) => PlanState()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: FloPicksHero(session: session, showBuildAfternoon: true),
          ),
        ),
      ),
    );

    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Ask about this'), findsNothing);
    expect(find.text('Build my afternoon'), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Ask about this'), findsOneWidget);
    expect(find.text('Build my afternoon'), findsOneWidget);
  });
}
