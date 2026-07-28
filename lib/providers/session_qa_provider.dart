import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/auth/audit_actor_resolver.dart';
import '../core/di/service_locator.dart';
import '../data/models/models.dart';
import '../data/repositories/mock_session_qa_repository.dart';
import '../data/services/audit_log_service.dart';
import '../domain/repositories/session_qa_repository.dart';
import 'ops_config_provider.dart';

SessionQaRepository _defaultSessionQaRepository() {
  if (sl.isRegistered<SessionQaRepository>()) {
    return sl<SessionQaRepository>();
  }
  return MockSessionQaRepository();
}

enum SessionQaSort { top, newest, unanswered }

extension SessionQaSortX on SessionQaSort {
  String get label => switch (this) {
    SessionQaSort.top => 'Top',
    SessionQaSort.newest => 'New',
    SessionQaSort.unanswered => 'Unanswered',
  };
}

const sessionQaSortModes = SessionQaSort.values;

class SessionQaState extends ChangeNotifier {
  SessionQaState({SessionQaRepository? repository})
    : _repository = repository ?? _defaultSessionQaRepository();

  final SessionQaRepository _repository;

  bool loading = false;
  String? error;
  String? sessionId;
  List<SessionQuestion> questions = [];
  List<String> prompts = [];
  SessionQaSort sort = SessionQaSort.top;
  final Set<String> expandedQuestionIds = {};

  List<SessionQuestion> visibleQuestionsForRole({required bool includeHidden}) {
    final items = [
      for (final question in questions)
        if (includeHidden || !question.hidden) question,
    ];
    switch (sort) {
      case SessionQaSort.top:
        _sortPinnedThen(items, (a, b) => b.upvotes.compareTo(a.upvotes));
      case SessionQaSort.newest:
        _sortPinnedThen(items, (a, b) => b.createdAt.compareTo(a.createdAt));
      case SessionQaSort.unanswered:
        items.removeWhere((q) => q.answered);
        _sortPinnedThen(items, (a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return items;
  }

  List<SessionQuestion> get visibleQuestions =>
      visibleQuestionsForRole(includeHidden: false);

  Future<void> load(String nextSessionId) async {
    if (sessionId == nextSessionId && questions.isNotEmpty) return;
    sessionId = nextSessionId;
    expandedQuestionIds.clear();
    await _fetch();
  }

  Future<void> refresh() async {
    if (sessionId == null) return;
    await _fetch();
  }

  void setSort(SessionQaSort next) {
    if (sort == next) return;
    sort = next;
    notifyListeners();
  }

  void toggleExpanded(String questionId) {
    if (expandedQuestionIds.contains(questionId)) {
      expandedQuestionIds.remove(questionId);
    } else {
      expandedQuestionIds.add(questionId);
    }
    notifyListeners();
  }

  Future<SessionQuestion?> addQuestion(String question) async {
    if (sessionId == null) return null;
    final actor = resolveAuditActor();
    final created = await _repository.addQuestion(
      sessionId!,
      question,
      actor: actor,
    );
    questions = [...questions, created];
    notifyListeners();
    await recordAudit(
      action: AuditActions.qaAsk,
      entityType: 'question',
      entityId: created.id,
      metadata: {'sessionId': sessionId},
    );
    return created;
  }

  Future<SessionReply?> addReply(String questionId, String message) async {
    final actor = resolveAuditActor();
    final reply = await _repository.addReply(questionId, message, actor: actor);
    final index = questions.indexWhere((q) => q.id == questionId);
    if (index != -1) {
      final target = questions[index];
      final updated = target.copyWith(
        replies: [...target.replies, reply],
        answered: true,
      );
      final next = [...questions];
      next[index] = updated;
      questions = next;
      notifyListeners();
    }
    await recordAudit(
      action: AuditActions.qaReply,
      entityType: 'question',
      entityId: questionId,
      metadata: {'replyId': reply.id},
    );
    return reply;
  }

  Future<bool> toggleVote(String questionId) async {
    final actor = resolveAuditActor();
    final nowUpvoted = await _repository.toggleVote(questionId, actor: actor);
    final index = questions.indexWhere((q) => q.id == questionId);
    if (index == -1) return nowUpvoted;
    final target = questions[index];
    final updated = target.copyWith(
      upvotes: max(0, target.upvotes + (nowUpvoted ? 1 : -1)),
      viewerHasUpvoted: nowUpvoted,
    );
    final next = [...questions];
    next[index] = updated;
    questions = next;
    notifyListeners();
    await recordAudit(
      action: nowUpvoted ? AuditActions.qaUpvote : AuditActions.qaUnupvote,
      entityType: 'question',
      entityId: questionId,
    );
    return nowUpvoted;
  }

  Future<void> setQuestionAnswered(String questionId, bool answered) async {
    final actor = resolveAuditActor();
    await _repository.setQuestionAnswered(questionId, answered, actor: actor);
    _updateQuestion(
      questionId,
      (target) => target.copyWith(answered: answered),
    );
    await recordAudit(
      action: answered
          ? AuditActions.qaMarkAnswered
          : AuditActions.qaMarkUnanswered,
      entityType: 'question',
      entityId: questionId,
    );
  }

  Future<void> setQuestionPinned(String questionId, bool pinned) async {
    final actor = resolveAuditActor();
    await _repository.setQuestionPinned(questionId, pinned, actor: actor);
    _updateQuestion(questionId, (target) => target.copyWith(pinned: pinned));
    await recordAudit(
      action: pinned ? AuditActions.qaPin : AuditActions.qaUnpin,
      entityType: 'question',
      entityId: questionId,
    );
  }

  Future<void> setQuestionHidden(String questionId, bool hidden) async {
    final actor = resolveAuditActor();
    await _repository.setQuestionHidden(questionId, hidden, actor: actor);
    _updateQuestion(questionId, (target) => target.copyWith(hidden: hidden));
    await recordAudit(
      action: hidden ? AuditActions.qaHide : AuditActions.qaUnhide,
      entityType: 'question',
      entityId: questionId,
    );
  }

  Future<void> _fetch() async {
    if (sessionId == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final bundle = await _repository.loadQuestions(sessionId!);
      questions = bundle.questions;
      prompts = bundle.prompts;
    } catch (e) {
      error = kDebugMode ? '$e' : 'Failed to load Q&A';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _sortPinnedThen(
    List<SessionQuestion> items,
    int Function(SessionQuestion a, SessionQuestion b) compareBody,
  ) {
    items.sort((a, b) {
      if (a.pinned != b.pinned) {
        return a.pinned ? -1 : 1;
      }
      return compareBody(a, b);
    });
  }

  void _updateQuestion(
    String questionId,
    SessionQuestion Function(SessionQuestion target) mutate,
  ) {
    final index = questions.indexWhere((q) => q.id == questionId);
    if (index == -1) return;
    final next = [...questions];
    next[index] = mutate(next[index]);
    questions = next;
    notifyListeners();
  }
}
