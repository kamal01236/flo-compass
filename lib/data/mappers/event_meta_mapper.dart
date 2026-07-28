import '../../domain/entities/event_day.dart';
import '../../domain/entities/event_meta.dart';
import '../dtos/event_day_dto.dart';
import '../dtos/event_meta_dto.dart';

EventDay eventDayFromDto(EventDayDto dto) {
  return EventDay(
    id: dto.id,
    name: dto.name,
    date: dto.date,
    description: dto.description,
  );
}

EventMeta eventMetaFromDto(EventMetaDto dto) {
  return EventMeta(
    eventName: dto.eventName,
    venue: dto.venue,
    timezone: dto.timezone,
    slots: dto.slots,
    days: dto.days.map(eventDayFromDto).toList(),
    floorStories: dto.floorStories,
  );
}
