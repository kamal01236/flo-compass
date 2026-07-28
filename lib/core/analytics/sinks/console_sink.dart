import '../../logging/app_logger.dart';
import '../analytics_event.dart';
import '../analytics_sink.dart';

/// Dev-only structured console output via [AppLog].
class ConsoleSink extends AnalyticsSink {
  const ConsoleSink();

  @override
  Future<void> emit(AnalyticsEvent event) async {
    AppLog.d('[analytics] ${event.name} ${event.properties}');
  }

  @override
  Future<void> flush() async {}
}
