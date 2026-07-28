import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/providers/plan_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('mergeSessions unions and dedupes ids', () async {
    final plan = PlanState(prefs: prefs);
    await plan.init();
    await plan.toggle('s-001');
    await plan.toggle('s-002');

    final result = await plan.mergeSessions(['s-002', 's-003', 's-003']);

    expect(result.importedCount, 2);
    expect(result.newCount, 1);
    expect(plan.sessionIds, {'s-001', 's-002', 's-003'});
  });

  test('replaceSessions clears existing plan', () async {
    final plan = PlanState(prefs: prefs);
    await plan.init();
    await plan.toggle('s-001');
    await plan.toggle('s-002');

    final result = await plan.replaceSessions(['s-010', 's-011']);

    expect(result.importedCount, 2);
    expect(result.newCount, 2);
    expect(plan.sessionIds, {'s-010', 's-011'});
  });
}
