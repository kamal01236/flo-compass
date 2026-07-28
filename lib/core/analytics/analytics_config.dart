import '../config/app_config.dart';
import '../config/feature_flags.dart';
import '../config/runtime_config.dart';

/// Resolved analytics runtime configuration.
class AnalyticsConfig {
  const AnalyticsConfig({
    required this.enabled,
    required this.remoteEnabled,
    required this.isDevProfile,
    required this.localBufferEnabled,
    required this.consoleEnabled,
    required this.apiUrl,
    this.ringBufferCapacity = 200,
    this.batchSize = 20,
    this.flushInterval = const Duration(seconds: 30),
  });

  final bool enabled;
  final bool remoteEnabled;
  final bool isDevProfile;
  final bool localBufferEnabled;
  final bool consoleEnabled;
  final String apiUrl;
  final int ringBufferCapacity;
  final int batchSize;
  final Duration flushInterval;

  static AnalyticsConfig resolve({
    FeatureFlags? flags,
    String? configProfile,
    String? apiUrl,
    bool? analyticsEnabledOverride,
  }) {
    final effectiveFlags = flags ?? RuntimeConfig.flags;
    const enabledDefine = bool.fromEnvironment(
      'ANALYTICS_ENABLED',
      defaultValue: false,
    );
    final profile = AppConfig.normalizedConfigProfile(
      configProfile ?? AppConfig.configProfile,
    );
    final isDev = profile == 'dev';
    final enabled =
        analyticsEnabledOverride ?? enabledDefine || effectiveFlags.analytics;
    final url = apiUrl ?? AppConfig.analyticsApiUrl;
    final remote = effectiveFlags.analyticsRemote && url.isNotEmpty && enabled;

    return AnalyticsConfig(
      enabled: enabled,
      remoteEnabled: remote,
      isDevProfile: isDev,
      localBufferEnabled: isDev && enabled,
      consoleEnabled: isDev && enabled,
      apiUrl: url,
    );
  }

  static AnalyticsConfig fromFlags(FeatureFlags flags) => resolve(flags: flags);
}
