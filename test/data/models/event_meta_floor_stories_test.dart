import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/dtos/event_meta_dto.dart';
import 'package:flo_compass/data/mappers/event_meta_mapper.dart';

void main() {
  test('EventMeta parses floorStories for all tower floors', () {
    const floors = ['G', '6', '7', '8', '9', '10', '11', '12', '13'];
    final stories = {for (final floor in floors) floor: 'Story for $floor'};

    final meta = eventMetaFromDto(
      EventMetaDto.fromJson({
        'eventName': 'Flo 2026',
        'venue': 'Nagarro Gurgaon Office',
        'timezone': 'IST',
        'slots': ['09:00'],
        'days': [],
        'floorStories': stories,
      }),
    );

    for (final floor in floors) {
      expect(meta.storyForFloor(floor), isNotEmpty);
    }
  });
}
