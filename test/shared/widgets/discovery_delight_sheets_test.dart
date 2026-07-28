import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/shared/widgets/discovery_delight_sheets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Show detail dismisses surprise dialog before navigation', (
    tester,
  ) async {
    const session = Session(
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
    final event = EventState()
      ..venues = const [
        Venue(
          id: 'ven-G01',
          name: 'Ground Auditorium',
          floor: 'G',
          zone: 'auditorium',
          wing: 'central',
          capacity: 100,
          building: 'Nagarro Gurgaon Office',
        ),
      ];
    final plan = PlanState();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showSurpriseSessionModal(
                  context,
                  session: session,
                  event: event,
                ),
                child: const Text('Open surprise'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/session/:id',
          builder: (context, state) =>
              Text('Session ${state.pathParameters['id']}'),
        ),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: plan,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open surprise'));
    await tester.pumpAndSettle();
    expect(find.text('Surprise pick'), findsOneWidget);

    await tester.tap(find.text('Show detail'));
    await tester.pumpAndSettle();

    expect(find.text('Session s-001'), findsOneWidget);
    expect(find.text('Surprise pick'), findsNothing);
    event.dispose();
  });
}
