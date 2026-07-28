import '../../domain/entities/session.dart';
import '../dtos/session_dto.dart';

Session sessionFromDto(SessionDto dto) {
  return Session(
    id: dto.id,
    title: dto.title,
    abstract: dto.abstract,
    day: dto.day,
    startTime: dto.startTime,
    endTime: dto.endTime,
    venueId: dto.venueId,
    trackId: dto.trackId,
    speakerIds: dto.speakerIds,
    tags: dto.tags,
    format: dto.format,
    level: dto.level,
    featured: dto.featured,
    capacity: dto.capacity,
    building: dto.building,
    attendeeInterestCount: dto.attendeeInterestCount,
    occupancyPercent: dto.occupancyPercent,
  );
}
