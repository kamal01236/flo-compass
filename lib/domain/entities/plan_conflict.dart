import 'session.dart';

class PlanConflict {
  const PlanConflict({required this.sessionA, required this.sessionB});

  final Session sessionA;
  final Session sessionB;
}
