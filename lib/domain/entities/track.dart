class Track {
  const Track({
    required this.id,
    required this.name,
    required this.tags,
    this.color,
  });

  final String id;
  final String name;
  final List<String> tags;
  final String? color;
}
