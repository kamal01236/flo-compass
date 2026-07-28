/// Scheme allowlist for [url_launcher] calls from user-supplied URLs.
bool isAllowedLaunchScheme(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  return scheme == 'mailto' ||
      scheme == 'http' ||
      scheme == 'https' ||
      scheme == 'tel';
}
