import '../../domain/entities/amenity.dart';

Amenity amenityFromJson(Map<String, dynamic> json) {
  return Amenity(
    id: json['id'] as String,
    type: json['type'] as String,
    floor: json['floor'] as String,
    wing: json['wing'] as String,
    label: json['label'] as String,
    venueId: json['venueId'] as String?,
    capacityTotal: json['capacityTotal'] as int?,
    capacityAvailable: json['capacityAvailable'] as int?,
    vehicleType: json['vehicleType'] as String?,
  );
}
