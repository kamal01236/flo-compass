import '../../domain/entities/speaker.dart';
import '../dtos/speaker_dto.dart';

Speaker speakerFromDto(SpeakerDto dto) {
  return Speaker(
    id: dto.id,
    name: dto.name,
    title: dto.title,
    tier: dto.tier,
    bio: dto.bio,
    photoAsset: dto.photoAsset,
  );
}
