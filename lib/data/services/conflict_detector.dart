import '../models/models.dart';

class ConflictDetector {
  List<PlanConflict> findConflicts(List<Session> planned) {
    final conflicts = <PlanConflict>[];
    for (var i = 0; i < planned.length; i++) {
      for (var j = i + 1; j < planned.length; j++) {
        final a = planned[i];
        final b = planned[j];
        if (a.day == b.day && _overlaps(a, b)) {
          conflicts.add(PlanConflict(sessionA: a, sessionB: b));
        }
      }
    }
    return conflicts;
  }

  bool _overlaps(Session a, Session b) {
    final aStart = _minutes(a.startTime);
    final aEnd = _minutes(a.endTime);
    final bStart = _minutes(b.startTime);
    final bEnd = _minutes(b.endTime);
    return aStart < bEnd && bStart < aEnd;
  }

  int _minutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
