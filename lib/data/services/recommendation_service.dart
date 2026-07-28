import '../models/models.dart';
import '../models/user_profile.dart';
import '../../domain/inputs/recommendation_context.dart';
import 'behavior_signal_service.dart';

enum FloPickSource { happeningNow, afternoonGap, topRanked }

class FloPickCandidate {
  const FloPickCandidate({required this.session, required this.source});

  final Session session;
  final FloPickSource source;
}

class RecommendationService {
  /// Same track or tag overlap; prefers same day. Excludes [session.id].
  List<Session> findMissedAlternatives({
    required Session session,
    required List<Session> allSessions,
    int limit = 2,
  }) {
    double score(Session other) {
      var value = 0.0;
      if (other.trackId == session.trackId) value += 3.0;
      final tagOverlap = other.tags
          .toSet()
          .intersection(session.tags.toSet())
          .length;
      value += tagOverlap * 2.0;
      if (other.day == session.day) value += 2.0;
      return value;
    }

    final alternatives =
        allSessions
            .where((s) => s.id != session.id)
            .map((s) => MapEntry(s, score(s)))
            .where((e) => e.value > 0)
            .toList()
          ..sort((a, b) {
            final cmp = b.value.compareTo(a.value);
            if (cmp != 0) return cmp;
            return a.key.id.compareTo(b.key.id);
          });

    return alternatives.take(limit).map((e) => e.key).toList();
  }

  List<Session> findRelated(
    Session session,
    List<Session> allSessions, {
    int limit = 4,
  }) {
    final sessionTags = session.tags.toSet();
    final tagSets = {for (final s in allSessions) s.id: s.tags.toSet()};
    double overlapScore(Session other) {
      final b = tagSets[other.id] ?? other.tags.toSet();
      final intersect = sessionTags.intersection(b).length.toDouble();
      final union = sessionTags.union(b).length.toDouble();
      if (union == 0) return 0;
      return intersect / union;
    }

    final related =
        allSessions.where((other) => other.id != session.id).toList()
          ..sort((a, b) => overlapScore(b).compareTo(overlapScore(a)));
    return related.take(limit).toList();
  }

  List<ScoredSession> rankSessions({
    required List<Session> sessions,
    required List<Speaker> speakers,
    required List<Track> tracks,
    required UserProfile profile,
    DateTime? now,
    RecommendationMode preferenceMode = RecommendationMode.balanced,
    BehaviorSnapshot? behaviorSnapshot,
  }) {
    final speakerById = {for (final s in speakers) s.id: s};
    final trackById = {for (final t in tracks) t.id: t};
    final interestSet = profile.interests.toSet();

    final scored = sessions.map((session) {
      final overlap = session.tags.where(interestSet.contains).toList();
      final interestScore = overlap.length.toDouble();

      final roleScore = _roleAffinity(profile.role, session);
      final track = trackById[session.trackId];
      final trackScore = track != null && track.tags.any(interestSet.contains)
          ? 1.0
          : 0.0;

      var speakerTierBoost = 0.0;
      for (final sid in session.speakerIds) {
        final tier = speakerById[sid]?.tier ?? 4;
        if (tier == 1) {
          speakerTierBoost = 2.0;
          break;
        }
        if (tier == 2) speakerTierBoost = 1.0;
      }

      final featuredBoost = session.featured ? 1.0 : 0.0;
      final timeBonus = _timeProximityBonus(session, now);
      final behaviorAffinity =
          (behaviorSnapshot?.affinityForTrack(session.trackId) ?? 0) / 10.0;
      final positiveTagBonus = _positiveTagBonus(
        session.tags,
        behaviorSnapshot,
      );

      final (interestWeight, noveltyWeight) = _weightsForMode(preferenceMode);
      final noveltyBoost = overlap.isEmpty ? noveltyWeight : 0.0;
      final score =
          interestScore * interestWeight +
          roleScore * 3.0 +
          trackScore * 2.5 +
          speakerTierBoost * 1.5 +
          featuredBoost * 1.0 +
          timeBonus * 0.5 +
          noveltyBoost +
          behaviorAffinity * 2.0 +
          positiveTagBonus;

      final reasons = _matchReasons(
        session: session,
        overlap: overlap,
        track: track,
        speakers: session.speakerIds
            .map((id) => speakerById[id])
            .whereType<Speaker>()
            .toList(),
        timeBonus: timeBonus,
        behaviorSnapshot: behaviorSnapshot,
      );

      return ScoredSession(
        session: session,
        score: score,
        matchReasons: reasons,
      );
    }).toList();

    scored.sort((a, b) {
      final scoreCmp = b.score.compareTo(a.score);
      if (scoreCmp != 0) return scoreCmp;
      if (a.session.featured != b.session.featured) {
        return a.session.featured ? -1 : 1;
      }
      final dayCmp = a.session.dayNumber.compareTo(b.session.dayNumber);
      if (dayCmp != 0) return dayCmp;
      return a.session.id.compareTo(b.session.id);
    });

    return scored;
  }

  double _roleAffinity(AttendeeRole role, Session session) {
    final technical = session.tags.any(
      (t) => const {
        'cloud',
        'kubernetes',
        'cursor',
        'devex',
        'genai',
        'architecture',
        'apis',
        'cybersecurity',
        'mlops',
      }.contains(t),
    );

    final strategic = session.tags.any(
      (t) => const {
        'ceo_vision',
        'strategy',
        'leadership',
        'culture',
        'client_delivery',
      }.contains(t),
    );

    return switch (role) {
      AttendeeRole.engineer ||
      AttendeeRole.architect ||
      AttendeeRole.engineeringManager => technical ? 1.0 : 0.0,
      AttendeeRole.executive ||
      AttendeeRole.consultant ||
      AttendeeRole.productManager => strategic ? 1.0 : 0.0,
      AttendeeRole.guest => session.featured ? 0.5 : 0.0,
    };
  }

  double _positiveTagBonus(
    List<String> tags,
    BehaviorSnapshot? behaviorSnapshot,
  ) {
    if (behaviorSnapshot == null) return 0;
    var bonus = 0.0;
    for (final tag in tags) {
      final signal = behaviorSnapshot.positiveTagSignals[tag] ?? 0;
      if (signal > 0) bonus += signal * 0.25;
    }
    return bonus;
  }

  double _timeProximityBonus(Session session, DateTime? now) {
    if (now == null) return 0;
    final eventDay = _eventDateForDay(session.day);
    final parts = session.startTime.split(':');
    final start = DateTime(
      eventDay.year,
      eventDay.month,
      eventDay.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    final diff = start.difference(now).inMinutes;
    if (diff >= 0 && diff <= 60) return 1.0;
    return 0;
  }

  (double, double) _weightsForMode(RecommendationMode mode) {
    return switch (mode) {
      RecommendationMode.focused => (7.0, 0.1),
      RecommendationMode.balanced => (5.0, 0.4),
      RecommendationMode.adventurous => (3.5, 2.2),
    };
  }

  DateTime _eventDateForDay(String day) {
    return switch (day) {
      'Day 1' => DateTime(2026, 11, 4),
      'Day 2' => DateTime(2026, 11, 5),
      'Day 3' => DateTime(2026, 11, 6),
      _ => DateTime(2026, 11, 4),
    };
  }

  List<String> _matchReasons({
    required Session session,
    required List<String> overlap,
    required Track? track,
    required List<Speaker> speakers,
    required double timeBonus,
    BehaviorSnapshot? behaviorSnapshot,
  }) {
    final reasons = <String>[];

    if (behaviorSnapshot != null) {
      final trackViews = behaviorSnapshot.trackViews[session.trackId] ?? 0;
      if (trackViews >= 2) {
        reasons.add('Because you explored similar sessions');
      }
      final bookmarks = behaviorSnapshot.bookmarksByTrack[session.trackId] ?? 0;
      if (bookmarks >= 1) {
        reasons.add('You bookmarked this track before');
      }
      if (behaviorSnapshot.positiveSignalForTags(session.tags) >= 2) {
        reasons.add('You liked similar sessions');
      }
    }

    if (overlap.isNotEmpty) {
      final labels = overlap.take(3).map(_tagLabel).join(', ');
      reasons.add('${overlap.length} of your interests: $labels');
    }
    if (track != null && overlap.any(track.tags.contains)) {
      reasons.add('${track.name} track (you selected this)');
    }
    if (session.featured) {
      reasons.add('Featured Flo 2026 keynote');
    }
    if (speakers.isNotEmpty) {
      final lead = speakers.first;
      reasons.add('By ${lead.name} (${_shortTitle(lead.title)})');
    }
    if (timeBonus > 0) {
      reasons.add(
        'Happening soon at ${session.venueId.replaceFirst('ven-', '')}',
      );
    }

    return reasons.take(2).toList();
  }

  /// Rule-based serendipity pick for Discover "Surprise me".
  /// Excludes bookmarked and attended sessions; prefers unseen tracks.
  Session? pickSurprise(
    RecommendationContext ctx, {
    Set<String> attendedSessionIds = const {},
  }) {
    final excluded = {...ctx.plannedSessionIds, ...attendedSessionIds};
    final candidates = ctx.sessions
        .where((session) => !excluded.contains(session.id))
        .toList();
    if (candidates.isEmpty) return null;

    final behavior = ctx.behaviorSnapshot;
    final now = ctx.currentTime;
    final interestSet = ctx.profile.interests.toSet();

    final scored =
        candidates.map((session) {
          final overlap = session.tags.where(interestSet.contains).length;
          var score = overlap * 3.0;
          if (session.featured) score += 2.0;
          score += _surpriseTimeBonus(session, now);

          final trackViews = behavior?.trackViews[session.trackId] ?? 0;
          if (trackViews == 0) {
            score += 4.0;
          } else {
            score -= trackViews * 0.5;
          }

          return MapEntry(session, score);
        }).toList()..sort((a, b) {
          final cmp = b.value.compareTo(a.value);
          if (cmp != 0) return cmp;
          return a.key.id.compareTo(b.key.id);
        });

    return scored.first.key;
  }

  /// Single best Flo Picks hero candidate for event-day Discover.
  FloPickCandidate? pickFloPickCandidate(RecommendationContext ctx) {
    final session = pickFloPickHero(ctx);
    if (session == null) return null;
    final source = _floPickSource(ctx, session);
    return FloPickCandidate(session: session, source: source);
  }

  /// Returns the hero session only (convenience for widgets).
  Session? pickFloPickHero(RecommendationContext ctx) {
    final interests = ctx.profile.interests.toSet();
    if (interests.isEmpty) {
      return _pickTopRankedNotBookmarked(ctx);
    }

    final liveMatches = ctx.happeningNow
        .where(
          (session) =>
              !ctx.isInPlan(session.id) && session.tags.any(interests.contains),
        )
        .toList();
    if (liveMatches.isNotEmpty) {
      return _bestByRank(liveMatches, ctx).session;
    }

    final gapPick = _pickFromAfternoonGap(ctx);
    if (gapPick != null) return gapPick;

    return _pickTopRankedNotBookmarked(ctx);
  }

  FloPickSource _floPickSource(RecommendationContext ctx, Session session) {
    final interests = ctx.profile.interests.toSet();
    if (ctx.happeningNow.any((s) => s.id == session.id) &&
        session.tags.any(interests.contains)) {
      return FloPickSource.happeningNow;
    }
    if (_pickFromAfternoonGap(ctx)?.id == session.id) {
      return FloPickSource.afternoonGap;
    }
    return FloPickSource.topRanked;
  }

  Session? _pickFromAfternoonGap(RecommendationContext ctx) {
    final day = ctx.currentDay ?? 'Day 1';
    final planned = ctx
        .plannedSessions()
        .where((session) => session.day == day)
        .toList();
    final gaps =
        _afternoonGaps(
            planned,
          ).where((gap) => gap.durationMinutes > 60).toList()
          ..sort((a, b) => b.durationMinutes.compareTo(a.durationMinutes));
    if (gaps.isEmpty) return null;

    final interests = ctx.profile.interests.toSet();
    final rankedById = {for (final s in ctx.rankedSessions) s.session.id: s};

    for (final gap in gaps) {
      final fits = ctx.sessions.where((session) {
        if (session.day != day || ctx.isInPlan(session.id)) return false;
        final start = _minutesFromTime(session.startTime);
        final end = _minutesFromTime(session.endTime);
        if (start < gap.startMinutes || end > gap.endMinutes) return false;
        return interests.isEmpty || session.tags.any(interests.contains);
      }).toList();
      if (fits.isEmpty) continue;
      fits.sort((a, b) {
        final scoreA = rankedById[a.id]?.score ?? 0;
        final scoreB = rankedById[b.id]?.score ?? 0;
        return scoreB.compareTo(scoreA);
      });
      return fits.first;
    }
    return null;
  }

  Session? _pickTopRankedNotBookmarked(RecommendationContext ctx) {
    for (final scored in ctx.rankedSessions) {
      if (!ctx.isInPlan(scored.session.id)) {
        return scored.session;
      }
    }
    return null;
  }

  ScoredSession _bestByRank(List<Session> sessions, RecommendationContext ctx) {
    final byId = {for (final s in ctx.rankedSessions) s.session.id: s};
    sessions.sort((a, b) {
      final scoreA = byId[a.id]?.score ?? 0;
      final scoreB = byId[b.id]?.score ?? 0;
      return scoreB.compareTo(scoreA);
    });
    return byId[sessions.first.id] ??
        ScoredSession(
          session: sessions.first,
          score: 0,
          matchReasons: const [],
        );
  }

  double _surpriseTimeBonus(Session session, DateTime? now) {
    if (now == null) return 0;
    final eventDay = _eventDateForDay(session.day);
    final parts = session.startTime.split(':');
    final start = DateTime(
      eventDay.year,
      eventDay.month,
      eventDay.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    final diff = start.difference(now).inMinutes;
    if (diff < 0 || diff > 120) return 0;
    return 2.0 * (1.0 - diff / 120.0);
  }

  List<_AfternoonGap> _afternoonGaps(List<Session> plannedOnDay) {
    const windowStart = 13 * 60;
    const windowEnd = 17 * 60;

    final occupied = <_AfternoonGap>[];
    for (final session in plannedOnDay) {
      final start = _minutesFromTime(session.startTime);
      final end = _minutesFromTime(session.endTime);
      if (end <= windowStart || start >= windowEnd) continue;
      occupied.add(
        _AfternoonGap(
          startMinutes: start.clamp(windowStart, windowEnd),
          endMinutes: end.clamp(windowStart, windowEnd),
        ),
      );
    }
    occupied.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    final merged = <_AfternoonGap>[];
    for (final slot in occupied) {
      if (merged.isEmpty || slot.startMinutes > merged.last.endMinutes) {
        merged.add(slot);
      } else if (slot.endMinutes > merged.last.endMinutes) {
        merged[merged.length - 1] = _AfternoonGap(
          startMinutes: merged.last.startMinutes,
          endMinutes: slot.endMinutes,
        );
      }
    }

    final gaps = <_AfternoonGap>[];
    var cursor = windowStart;
    for (final slot in merged) {
      if (slot.startMinutes > cursor) {
        gaps.add(
          _AfternoonGap(startMinutes: cursor, endMinutes: slot.startMinutes),
        );
      }
      cursor = slot.endMinutes > cursor ? slot.endMinutes : cursor;
    }
    if (cursor < windowEnd) {
      gaps.add(_AfternoonGap(startMinutes: cursor, endMinutes: windowEnd));
    }
    return gaps;
  }

  int _minutesFromTime(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _tagLabel(String tag) => tag
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  String _shortTitle(String title) {
    if (title.contains('CEO')) return 'CEO';
    if (title.contains('CTO')) return 'CTO';
    if (title.contains('Chairman')) return 'Chairman';
    if (title.contains('COO')) return 'COO';
    return title.split(' ').first;
  }

  /// Alternative in the same slot for My Plan swap simulator.
  Session? pickSwapAlternative({
    required Session conflictSession,
    required List<Session> allSessions,
    required List<Speaker> speakers,
    required List<Track> tracks,
    required UserProfile profile,
    required Set<String> plannedIds,
    BehaviorSnapshot? behaviorSnapshot,
  }) {
    final sameSlot = allSessions.where((s) {
      return s.day == conflictSession.day &&
          s.startTime == conflictSession.startTime &&
          s.id != conflictSession.id &&
          !plannedIds.contains(s.id);
    }).toList();
    if (sameSlot.isEmpty) return null;
    final ranked = rankSessions(
      sessions: sameSlot,
      speakers: speakers,
      tracks: tracks,
      profile: profile,
      behaviorSnapshot: behaviorSnapshot,
    );
    return ranked.first.session;
  }

  double scoreForSession({
    required Session session,
    required List<Speaker> speakers,
    required List<Track> tracks,
    required UserProfile profile,
    DateTime? now,
    BehaviorSnapshot? behaviorSnapshot,
  }) {
    return rankSessions(
      sessions: [session],
      speakers: speakers,
      tracks: tracks,
      profile: profile,
      now: now,
      behaviorSnapshot: behaviorSnapshot,
    ).first.score;
  }
}

class _AfternoonGap {
  const _AfternoonGap({required this.startMinutes, required this.endMinutes});

  final int startMinutes;
  final int endMinutes;

  int get durationMinutes => endMinutes - startMinutes;
}
