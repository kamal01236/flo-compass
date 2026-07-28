import '../entities/audit_actor.dart';
import '../entities/session_qa.dart';
import '../entities/session_qa_moderation_stats.dart';

abstract class SessionQaRepository {
  Future<SessionQaBundle> loadQuestions(String sessionId);
  Future<SessionQaModerationStats> loadModerationStats();
  Future<SessionQuestion> addQuestion(
    String sessionId,
    String question, {
    required AuditActor actor,
    String? authorName,
  });
  Future<SessionReply> addReply(
    String questionId,
    String message, {
    required AuditActor actor,
    String? authorName,
  });
  Future<bool> toggleVote(String questionId, {required AuditActor actor});
  Future<void> setQuestionAnswered(
    String questionId,
    bool answered, {
    required AuditActor actor,
  });
  Future<void> setQuestionPinned(
    String questionId,
    bool pinned, {
    required AuditActor actor,
  });
  Future<void> setQuestionHidden(
    String questionId,
    bool hidden, {
    required AuditActor actor,
  });
}
