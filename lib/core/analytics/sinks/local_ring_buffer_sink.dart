import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../analytics_event.dart';
import '../analytics_sink.dart';

/// Persists the last [capacity] events in shared_preferences.
class LocalRingBufferSink extends AnalyticsSink {
  LocalRingBufferSink({
    SharedPreferences? prefs,
    this.capacity = 200,
    this.storageKey = 'flo_compass_analytics',
  }) : _prefs = prefs;

  static const defaultStorageKey = 'flo_compass_analytics';

  final SharedPreferences? _prefs;
  final int capacity;
  final String storageKey;

  SharedPreferences? _resolvedPrefs;

  Future<SharedPreferences> _ensurePrefs() async {
    return _resolvedPrefs ??= _prefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<void> emit(AnalyticsEvent event) async {
    final prefs = await _ensurePrefs();
    final existing = prefs.getStringList(storageKey) ?? [];
    final encoded = jsonEncode(event.toJson());
    final next = [...existing, encoded];
    final trimmed = next.length > capacity
        ? next.sublist(next.length - capacity)
        : next;
    await prefs.setStringList(storageKey, trimmed);
  }

  @override
  Future<void> flush() async {}

  Future<List<AnalyticsEvent>> readAll() async {
    final prefs = await _ensurePrefs();
    final raw = prefs.getStringList(storageKey) ?? [];
    return raw
        .map(
          (line) =>
              AnalyticsEvent.fromJson(jsonDecode(line) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<int> count() async {
    final prefs = await _ensurePrefs();
    return (prefs.getStringList(storageKey) ?? []).length;
  }

  Future<void> clear() async {
    final prefs = await _ensurePrefs();
    await prefs.remove(storageKey);
  }

  Future<String> exportJson() async {
    final events = await readAll();
    return jsonEncode(events.map((e) => e.toJson()).toList());
  }
}
