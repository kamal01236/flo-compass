import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/services/walking_time_estimator.dart';

void main() {
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

  const venue6n = Venue(
    id: 'ven-6N1',
    name: 'Pod 6N1',
    floor: '6',
    zone: 'Pod',
    wing: 'N',
    capacity: 12,
    building: 'Nagarro Gurgaon Office',
  );

  const venue8n = Venue(
    id: 'ven-8N1',
    name: 'Pod 8N1',
    floor: '8',
    zone: 'Pod',
    wing: 'N',
    capacity: 12,
    building: 'Nagarro Gurgaon Office',
  );

  const venue8s = Venue(
    id: 'ven-8S1',
    name: 'Pod 8S1',
    floor: '8',
    zone: 'Pod',
    wing: 'S',
    capacity: 12,
    building: 'Nagarro Gurgaon Office',
  );

  test('6 to 8 same wing recommends stairs on event day', () {
    final estimate = WalkingTimeEstimator(
      campus: campus,
      isEventDayMode: true,
    ).estimate(from: venue6n, to: venue8n);

    expect(estimate.minutes, 2);
    expect(estimate.recommendedMode, 'stairs');
    expect(estimate.alternateMode, 'lift');
  });

  test('same floor wing cross is one minute walk', () {
    final estimate = WalkingTimeEstimator(
      campus: campus,
      isEventDayMode: true,
    ).estimate(from: venue8n, to: venue8s);

    expect(estimate.minutes, 1);
    expect(estimate.recommendedMode, 'walk');
  });

  test('legacy estimator without campus still works', () {
    final estimate = WalkingTimeEstimator().estimate(
      from: venue6n,
      to: venue8n,
    );
    expect(estimate.minutes, greaterThan(0));
  });
}
