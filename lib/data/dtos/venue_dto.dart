class VenueDto {
  const VenueDto({
    required this.id,
    required this.name,
    required this.floor,
    required this.zone,
    required this.wing,
    required this.capacity,
    required this.building,
    this.mapZone,
    this.landmarks = const [],
    this.nearestElevator,
    this.stepFree = false,
  });

  final String id;
  final String name;
  final String floor;
  final String zone;
  final String wing;
  final int capacity;
  final String building;
  final String? mapZone;
  final List<String> landmarks;
  final String? nearestElevator;
  final bool stepFree;

  factory VenueDto.fromJson(Map<String, dynamic> json) {
    return VenueDto(
      id: json['id'] as String,
      name: json['name'] as String,
      floor: json['floor'] as String,
      zone: json['zone'] as String,
      wing: (json['wing'] as String?) ?? 'central',
      capacity: json['capacity'] as int,
      building: json['building'] as String,
      mapZone: json['mapZone'] as String?,
      landmarks:
          (json['landmarks'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      nearestElevator: json['nearestElevator'] as String?,
      stepFree: json['stepFree'] as bool? ?? false,
    );
  }
}
