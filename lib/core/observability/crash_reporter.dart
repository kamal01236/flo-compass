import 'package:flutter/foundation.dart';

import '../analytics/analytics_service.dart';
import '../logging/app_logger.dart';

class CrashReporter {
  CrashReporter._();

  static final CrashReporter instance = CrashReporter._();

  AnalyticsService? _analytics;

  void bindAnalytics(AnalyticsService analytics) {
    _analytics = analytics;
  }

  void recordFlutterError(FlutterErrorDetails details) {
    AppLog.e('Flutter error', details.exception, details.stack);
    _recordAppError(details.exception);
  }

  void recordZoneError(Object error, StackTrace stack) {
    AppLog.e('Zone error', error, stack);
    _recordAppError(error);
  }

  void _recordAppError(Object error) {
    final analytics = _analytics;
    if (analytics == null) return;
    analytics.trackAppError(
      errorType: error.runtimeType.toString(),
      fatal: true,
    );
  }
}
