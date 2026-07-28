import 'event_day_dto.dart';

class EventMetaDto {
  const EventMetaDto({
    required this.eventName,
    required this.venue,
    required this.timezone,
    required this.slots,
    required this.days,
    this.floorStories = const {},
  });

  final String eventName;
  final String venue;
  final String timezone;
  final List<String> slots;
  final List<EventDayDto> days;
  final Map<String, String> floorStories;

  factory EventMetaDto.fromJson(Map<String, dynamic> json) {
    final rawStories = json['floorStories'] as Map<String, dynamic>? ?? {};
    return EventMetaDto(
      eventName: json['eventName'] as String,
      venue: json['venue'] as String,
      timezone: json['timezone'] as String? ?? '',
      slots: (json['slots'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      days: (json['days'] as List<dynamic>? ?? [])
          .map((e) => EventDayDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      floorStories: rawStories.map(
        (key, value) => MapEntry(key, value as String),
      ),
    );
  }
}
