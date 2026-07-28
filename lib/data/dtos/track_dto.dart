class TrackDto {
  const TrackDto({
    required this.id,
    required this.name,
    required this.tags,
    this.color,
  });

  final String id;
  final String name;
  final List<String> tags;
  final String? color;

  factory TrackDto.fromJson(Map<String, dynamic> json) {
    return TrackDto(
      id: json['id'] as String,
      name: json['name'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      color: json['color'] as String?,
    );
  }
}
