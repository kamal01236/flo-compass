/// Human-readable countdown labels for session start/end times.
abstract final class CountdownFormat {
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Formats minutes until a session starts.
  ///
  /// When [target] and [now] are provided, labels beyond 12 hours use
  /// calendar context (`Tomorrow · 11:00`, `Wed · 14:30`).
  static String formatUntil(int minutes, {DateTime? now, DateTime? target}) {
    if (minutes <= 0) return 'Starting soon';
    if (minutes < 60) return 'Starts in ${minutes}m';
    if (minutes < 12 * 60) return 'Starts in ${_hoursMinutes(minutes)}';

    if (target != null && now != null) {
      final targetDate = DateTime(target.year, target.month, target.day);
      final nowDate = DateTime(now.year, now.month, now.day);
      final dayDiff = targetDate.difference(nowDate).inDays;
      final timeStr = _formatClock(target);

      if (dayDiff == 1) return 'Tomorrow · $timeStr';
      if (dayDiff > 1) {
        return '${_weekdays[target.weekday - 1]} · $timeStr';
      }
    }

    return 'Starts in ${_hoursMinutes(minutes)}';
  }

  /// Formats minutes remaining until a session ends.
  static String formatRemaining(int minutes) {
    if (minutes <= 0) return 'Ending soon';
    if (minutes < 60) return 'Ends in ${minutes}m';
    return 'Ends in ${_hoursMinutes(minutes)}';
  }

  /// Maps venue wing codes to display labels.
  static String wingLabel(String wing) {
    return switch (wing.toLowerCase()) {
      'n' => 'North',
      's' => 'South',
      'c' || 'central' => 'Central',
      _ => wing,
    };
  }

  static String _hoursMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  static String _formatClock(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
