import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/features/discover/discover_filters.dart';
import 'package:flo_compass/providers/plan_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('plan provider toggles sessions', () async {
    final plan = PlanState(prefs: prefs);
    await plan.init();

    const sessionId = 's-001';
    expect(plan.isInPlan(sessionId), isFalse);

    await plan.toggle(sessionId);
    expect(plan.isInPlan(sessionId), isTrue);

    await plan.toggle(sessionId);
    expect(plan.isInPlan(sessionId), isFalse);
  });

  test('DiscoverFilters loads day and floor from deep link URI', () {
    final filters = DiscoverFilters.fromUri(
      Uri.parse('/discover?day=Day%201&floor=7&track=track-genai'),
    );
    expect(filters.day, 'Day 1');
    expect(filters.floor, '7');
    expect(filters.track, 'track-genai');
  });
}
