import 'event_day.dart';

class EventMeta {
  const EventMeta({
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
  final List<EventDay> days;
  final Map<String, String> floorStories;

  String? storyForFloor(String floor) => floorStories[floor];

  DateTime? dateForDay(String dayId) {
    for (final day in days) {
      if (day.id == dayId) {
        return DateTime.tryParse(day.date);
      }
    }
    return null;
  }
}
