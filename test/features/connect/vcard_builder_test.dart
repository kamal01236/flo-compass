import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/networking_card.dart';
import 'package:flo_compass/features/connect/vcard_builder.dart';

void main() {
  test('escapes CRLF injection in display name', () {
    const payload = NetworkingCardPayload(displayName: 'Alice\r\nX-EVIL:phish');

    final vcard = buildVCard(payload);

    expect(vcard, contains('FN:Alice\\r\\nX-EVIL:phish'));
    expect(vcard.split('\n').where((l) => l.isNotEmpty), hasLength(4));
    expect(vcard, isNot(contains('\nX-EVIL:')));
  });

  test('escapes semicolon and comma in fields', () {
    const payload = NetworkingCardPayload(
      displayName: 'Bob',
      jobTitle: 'Lead; Architect',
      company: 'Flo, Inc',
    );

    final vcard = buildVCard(payload);

    expect(vcard, contains('TITLE:Lead\\; Architect'));
    expect(vcard, contains('ORG:Flo\\, Inc'));
  });
}
