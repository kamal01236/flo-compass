import '../../data/models/models.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/behavior_signal_service.dart';

/// Primitive inputs for recommendation helpers — assembled by providers/widgets.
class RecommendationContext {
  const RecommendationContext({
    required this.profile,
    required this.plannedSessionIds,
    required this.sessions,
    required this.speakers,
    required this.tracks,
    required this.rankedSessions,
    required this.happeningNow,
    this.currentTime,
    this.currentDay,
    this.behaviorSnapshot,
  });

  final UserProfile profile;
  final Set<String> plannedSessionIds;
  final List<Session> sessions;
  final List<Speaker> speakers;
  final List<Track> tracks;
  final List<ScoredSession> rankedSessions;
  final List<Session> happeningNow;
  final DateTime? currentTime;
  final String? currentDay;
  final BehaviorSnapshot? behaviorSnapshot;

  bool isInPlan(String sessionId) => plannedSessionIds.contains(sessionId);

  List<Session> plannedSessions() {
    return sessions.where((s) => plannedSessionIds.contains(s.id)).toList();
  }
}
