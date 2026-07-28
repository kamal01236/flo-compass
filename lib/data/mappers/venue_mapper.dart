import '../../domain/entities/venue.dart';
import '../dtos/venue_dto.dart';

Venue venueFromDto(VenueDto dto) {
  return Venue(
    id: dto.id,
    name: dto.name,
    floor: dto.floor,
    zone: dto.zone,
    wing: dto.wing,
    capacity: dto.capacity,
    building: dto.building,
    mapZone: dto.mapZone,
    landmarks: dto.landmarks,
    nearestElevator: dto.nearestElevator,
    stepFree: dto.stepFree,
  );
}
