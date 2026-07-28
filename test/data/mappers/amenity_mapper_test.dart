import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/mappers/amenity_mapper.dart';

void main() {
  test('amenityFromJson parses optional capacity fields', () {
    final amenity = amenityFromJson({
      'id': 'park-2-car',
      'type': 'parking_car',
      'floor': '2',
      'wing': 'central',
      'label': '2nd Floor Car Parking',
      'capacityTotal': 40,
      'capacityAvailable': 12,
      'vehicleType': 'car',
    });

    expect(amenity.capacityTotal, 40);
    expect(amenity.capacityAvailable, 12);
    expect(amenity.vehicleType, 'car');
    expect(amenity.isParking, isTrue);
    expect(amenity.availabilityRatio, closeTo(0.3, 0.01));
  });
}
