import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/engagement_snapshot.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/services/daily_quest_service.dart';
import 'package:flo_compass/data/services/event_clock_service.dart';

void main() {
  final service = DailyQuestService();
  final clock = EventClockService(clock: () => DateTime(2026, 11, 4, 10, 0));

  Session bookmarkSession() => Session(
    id: 's-001',
    title: 'Morning talk',
    abstract: 'abstract',
    day: 'Day 1',
    startTime: '10:00',
    endTime: '11:00',
    venueId: 'ven-7N1',
    trackId: 'trk-01',
    speakerIds: const [],
    tags: const ['genai'],
    format: 'Talk',
    level: 'beginner',
    featured: false,
    capacity: 40,
    building: 'Nagarro Gurgaon Office',
  );

  test('resetIfNewDay clears progress counters', () {
    const snapshot = EngagementSnapshot(
      xp: 0,
      streakDays: [],
      achievements: [],
      attendedSessionIds: [],
      ratings: {},
      bingoMarks: [],
      companionQuestions: 0,
      detailViews: 0,
      questProgress: {'companion': 1},
      lastQuestDay: 'Day 1',
      todayTracksViewed: ['trk-01'],
      todayBookmarksBeforeNoon: 1,
    );

    final reset = service.resetIfNewDay(snapshot, 'Day 2');
    expect(reset.lastQuestDay, 'Day 2');
    expect(reset.questProgress, isEmpty);
    expect(reset.todayTracksViewed, isEmpty);
    expect(reset.todayBookmarksBeforeNoon, 0);
  });

  test('bumpBookmark increments noon quest before noon', () {
    final updated = service.bumpBookmark(
      snapshot: EngagementSnapshot.empty,
      session: bookmarkSession(),
      clock: clock,
    );
    expect(updated.questProgress[DailyQuestService.bookmarkNoonId], 1);
  });

  test('progress reaches completion at target', () {
    var snapshot = EngagementSnapshot.empty;
    snapshot = service.bumpCompanion(snapshot);
    final progress = service.progressFor(
      snapshot: snapshot,
      currentDay: 'Day 1',
    );
    final companion = progress.firstWhere(
      (q) => q.templateId == DailyQuestService.companionId,
    );
    expect(companion.completed, isTrue);
    expect(companion.current, 1);
  });

  test('bumpTrackView counts distinct tracks', () {
    var snapshot = EngagementSnapshot.empty;
    snapshot = service.bumpTrackView(snapshot: snapshot, trackId: 'trk-01');
    snapshot = service.bumpTrackView(snapshot: snapshot, trackId: 'trk-02');
    snapshot = service.bumpTrackView(snapshot: snapshot, trackId: 'trk-01');
    expect(snapshot.questProgress[DailyQuestService.exploreTracksId], 2);
  });
}
