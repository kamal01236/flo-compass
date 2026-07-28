import '../entities/audit_actor.dart';

abstract class PromptCurationRepository {
  Future<Map<String, List<String>>> listAllPromptSets();
  Future<List<String>> promptsForSession(String sessionId);
  Future<void> saveSessionPrompts(
    String sessionId,
    List<String> prompts, {
    required AuditActor actor,
  });
  Future<void> resetSessionPrompts(
    String sessionId, {
    required AuditActor actor,
  });
}
