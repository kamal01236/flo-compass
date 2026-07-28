/// Flo 2026 event window constants (Nagarro Gurgaon Office).
abstract final class EventDates {
  static final DateTime eventStart = DateTime(2026, 11, 4);
  static final DateTime eventEndExclusive = DateTime(2026, 11, 7);

  static DateTime dateForDay(String day) {
    return switch (day) {
      'Day 1' => DateTime(2026, 11, 4),
      'Day 2' => DateTime(2026, 11, 5),
      'Day 3' => DateTime(2026, 11, 6),
      _ => DateTime(2026, 11, 4),
    };
  }
}
