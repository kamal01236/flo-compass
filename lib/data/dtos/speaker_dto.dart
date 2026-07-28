class SpeakerDto {
  const SpeakerDto({
    required this.id,
    required this.name,
    required this.title,
    required this.tier,
    required this.bio,
    this.photoAsset,
  });

  final String id;
  final String name;
  final String title;
  final int tier;
  final String bio;
  final String? photoAsset;

  factory SpeakerDto.fromJson(Map<String, dynamic> json) {
    return SpeakerDto(
      id: json['id'] as String,
      name: json['name'] as String,
      title: json['title'] as String,
      tier:
          (json['tier'] as num?)?.toInt() ??
          _tierFromTitle(json['title'] as String? ?? ''),
      bio: json['bio'] as String? ?? '',
      photoAsset: json['photoAsset'] as String?,
    );
  }

  static int _tierFromTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('chairman') ||
        lower.contains('chief executive') ||
        lower.contains('ceo') ||
        lower.contains('cto') ||
        lower.contains('coo') ||
        lower.contains('cfo') ||
        lower.contains('cpo')) {
      return 1;
    }
    if (lower.contains('chief') ||
        lower.contains('vp') ||
        lower.contains('head')) {
      return 2;
    }
    if (lower.contains('director') || lower.contains('principal')) {
      return 3;
    }
    return 4;
  }
}
