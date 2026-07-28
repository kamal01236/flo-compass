/// Supplies bearer tokens for [ApiClient] without importing Provider.
abstract class AuthTokenProvider {
  Future<String?> getAccessToken();

  /// Forces a token refresh (e.g. after a 401). Returns true when a new token
  /// was obtained.
  Future<bool> refresh() async => false;
}
