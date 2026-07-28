class Venue {
  const Venue({
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
}
