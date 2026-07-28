import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/networking_card.dart';
import 'package:flo_compass/features/connect/business_card_preview.dart';

void main() {
  testWidgets('shows empty prompt when card has no display name', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BusinessCardPreview.fromCard(
            card: NetworkingCard(enabled: true),
          ),
        ),
      ),
    );

    expect(
      find.text(
        'Add a display name and enable at least one channel to preview.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows disabled overlay when card is not enabled', (
    tester,
  ) async {
    const card = NetworkingCard(
      enabled: false,
      displayName: 'Jordan Lee',
      jobTitle: 'Engineer',
      email: ShareField(value: 'jordan@example.com', visible: true),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BusinessCardPreview.fromCard(card: card)),
      ),
    );

    expect(find.text('Jordan Lee'), findsOneWidget);
    expect(find.text('Business card disabled'), findsOneWidget);
  });

  testWidgets('hides empty prompt when disabled card is empty', (tester) async {
    const card = NetworkingCard(enabled: false);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BusinessCardPreview.fromCard(card: card)),
      ),
    );

    expect(
      find.text(
        'Add a display name and enable at least one channel to preview.',
      ),
      findsNothing,
    );
    expect(find.text('Business card disabled'), findsOneWidget);
  });

  testWidgets('renders initials avatar and contact icons from card', (
    tester,
  ) async {
    const card = NetworkingCard(
      enabled: true,
      displayName: 'Jordan Lee',
      jobTitle: 'Engineering Manager',
      company: 'Flo Demo Co',
      email: ShareField(value: 'jordan@example.com', visible: true),
      linkedInUrl: ShareField(
        value: 'https://linkedin.com/in/jordan',
        visible: true,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BusinessCardPreview.fromCard(card: card)),
      ),
    );

    expect(find.text('JL'), findsOneWidget);
    expect(find.text('Jordan Lee'), findsOneWidget);
    expect(find.text('Engineering Manager'), findsOneWidget);
    expect(find.text('Flo Demo Co'), findsOneWidget);
    expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    expect(find.byIcon(Icons.link), findsOneWidget);
  });

  testWidgets('renders payload mode without disabled overlay', (tester) async {
    const payload = NetworkingCardPayload(
      displayName: 'Sam Rivera',
      jobTitle: 'Designer',
      email: 'sam@example.com',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BusinessCardPreview.fromPayload(payload: payload)),
      ),
    );

    expect(find.text('SR'), findsOneWidget);
    expect(find.text('Sam Rivera'), findsOneWidget);
    expect(find.text('Designer'), findsOneWidget);
    expect(find.text('Business card disabled'), findsNothing);
  });
}
