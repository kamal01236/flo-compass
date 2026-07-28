class EventDayDto {
  const EventDayDto({
    required this.id,
    required this.name,
    required this.date,
    required this.description,
  });

  final String id;
  final String name;
  final String date;
  final String description;

  factory EventDayDto.fromJson(Map<String, dynamic> json) {
    return EventDayDto(
      id: json['id'] as String,
      name: json['name'] as String,
      date: json['date'] as String,
      description: json['description'] as String? ?? '',
    );
  }
}
