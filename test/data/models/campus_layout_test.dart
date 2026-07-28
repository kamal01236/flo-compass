import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/mappers/campus_mapper.dart';
import 'package:flo_compass/data/models/models.dart';

void main() {
  test('campusFromJson parses parking and vertical movement', () {
    final campus = campusFromJson({
      'building': 'Nagarro Gurgaon Office',
      'parkingFloors': ['B', 'G', '1', '2', '3', '4'],
      'parkingCapacityPerFloor': {'cars': 40, 'bikes': 100},
      'wellnessFloor': '5',
      'eventFloors': ['G', '6', '7', '8', '9', '10', '11', '12', '13'],
      'restroomConvention': {
        'northWing': 'ladies',
        'southWing': 'gents',
        'disclaimer': 'Per building signage',
      },
      'floor6': {
        'north': ['cafeteria'],
        'south': ['gym'],
      },
      'floors7to13': {
        'podsPerWing': 6,
        'conferenceRoomsPerWing': 4,
        'coffeePerWing': true,
      },
      'verticalMovement': {
        'liftCount': 8,
        'liftLocation': 'central',
        'eventDayLiftMinutes': 5,
        'offPeakLiftMinutes': 3,
        'stairsMinutesPerFloor': 1,
        'preferStairsWhen': {'floorsUpMax': 2, 'floorsDownMax': 3},
      },
    });

    expect(campus.parkingFloors, hasLength(6));
    expect(campus.parkingCapacityPerFloor.cars, 40);
    expect(campus.floorIndex('6'), 7);
    expect(campus.floorIndex('8'), 9);
    expect((campus.floorIndex('6') - campus.floorIndex('8')).abs(), 2);
    expect(campus.verticalMovement.eventDayLiftMinutes, 5);
    expect(campus.restroomConvention.northWing, 'ladies');
  });
}
