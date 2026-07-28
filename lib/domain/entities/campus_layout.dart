class CampusLayout {
  const CampusLayout({
    required this.building,
    required this.parkingFloors,
    required this.parkingCapacityPerFloor,
    required this.wellnessFloor,
    required this.eventFloors,
    required this.restroomConvention,
    required this.floor6,
    required this.floors7to13,
    required this.verticalMovement,
  });

  final String building;
  final List<String> parkingFloors;
  final ParkingCapacity parkingCapacityPerFloor;
  final String wellnessFloor;
  final List<String> eventFloors;
  final RestroomConvention restroomConvention;
  final Floor6Layout floor6;
  final Floors7to13Layout floors7to13;
  final VerticalMovement verticalMovement;
}

class ParkingCapacity {
  const ParkingCapacity({required this.cars, required this.bikes});

  final int cars;
  final int bikes;
}

class RestroomConvention {
  const RestroomConvention({
    required this.northWing,
    required this.southWing,
    required this.disclaimer,
  });

  final String northWing;
  final String southWing;
  final String disclaimer;
}

class Floor6Layout {
  const Floor6Layout({required this.north, required this.south});

  final List<String> north;
  final List<String> south;
}

class Floors7to13Layout {
  const Floors7to13Layout({
    required this.podsPerWing,
    required this.conferenceRoomsPerWing,
    required this.coffeePerWing,
  });

  final int podsPerWing;
  final int conferenceRoomsPerWing;
  final bool coffeePerWing;
}

class VerticalMovement {
  const VerticalMovement({
    required this.liftCount,
    required this.liftLocation,
    required this.eventDayLiftMinutes,
    required this.offPeakLiftMinutes,
    required this.stairsMinutesPerFloor,
    required this.preferStairsWhen,
  });

  final int liftCount;
  final String liftLocation;
  final int eventDayLiftMinutes;
  final int offPeakLiftMinutes;
  final int stairsMinutesPerFloor;
  final PreferStairsWhen preferStairsWhen;
}

class PreferStairsWhen {
  const PreferStairsWhen({
    required this.floorsUpMax,
    required this.floorsDownMax,
  });

  final int floorsUpMax;
  final int floorsDownMax;
}

extension CampusFloorIndex on CampusLayout {
  /// Ordered index: B=0, G=1, 1–4 parking, 5 wellness, 6–13 event.
  int floorIndex(String floor) {
    return switch (floor.toUpperCase()) {
      'B' => 0,
      'G' => 1,
      '1' => 2,
      '2' => 3,
      '3' => 4,
      '4' => 5,
      '5' => 6,
      _ => 7 + ((int.tryParse(floor) ?? 6) - 6),
    };
  }

  int floorDelta(String fromFloor, String toFloor) =>
      (floorIndex(fromFloor) - floorIndex(toFloor)).abs();
}
