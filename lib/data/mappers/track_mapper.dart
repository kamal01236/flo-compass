import '../../domain/entities/track.dart';
import '../dtos/track_dto.dart';

Track trackFromDto(TrackDto dto) {
  return Track(id: dto.id, name: dto.name, tags: dto.tags, color: dto.color);
}
