import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/domain/entities/audit_actor.dart';
import 'package:flo_compass/domain/entities/session_qa.dart';
import 'package:flo_compass/domain/entities/session_qa_moderation_stats.dart';
import 'package:flo_compass/domain/repositories/session_qa_repository.dart';
import 'package:flo_compass/providers/session_qa_provider.dart';

void main() {
  group('SessionQaState moderation', () {
    test('supports moderation transitions and attendee filtering', () async {
      final repository = _FakeSessionQaRepository();
      final state = SessionQaState(repository: repository);

      await state.load('s-001');

      expect(state.visibleQuestions.map((question) => question.id), [
        'q-pinned',
        'q-open',
      ]);
      expect(
        state
            .visibleQuestionsForRole(includeHidden: true)
            .map((question) => question.id),
        ['q-pinned', 'q-open', 'q-hidden'],
      );

      await state.setQuestionPinned('q-open', true);
      state.setSort(SessionQaSort.newest);
      expect(
        state.visibleQuestions.map((question) => question.id).first,
        'q-open',
      );

      await state.setQuestionAnswered('q-open', true);
      state.setSort(SessionQaSort.unanswered);
      expect(state.visibleQuestions.map((question) => question.id), [
        'q-pinned',
      ]);

      await state.setQuestionHidden('q-pinned', true);
      state.setSort(SessionQaSort.top);
      expect(state.visibleQuestions.map((question) => question.id), ['q-open']);
      expect(
        state
            .visibleQuestionsForRole(includeHidden: true)
            .map((question) => question.id),
        ['q-pinned', 'q-open', 'q-hidden'],
      );
    });
  });
}

class _FakeSessionQaRepository implements SessionQaRepository {
  final Map<String, SessionQuestion> _questions = {
    'q-pinned': SessionQuestion(
      id: 'q-pinned',
      sessionId: 's-001',
      authorName: 'Priya',
      question: 'Pinned question',
      createdAt: DateTime(2026, 1, 1, 10, 0),
      upvotes: 9,
      replies: const [],
      answered: false,
      pinned: true,
    ),
    'q-open': SessionQuestion(
      id: 'q-open',
      sessionId: 's-001',
      authorName: 'Anya',
      question: 'Open question',
      createdAt: DateTime(2026, 1, 1, 11, 0),
      upvotes: 2,
      replies: const [],
      answered: false,
    ),
    'q-hidden': SessionQuestion(
      id: 'q-hidden',
      sessionId: 's-001',
      authorName: 'Dev',
      question: 'Hidden question',
      createdAt: DateTime(2026, 1, 1, 9, 0),
      upvotes: 1,
      replies: const [],
      answered: false,
      hidden: true,
    ),
  };

  @override
  Future<SessionQuestion> addQuestion(
    String sessionId,
    String question, {
    required AuditActor actor,
    String? authorName,
  }) async {
    final created = SessionQuestion(
      id: 'q-${_questions.length + 1}',
      sessionId: sessionId,
      authorName: authorName ?? 'You',
      authorId: actor.id,
      question: question,
      createdAt: DateTime.now(),
      upvotes: 0,
      replies: const [],
      answered: false,
    );
    _questions[created.id] = created;
    return created;
  }

  @override
  Future<SessionReply> addReply(
    String questionId,
    String message, {
    required AuditActor actor,
    String? authorName,
  }) async {
    final reply = SessionReply(
      id: 'r-${DateTime.now().millisecondsSinceEpoch}',
      questionId: questionId,
      authorName: authorName ?? 'You',
      authorId: actor.id,
      message: message,
      createdAt: DateTime.now(),
    );
    final question = _questions[questionId];
    if (question != null) {
      _questions[questionId] = question.copyWith(
        replies: [...question.replies, reply],
        answered: true,
      );
    }
    return reply;
  }

  @override
  Future<SessionQaModerationStats> loadModerationStats() async {
    var pending = 0;
    var hidden = 0;
    final pendingBySession = <String, int>{};
    for (final question in _questions.values) {
      if (question.hidden) {
        hidden++;
        continue;
      }
      if (!question.answered) {
        pending++;
        pendingBySession.update(
          question.sessionId,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    return SessionQaModerationStats(
      pendingCount: pending,
      hiddenCount: hidden,
      totalCount: _questions.length,
      pendingBySession: pendingBySession,
    );
  }

  @override
  Future<SessionQaBundle> loadQuestions(String sessionId) async {
    final list = _questions.values
        .where((question) => question.sessionId == sessionId)
        .toList();
    return SessionQaBundle(prompts: const [], questions: list);
  }

  @override
  Future<void> setQuestionAnswered(
    String questionId,
    bool answered, {
    required AuditActor actor,
  }) async {
    final question = _questions[questionId];
    if (question == null) return;
    _questions[questionId] = question.copyWith(answered: answered);
  }

  @override
  Future<void> setQuestionHidden(
    String questionId,
    bool hidden, {
    required AuditActor actor,
  }) async {
    final question = _questions[questionId];
    if (question == null) return;
    _questions[questionId] = question.copyWith(hidden: hidden);
  }

  @override
  Future<void> setQuestionPinned(
    String questionId,
    bool pinned, {
    required AuditActor actor,
  }) async {
    final question = _questions[questionId];
    if (question == null) return;
    _questions[questionId] = question.copyWith(pinned: pinned);
  }

  @override
  Future<bool> toggleVote(
    String questionId, {
    required AuditActor actor,
  }) async {
    final question = _questions[questionId];
    if (question == null) return false;
    final nextUpvoted = !question.viewerHasUpvoted;
    _questions[questionId] = question.copyWith(
      viewerHasUpvoted: nextUpvoted,
      upvotes: nextUpvoted ? question.upvotes + 1 : question.upvotes - 1,
    );
    return nextUpvoted;
  }
}
