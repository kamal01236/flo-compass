import '../../domain/entities/campus_layout.dart';

CampusLayout campusFromJson(Map<String, dynamic> json) {
  final parkingCap =
      json['parkingCapacityPerFloor'] as Map<String, dynamic>? ?? {};
  final restroom = json['restroomConvention'] as Map<String, dynamic>? ?? {};
  final floor6 = json['floor6'] as Map<String, dynamic>? ?? {};
  final floors7 = json['floors7to13'] as Map<String, dynamic>? ?? {};
  final vertical = json['verticalMovement'] as Map<String, dynamic>? ?? {};
  final preferStairs =
      vertical['preferStairsWhen'] as Map<String, dynamic>? ?? {};

  return CampusLayout(
    building: json['building'] as String? ?? 'Nagarro Gurgaon Office',
    parkingFloors: (json['parkingFloors'] as List<dynamic>? ?? [])
        .cast<String>(),
    parkingCapacityPerFloor: ParkingCapacity(
      cars: parkingCap['cars'] as int? ?? 40,
      bikes: parkingCap['bikes'] as int? ?? 100,
    ),
    wellnessFloor: json['wellnessFloor'] as String? ?? '5',
    eventFloors: (json['eventFloors'] as List<dynamic>? ?? []).cast<String>(),
    restroomConvention: RestroomConvention(
      northWing: restroom['northWing'] as String? ?? 'ladies',
      southWing: restroom['southWing'] as String? ?? 'gents',
      disclaimer:
          restroom['disclaimer'] as String? ??
          'Per building signage; choose the wing that applies to you.',
    ),
    floor6: Floor6Layout(
      north: (floor6['north'] as List<dynamic>? ?? []).cast<String>(),
      south: (floor6['south'] as List<dynamic>? ?? []).cast<String>(),
    ),
    floors7to13: Floors7to13Layout(
      podsPerWing: floors7['podsPerWing'] as int? ?? 6,
      conferenceRoomsPerWing: floors7['conferenceRoomsPerWing'] as int? ?? 4,
      coffeePerWing: floors7['coffeePerWing'] as bool? ?? true,
    ),
    verticalMovement: VerticalMovement(
      liftCount: vertical['liftCount'] as int? ?? 8,
      liftLocation: vertical['liftLocation'] as String? ?? 'central',
      eventDayLiftMinutes: vertical['eventDayLiftMinutes'] as int? ?? 5,
      offPeakLiftMinutes: vertical['offPeakLiftMinutes'] as int? ?? 3,
      stairsMinutesPerFloor: vertical['stairsMinutesPerFloor'] as int? ?? 1,
      preferStairsWhen: PreferStairsWhen(
        floorsUpMax: preferStairs['floorsUpMax'] as int? ?? 2,
        floorsDownMax: preferStairs['floorsDownMax'] as int? ?? 3,
      ),
    ),
  );
}
