import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/shared/utils/linkedin_url.dart';

void main() {
  group('normalizeLinkedInUrl', () {
    test('returns null for empty input', () {
      expect(normalizeLinkedInUrl(''), isNull);
      expect(normalizeLinkedInUrl('   '), isNull);
    });

    test('adds https scheme when missing', () {
      expect(
        normalizeLinkedInUrl('linkedin.com/in/jordan'),
        'https://linkedin.com/in/jordan',
      );
      expect(
        normalizeLinkedInUrl('www.linkedin.com/in/jordan'),
        'https://www.linkedin.com/in/jordan',
      );
    });

    test('normalizes in/ shorthand', () {
      expect(
        normalizeLinkedInUrl('in/jordan'),
        'https://www.linkedin.com/in/jordan',
      );
      expect(
        normalizeLinkedInUrl('/in/jordan'),
        'https://www.linkedin.com/in/jordan',
      );
    });

    test('keeps https URLs', () {
      expect(
        normalizeLinkedInUrl('https://linkedin.com/in/jordan'),
        'https://linkedin.com/in/jordan',
      );
    });

    test('rejects non-LinkedIn hosts', () {
      expect(normalizeLinkedInUrl('https://evil.com/in/jordan'), isNull);
      expect(normalizeLinkedInUrl('mailto:jordan@example.com'), isNull);
    });
  });
}
