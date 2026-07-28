import '../analytics_event.dart';
import '../analytics_sink.dart';

/// Discards all events — prod default when analytics is disabled.
class NoOpSink extends AnalyticsSink {
  const NoOpSink();

  @override
  Future<void> emit(AnalyticsEvent event) async {}

  @override
  Future<void> flush() async {}
}
