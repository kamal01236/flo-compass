class PkceStoredState {
  const PkceStoredState({
    required this.verifier,
    required this.returnUrl,
    required this.state,
  });

  final String verifier;
  final String returnUrl;
  final String state;
}

abstract final class OAuthRedirect {
  static void storePkceState({
    required String verifier,
    required String returnUrl,
    required String state,
  }) {}

  static PkceStoredState? readPkceState() => null;

  static void clearPkceState() {}

  static Future<void> navigateTo(String url) async {}

  /// Test-only override for [exchangeToken].
  static Future<Map<String, dynamic>?> Function(
    Uri tokenUri,
    Map<String, String> body,
  )?
  testExchangeToken;

  static Future<Map<String, dynamic>?> exchangeToken(
    Uri tokenUri,
    Map<String, String> body,
  ) async {
    final override = testExchangeToken;
    if (override != null) {
      return override(tokenUri, body);
    }
    return null;
  }
}
