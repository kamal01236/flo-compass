/// Builds absolute deep-link URLs for demo QR posters.
class QrUrlBuilder {
  const QrUrlBuilder._();

  static String resolveOrigin(Uri base) => base.origin;

  static String sessionUrl(String sessionId, {required String origin}) {
    return '$origin/session/$sessionId';
  }

  static String roomUrl(String venueId, {required String origin}) {
    return '$origin/map?room=$venueId';
  }

  static String connectUrl(String token, {required String origin}) =>
      '$origin/connect/$token';
}
