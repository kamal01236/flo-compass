import '../models/models.dart';
import '../models/engagement_snapshot.dart';
import 'event_clock_service.dart';

class DailyQuestProgress {
  const DailyQuestProgress({
    required this.templateId,
    required this.title,
    required this.current,
    required this.target,
    required this.completed,
  });

  final String templateId;
  final String title;
  final int current;
  final int target;
  final bool completed;
}

class DailyQuestService {
  static const bookmarkNoonId = 'bookmark_noon';
  static const companionId = 'companion';
  static const exploreTracksId = 'explore_tracks';

  static const _templates = <({String id, String title, int target})>[
    (id: bookmarkNoonId, title: 'Bookmark 2 sessions before noon', target: 2),
    (id: companionId, title: 'Ask Flo 1 question', target: 1),
    (id: exploreTracksId, title: 'Explore 3 tracks', target: 3),
  ];

  List<({String id, String title, int target})> templatesForDay(String? day) {
    if (day == null) return _templates;
    final seed = day.hashCode.abs();
    final rotated = List.of(_templates);
    rotated.sort(
      (a, b) => (a.id.hashCode + seed).compareTo(b.id.hashCode + seed),
    );
    return rotated;
  }

  EngagementSnapshot resetIfNewDay(
    EngagementSnapshot snapshot,
    String? currentDay,
  ) {
    if (currentDay == null) return snapshot;
    if (snapshot.lastQuestDay == currentDay) return snapshot;
    return EngagementSnapshot.fromJson({
      ...snapshot.toJson(),
      'lastQuestDay': currentDay,
      'questProgress': <String, int>{},
      'todayTracksViewed': <String>[],
      'todayBookmarksBeforeNoon': 0,
    });
  }

  List<DailyQuestProgress> progressFor({
    required EngagementSnapshot snapshot,
    required String? currentDay,
  }) {
    final progress = snapshot.questProgress;
    return templatesForDay(currentDay).map((template) {
      final current = progress[template.id] ?? 0;
      final completed =
          snapshot.completedQuestIds.contains(template.id) ||
          current >= template.target;
      return DailyQuestProgress(
        templateId: template.id,
        title: template.title,
        current: current.clamp(0, template.target),
        target: template.target,
        completed: completed,
      );
    }).toList();
  }

  EngagementSnapshot bumpBookmark({
    required EngagementSnapshot snapshot,
    required Session session,
    required EventClockService clock,
  }) {
    final now = clock.now();
    final isBeforeNoon = now.hour < 12;
    final isSameDay = session.day == clock.currentDay();
    if (!isBeforeNoon || !isSameDay) return snapshot;

    final progress = Map<String, int>.from(snapshot.questProgress);
    progress.update(bookmarkNoonId, (v) => v + 1, ifAbsent: () => 1);
    return EngagementSnapshot.fromJson({
      ...snapshot.toJson(),
      'questProgress': progress,
      'todayBookmarksBeforeNoon': snapshot.todayBookmarksBeforeNoon + 1,
    });
  }

  EngagementSnapshot bumpCompanion(EngagementSnapshot snapshot) {
    final progress = Map<String, int>.from(snapshot.questProgress);
    progress.update(companionId, (v) => v + 1, ifAbsent: () => 1);
    return snapshot.copyWith(questProgress: progress);
  }

  EngagementSnapshot bumpTrackView({
    required EngagementSnapshot snapshot,
    required String trackId,
  }) {
    final tracks = [...snapshot.todayTracksViewed];
    if (!tracks.contains(trackId)) tracks.add(trackId);
    final progress = Map<String, int>.from(snapshot.questProgress);
    progress[exploreTracksId] = tracks.length;
    return snapshot.copyWith(
      todayTracksViewed: tracks,
      questProgress: progress,
    );
  }

  String? newlyCompletedQuestId({
    required EngagementSnapshot before,
    required EngagementSnapshot after,
    required String? currentDay,
  }) {
    final beforeProgress = progressFor(
      snapshot: before,
      currentDay: currentDay,
    );
    final afterProgress = progressFor(snapshot: after, currentDay: currentDay);
    for (var i = 0; i < afterProgress.length; i++) {
      final afterQuest = afterProgress[i];
      final beforeQuest = beforeProgress[i];
      if (afterQuest.completed &&
          !beforeQuest.completed &&
          !before.completedQuestIds.contains(afterQuest.templateId)) {
        return afterQuest.templateId;
      }
    }
    return null;
  }
}
