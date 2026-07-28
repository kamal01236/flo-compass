import 'package:flutter/material.dart';

import '../../domain/entities/learning_path.dart';
import '../../domain/entities/plan_conflict.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/track.dart';
import '../../domain/entities/venue.dart';
import '../../providers/engagement_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/plan_provider.dart';
import '../../shared/utils/session_capacity.dart';
import '../../shared/utils/session_time_display.dart';
import '../models/user_profile.dart';
import 'conflict_detector.dart';
import 'event_clock_service.dart';
import 'recommendation_service.dart';
import 'session_format_hints.dart';
import 'session_stream_resolver.dart';

enum SessionLiveState { upcoming, startingSoon, live, ended }

class LearningPathHit {
  const LearningPathHit({
    required this.path,
    required this.completedCount,
    required this.totalCount,
  });

  final LearningPath path;
  final int completedCount;
  final int totalCount;

  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;
}

class SessionDetailViewModel {
  const SessionDetailViewModel({
    required this.matchReasons,
    required this.relatedSessions,
    required this.missedAlternatives,
    required this.planConflicts,
    required this.learningPathHits,
    required this.bingoHints,
    required this.liveState,
    required this.capacityLabel,
    required this.capacityColor,
    required this.timeDisplay,
    required this.streamAction,
    required this.formatHints,
    required this.dayTheme,
    required this.attendeeInterestCount,
    required this.inPlan,
    required this.attended,
    required this.showStreamPriority,
    this.coWatchCount,
    this.streamNudge,
    this.venue,
    this.track,
  });

  final List<String> matchReasons;
  final List<Session> relatedSessions;
  final List<Session> missedAlternatives;
  final List<PlanConflict> planConflicts;
  final List<LearningPathHit> learningPathHits;
  final List<String> bingoHints;
  final SessionLiveState liveState;
  final String capacityLabel;
  final Color capacityColor;
  final String timeDisplay;
  final StreamAction streamAction;
  final List<String> formatHints;
  final String? dayTheme;
  final int attendeeInterestCount;
  final bool inPlan;
  final bool attended;
  final bool showStreamPriority;
  final int? coWatchCount;
  final StreamNudge? streamNudge;
  final Venue? venue;
  final Track? track;
}

class SessionDetailAssembler {
  SessionDetailAssembler({
    RecommendationService? recommendationService,
    ConflictDetector? conflictDetector,
    EventClockService? clockService,
    SessionStreamResolver? streamResolver,
    SessionFormatHints? formatHints,
  }) : _recommendationService =
           recommendationService ?? RecommendationService(),
       _conflictDetector = conflictDetector ?? ConflictDetector(),
       _clockService = clockService ?? EventClockService(),
       _streamResolver = streamResolver ?? const SessionStreamResolver(),
       _formatHints = formatHints ?? const SessionFormatHints();

  final RecommendationService _recommendationService;
  final ConflictDetector _conflictDetector;
  final EventClockService _clockService;
  final SessionStreamResolver _streamResolver;
  final SessionFormatHints _formatHints;

  SessionDetailViewModel assemble({
    required Session session,
    required EventState event,
    required UserProfile profile,
    required PlanState plan,
    required EngagementState engagement,
  }) {
    final ranked = event.rankedSessions(profile);
    final scored = ranked.where((s) => s.session.id == session.id).firstOrNull;
    final matchReasons = scored?.matchReasons ?? const <String>[];

    final related = _recommendationService.findRelated(session, event.sessions);
    final missed = _recommendationService.findMissedAlternatives(
      session: session,
      allSessions: event.sessions,
    );

    final inPlan = plan.isInPlan(session.id);
    final planConflicts = inPlan
        ? const <PlanConflict>[]
        : _conflictDetector
              .findConflicts([...plan.plannedSessions(event.sessions), session])
              .where(
                (c) =>
                    c.sessionA.id == session.id || c.sessionB.id == session.id,
              )
              .toList();

    final attendedIds = {...engagement.attendedSessionIds, ...plan.sessionIds};
    final learningPathHits = event.learningPaths
        .where((path) => path.sessionIds.contains(session.id))
        .map((path) {
          final completed = path.sessionIds
              .where((id) => attendedIds.contains(id))
              .length;
          return LearningPathHit(
            path: path,
            completedCount: completed,
            totalCount: path.sessionIds.length,
          );
        })
        .toList();

    final track = event.trackById(session.trackId);
    final bingoHints = _bingoHints(session, track);

    final liveState = _liveState(session);
    final (capacityColor, capacityLabel) = capacityPresentation(
      session.occupancyPercent,
    );
    final timeDisplay = formatSessionTimeDisplay(
      session: session,
      meta: event.meta,
      referenceNow: _clockService.now(),
    );
    final streamAction = _streamResolver.resolve(session);
    final formatHints = _formatHints.hintsFor(session.format);
    final dayTheme = event.meta?.days
        .where((d) => d.id == session.day)
        .map((d) => d.description)
        .firstOrNull;

    final showStreamPriority =
        (liveState == SessionLiveState.live ||
            liveState == SessionLiveState.startingSoon) &&
        streamAction.isStreamable;
    final coWatchCount =
        liveState == SessionLiveState.live && streamAction.isStreamable
        ? 8 + session.id.hashCode.abs() % 40
        : null;
    final streamNudge = streamNudgeFor(
      occupancyPercent: session.occupancyPercent,
      isStreamable: streamAction.isStreamable,
    );

    final interest = session.attendeeInterestCount > 0
        ? session.attendeeInterestCount
        : 12 + (session.id.hashCode.abs() % 88);

    return SessionDetailViewModel(
      matchReasons: matchReasons,
      relatedSessions: related,
      missedAlternatives: missed,
      planConflicts: planConflicts,
      learningPathHits: learningPathHits,
      bingoHints: bingoHints,
      liveState: liveState,
      capacityLabel: capacityLabel,
      capacityColor: capacityColor,
      timeDisplay: timeDisplay,
      streamAction: streamAction,
      formatHints: formatHints,
      dayTheme: dayTheme,
      attendeeInterestCount: interest,
      inPlan: inPlan,
      attended: engagement.attendedSessionIds.contains(session.id),
      showStreamPriority: showStreamPriority,
      coWatchCount: coWatchCount,
      streamNudge: streamNudge,
      venue: event.venueById(session.venueId),
      track: track,
    );
  }

  SessionLiveState _liveState(Session session) {
    if (_clockService.isHappeningNow(session)) {
      return SessionLiveState.live;
    }
    if (_clockService.isStartingSoon(session)) {
      return SessionLiveState.startingSoon;
    }
    if (_clockService.minutesRemaining(session) < 0) {
      return SessionLiveState.ended;
    }
    return SessionLiveState.upcoming;
  }

  List<String> _bingoHints(Session session, Track? track) {
    final hints = <String>[];
    if (session.tags.contains('genai') ||
        track?.name.toLowerCase() == 'genai') {
      hints.add('Counts toward GenAI track');
    }
    if (session.featured) {
      hints.add('Featured session — bingo eligible');
    }
    if (session.format.toLowerCase().contains('workshop')) {
      hints.add('Hands-on format for bingo explorers');
    }
    return hints.take(2).toList();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
