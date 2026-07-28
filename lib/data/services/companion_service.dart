import '../models/models.dart';
import 'companion_knowledge_retriever.dart';
import 'llm_companion_service.dart';
import 'rule_based_companion_service.dart';

/// Facade: tries optional LLM path, always falls back to rule-based search.
class CompanionService {
  CompanionService({
    RuleBasedCompanionService? ruleBased,
    LlmCompanionService? llm,
    CompanionKnowledgeRetriever? retriever,
  }) : _ruleBased = ruleBased ?? RuleBasedCompanionService(),
       _llm = llm ?? LlmCompanionService(),
       _retriever = retriever ?? CompanionKnowledgeRetriever();

  final RuleBasedCompanionService _ruleBased;
  final LlmCompanionService _llm;
  final CompanionKnowledgeRetriever _retriever;

  Future<CompanionMessage> answer({
    required CompanionContext context,
    bool preferLlm = true,
  }) async {
    final pack = _retriever.retrieve(context);
    if (preferLlm) {
      return _llm.answer(context: context, pack: pack);
    }
    return _ruleBased.answer(context: context, pack: pack);
  }
}
