import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/features/speaker/speaker_detail_screen.dart';
import 'package:flo_compass/providers/engagement_provider.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/providers/profile_provider.dart';

Session _session({
  required String id,
  required String title,
  required String day,
  required String startTime,
  required String endTime,
}) {
  return Session(
    id: id,
    title: title,
    abstract: 'abstract',
    day: day,
    startTime: startTime,
    endTime: endTime,
    venueId: 'ven-G01',
    trackId: 'trk-01',
    speakerIds: const ['spk-timeline'],
    tags: const ['genai'],
    format: 'Talk',
    level: 'beginner',
    featured: false,
    capacity: 40,
    building: 'Nagarro Gurgaon Office',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('speaker timeline shows sessions chronologically with add all', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final event = EventState();
    final profile = ProfileState();
    final plan = PlanState(prefs: prefs);
    final engagement = EngagementState(prefs: prefs);
    await plan.init();
    await engagement.init();

    event.loading = false;
    event.speakers = [
      const Speaker(
        id: 'spk-timeline',
        name: 'Timeline Speaker',
        title: 'CTO',
        tier: 1,
        bio: 'Speaker bio for timeline test.',
        photoAsset: null,
      ),
    ];
    event.sessions = [
      _session(
        id: 's-late',
        title: 'Later Session',
        day: 'Day 1',
        startTime: '14:00',
        endTime: '15:00',
      ),
      _session(
        id: 's-early',
        title: 'Early Session',
        day: 'Day 1',
        startTime: '09:00',
        endTime: '10:00',
      ),
      _session(
        id: 's-day2',
        title: 'Day Two Session',
        day: 'Day 2',
        startTime: '10:00',
        endTime: '11:00',
      ),
    ];

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/speaker/:id',
          builder: (context, state) =>
              SpeakerDetailScreen(speakerId: state.pathParameters['id']!),
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
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.go('/speaker/spk-timeline');
    await tester.pumpAndSettle();

    expect(find.text('Add all to plan'), findsOneWidget);
    expect(find.text('Day 1'), findsNWidgets(2));
    expect(find.text('Day 2'), findsNWidgets(2));
    expect(find.text('Early Session'), findsOneWidget);
    expect(find.text('Later Session'), findsOneWidget);
    expect(find.text('Day Two Session'), findsOneWidget);

    final earlyOffset = tester.getTopLeft(find.text('Early Session'));
    final laterOffset = tester.getTopLeft(find.text('Later Session'));
    expect(earlyOffset.dy, lessThan(laterOffset.dy));

    event.dispose();
  });
}
