/// Build metadata injected at compile time.
abstract final class BuildInfo {
  static const String version = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  static const String buildSha = String.fromEnvironment(
    'BUILD_SHA',
    defaultValue: 'dev',
  );

  static String get displayLabel => '$version ($buildSha)';
}
