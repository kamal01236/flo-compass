import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/networking_card.dart';
import 'package:flo_compass/data/services/networking_card_share_service.dart';

void main() {
  final service = NetworkingCardShareService();

  test('encode/decode round-trip includes only visible channels', () {
    const card = NetworkingCard(
      enabled: true,
      displayName: 'Alex Rivera',
      jobTitle: 'Principal Architect',
      company: 'Nagarro',
      email: ShareField(value: 'alex@example.com', visible: true),
      linkedInUrl: ShareField(
        value: 'https://linkedin.com/in/alex',
        visible: false,
      ),
    );

    final token = service.encode(card);
    expect(token, isNotEmpty);
    expect(token, isNot(contains('alex@example.com')));

    final payload = service.decode(token);
    expect(payload, isNotNull);
    expect(payload!.displayName, 'Alex Rivera');
    expect(payload.jobTitle, 'Principal Architect');
    expect(payload.company, 'Nagarro');
    expect(payload.email, 'alex@example.com');
    expect(payload.linkedInUrl, isNull);
  });

  test('decode returns null for invalid token', () {
    expect(service.decode('not-a-valid-token'), isNull);
    expect(service.decode(''), isNull);
  });

  test('encode omits hidden email', () {
    const card = NetworkingCard(
      enabled: true,
      displayName: 'Sam',
      email: ShareField(value: 'hidden@example.com', visible: false),
      linkedInUrl: ShareField(
        value: 'https://linkedin.com/in/sam',
        visible: true,
      ),
    );

    final payload = service.decode(service.encode(card));
    expect(payload!.email, isNull);
    expect(payload.linkedInUrl, 'https://linkedin.com/in/sam');
  });

  test('encode normalizes LinkedIn URL without scheme', () {
    const card = NetworkingCard(
      enabled: true,
      displayName: 'Sam',
      linkedInUrl: ShareField(value: 'linkedin.com/in/sam', visible: true),
    );

    final payload = service.decode(service.encode(card));
    expect(payload!.linkedInUrl, 'https://linkedin.com/in/sam');
  });

  test('decode nulls malicious LinkedIn URL', () {
    final token = base64Url.encode(
      utf8.encode(jsonEncode({'n': 'Attacker', 'l': 'javascript:alert(1)'})),
    );

    final payload = service.decode(token);
    expect(payload, isNotNull);
    expect(payload!.linkedInUrl, isNull);
  });
}
