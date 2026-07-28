import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NavigationHistoryEntry {
  const NavigationHistoryEntry({
    required this.route,
    required this.label,
    this.subtitle,
    required this.timestamp,
  });

  final String route;
  final String label;
  final String? subtitle;
  final int timestamp;

  Map<String, dynamic> toJson() => {
    'route': route,
    'label': label,
    if (subtitle != null) 'subtitle': subtitle,
    'timestamp': timestamp,
  };

  factory NavigationHistoryEntry.fromJson(Map<String, dynamic> json) {
    return NavigationHistoryEntry(
      route: json['route'] as String,
      label: json['label'] as String,
      subtitle: json['subtitle'] as String?,
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }
}

class NavigationHistoryService {
  NavigationHistoryService({SharedPreferences? prefs}) : _prefs = prefs;

  static const _storageKey = 'flo_compass_nav_history';
  static const _maxEntries = 10;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _storage async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<NavigationHistoryEntry>> load() async {
    final prefs = await _storage;
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (e) => NavigationHistoryEntry.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> record({
    required String route,
    required String label,
    String? subtitle,
  }) async {
    if (route.isEmpty || label.isEmpty) return;
    final prefs = await _storage;
    final existing = await load();
    final filtered = existing.where((e) => e.route != route).toList();
    final entry = NavigationHistoryEntry(
      route: route,
      label: label,
      subtitle: subtitle,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    final updated = [entry, ...filtered].take(_maxEntries).toList();
    await prefs.setString(
      _storageKey,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    final prefs = await _storage;
    await prefs.remove(_storageKey);
  }
}
