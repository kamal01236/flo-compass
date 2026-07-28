import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/repositories/mock_event_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const floors = ['G', '6', '7', '8', '9', '10', '11', '12', '13'];

  test('MockEventRepository loads non-empty floor stories from meta', () async {
    final repository = MockEventRepository();
    final meta = await repository.loadMeta();

    for (final floor in floors) {
      expect(
        meta.storyForFloor(floor),
        isNotNull,
        reason: 'floor $floor should have a story',
      );
      expect(meta.storyForFloor(floor)!.trim(), isNotEmpty);
    }
  });
}
