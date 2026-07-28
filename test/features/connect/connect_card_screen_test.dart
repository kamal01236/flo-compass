import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/networking_card.dart';
import 'package:flo_compass/data/services/networking_card_share_service.dart';
import 'package:flo_compass/features/connect/connect_card_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('public card renders only visible fields from token', (
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
        visible: false,
      ),
    );
    final token = NetworkingCardShareService().encode(card);

    await tester.pumpWidget(MaterialApp(home: ConnectCardScreen(token: token)));
    await tester.pumpAndSettle();

    expect(find.text('Jordan Lee'), findsOneWidget);
    expect(find.text('Engineering Manager'), findsOneWidget);
    expect(find.text('Flo Demo Co'), findsOneWidget);
    expect(find.text('Save contact (vCard)'), findsOneWidget);
    expect(find.textContaining('jordan@example.com'), findsOneWidget);
    expect(find.text('Open LinkedIn'), findsNothing);
    expect(
      find.textContaining('Flo Compass complements Accelevents'),
      findsOneWidget,
    );
  });

  testWidgets('invalid token shows error message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ConnectCardScreen(token: 'bad-token')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('This business card link is invalid or has expired.'),
      findsOneWidget,
    );
  });

  testWidgets('malicious linkedIn token does not show Open LinkedIn', (
    tester,
  ) async {
    final token = base64Url.encode(
      utf8.encode(jsonEncode({'n': 'Attacker', 'l': 'javascript:alert(1)'})),
    );

    await tester.pumpWidget(MaterialApp(home: ConnectCardScreen(token: token)));
    await tester.pumpAndSettle();

    expect(find.text('Attacker'), findsOneWidget);
    expect(find.text('Open LinkedIn'), findsNothing);
  });
}
