class Session {
  const Session({
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

  int get dayNumber {
    final digits = RegExp(r'\d+').firstMatch(day)?.group(0);
    return int.tryParse(digits ?? '') ?? 1;
  }
}
