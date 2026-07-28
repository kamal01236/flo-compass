import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

String pkceChallengeForVerifier(String verifier) {
  final digest = sha256.convert(utf8.encode(verifier));
  return base64Url.encode(digest.bytes).replaceAll('=', '');
}

void main() {
  test('PKCE challenge is base64url SHA256 of verifier', () {
    const verifier = 'test-verifier-1234567890';
    final challenge = pkceChallengeForVerifier(verifier);
    expect(challenge, isNotEmpty);
    expect(challenge.contains('='), isFalse);
  });
}
