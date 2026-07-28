class Speaker {
  const Speaker({
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
}
