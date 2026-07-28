import 'session.dart';

class ScoredSession {
  const ScoredSession({
    required this.session,
    required this.score,
    required this.matchReasons,
  });

  final Session session;
  final double score;
  final List<String> matchReasons;
}
