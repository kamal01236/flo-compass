import '../../domain/entities/learning_path.dart';
import '../dtos/learning_path_dto.dart';

LearningPath learningPathFromDto(LearningPathDto dto) {
  return LearningPath(
    id: dto.id,
    title: dto.title,
    description: dto.description,
    sessionIds: dto.sessionIds,
  );
}
