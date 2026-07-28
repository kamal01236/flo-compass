import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/services/event_clock_service.dart';
import 'package:flo_compass/features/recap/recap_screen.dart';
import 'package:flo_compass/providers/engagement_provider.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/providers/profile_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('So far slide shows counts and mark attended updates total', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime(2026, 11, 4, 10, 30);
    final event = EventState(
      eventClockService: EventClockService(clock: () => now),
    );
    final profile = ProfileState();
    final plan = PlanState(prefs: prefs);
    final engagement = EngagementState(prefs: prefs);
    await plan.init();
    await engagement.init();

    event.loading = false;
    event.sessions = [
      const Session(
        id: 's-live',
        title: 'Live Keynote',
        abstract: 'abstract',
        day: 'Day 1',
        startTime: '10:00',
        endTime: '11:00',
        venueId: 'ven-G01',
        trackId: 'trk-01',
        speakerIds: ['spk-001'],
        tags: ['genai'],
        format: 'Talk',
        level: 'beginner',
        featured: true,
        capacity: 40,
        building: 'Nagarro Gurgaon Office',
      ),
    ];

    await plan.mergeSessions(['s-live']);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: event),
          ChangeNotifierProvider.value(value: profile),
          ChangeNotifierProvider.value(value: plan),
          ChangeNotifierProvider.value(value: engagement),
        ],
        child: const MaterialApp(home: RecapScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('XP and Level'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-380, 0));
    await tester.pumpAndSettle();

    expect(find.text('Mid-event progress'), findsOneWidget);

    final pageView = find.byType(PageView);
    expect(
      find.descendant(of: pageView, matching: find.text('Bookmarked')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: pageView, matching: find.text('Attended')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: pageView, matching: find.text('1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: pageView, matching: find.text('0')),
      findsOneWidget,
    );
    expect(find.text('Mark current session attended'), findsOneWidget);

    await tester.tap(find.text('Mark current session attended'));
    await tester.pumpAndSettle();

    expect(find.text('Current session marked attended'), findsOneWidget);
    expect(engagement.attendedSessionIds, contains('s-live'));

    event.dispose();
  });
}
