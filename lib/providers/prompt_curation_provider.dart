import 'package:flutter/foundation.dart';

import '../core/auth/audit_actor_resolver.dart';
import '../core/di/service_locator.dart';
import '../data/repositories/mock_prompt_curation_repository.dart';
import '../data/services/audit_log_service.dart';
import '../domain/repositories/prompt_curation_repository.dart';
import 'ops_config_provider.dart';

PromptCurationRepository _defaultPromptCurationRepository() {
  if (sl.isRegistered<PromptCurationRepository>()) {
    return sl<PromptCurationRepository>();
  }
  return MockPromptCurationRepository();
}

class PromptCurationState extends ChangeNotifier {
  PromptCurationState({PromptCurationRepository? repository})
    : _repository = repository ?? _defaultPromptCurationRepository();

  final PromptCurationRepository _repository;

  bool loading = false;
  String? error;
  Map<String, List<String>> promptSets = {};

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      promptSets = await _repository.listAllPromptSets();
    } catch (e) {
      error = kDebugMode ? '$e' : 'Failed to load prompts';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<List<String>> promptsForSession(String sessionId) {
    return _repository.promptsForSession(sessionId);
  }

  Future<void> saveSessionPrompts(
    String sessionId,
    List<String> prompts,
  ) async {
    final actor = resolveAuditActor();
    await _repository.saveSessionPrompts(sessionId, prompts, actor: actor);
    await load();
    await recordAudit(
      action: AuditActions.qaPromptSave,
      entityType: 'session',
      entityId: sessionId,
    );
  }

  Future<void> resetSessionPrompts(String sessionId) async {
    final actor = resolveAuditActor();
    await _repository.resetSessionPrompts(sessionId, actor: actor);
    await load();
    await recordAudit(
      action: AuditActions.qaPromptReset,
      entityType: 'session',
      entityId: sessionId,
    );
  }
}
