import '../../data/models/models.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/behavior_signal_service.dart';

/// Inputs for afternoon gap filling — no provider types.
class DayPlannerContext {
  const DayPlannerContext({
    required this.day,
    required this.plannedSessionIds,
    required this.sessions,
    required this.speakers,
    required this.tracks,
    required this.profile,
    this.currentTime,
    this.behaviorSnapshot,
  });

  final String day;
  final Set<String> plannedSessionIds;
  final List<Session> sessions;
  final List<Speaker> speakers;
  final List<Track> tracks;
  final UserProfile profile;
  final DateTime? currentTime;
  final BehaviorSnapshot? behaviorSnapshot;
}
