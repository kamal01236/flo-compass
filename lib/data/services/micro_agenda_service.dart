import '../models/models.dart';
import '../models/user_profile.dart';
import 'event_clock_service.dart';
import '../../providers/event_provider.dart';
import '../../providers/plan_provider.dart';

/// Sessions in the next [windowMinutes] — planned first, then top ranked picks.
class MicroAgendaService {
  MicroAgendaService({EventClockService? clockService})
    : _clockService = clockService ?? EventClockService();

  final EventClockService _clockService;

  List<Session> nextTwoHours({
    required EventState event,
    required PlanState plan,
    required UserProfile profile,
    int windowMinutes = 120,
    int cap = 6,
  }) {
    final planned = plan.plannedSessions(event.sessions);
    final plannedInWindow = planned.where((s) {
      final until = _clockService.minutesUntil(s);
      return until >= 0 && until <= windowMinutes;
    }).toList();

    final plannedIds = planned.map((s) => s.id).toSet();
    final ranked = event
        .rankedSessions(profile)
        .map((scored) => scored.session)
        .where((s) => !plannedIds.contains(s.id))
        .where((s) {
          final until = _clockService.minutesUntil(s);
          return until >= 0 && until <= windowMinutes;
        })
        .take(2)
        .toList();

    final merged = <Session>[...plannedInWindow, ...ranked];
    merged.sort((a, b) {
      final day = a.dayNumber.compareTo(b.dayNumber);
      if (day != 0) return day;
      return a.startTime.compareTo(b.startTime);
    });

    final seen = <String>{};
    final deduped = <Session>[];
    for (final session in merged) {
      if (seen.add(session.id)) {
        deduped.add(session);
      }
    }
    return deduped.take(cap).toList();
  }

  bool shouldShowForSession(Session session, {int windowMinutes = 120}) {
    final until = _clockService.minutesUntil(session);
    return until >= -30 && until <= windowMinutes;
  }
}
