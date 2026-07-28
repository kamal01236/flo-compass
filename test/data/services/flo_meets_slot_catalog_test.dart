import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/services/flo_meets_slot_catalog.dart';

void main() {
  group('FloMeetsSlotCatalog', () {
    test('defines six slots per day', () {
      expect(FloMeetsSlotCatalog.slotsForDay('Day 1'), hasLength(6));
    });

    test('slot keys follow Day_N_HHMM pattern', () {
      final keys = FloMeetsSlotCatalog.slotsForDay('Day 1').map((s) => s.key);
      expect(keys, contains('Day_1_0800'));
      expect(keys, contains('Day_1_1800'));
    });

    test('T-30 match run at 07:30 for 08:00 slot on Day 1', () {
      final slot = FloMeetsSlotCatalog.slotByKey('Day_1_0800')!;
      final now = DateTime(2026, 11, 4, 7, 30);
      expect(FloMeetsSlotCatalog.isMatchRunMinute(now, slot, 'Day 1'), isTrue);
      expect(
        FloMeetsSlotCatalog.slotDueForMatching(now, 'Day 1')?.key,
        'Day_1_0800',
      );
    });

    test('no slot due outside match minute', () {
      final now = DateTime(2026, 11, 4, 7, 45);
      expect(FloMeetsSlotCatalog.slotDueForMatching(now, 'Day 1'), isNull);
    });
  });
}
