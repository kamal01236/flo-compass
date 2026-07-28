import 'package:intl/intl.dart';

import '../../domain/entities/event_meta.dart';
import '../../domain/entities/session.dart';

/// Dual timezone line: venue/event TZ (IST) plus viewer-local offset.
String formatSessionTimeDisplay({
  required Session session,
  EventMeta? meta,
  DateTime? referenceNow,
}) {
  final eventTzLabel = _eventTimezoneLabel(meta?.timezone ?? 'Asia/Kolkata');
  final start = _sessionStartDateTime(session, meta);
  final istFormatter = DateFormat('HH:mm');
  final istLine = '${istFormatter.format(start)} $eventTzLabel';

  final now = referenceNow ?? DateTime.now();
  final localOffset = now.timeZoneOffset;
  final localStart = start.add(
    localOffset - const Duration(hours: 5, minutes: 30),
  );
  final localLabel = _localTimezoneAbbrev(now);
  final localLine = '${istFormatter.format(localStart)} $localLabel';

  return '$istLine · $localLine';
}

String _eventTimezoneLabel(String timezone) {
  final upper = timezone.toUpperCase();
  if (upper.contains('IST') || timezone.contains('Kolkata')) return 'IST';
  return timezone.split('/').last.replaceAll('_', ' ');
}

String _localTimezoneAbbrev(DateTime now) {
  final name = now.timeZoneName;
  if (name.isNotEmpty && name.length <= 5) return name;
  final hours = now.timeZoneOffset.inHours;
  final sign = hours >= 0 ? '+' : '';
  return 'UTC$sign$hours';
}

DateTime _sessionStartDateTime(Session session, EventMeta? meta) {
  final dayDate = meta?.dateForDay(session.day);
  final base = dayDate ?? _fallbackDayDate(session.day);
  final parts = session.startTime.split(':');
  return DateTime(
    base.year,
    base.month,
    base.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
}

DateTime _fallbackDayDate(String day) {
  return switch (day) {
    'Day 1' => DateTime(2026, 11, 4),
    'Day 2' => DateTime(2026, 11, 5),
    'Day 3' => DateTime(2026, 11, 6),
    _ => DateTime(2026, 11, 4),
  };
}
