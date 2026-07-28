import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/core/auth/auth_service.dart';

void main() {
  group('AuthService.validateOAuthState', () {
    test('accepts matching non-empty state values', () {
      expect(AuthService.validateOAuthState('abc123', 'abc123'), isTrue);
    });

    test('rejects null or empty callback state', () {
      expect(AuthService.validateOAuthState(null, 'stored'), isFalse);
      expect(AuthService.validateOAuthState('', 'stored'), isFalse);
    });

    test('rejects null or empty stored state', () {
      expect(AuthService.validateOAuthState('callback', null), isFalse);
      expect(AuthService.validateOAuthState('callback', ''), isFalse);
    });

    test('rejects mismatched state', () {
      expect(
        AuthService.validateOAuthState('callback-a', 'callback-b'),
        isFalse,
      );
    });
  });
}
