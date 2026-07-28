import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/services/achievement_service.dart';

void main() {
  group('AchievementService.unlockedFromIds', () {
    test('returns empty list for empty input', () {
      expect(AchievementService.unlockedFromIds([]), isEmpty);
    });

    test('ignores unknown achievement ids', () {
      final unlocked = AchievementService.unlockedFromIds([
        'keynote_hunter',
        'bogus_legacy_id',
        'cursor_ninja',
      ]);

      expect(unlocked.map((a) => a.id), ['keynote_hunter', 'cursor_ninja']);
    });

    test('preserves input order for known ids', () {
      final unlocked = AchievementService.unlockedFromIds([
        'marathon',
        'early_bird',
        'flo_explorer',
      ]);

      expect(unlocked.map((a) => a.id), [
        'marathon',
        'early_bird',
        'flo_explorer',
      ]);
    });
  });
}
