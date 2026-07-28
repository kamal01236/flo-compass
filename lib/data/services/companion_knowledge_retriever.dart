import '../models/models.dart';
import 'walking_time_estimator.dart';

class CompanionKnowledgeRetriever {
  CompanionKnowledgeRetriever({WalkingTimeEstimator? walkEstimator})
    : _walkEstimator = walkEstimator ?? WalkingTimeEstimator();

  final WalkingTimeEstimator _walkEstimator;

  WalkingTimeEstimator _estimator(CompanionContext context) {
    return _walkEstimator.withContext(
      campus: context.campus,
      isEventDayMode: context.currentDay != null,
    );
  }

  CompanionKnowledgePack retrieve(CompanionContext context) {
    final tokens = _tokenize(context.query);
    if (tokens.isEmpty) {
      return _defaultPack(context);
    }

    final speakerById = {for (final s in context.speakers) s.id: s};
    final scoredSessions = <_Scored<Session>>[];
    for (final session in context.sessions) {
      final score = _scoreSession(session, tokens, speakerById, context);
      if (score > 0) scoredSessions.add(_Scored(session, score));
    }
    scoredSessions.sort((a, b) => b.score.compareTo(a.score));

    final scoredVenues = <_Scored<Venue>>[];
    for (final venue in context.venues) {
      final score = _scoreVenue(venue, tokens);
      if (score > 0) scoredVenues.add(_Scored(venue, score));
    }
    scoredVenues.sort((a, b) => b.score.compareTo(a.score));

    final scoredAmenities = <_Scored<Amenity>>[];
    for (final amenity in context.amenities) {
      var score = _scoreAmenity(amenity, tokens);
      if (context.campus != null && amenity.isParking) {
        if (tokens.any((t) => ['park', 'parking', 'car', 'bike'].contains(t))) {
          score += 8;
        }
        score += (amenity.capacityAvailable ?? 0) / 100;
      }
      if (score > 0) scoredAmenities.add(_Scored(amenity, score));
    }
    scoredAmenities.sort((a, b) => b.score.compareTo(a.score));

    final scoredSpeakers = <_Scored<Speaker>>[];
    for (final speaker in context.speakers) {
      final score = _scoreSpeaker(speaker, tokens);
      if (score > 0) scoredSpeakers.add(_Scored(speaker, score));
    }
    scoredSpeakers.sort((a, b) => b.score.compareTo(a.score));

    final floorStories = _matchFloorStories(tokens, context);
    final navHints = _matchNavigationHints(tokens, context);

    return CompanionKnowledgePack(
      sessions: scoredSessions.take(8).map((e) => e.item).toList(),
      speakers: scoredSpeakers.take(4).map((e) => e.item).toList(),
      venues: scoredVenues.take(6).map((e) => e.item).toList(),
      amenities: scoredAmenities.take(6).map((e) => e.item).toList(),
      floorStories: floorStories.take(3).toList(),
      navigationHints: navHints.take(2).toList(),
      planSnapshot: _buildPlanSnapshot(context),
    );
  }

  CompanionKnowledgePack _defaultPack(CompanionContext context) {
    final featured = context.sessions.where((s) => s.featured).take(5).toList();
    return CompanionKnowledgePack(
      sessions: featured,
      planSnapshot: _buildPlanSnapshot(context),
    );
  }

  PlanSnapshot? _buildPlanSnapshot(CompanionContext context) {
    if (context.plannedSessions.isEmpty) return null;
    final ordered = [...context.plannedSessions]
      ..sort((a, b) {
        final day = a.dayNumber.compareTo(b.dayNumber);
        if (day != 0) return day;
        return a.startTime.compareTo(b.startTime);
      });

    Session? next;
    int? minutesUntil;
    for (final session in ordered) {
      if (context.currentDay != null && session.day != context.currentDay) {
        continue;
      }
      final until = context.minutesUntil?.call(session);
      if (until != null && until > 0) {
        next = session;
        minutesUntil = until;
        break;
      }
    }

    if (next == null) return null;

    Venue? fromVenue;
    Venue? toVenue;
    for (final v in context.venues) {
      if (v.id == 'ven-G01') fromVenue = v;
      if (v.id == next.venueId) toVenue = v;
    }
    final walk = _estimator(context).estimate(from: fromVenue, to: toVenue);
    final leaveIn = minutesUntil != null
        ? (minutesUntil - walk.minutes - 5).clamp(0, minutesUntil)
        : null;

    return PlanSnapshot(
      nextSession: next,
      minutesUntilNext: minutesUntil,
      leaveInMinutes: leaveIn,
      conflictCount: context.conflicts.length,
    );
  }

  double _scoreSession(
    Session session,
    List<String> tokens,
    Map<String, Speaker> speakerById,
    CompanionContext context,
  ) {
    var score = 0.0;
    final title = session.title.toLowerCase();
    final abstract = session.abstract.toLowerCase();
    for (final token in tokens) {
      if (title.contains(token)) score += 4;
      if (abstract.contains(token)) score += 1;
      if (session.tags.any((t) => t.contains(token))) score += 3;
      if (session.id.toLowerCase().contains(token)) score += 2;
    }
    if (session.featured) score += 2;
    for (final interest in context.profile.interests) {
      if (session.tags.contains(interest) ||
          title.contains(interest.replaceAll('_', ' '))) {
        score += 2;
      }
    }
    for (final sid in session.speakerIds) {
      final spk = speakerById[sid];
      if (spk != null) {
        for (final token in tokens) {
          if (spk.name.toLowerCase().contains(token)) score += 3;
        }
      }
    }
    return score;
  }

  double _scoreVenue(Venue venue, List<String> tokens) {
    var score = 0.0;
    final name = venue.name.toLowerCase();
    for (final token in tokens) {
      if (name.contains(token)) score += 4;
      if (venue.id.toLowerCase().contains(token)) score += 2;
      if (venue.floor == token) score += 3;
      if (venue.wing.toLowerCase() == token) score += 2;
      if (venue.landmarks.any((l) => l.toLowerCase().contains(token))) {
        score += 2;
      }
    }
    return score;
  }

  double _scoreAmenity(Amenity amenity, List<String> tokens) {
    var score = 0.0;
    final label = amenity.label.toLowerCase();
    final type = amenity.type.replaceAll('_', ' ');
    for (final token in tokens) {
      if (label.contains(token)) score += 4;
      if (type.contains(token)) score += 5;
      if (amenity.floor == token) score += 3;
      if (amenity.wing.toLowerCase() == token) score += 1;
    }
    const typeKeywords = {
      'restroom': [
        'restroom',
        'bathroom',
        'toilet',
        'washroom',
        'ladies',
        'gents',
      ],
      'coffee': ['coffee', 'cafe', 'cafeteria'],
      'quiet_zone': ['quiet', 'silence'],
      'elevator': ['elevator', 'lift'],
      'help_desk': ['help', 'lost', 'desk', 'reception', 'arrived'],
      'first_aid': ['first', 'aid', 'medical'],
      'parking_car': ['park', 'parking', 'car'],
      'parking_bike': ['park', 'parking', 'bike', 'cycle'],
      'garden': ['garden', 'fresh', 'break', 'wellness'],
      'gym': ['gym', 'workout'],
      'library': ['library', 'read'],
      'stairs': ['stairs', 'stairwell'],
      'training_room': ['training'],
    };
    for (final entry in typeKeywords.entries) {
      if (amenity.type == entry.key &&
          entry.value.any((k) => tokens.contains(k))) {
        score += 6;
      }
    }
    return score;
  }

  double _scoreSpeaker(Speaker speaker, List<String> tokens) {
    var score = 0.0;
    final name = speaker.name.toLowerCase();
    final title = speaker.title.toLowerCase();
    for (final token in tokens) {
      if (name.contains(token)) score += 5;
      if (title.contains(token)) score += 3;
    }
    return score;
  }

  List<String> _matchFloorStories(
    List<String> tokens,
    CompanionContext context,
  ) {
    final stories = context.meta?.floorStories ?? {};
    final hits = <String>[];
    for (final entry in stories.entries) {
      if (tokens.any(
        (t) => entry.key == t || entry.value.toLowerCase().contains(t),
      )) {
        hits.add('Floor ${entry.key}: ${entry.value}');
      }
    }
    return hits;
  }

  List<NavigationHint> _matchNavigationHints(
    List<String> tokens,
    CompanionContext context,
  ) {
    return context.navigationHints
        .where(
          (h) => tokens.any(
            (t) =>
                h.fromFloor == t ||
                h.toFloor == t ||
                h.text.toLowerCase().contains(t),
          ),
        )
        .toList();
  }

  List<String> _tokenize(String query) {
    return query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .where((w) => !_stopWords.contains(w))
        .toList();
  }

  static const _stopWords = {
    'the',
    'and',
    'for',
    'what',
    'where',
    'how',
    'can',
    'you',
    'are',
    'my',
    'me',
    'is',
    'at',
    'on',
    'in',
    'to',
    'do',
    'get',
    'take',
    'show',
    'tell',
    'about',
    'that',
    'this',
    'with',
    'from',
    'nearest',
    'next',
    'session',
    'room',
    'floor',
  };
}

class _Scored<T> {
  const _Scored(this.item, this.score);
  final T item;
  final double score;
}
