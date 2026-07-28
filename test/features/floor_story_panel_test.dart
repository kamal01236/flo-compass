import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flo_compass/features/venue_map/floor_story_panel.dart';

void main() {
  testWidgets('FloorStoryPanel shows blurb and landmark links', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: FloorStoryPanel(
              floor: '6',
              blurb: 'Cafeteria and training labs on this floor.',
            ),
          ),
        ),
        GoRoute(
          path: '/map',
          builder: (context, state) =>
              Scaffold(body: Text('room=${state.uri.queryParameters['room']}')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('About this floor'), findsOneWidget);
    expect(
      find.text('Cafeteria and training labs on this floor.'),
      findsOneWidget,
    );
    expect(find.text('Go to Cafeteria'), findsOneWidget);
    expect(find.text('Reception'), findsOneWidget);

    await tester.tap(find.text('Go to Cafeteria'));
    await tester.pumpAndSettle();

    expect(find.text('room=ven-C601'), findsOneWidget);
  });

  testWidgets('FloorStoryPanel collapses to save space', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FloorStoryPanel(
            floor: 'G',
            blurb: 'Welcome hall and reception.',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome hall and reception.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.expand_less));
    await tester.pumpAndSettle();

    expect(find.text('Welcome hall and reception.'), findsNothing);
  });
}
