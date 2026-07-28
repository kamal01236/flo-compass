import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flo_compass/data/models/flo_meet_room.dart';
import 'package:flo_compass/data/services/flo_meets_room_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('loads seed rooms and merges organizer overlay by id', () async {
    final catalog = FloMeetsRoomCatalog(prefs: prefs);
    catalog.clearCacheForTests();
    final seed = await catalog.loadSeedRooms();
    expect(seed.length, greaterThanOrEqualTo(5));
    expect(seed.every((r) => r.source == FloMeetRoomSource.seed), isTrue);

    final overrideId = seed.first.id;
    await catalog.save(
      seed.first.copyWith(
        title: 'Organizer override',
        status: FloMeetRoomStatus.published,
        source: FloMeetRoomSource.organizer,
      ),
    );

    final merged = await catalog.loadAll(publishedOnly: true);
    final overridden = merged.firstWhere((r) => r.id == overrideId);
    expect(overridden.title, 'Organizer override');
    expect(overridden.source, FloMeetRoomSource.organizer);
  });

  test('publishedOnly hides drafts', () async {
    final catalog = FloMeetsRoomCatalog(prefs: prefs);
    await catalog.save(
      FloMeetRoom(
        id: 'draft-only',
        title: 'Draft',
        purposeTags: const [],
        amenityId: 'am-6-coffee',
        day: 'Day 1',
        windowStart: DateTime(2026, 11, 4, 11),
        windowEnd: DateTime(2026, 11, 4, 12),
        capacity: 8,
        status: FloMeetRoomStatus.draft,
        source: FloMeetRoomSource.organizer,
      ),
    );
    final published = await catalog.loadAll(publishedOnly: true);
    expect(published.any((r) => r.id == 'draft-only'), isFalse);
    final all = await catalog.loadAll();
    expect(all.any((r) => r.id == 'draft-only'), isTrue);
  });
}
