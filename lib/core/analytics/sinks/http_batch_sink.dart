import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../data/local/local_user_store.dart';
import '../analytics_config.dart';
import '../analytics_event.dart';
import '../analytics_sink.dart';

/// Batches events and POSTs to [AnalyticsConfig.apiUrl]; queues on failure.
class HttpBatchSink extends AnalyticsSink {
  HttpBatchSink({
    required AnalyticsConfig config,
    LocalUserStore? store,
    http.Client? client,
    DateTime Function()? clock,
  }) : _config = config,
       _store = store ?? LocalUserStore(),
       _client = client ?? http.Client(),
       _clock = clock ?? DateTime.now;

  final AnalyticsConfig _config;
  final LocalUserStore _store;
  final http.Client _client;
  final DateTime Function() _clock;

  final List<AnalyticsEvent> _pending = [];
  Timer? _flushTimer;
  bool _flushing = false;

  @override
  Future<void> emit(AnalyticsEvent event) async {
    if (!_config.remoteEnabled) return;
    _pending.add(event);
    if (_pending.length >= _config.batchSize) {
      await flush();
      return;
    }
    _flushTimer ??= Timer(_config.flushInterval, () {
      unawaited(flush());
    });
  }

  @override
  Future<void> flush() async {
    if (_flushing) {
      _flushTimer ??= Timer(_config.flushInterval, () {
        unawaited(flush());
      });
      return;
    }
    _flushTimer?.cancel();
    _flushTimer = null;
    _flushing = true;
    try {
      await _flushQueuedFromStore();
      if (_pending.isEmpty) return;
      final batch = List<AnalyticsEvent>.from(_pending);
      _pending.clear();
      final ok = await _postBatch(batch);
      if (!ok) {
        for (final event in batch) {
          await _store.enqueueAnalytics(
            jsonEncode(event.toJson(now: _clock())),
          );
        }
      }
    } finally {
      _flushing = false;
    }
  }

  Future<void> _flushQueuedFromStore() async {
    final queued = await _store.getAnalyticsQueue();
    if (queued.isEmpty) return;
    final events = <AnalyticsEvent>[];
    final validLines = <String>[];
    for (final line in queued) {
      try {
        events.add(
          AnalyticsEvent.fromJson(jsonDecode(line) as Map<String, dynamic>),
        );
        validLines.add(line);
      } catch (_) {
        // Drop malformed entries.
      }
    }
    if (events.isEmpty) {
      await _store.clearAnalyticsQueue();
      return;
    }
    final ok = await _postBatch(events);
    if (ok) {
      await _store.clearAnalyticsQueue();
    } else if (validLines.length != queued.length) {
      await _store.setAnalyticsQueue(validLines);
    }
  }

  Future<bool> _postBatch(List<AnalyticsEvent> events) async {
    if (events.isEmpty) return true;
    if (_config.apiUrl.isEmpty) return false;
    try {
      final response = await _client
          .post(
            Uri.parse(_config.apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
              events.map((e) => e.toJson(now: _clock())).toList(),
            ),
          )
          .timeout(const Duration(seconds: 8));
      return response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
    unawaited(flush());
  }
}
