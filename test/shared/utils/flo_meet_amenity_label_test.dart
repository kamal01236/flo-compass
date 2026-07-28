import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/services/flo_meets_service.dart';
import 'package:flo_compass/domain/entities/amenity.dart';
import 'package:flo_compass/shared/utils/flo_meet_amenity_label.dart';

void main() {
  group('formatFloMeetAmenityLabel', () {
    test('formats ground help desk with floor only', () {
      const amenity = Amenity(
        id: 'am-G-help',
        type: 'help_desk',
        floor: 'G',
        wing: 'central',
        label: 'Registration Help Desk',
        venueId: 'ven-G01',
      );
      expect(
        formatFloMeetAmenityLabel(amenity),
        'Registration Help Desk · Ground floor',
      );
    });

    test('formats 6th floor north wing coffee', () {
      const amenity = Amenity(
        id: 'am-6-coffee',
        type: 'coffee',
        floor: '6',
        wing: 'N',
        label: 'Community Cafeteria',
        venueId: 'ven-C601',
      );
      expect(
        formatFloMeetAmenityLabel(amenity),
        'Community Cafeteria · 6th floor · North wing',
      );
    });
  });

  group('floMeetAmenityTypes', () {
    test('excludes parking types', () {
      expect(floMeetAmenityTypes.contains('parking_car'), isFalse);
      expect(floMeetAmenityTypes.contains('parking_bike'), isFalse);
      expect(floMeetAmenityTypes.contains('coffee'), isTrue);
    });
  });
}
