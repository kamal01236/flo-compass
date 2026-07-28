import '../../domain/entities/amenity.dart';

/// Formats a Flo Meets amenity for pickers and meet cards, including floor + wing.
String formatFloMeetAmenityLabel(Amenity amenity) {
  final parts = <String>[amenity.label, formatFloMeetFloorLabel(amenity.floor)];
  final wing = formatFloMeetWingLabel(amenity.wing);
  if (wing != null) parts.add(wing);
  return parts.join(' · ');
}

String formatFloMeetFloorLabel(String floor) {
  return switch (floor) {
    'G' => 'Ground floor',
    'B' => 'Basement',
    _ when int.tryParse(floor) != null => _ordinalFloor(int.parse(floor)),
    _ => 'Floor $floor',
  };
}

String? formatFloMeetWingLabel(String wing) {
  return switch (wing) {
    'N' => 'North wing',
    'S' => 'South wing',
    'central' => null,
    _ => wing,
  };
}

int compareFloMeetFloors(String a, String b) {
  int order(String floor) => switch (floor) {
    'B' => -1,
    'G' => 0,
    _ when int.tryParse(floor) != null => int.parse(floor),
    _ => 999,
  };
  final cmp = order(a).compareTo(order(b));
  return cmp != 0 ? cmp : a.compareTo(b);
}

/// Sort amenities for grouped picker: floor, wing, then label.
int compareFloMeetAmenities(Amenity a, Amenity b) {
  final floor = compareFloMeetFloors(a.floor, b.floor);
  if (floor != 0) return floor;
  final wing = a.wing.compareTo(b.wing);
  if (wing != 0) return wing;
  return a.label.compareTo(b.label);
}

/// Groups sorted amenities by floor for dropdown section headers.
Map<String, List<Amenity>> groupFloMeetAmenitiesByFloor(
  List<Amenity> amenities,
) {
  final sorted = [...amenities]..sort(compareFloMeetAmenities);
  final grouped = <String, List<Amenity>>{};
  for (final amenity in sorted) {
    grouped.putIfAbsent(amenity.floor, () => []).add(amenity);
  }
  return grouped;
}

String _ordinalFloor(int n) {
  if (n % 100 >= 11 && n % 100 <= 13) return '${n}th floor';
  return switch (n % 10) {
    1 => '${n}st floor',
    2 => '${n}nd floor',
    3 => '${n}rd floor',
    _ => '${n}th floor',
  };
}
