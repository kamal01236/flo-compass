import 'amenity.dart';
import 'campus_layout.dart';
import 'event_meta.dart';
import 'navigation_hint.dart';
import 'plan_conflict.dart';
import 'session.dart';
import 'speaker.dart';
import 'track.dart';
import 'venue.dart';
import '../../data/models/user_profile.dart';

/// Full event context passed to retrieval and companion services.
class CompanionContext {
  const CompanionContext({
    required this.query,
    required this.sessions,
    required this.speakers,
    required this.venues,
    required this.tracks,
    required this.amenities,
    required this.profile,
    this.meta,
    this.campus,
    this.navigationHints = const [],
    this.plannedSessions = const [],
    this.now,
    this.currentDay,
    this.priorQueries = const [],
    this.lastReferencedSessionId,
    this.minutesUntil,
    this.conflicts = const [],
  });

  final String query;
  final List<Session> sessions;
  final List<Speaker> speakers;
  final List<Venue> venues;
  final List<Track> tracks;
  final List<Amenity> amenities;
  final UserProfile profile;
  final EventMeta? meta;
  final CampusLayout? campus;
  final List<NavigationHint> navigationHints;
  final List<Session> plannedSessions;
  final DateTime? now;
  final String? currentDay;
  final List<String> priorQueries;
  final String? lastReferencedSessionId;
  final int Function(Session session)? minutesUntil;
  final List<PlanConflict> conflicts;
}

class PlanSnapshot {
  const PlanSnapshot({
    this.nextSession,
    this.minutesUntilNext,
    this.leaveInMinutes,
    this.conflictCount = 0,
  });

  final Session? nextSession;
  final int? minutesUntilNext;
  final int? leaveInMinutes;
  final int conflictCount;
}

class CompanionKnowledgePack {
  const CompanionKnowledgePack({
    this.sessions = const [],
    this.speakers = const [],
    this.venues = const [],
    this.amenities = const [],
    this.floorStories = const [],
    this.navigationHints = const [],
    this.planSnapshot,
  });

  final List<Session> sessions;
  final List<Speaker> speakers;
  final List<Venue> venues;
  final List<Amenity> amenities;
  final List<String> floorStories;
  final List<NavigationHint> navigationHints;
  final PlanSnapshot? planSnapshot;

  Set<String> get sessionIds => sessions.map((s) => s.id).toSet();
  Set<String> get venueIds => venues.map((v) => v.id).toSet();
  Set<String> get amenityIds => amenities.map((a) => a.id).toSet();
}
