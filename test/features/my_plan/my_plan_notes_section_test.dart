import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/features/my_plan/widgets/my_plan_notes_section.dart';
import 'package:flo_compass/providers/engagement_provider.dart';
import 'package:flo_compass/providers/event_provider.dart';

Session _sampleSession() {
  return const Session(
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
}

void main() {
  testWidgets('MyPlanNotesSection hidden when no notes', (tester) async {
    final event = EventState();
    final engagement = EngagementState();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: event),
          ChangeNotifierProvider.value(value: engagement),
        ],
        child: const MaterialApp(home: Scaffold(body: MyPlanNotesSection())),
      ),
    );

    expect(find.text('My notes'), findsNothing);
    event.dispose();
  });

  testWidgets('MyPlanNotesSection starts collapsed and expands on tap', (
    tester,
  ) async {
    final event = EventState();
    final engagement = EngagementState();
    engagement.snapshot = EngagementSnapshot.empty.copyWith(
      notesBySessionId: const {'s-001': 'Remember the AI roadmap quote.'},
    );
    event.sessions = [_sampleSession()];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: event),
          ChangeNotifierProvider.value(value: engagement),
        ],
        child: const MaterialApp(home: Scaffold(body: MyPlanNotesSection())),
      ),
    );

    expect(find.text('My notes'), findsOneWidget);
    expect(find.text('1 saved'), findsOneWidget);
    expect(find.text('CEO Keynote'), findsNothing);
    expect(find.textContaining('AI roadmap'), findsNothing);

    await tester.tap(find.text('My notes'));
    await tester.pumpAndSettle();

    expect(find.text('CEO Keynote'), findsOneWidget);
    expect(find.textContaining('AI roadmap'), findsOneWidget);
    event.dispose();
  });
}
