import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/shared/utils/social_proof.dart';

void main() {
  test('mockSavedCount is deterministic for session id', () {
    expect(mockSavedCount('s-001'), mockSavedCount('s-001'));
    expect(mockSavedCount('s-002'), mockSavedCount('s-002'));
  });

  test('mockSavedCount stays in demo range', () {
    for (final id in ['s-001', 's-050', 's-999', 's-abc']) {
      final count = mockSavedCount(id);
      expect(count, inInclusiveRange(12, 99));
    }
  });
}
