import 'analytics_event.dart';

/// Pluggable destination for analytics events.
abstract class AnalyticsSink {
  const AnalyticsSink();

  Future<void> emit(AnalyticsEvent event);

  Future<void> flush();
}
