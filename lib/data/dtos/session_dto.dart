class SessionDto {
  const SessionDto({
    required this.id,
    required this.title,
    required this.abstract,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.venueId,
    required this.trackId,
    required this.speakerIds,
    required this.tags,
    required this.format,
    required this.level,
    required this.featured,
    required this.capacity,
    required this.building,
    this.attendeeInterestCount = 0,
    this.occupancyPercent = 40,
  });

  final String id;
  final String title;
  final String abstract;
  final String day;
  final String startTime;
  final String endTime;
  final String venueId;
  final String trackId;
  final List<String> speakerIds;
  final List<String> tags;
  final String format;
  final String level;
  final bool featured;
  final int capacity;
  final String building;
  final int attendeeInterestCount;
  final int occupancyPercent;

  factory SessionDto.fromJson(Map<String, dynamic> json) {
    return SessionDto(
      id: json['id'] as String,
      title: json['title'] as String,
      abstract: json['abstract'] as String,
      day: _parseDay(json['day']),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      venueId: json['venueId'] as String,
      trackId: json['trackId'] as String,
      speakerIds: (json['speakerIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      format: json['format'] as String,
      level: json['level'] as String,
      featured: json['featured'] as bool,
      capacity: json['capacity'] as int,
      building: json['building'] as String,
      attendeeInterestCount:
          (json['attendeeInterestCount'] as num?)?.toInt() ?? 0,
      occupancyPercent: ((json['occupancyPercent'] as num?)?.toInt() ?? 40)
          .clamp(0, 100),
    );
  }

  static String _parseDay(Object? raw) {
    if (raw is String && raw.isNotEmpty) return raw;
    if (raw is num) return 'Day ${raw.toInt()}';
    return 'Day 1';
  }
}
