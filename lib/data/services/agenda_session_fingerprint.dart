import '../models/models.dart';

class AgendaSessionFingerprint {
  const AgendaSessionFingerprint({
    required this.title,
    required this.venueId,
    required this.startTime,
    required this.endTime,
    required this.day,
    required this.exists,
  });

  final String title;
  final String venueId;
  final String startTime;
  final String endTime;
  final String day;
  final bool exists;

  factory AgendaSessionFingerprint.fromSession(Session session) {
    return AgendaSessionFingerprint(
      title: session.title,
      venueId: session.venueId,
      startTime: session.startTime,
      endTime: session.endTime,
      day: session.day,
      exists: true,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'venueId': venueId,
    'startTime': startTime,
    'endTime': endTime,
    'day': day,
    'exists': exists,
  };

  factory AgendaSessionFingerprint.fromJson(Map<String, dynamic> json) {
    return AgendaSessionFingerprint(
      title: json['title'] as String? ?? '',
      venueId: json['venueId'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      day: json['day'] as String? ?? '',
      exists: json['exists'] as bool? ?? true,
    );
  }

  bool matchesSchedule(AgendaSessionFingerprint other) {
    return venueId == other.venueId &&
        startTime == other.startTime &&
        endTime == other.endTime &&
        day == other.day &&
        exists == other.exists;
  }
}
