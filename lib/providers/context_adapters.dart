import '../data/models/user_profile.dart';
import '../domain/inputs/day_planner_context.dart';
import '../domain/inputs/navigation_search_context.dart';
import '../domain/inputs/recommendation_context.dart';
import 'event_provider.dart';
import 'plan_provider.dart';
import 'profile_provider.dart';

RecommendationContext buildRecommendationContext({
  required ProfileState profile,
  required PlanState plan,
  required EventState event,
}) {
  return RecommendationContext(
    profile: profile.profile,
    plannedSessionIds: plan.sessionIds,
    sessions: event.sessions,
    speakers: event.speakers,
    tracks: event.tracks,
    rankedSessions: event.rankedSessions(profile.profile),
    happeningNow: event.happeningNow(),
    currentTime: event.currentTime,
    currentDay: event.currentDay,
    behaviorSnapshot: event.behaviorSnapshot,
  );
}

DayPlannerContext buildDayPlannerContext({
  required String day,
  required PlanState plan,
  required EventState event,
  ProfileState? profile,
}) {
  return DayPlannerContext(
    day: day,
    plannedSessionIds: plan.sessionIds,
    sessions: event.sessions,
    speakers: event.speakers,
    tracks: event.tracks,
    profile: profile?.profile ?? UserProfile.empty,
    currentTime: event.currentTime,
    behaviorSnapshot: event.behaviorSnapshot,
  );
}

NavigationSearchContext buildNavigationSearchContext(EventState event) {
  return NavigationSearchContext(
    sessions: event.sessions,
    speakers: event.speakers,
    venues: event.venues,
    tracks: event.tracks,
  );
}
