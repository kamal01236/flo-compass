import '../models/models.dart';

class IcsExportService {
  String buildForSession({
    required Session session,
    required EventMeta? meta,
    required String location,
  }) {
    final start = _toUtcString(
      _eventDate(session.day, session.startTime, meta),
    );
    final end = _toUtcString(_eventDate(session.day, session.endTime, meta));
    return '''
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//AI Avengers//Flo Compass//EN
BEGIN:VEVENT
UID:${session.id}@flo-compass
DTSTAMP:$start
DTSTART:$start
DTEND:$end
SUMMARY:${_escape(session.title)}
DESCRIPTION:${_escape(session.abstract)}
LOCATION:${_escape(location)}
END:VEVENT
END:VCALENDAR
''';
  }

  String buildForSessions({
    required List<Session> sessions,
    required EventMeta? meta,
    String Function(String venueId)? resolveVenueName,
  }) {
    final buffer = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//AI Avengers//Flo Compass//EN');
    for (final session in sessions) {
      final start = _toUtcString(
        _eventDate(session.day, session.startTime, meta),
      );
      final end = _toUtcString(_eventDate(session.day, session.endTime, meta));
      buffer
        ..writeln('BEGIN:VEVENT')
        ..writeln('UID:${session.id}@flo-compass')
        ..writeln('DTSTAMP:$start')
        ..writeln('DTSTART:$start')
        ..writeln('DTEND:$end')
        ..writeln('SUMMARY:${_escape(session.title)}')
        ..writeln('DESCRIPTION:${_escape(session.abstract)}')
        ..writeln(
          'LOCATION:${_escape(resolveVenueName?.call(session.venueId) ?? session.venueId)}',
        )
        ..writeln('END:VEVENT');
    }
    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  DateTime _eventDate(String day, String hhmm, EventMeta? meta) {
    final parts = hhmm.split(':');
    final base =
        meta?.dateForDay(day) ??
        switch (day) {
          'Day 1' => DateTime(2026, 11, 4),
          'Day 2' => DateTime(2026, 11, 5),
          'Day 3' => DateTime(2026, 11, 6),
          _ => DateTime(2026, 11, 4),
        };
    return DateTime.utc(
      base.year,
      base.month,
      base.day,
      int.parse(parts.first),
      int.parse(parts.last),
    );
  }

  String _toUtcString(DateTime value) {
    final s = value.toIso8601String().replaceAll('-', '').replaceAll(':', '');
    return '${s.split('.').first}Z';
  }

  String _escape(String raw) => raw
      .replaceAll('\\', '\\\\')
      .replaceAll('\r', '\\r')
      .replaceAll('\n', '\\n')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,');
}
