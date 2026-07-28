import '../di/service_locator.dart';
import 'analytics_property_allowlist.dart';
import 'analytics_service.dart';

/// Safe analytics entry point for widgets — no-ops when DI is not configured (tests).
Future<void> trackAnalytics(
  String name, {
  Map<String, Object?> properties = const {},
  String? route,
  String? sessionId,
}) async {
  if (!sl.isRegistered<AnalyticsService>()) return;
  await sl<AnalyticsService>().track(
    name,
    properties: properties,
    route: route,
    sessionId: sessionId,
  );
}

Future<void> flushAnalytics() async {
  if (!sl.isRegistered<AnalyticsService>()) return;
  await sl<AnalyticsService>().flush();
}

/// Re-export for companion instrumentation.
String questionLengthBucketForAnalytics(int length) =>
    questionLengthBucket(length);
