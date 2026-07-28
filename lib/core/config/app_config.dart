/// Runtime configuration read from `--dart-define` and app constants.
class AppConfig {
  AppConfig._();

  static const String appTitle = 'Flo Compass · Flo 2026';
  static const String appDescription =
      'Discover sessions, get AI-powered answers, and build your personal plan '
      'for Flo 2026 at Nagarro Gurgaon Office.';

  /// Optional companion API base URL (demo-only; never ship secrets in web builds).
  static const String companionApiUrl = String.fromEnvironment(
    'COMPANION_API_URL',
    defaultValue: '',
  );
  static const String eventNow = String.fromEnvironment(
    'EVENT_NOW',
    defaultValue: '',
  );

  /// Raw compile-time profile from `--dart-define=CONFIG_PROFILE`.
  static const String _configProfileRaw = String.fromEnvironment(
    'CONFIG_PROFILE',
    defaultValue: 'default',
  );

  /// Normalized runtime config profile: `default`, `dev`, or `prod`.
  static String get configProfile => normalizedConfigProfile(_configProfileRaw);

  /// Lowercases and trims profile names so `Dev` resolves like `dev`.
  static String normalizedConfigProfile(String raw) => raw.trim().toLowerCase();

  static bool get companionApiEnabled => companionApiUrl.isNotEmpty;

  /// Optional remote event API base URL.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Optional feedback API endpoint.
  static const String feedbackApiUrl = String.fromEnvironment(
    'FEEDBACK_API_URL',
    defaultValue: '',
  );

  /// Optional product analytics batch endpoint (demo only).
  static const String analyticsApiUrl = String.fromEnvironment(
    'ANALYTICS_API_URL',
    defaultValue: '',
  );

  static bool get analyticsApiEnabled => analyticsApiUrl.isNotEmpty;
}
