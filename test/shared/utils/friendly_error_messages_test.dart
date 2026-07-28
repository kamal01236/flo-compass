import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/shared/utils/friendly_error_messages.dart';

void main() {
  group('FriendlyErrorCopy', () {
    for (final kind in FriendlyErrorKind.values) {
      test('$kind pool returns non-empty copy fields', () {
        final copy = FriendlyErrorCopy.random(kind, random: Random(0));
        expect(copy.title, isNotEmpty);
        expect(copy.message, isNotEmpty);
        expect(copy.semanticLabel, isNotEmpty);
      });
    }

    test('seeded random yields deterministic pick', () {
      const kind = FriendlyErrorKind.loadFailure;
      final first = FriendlyErrorCopy.random(kind, random: Random(42));
      final second = FriendlyErrorCopy.random(kind, random: Random(42));
      expect(first.title, second.title);
      expect(first.message, second.message);
      expect(first.semanticLabel, second.semanticLabel);
    });

    test('semanticLabel stays factual without joke phrasing', () {
      const jokePhrases = [
        'coffee break',
        'elevator',
        'parking lot',
        'ballroom',
        'bio break',
        'photocopied',
        'teleportation',
      ];

      for (final kind in FriendlyErrorKind.values) {
        for (var seed = 0; seed < 8; seed++) {
          final copy = FriendlyErrorCopy.random(kind, random: Random(seed));
          final label = copy.semanticLabel.toLowerCase();
          expect(
            label,
            anyOf(
              contains('error'),
              contains('not found'),
              contains('retry'),
              contains('invalid'),
            ),
            reason: 'Expected factual wording in semanticLabel for $kind',
          );
          for (final phrase in jokePhrases) {
            expect(
              label,
              isNot(contains(phrase)),
              reason: 'semanticLabel should not contain joke phrase "$phrase"',
            );
          }
        }
      }
    });
  });
}
