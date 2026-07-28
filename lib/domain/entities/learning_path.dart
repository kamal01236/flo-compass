class LearningPath {
  const LearningPath({
    required this.id,
    required this.title,
    required this.description,
    required this.sessionIds,
  });

  final String id;
  final String title;
  final String description;
  final List<String> sessionIds;
}
