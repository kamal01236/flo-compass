import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/data/repositories/mock_prompt_curation_repository.dart';
import 'package:flo_compass/data/repositories/mock_session_qa_repository.dart';

import '../../support/test_audit_actor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists prompt overrides and resets to seed', () async {
    final prefs = await SharedPreferences.getInstance();
    final curation = MockPromptCurationRepository(prefs: prefs);
    final qa = MockSessionQaRepository(prefs: prefs);

    final seedPrompts = await curation.promptsForSession('s-001');
    expect(seedPrompts, isNotEmpty);

    await curation.saveSessionPrompts('s-001', [
      'What surprised you most?',
      'What would you do differently?',
    ], actor: testAuditActor);

    final overridden = await curation.promptsForSession('s-001');
    expect(overridden, [
      'What surprised you most?',
      'What would you do differently?',
    ]);

    final bundle = await qa.loadQuestions('s-001');
    expect(bundle.prompts, overridden);

    await curation.resetSessionPrompts('s-001', actor: testAuditActor);
    final restored = await curation.promptsForSession('s-001');
    expect(restored, seedPrompts);
  });

  test('lists all prompt sets from seed and overrides', () async {
    final prefs = await SharedPreferences.getInstance();
    final curation = MockPromptCurationRepository(prefs: prefs);

    final sets = await curation.listAllPromptSets();
    expect(sets.keys, containsAll(['s-001', 's-014']));
    expect(sets['s-001'], isNotEmpty);
  });
}
