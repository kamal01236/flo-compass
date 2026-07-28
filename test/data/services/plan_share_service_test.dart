import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/services/plan_share_service.dart';

void main() {
  final service = PlanShareService();

  test('decode accepts valid session ids', () {
    final encoded = service.encodeSessionIds(['s-001', 's-002']);
    expect(service.decodeSessionIds(encoded), ['s-001', 's-002']);
  });

  test('decode strips invalid session ids', () {
    final payload = base64Url.encode(
      utf8.encode(
        jsonEncode({
          's': ['s-001', '../../../evil', 's-99999', 'not-a-session'],
        }),
      ),
    );

    expect(service.decodeSessionIds(payload), ['s-001']);
  });

  test('decode returns empty list for malformed payload', () {
    expect(service.decodeSessionIds('not-valid-base64'), isEmpty);
  });

  test('decode caps at 20 session ids', () {
    final ids = List.generate(
      25,
      (i) => 's-${(i + 1).toString().padLeft(3, '0')}',
    );
    final encoded = service.encodeSessionIds(ids);
    expect(service.decodeSessionIds(encoded), hasLength(20));
  });
}
