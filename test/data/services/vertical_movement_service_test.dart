import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/services/vertical_movement_service.dart';
import 'package:flo_compass/data/models/models.dart';

void main() {
  const service = VerticalMovementService();

  final campus = CampusLayout(
    building: 'Nagarro Gurgaon Office',
    parkingFloors: const ['B', 'G', '1', '2', '3', '4'],
    parkingCapacityPerFloor: const ParkingCapacity(cars: 40, bikes: 100),
    wellnessFloor: '5',
    eventFloors: const ['G', '6', '7', '8', '9', '10', '11', '12', '13'],
    restroomConvention: const RestroomConvention(
      northWing: 'ladies',
      southWing: 'gents',
      disclaimer: 'Per building signage',
    ),
    floor6: const Floor6Layout(north: ['cafeteria'], south: ['gym']),
    floors7to13: const Floors7to13Layout(
      podsPerWing: 6,
      conferenceRoomsPerWing: 4,
      coffeePerWing: true,
    ),
    verticalMovement: const VerticalMovement(
      liftCount: 8,
      liftLocation: 'central',
      eventDayLiftMinutes: 5,
      offPeakLiftMinutes: 3,
      stairsMinutesPerFloor: 1,
      preferStairsWhen: PreferStairsWhen(floorsUpMax: 2, floorsDownMax: 3),
    ),
  );

  test('prefers stairs for two floors up', () {
    final rec = service.recommend(
      campus: campus,
      fromFloor: '6',
      toFloor: '8',
      isEventDayMode: true,
    );
    expect(rec.mode, 'stairs');
    expect(rec.minutes, 2);
    expect(rec.tip, contains('5 min'));
  });

  test('uses lift for four floors during event day', () {
    final rec = service.recommend(
      campus: campus,
      fromFloor: '6',
      toFloor: '10',
      isEventDayMode: true,
    );
    expect(rec.mode, 'lift');
    expect(rec.minutes, 5);
  });

  test('step-free always uses lift', () {
    final rec = service.recommend(
      campus: campus,
      fromFloor: '6',
      toFloor: '7',
      stepFree: true,
      isEventDayMode: true,
    );
    expect(rec.mode, 'lift');
  });

  test('off-peak lift uses shorter minutes', () {
    final rec = service.recommend(
      campus: campus,
      fromFloor: '6',
      toFloor: '10',
      isEventDayMode: false,
    );
    expect(rec.mode, 'lift');
    expect(rec.minutes, 3);
  });
}
