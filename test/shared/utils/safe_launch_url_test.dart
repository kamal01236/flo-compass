import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/shared/utils/safe_launch_url.dart';

void main() {
  group('isAllowedLaunchScheme', () {
    test('allows mailto, http, https, tel', () {
      expect(isAllowedLaunchScheme(Uri.parse('mailto:a@b.com')), isTrue);
      expect(isAllowedLaunchScheme(Uri.parse('https://example.com')), isTrue);
      expect(isAllowedLaunchScheme(Uri.parse('http://example.com')), isTrue);
      expect(isAllowedLaunchScheme(Uri.parse('tel:+15551212')), isTrue);
    });

    test('rejects javascript and data schemes', () {
      expect(isAllowedLaunchScheme(Uri.parse('javascript:alert(1)')), isFalse);
      expect(isAllowedLaunchScheme(Uri.parse('data:text/html,evil')), isFalse);
    });
  });
}
