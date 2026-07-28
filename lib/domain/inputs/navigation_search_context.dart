import '../../data/models/models.dart';
import '../../shared/utils/now_next_resolver.dart';

/// Search corpus for command palette / navigation search — no provider types.
class NavigationSearchContext {
  const NavigationSearchContext({
    required this.sessions,
    required this.speakers,
    required this.venues,
    required this.tracks,
    this.plannedSessionIds = const {},
    this.nowNext,
  });

  final List<Session> sessions;
  final List<Speaker> speakers;
  final List<Venue> venues;
  final List<Track> tracks;
  final Set<String> plannedSessionIds;
  final NowNextResult? nowNext;

  Speaker? speakerById(String id) {
    for (final s in speakers) {
      if (s.id == id) return s;
    }
    return null;
  }

  Venue? venueById(String id) {
    for (final v in venues) {
      if (v.id == id) return v;
    }
    return null;
  }

  Track? trackById(String id) {
    for (final t in tracks) {
      if (t.id == id) return t;
    }
    return null;
  }
}
