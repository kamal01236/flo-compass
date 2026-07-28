import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/core/config/auth_config.dart';
import 'package:flo_compass/core/config/runtime_config.dart';
import 'package:flo_compass/data/repositories/mock_session_qa_repository.dart';

import '../../support/test_audit_actor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RuntimeConfig.auth = AuthConfig.disabled;
  });

  test('persists moderation flags for seeded questions', () async {
    final prefs = await SharedPreferences.getInstance();
    final repository = MockSessionQaRepository(prefs: prefs);
    final before = await repository.loadQuestions('s-001');
    final target = before.questions.first;

    await repository.setQuestionPinned(target.id, true, actor: testAuditActor);
    await repository.setQuestionHidden(target.id, true, actor: testAuditActor);
    await repository.setQuestionAnswered(
      target.id,
      true,
      actor: testAuditActor,
    );

    final after = await repository.loadQuestions('s-001');
    final updated = after.questions.firstWhere((q) => q.id == target.id);
    expect(updated.pinned, isTrue);
    expect(updated.hidden, isTrue);
    expect(updated.answered, isTrue);
  });

  test('persists moderation flags for custom questions', () async {
    final prefs = await SharedPreferences.getInstance();
    final repository = MockSessionQaRepository(prefs: prefs);

    final created = await repository.addQuestion(
      's-001',
      'Can we get slides?',
      actor: testAuditActor,
    );
    expect(created.authorId, testAuditActor.id);

    await repository.setQuestionHidden(created.id, true, actor: testAuditActor);
    await repository.setQuestionPinned(created.id, true, actor: testAuditActor);

    final after = await repository.loadQuestions('s-001');
    final updated = after.questions.firstWhere((q) => q.id == created.id);
    expect(updated.hidden, isTrue);
    expect(updated.pinned, isTrue);
  });

  test('loadModerationStats counts pending and hidden questions', () async {
    final prefs = await SharedPreferences.getInstance();
    final repository = MockSessionQaRepository(prefs: prefs);

    final before = await repository.loadModerationStats();
    expect(before.totalCount, greaterThan(0));
    expect(before.pendingCount, greaterThan(0));

    final target = (await repository.loadQuestions(
      's-001',
    )).questions.firstWhere((q) => !q.answered);
    await repository.setQuestionHidden(target.id, true, actor: testAuditActor);

    final after = await repository.loadModerationStats();
    expect(after.hiddenCount, greaterThan(before.hiddenCount));
    expect(after.pendingCount, lessThan(before.pendingCount));
  });
}
