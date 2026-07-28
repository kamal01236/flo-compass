import '../models/models.dart';
import 'conflict_detector.dart';
import 'recommendation_service.dart';
import 'event_clock_service.dart';
import '../../data/models/user_profile.dart';
import '../../domain/inputs/day_planner_context.dart';
import 'behavior_signal_service.dart';

class DayPlannerResult {
  const DayPlannerResult({required this.sessions, required this.text});

  final List<Session> sessions;
  final String text;
}

class DayPlannerService {
  DayPlannerService({
    RecommendationService? recommendationService,
    ConflictDetector? conflictDetector,
    EventClockService? eventClockService,
  }) : _recommendationService =
           recommendationService ?? RecommendationService(),
       _conflictDetector = conflictDetector ?? ConflictDetector(),
       _eventClockService = eventClockService ?? EventClockService();

  final RecommendationService _recommendationService;
  final ConflictDetector _conflictDetector;
  final EventClockService _eventClockService;

  DayPlannerResult buildPlan({
    required List<Session> sessions,
    required List<Speaker> speakers,
    required List<Track> tracks,
    required UserProfile profile,
    String? requestedDay,
  }) {
    final targetDay =
        requestedDay ?? _eventClockService.currentDay() ?? 'Day 1';
    final daySessions = sessions.where((s) => s.day == targetDay).toList();
    final ranked = _recommendationService.rankSessions(
      sessions: daySessions,
      speakers: speakers,
      tracks: tracks,
      profile: profile,
      now: _eventClockService.now(),
      preferenceMode: profile.recommendationMode,
    );

    final selected = <Session>[];
    for (final scored in ranked) {
      if (selected.length >= 5) break;
      final candidate = scored.session;
      final test = [...selected, candidate];
      if (_conflictDetector.findConflicts(test).isEmpty) {
        selected.add(candidate);
      }
    }
    final lines = selected
        .map((s) => '• ${s.startTime} ${s.title} (${s.venueId})')
        .join('\n');
    return DayPlannerResult(
      sessions: selected,
      text: 'Here is a conflict-free $targetDay plan:\n$lines',
    );
  }

  /// Fills 13:00–17:00 gaps on [day] with ranked conflict-free sessions.
  List<Session> buildAfternoon(DayPlannerContext ctx) {
    return _fillAfternoonGaps(
      day: ctx.day,
      sessions: ctx.sessions,
      speakers: ctx.speakers,
      tracks: ctx.tracks,
      profile: ctx.profile,
      plannedIds: ctx.plannedSessionIds,
      now: ctx.currentTime,
      behaviorSnapshot: ctx.behaviorSnapshot,
    );
  }

  List<Session> _fillAfternoonGaps({
    required String day,
    required List<Session> sessions,
    required List<Speaker> speakers,
    required List<Track> tracks,
    required UserProfile profile,
    required Set<String> plannedIds,
    DateTime? now,
    BehaviorSnapshot? behaviorSnapshot,
  }) {
    const afternoonStart = 13 * 60;
    const afternoonEnd = 17 * 60;

    final daySessions = sessions.where((s) => s.day == day).toList();
    final planned = daySessions.where((s) => plannedIds.contains(s.id)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final gaps = <({int start, int end})>[];
    var cursor = afternoonStart;
    for (final session in planned) {
      final start = _minutes(session.startTime);
      final end = _minutes(session.endTime);
      if (end <= afternoonStart) continue;
      if (start >= afternoonEnd) break;
      if (start > cursor) {
        gaps.add((start: cursor, end: start));
      }
      cursor = end > cursor ? end : cursor;
    }
    if (afternoonEnd > cursor) {
      gaps.add((start: cursor, end: afternoonEnd));
    }

    if (gaps.isEmpty) return const [];

    final ranked = _recommendationService.rankSessions(
      sessions: daySessions.where((s) => !plannedIds.contains(s.id)).toList(),
      speakers: speakers,
      tracks: tracks,
      profile: profile,
      now: now ?? _eventClockService.now(),
      preferenceMode: profile.recommendationMode,
      behaviorSnapshot: behaviorSnapshot,
    );

    final selected = <Session>[...planned];
    final result = <Session>[];

    for (final gap in gaps) {
      for (final scored in ranked) {
        if (result.any((s) => s.id == scored.session.id)) continue;
        final start = _minutes(scored.session.startTime);
        final end = _minutes(scored.session.endTime);
        if (start < gap.start || start >= gap.end) continue;
        if (end > gap.end) continue;
        final test = [...selected, scored.session];
        if (_conflictDetector.findConflicts(test).isEmpty) {
          selected.add(scored.session);
          result.add(scored.session);
          break;
        }
      }
    }

    result.sort((a, b) => a.startTime.compareTo(b.startTime));
    return result;
  }

  int _minutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
