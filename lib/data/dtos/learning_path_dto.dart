class LearningPathDto {
  const LearningPathDto({
    required this.id,
    required this.title,
    required this.description,
    required this.sessionIds,
  });

  final String id;
  final String title;
  final String description;
  final List<String> sessionIds;

  factory LearningPathDto.fromJson(Map<String, dynamic> json) {
    return LearningPathDto(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      sessionIds: (json['sessionIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }
}
