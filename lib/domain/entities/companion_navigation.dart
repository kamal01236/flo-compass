enum CompanionNavigationAction {
  none,
  directionsToSession,
  openVenueMap,
  openAmenity,
}

class CompanionSource {
  const CompanionSource({
    required this.kind,
    required this.id,
    required this.label,
  });

  final String kind;
  final String id;
  final String label;
}
