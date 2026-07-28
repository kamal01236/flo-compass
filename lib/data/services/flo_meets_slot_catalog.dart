/// Fixed 1-hour Flo Meets availability slots with T−30 matching windows.
class FloMeetSlot {
  const FloMeetSlot({
    required this.key,
    required this.day,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  final String key;
  final String day;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  String get label {
    final start = _formatTime(startHour, startMinute);
    final end = _formatTime(endHour, endMinute);
    return '$start – $end';
  }

  static String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class FloMeetsSlotCatalog {
  FloMeetsSlotCatalog._();

  static const _slotTemplates = [
    (0800, 0900),
    (0900, 1000),
    (1200, 1300),
    (1300, 1400),
    (1700, 1800),
    (1800, 1900),
  ];

  static const days = ['Day 1', 'Day 2', 'Day 3'];

  static List<FloMeetSlot> allSlots() {
    final slots = <FloMeetSlot>[];
    for (final day in days) {
      slots.addAll(slotsForDay(day));
    }
    return slots;
  }

  static List<FloMeetSlot> slotsForDay(String day) {
    final dayNum = _dayNumber(day);
    return _slotTemplates.map((template) {
      final start = template.$1;
      final end = template.$2;
      return FloMeetSlot(
        key: 'Day_${dayNum}_${start.toString().padLeft(4, '0')}',
        day: day,
        startHour: start ~/ 100,
        startMinute: start % 100,
        endHour: end ~/ 100,
        endMinute: end % 100,
      );
    }).toList();
  }

  static FloMeetSlot? slotByKey(String key) {
    for (final slot in allSlots()) {
      if (slot.key == key) return slot;
    }
    return null;
  }

  /// Returns the slot whose T−30 match window includes [now] (same minute).
  static FloMeetSlot? slotDueForMatching(DateTime now, String? eventDay) {
    if (eventDay == null) return null;
    for (final slot in slotsForDay(eventDay)) {
      if (isMatchRunMinute(now, slot, eventDay)) return slot;
    }
    return null;
  }

  static bool isMatchRunMinute(
    DateTime now,
    FloMeetSlot slot,
    String eventDay,
  ) {
    final dayDate = _dayToDate(eventDay);
    final matchAt = DateTime(
      dayDate.year,
      dayDate.month,
      dayDate.day,
      slot.startHour,
      slot.startMinute,
    ).subtract(const Duration(minutes: 30));
    return now.year == matchAt.year &&
        now.month == matchAt.month &&
        now.day == matchAt.day &&
        now.hour == matchAt.hour &&
        now.minute == matchAt.minute;
  }

  static DateTime windowStart(FloMeetSlot slot, String eventDay) {
    final dayDate = _dayToDate(eventDay);
    return DateTime(
      dayDate.year,
      dayDate.month,
      dayDate.day,
      slot.startHour,
      slot.startMinute,
    );
  }

  static DateTime windowEnd(FloMeetSlot slot, String eventDay) {
    final dayDate = _dayToDate(eventDay);
    return DateTime(
      dayDate.year,
      dayDate.month,
      dayDate.day,
      slot.endHour,
      slot.endMinute,
    );
  }

  static DateTime matchRunAt(FloMeetSlot slot, String eventDay) {
    return windowStart(slot, eventDay).subtract(const Duration(minutes: 30));
  }

  static int _dayNumber(String day) => switch (day) {
    'Day 1' => 1,
    'Day 2' => 2,
    'Day 3' => 3,
    _ => 1,
  };

  static DateTime _dayToDate(String day) => switch (day) {
    'Day 1' => DateTime(2026, 11, 4),
    'Day 2' => DateTime(2026, 11, 5),
    'Day 3' => DateTime(2026, 11, 6),
    _ => DateTime(2026, 11, 4),
  };
}
