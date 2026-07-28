import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class BehaviorSnapshot {
  const BehaviorSnapshot({
    required this.trackViews,
    required this.tagViews,
    required this.bookmarksByTrack,
    required this.positiveTagSignals,
  });

  final Map<String, int> trackViews;
  final Map<String, int> tagViews;
  final Map<String, int> bookmarksByTrack;
  final Map<String, int> positiveTagSignals;

  static const empty = BehaviorSnapshot(
    trackViews: {},
    tagViews: {},
    bookmarksByTrack: {},
    positiveTagSignals: {},
  );

  int affinityForTrack(String trackId) {
    return (trackViews[trackId] ?? 0) + (bookmarksByTrack[trackId] ?? 0) * 2;
  }

  int positiveSignalForTags(List<String> tags) {
    var maxSignal = 0;
    for (final tag in tags) {
      final signal = positiveTagSignals[tag] ?? 0;
      if (signal > maxSignal) maxSignal = signal;
    }
    return maxSignal;
  }

  Map<String, dynamic> toJson() => {
    'trackViews': trackViews,
    'tagViews': tagViews,
    'bookmarksByTrack': bookmarksByTrack,
    'positiveTagSignals': positiveTagSignals,
  };

  factory BehaviorSnapshot.fromJson(Map<String, dynamic> json) {
    Map<String, int> asIntMap(dynamic raw) {
      final map = (raw as Map<String, dynamic>? ?? {});
      return map.map((k, v) => MapEntry(k, (v as num).toInt()));
    }

    return BehaviorSnapshot(
      trackViews: asIntMap(json['trackViews']),
      tagViews: asIntMap(json['tagViews']),
      bookmarksByTrack: asIntMap(json['bookmarksByTrack']),
      positiveTagSignals: asIntMap(json['positiveTagSignals']),
    );
  }
}

class BehaviorSignalService {
  static const _key = 'flo_compass_behavior_signals';

  Future<BehaviorSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return BehaviorSnapshot.empty;
    return BehaviorSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> trackSessionView({
    required String trackId,
    required List<String> tags,
  }) async {
    final snapshot = await load();
    final trackViews = Map<String, int>.from(snapshot.trackViews);
    final tagViews = Map<String, int>.from(snapshot.tagViews);
    trackViews.update(trackId, (v) => v + 1, ifAbsent: () => 1);
    for (final tag in tags) {
      tagViews.update(tag, (v) => v + 1, ifAbsent: () => 1);
    }
    await _save(
      BehaviorSnapshot(
        trackViews: trackViews,
        tagViews: tagViews,
        bookmarksByTrack: snapshot.bookmarksByTrack,
        positiveTagSignals: snapshot.positiveTagSignals,
      ),
    );
  }

  Future<void> bumpTrack(String trackId, List<String> tags) =>
      trackSessionView(trackId: trackId, tags: tags);

  Future<void> trackBookmark({required String trackId}) async {
    final snapshot = await load();
    final bookmarks = Map<String, int>.from(snapshot.bookmarksByTrack);
    bookmarks.update(trackId, (v) => v + 1, ifAbsent: () => 1);
    await _save(
      BehaviorSnapshot(
        trackViews: snapshot.trackViews,
        tagViews: snapshot.tagViews,
        bookmarksByTrack: bookmarks,
        positiveTagSignals: snapshot.positiveTagSignals,
      ),
    );
  }

  Future<void> recordPositiveFeedback({
    required List<String> tags,
    required String trackId,
  }) async {
    final snapshot = await load();
    final positive = Map<String, int>.from(snapshot.positiveTagSignals);
    for (final tag in tags) {
      positive.update(tag, (v) => v + 1, ifAbsent: () => 1);
    }
    await _save(
      BehaviorSnapshot(
        trackViews: snapshot.trackViews,
        tagViews: snapshot.tagViews,
        bookmarksByTrack: snapshot.bookmarksByTrack,
        positiveTagSignals: positive,
      ),
    );
  }

  Future<void> _save(BehaviorSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(snapshot.toJson()));
  }
}
