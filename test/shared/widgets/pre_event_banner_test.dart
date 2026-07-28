import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/shared/widgets/pre_event_banner.dart';
import '../../support/test_localizations.dart';

void main() {
  testWidgets('renders title, subtitle, Day 1 CTA, and notifications bell', (
    tester,
  ) async {
    final event = EventState()
      ..sessions = [
        const Session(
          id: 's-001',
          title: 'CEO Keynote',
          abstract: 'a',
          day: 'Day 1',
          startTime: '09:00',
          endTime: '10:00',
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

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: event,
        child: MaterialApp(
          localizationsDelegates: testLocalizationDelegates,
          supportedLocales: testSupportedLocales,
          home: Scaffold(
            body: PreEventBanner(
              event: event,
              notificationCount: 2,
              onNotificationsTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Event starts Wed at 09:00'), findsOneWidget);
    expect(find.textContaining('Nagarro Gurgaon Office'), findsOneWidget);
    expect(find.text('Build my Day 1 plan'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(find.byIcon(Icons.map_outlined), findsNothing);
    event.dispose();
  });
}
