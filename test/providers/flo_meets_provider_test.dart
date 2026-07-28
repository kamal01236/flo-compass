import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flo_compass/data/models/flo_meet_room.dart';
import 'package:flo_compass/data/models/flo_meets_preferences.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/providers/flo_meets_provider.dart';

import '../support/test_flo_meets_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('requires experience for setup complete', () {
    const invalid = FloMeetsPreferences(
      nickname: 'Pilot',
      identity: 'female',
      openTo: ['all'],
      purposes: ['networking'],
      personalInterests: ['photography'],
      personalityTraits: ['curious'],
      enabledSlots: ['Day_1_0900'],
      meetAmenityId: 'am-6-coffee',
    );
    expect(invalid.isSetupComplete, isFalse);
  });

  test('defaults include openTo all', () {
    expect(FloMeetsPreferences.defaults().openTo, [FloMeetOpenTo.all]);
  });

  test('savePreferences throws when incomplete', () async {
    final state = FloMeetsState(
      prefs: prefs,
      demoReciprocateDelay: Duration.zero,
      enableDemoSeed: false,
    );
    await initFloMeetsForTests(state);
    expect(
      () => state.savePreferences(
        const FloMeetsPreferences(
          nickname: 'x',
          identity: 'female',
          openTo: ['all'],
          purposes: ['networking'],
          personalInterests: ['photography'],
          personalityTraits: ['curious'],
          enabledSlots: ['Day_1_0900'],
          meetAmenityId: 'am-6-coffee',
        ),
      ),
      throwsStateError,
    );
  });

  test('connect returns null when setup incomplete', () async {
    final state = FloMeetsState(
      prefs: prefs,
      demoReciprocateDelay: Duration.zero,
      enableDemoSeed: false,
    );
    await initFloMeetsForTests(state);
    expect(state.preferences.isSetupComplete, isFalse);
    final result = await state.connect(
      roomId: 'any',
      partnerId: 'partner-1',
      userRole: AttendeeRole.engineer,
      professionalInterests: const ['genai'],
    );
    expect(result, isNull);
  });

  test('runRoundTick is a no-op', () async {
    final state = FloMeetsState(
      prefs: prefs,
      service: TestFloMeetsService(partnerId: 'partner-1'),
      demoReciprocateDelay: Duration.zero,
      enableDemoSeed: false,
    );
    await initFloMeetsForTests(state);
    await state.savePreferences(
      buildValidFloMeetsPreferences(enabledSlots: const ['Day_1_0900']),
    );

    final meet = await state.runRoundTick(
      now: DateTime(2026, 11, 4, 7, 30),
      eventDay: 'Day 1',
      isAuthenticated: true,
      role: AttendeeRole.engineer,
      professionalInterests: const ['genai'],
      networkingCard: null,
    );

    expect(meet, isNull);
    expect(state.meets, isEmpty);
  });

  test('joinRoom enforces capacity and connect alone is not a match', () async {
    final state = FloMeetsState(
      prefs: prefs,
      demoReciprocateDelay: Duration.zero,
      enableDemoSeed: false,
    );
    await initFloMeetsForTests(state);
    await state.savePreferences(
      buildValidFloMeetsPreferences(enabledSlots: const ['Day_1_0900']),
    );
    await state.loadRooms();
    expect(state.rooms, isNotEmpty);

    final room = state.rooms.first;
    final ok = await state.joinRoom(room.id);
    expect(ok, isTrue);
    expect(state.isJoined(room.id), isTrue);

    final waiting = await state.connect(
      roomId: room.id,
      partnerId: room.seedPartnerIds.first,
      userRole: AttendeeRole.engineer,
      professionalInterests: const ['genai', 'cloud'],
      reciprocateMockPartner: false,
    );
    expect(waiting, isNotNull);
    expect(waiting!.iConnected, isTrue);
    expect(waiting.theyConnected, isFalse);
    expect(waiting.isMatch, isFalse);
    expect(state.waitingConnections, hasLength(1));
    expect(state.matches, isEmpty);
  });

  test('both connected yields match and unlocks meet', () async {
    final state = FloMeetsState(
      prefs: prefs,
      demoReciprocateDelay: Duration.zero,
      enableDemoSeed: false,
    );
    await initFloMeetsForTests(state);
    await state.savePreferences(
      buildValidFloMeetsPreferences(enabledSlots: const ['Day_1_0900']),
    );
    await state.loadRooms();
    final room = state.rooms.first;
    await state.joinRoom(room.id);

    final matched = await state.connect(
      roomId: room.id,
      partnerId: room.seedPartnerIds.first,
      userRole: AttendeeRole.engineer,
      professionalInterests: const ['genai', 'cloud', 'architecture'],
      reciprocateMockPartner: true,
    );

    expect(matched, isNotNull);
    expect(matched!.isMatch, isTrue);
    expect(matched.meetId, isNotNull);
    expect(state.matches, hasLength(1));
    expect(state.waitingConnections, isEmpty);
    expect(state.meets, hasLength(1));
  });

  test('per-subject storage isolates preferences', () async {
    final state = FloMeetsState(
      prefs: prefs,
      demoReciprocateDelay: Duration.zero,
      enableDemoSeed: false,
    );
    await state.init();
    await state.bindAuthSubject('user-a');
    await state.savePreferences(
      buildValidFloMeetsPreferences(enabledSlots: const ['Day_1_0900']),
    );
    expect(state.preferences.nickname, 'Avery');

    await state.bindAuthSubject('user-b');
    expect(state.preferences.isSetupComplete, isFalse);

    await state.savePreferences(
      buildValidFloMeetsPreferences(enabledSlots: const ['Day_1_1200'])
          .copyWith(nickname: 'Blake'),
    );
    expect(state.preferences.nickname, 'Blake');

    await state.bindAuthSubject('user-a');
    expect(state.preferences.nickname, 'Avery');
  });

  test('migrates legacy unscoped storage into subject key', () async {
    final legacyPayload = {
      'preferences': buildValidFloMeetsPreferences(
        enabledSlots: const ['Day_1_0900'],
      ).toJson(),
      'meets': <dynamic>[],
      'metPartnerIds': <String>[],
      'completedRoundKeys': <String>[],
      'joinedRoomIds': <String>[],
      'connections': <dynamic>[],
      'demoSeedApplied': false,
    };
    await prefs.setString(
      'flo_compass_flo_meets',
      jsonEncode(legacyPayload),
    );

    final state = FloMeetsState(
      prefs: prefs,
      demoReciprocateDelay: Duration.zero,
      enableDemoSeed: false,
    );
    await state.init();
    await state.bindAuthSubject('legacy-user');
    expect(state.preferences.isSetupComplete, isTrue);
    expect(state.preferences.nickname, 'Avery');
    expect(
      prefs.containsKey(FloMeetsState.storageKeyFor('legacy-user')),
      isTrue,
    );
  });

  test('demo seed creates waiting and match once', () async {
    final state = FloMeetsState(
      prefs: prefs,
      demoReciprocateDelay: Duration.zero,
      enableDemoSeed: true,
    );
    await initFloMeetsForTests(state, subject: 'seed-user');
    await state.savePreferences(
      buildValidFloMeetsPreferences(enabledSlots: const ['Day_1_0900']),
    );

    expect(state.demoSeedApplied, isTrue);
    expect(state.waitingConnections, hasLength(1));
    expect(state.matches, hasLength(1));
    expect(state.joinedRoomIds, isNotEmpty);

    await state.applyDemoSeedIfNeeded();
    expect(state.waitingConnections, hasLength(1));
    expect(state.matches, hasLength(1));
  });

  test('organizer publish appears in attendee loadRooms', () async {
    final state = FloMeetsState(
      prefs: prefs,
      demoReciprocateDelay: Duration.zero,
      enableDemoSeed: false,
    );
    await initFloMeetsForTests(state);
    final catalog = state.roomCatalog;
    final draft = await catalog.save(
      FloMeetRoom(
        id: 'org-test-room',
        title: 'Organizer lounge',
        purposeTags: const ['networking'],
        amenityId: 'am-6-coffee',
        day: 'Day 1',
        windowStart: DateTime(2026, 11, 4, 15),
        windowEnd: DateTime(2026, 11, 4, 16),
        capacity: 8,
        status: FloMeetRoomStatus.draft,
        source: FloMeetRoomSource.organizer,
      ),
    );
    await state.loadRooms();
    expect(state.rooms.any((r) => r.id == draft.id), isFalse);

    await catalog.publish(draft.id);
    await state.loadRooms();
    expect(state.rooms.any((r) => r.id == draft.id && r.isPublished), isTrue);
  });
}
