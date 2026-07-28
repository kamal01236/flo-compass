import 'dart:async';

import 'analytics_service.dart';

/// Periodically flushes the HTTP analytics queue (mirrors feedback retry intent).
class AnalyticsFlushWorker {
  AnalyticsFlushWorker({
    required AnalyticsService analytics,
    Duration interval = const Duration(seconds: 30),
  }) : _analytics = analytics,
       _interval = interval;

  final AnalyticsService _analytics;
  final Duration _interval;
  Timer? _timer;

  void start() {
    _timer ??= Timer.periodic(_interval, (_) {
      unawaited(_analytics.flush());
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> flushNow() => _analytics.flush();
}
