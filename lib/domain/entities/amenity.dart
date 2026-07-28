class Amenity {
  const Amenity({
    required this.id,
    required this.type,
    required this.floor,
    required this.wing,
    required this.label,
    this.venueId,
    this.capacityTotal,
    this.capacityAvailable,
    this.vehicleType,
  });

  final String id;
  final String type;
  final String floor;
  final String wing;
  final String label;
  final String? venueId;
  final int? capacityTotal;
  final int? capacityAvailable;

  /// `car` or `bike` for parking amenities.
  final String? vehicleType;

  bool get isParking => type == 'parking_car' || type == 'parking_bike';

  double? get availabilityRatio {
    if (capacityTotal == null ||
        capacityTotal == 0 ||
        capacityAvailable == null) {
      return null;
    }
    return capacityAvailable! / capacityTotal!;
  }
}
