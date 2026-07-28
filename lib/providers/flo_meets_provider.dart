import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/flo_meet.dart';
import '../data/models/flo_meet_connection.dart';
import '../data/models/flo_meet_partner.dart';
import '../data/models/flo_meet_room.dart';
import '../data/models/flo_meets_preferences.dart';
import '../data/models/networking_card.dart';
import '../data/models/user_profile.dart';
import '../data/services/flo_meets_room_catalog.dart';
import '../data/services/flo_meets_service.dart';

class FloMeetsState extends ChangeNotifier {
  FloMeetsState({
    SharedPreferences? prefs,
    FloMeetsService? service,
    FloMeetsRoomCatalog? roomCatalog,
    this.demoReciprocateDelay = const Duration(milliseconds: 1200),
    this.enableDemoSeed = true,
  }) : _prefs = prefs,
       _service = service ?? FloMeetsService(),
       _roomCatalog = roomCatalog ?? FloMeetsRoomCatalog(prefs: prefs);

  SharedPreferences? _prefs;
  final FloMeetsService _service;
  final FloMeetsRoomCatalog _roomCatalog;

  /// Optional delay before mock partners reciprocate Connect (demo UX).
  final Duration demoReciprocateDelay;

  /// When false, skips one-time Waiting/Match bootstrap (tests).
  final bool enableDemoSeed;

  static const _legacyStorageKey = 'flo_compass_flo_meets';

  String? _authSubject;

  FloMeetsPreferences preferences = FloMeetsPreferences.empty;
  List<FloMeet> meets = [];
  Set<String> metPartnerIds = {};
  Set<String> completedRoundKeys = {};

  List<FloMeetRoom> rooms = [];
  Set<String> joinedRoomIds = {};
  List<FloMeetConnection> connections = [];
  bool demoSeedApplied = false;
  bool roomsLoading = false;
  String? roomsError;

  FloMeetsService get service => _service;
  FloMeetsRoomCatalog get roomCatalog => _roomCatalog;
  String? get authSubject => _authSubject;

  static String storageKeyFor(String subject) =>
      '${_legacyStorageKey}_$subject';

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    notifyListeners();
  }

  /// Loads persisted state for [subject]. Clears in-memory state when null (logout).
  Future<void> bindAuthSubject(String? subject) async {
    _prefs ??= await SharedPreferences.getInstance();
    if (_authSubject == subject) return;
    _authSubject = subject;
    _resetInMemory();
    if (subject != null) {
      await _migrateLegacyIfNeeded(subject);
      final raw = _prefs!.getString(storageKeyFor(subject));
      if (raw != null) {
        _loadFromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    }
    notifyListeners();
  }

  Future<void> _migrateLegacyIfNeeded(String subject) async {
    final scopedKey = storageKeyFor(subject);
    if (_prefs!.containsKey(scopedKey)) return;
    final legacy = _prefs!.getString(_legacyStorageKey);
    if (legacy != null) {
      await _prefs!.setString(scopedKey, legacy);
    }
  }

  void _resetInMemory() {
    preferences = FloMeetsPreferences.empty;
    meets = [];
    metPartnerIds = {};
    completedRoundKeys = {};
    joinedRoomIds = {};
    connections = [];
    demoSeedApplied = false;
    rooms = [];
    roomsError = null;
  }

  void _loadFromJson(Map<String, dynamic> json) {
    preferences = FloMeetsPreferences.fromJson(
      json['preferences'] as Map<String, dynamic>?,
    );
    meets = (json['meets'] as List<dynamic>? ?? [])
        .map((e) => FloMeet.fromJson(e as Map<String, dynamic>))
        .toList();
    final storedMetPartnerIds = (json['metPartnerIds'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toSet();
    metPartnerIds = {
      ...storedMetPartnerIds,
      ...meets.map((meet) => meet.partnerId),
    };
    completedRoundKeys = (json['completedRoundKeys'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toSet();
    joinedRoomIds = (json['joinedRoomIds'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toSet();
    connections = (json['connections'] as List<dynamic>? ?? [])
        .map((e) => FloMeetConnection.fromJson(e as Map<String, dynamic>))
        .toList();
    demoSeedApplied = json['demoSeedApplied'] as bool? ?? false;
  }

  Future<void> _persist() async {
    if (_authSubject == null) return;
    _prefs ??= await SharedPreferences.getInstance();
    final payload = {
      'preferences': preferences.toJson(),
      'meets': meets.map((m) => m.toJson()).toList(),
      'metPartnerIds': metPartnerIds.toList(),
      'completedRoundKeys': completedRoundKeys.toList(),
      'joinedRoomIds': joinedRoomIds.toList(),
      'connections': connections.map((c) => c.toJson()).toList(),
      'demoSeedApplied': demoSeedApplied,
    };
    await _prefs!.setString(storageKeyFor(_authSubject!), jsonEncode(payload));
  }

  Future<void> savePreferences(FloMeetsPreferences next) async {
    final normalized = next.coercedForSave();
    if (!normalized.isSetupComplete) {
      throw StateError('Incomplete Flo Meets preferences.');
    }
    preferences = normalized;
    await _persist();
    notifyListeners();
    await applyDemoSeedIfNeeded();
  }

  /// One-time demo Waiting + Match for a fresh authenticated subject.
  Future<void> applyDemoSeedIfNeeded() async {
    if (!enableDemoSeed) return;
    if (_authSubject == null) return;
    if (!preferences.isSetupComplete) return;
    if (demoSeedApplied) return;
    if (connections.isNotEmpty) {
      demoSeedApplied = true;
      await _persist();
      return;
    }

    if (rooms.isEmpty) await loadRooms();
    final published = rooms.where((r) => r.isPublished).toList();
    if (published.isEmpty) return;

    final room = published.first;
    await joinRoom(room.id);

    final partners = await _service.loadMockPartners();
    final byId = {for (final p in partners) p.id: p};
    final partnerIds = room.seedPartnerIds
        .where((id) => byId.containsKey(id))
        .toList();
    if (partnerIds.length < 2) return;

    final weights = await _service.loadWeights();
    final now = DateTime.now();

    final waitingPartner = byId[partnerIds[0]]!;
    final waitingPercent = _service.matchPercent(
      userPrefs: preferences,
      userRole: AttendeeRole.engineer,
      professionalInterests: const [],
      partner: waitingPartner,
      weights: weights,
    );
    final waitingTags = _service.overlapTags(
      userPrefs: preferences,
      professionalInterests: const [],
      partner: waitingPartner,
    );
    _upsertConnection(
      FloMeetConnection(
        id: 'conn-${room.id}-${waitingPartner.id}',
        roomId: room.id,
        partnerId: waitingPartner.id,
        partnerNickname: waitingPartner.nickname,
        matchPercent: waitingPercent,
        overlapTags: waitingTags,
        iConnected: true,
        meetAmenityId: preferences.meetAmenityId.isNotEmpty
            ? preferences.meetAmenityId
            : room.amenityId,
        createdAt: now,
      ),
    );

    final matchPartner = byId[partnerIds[1]]!;
    final matchPercent = _service.matchPercent(
      userPrefs: preferences,
      userRole: AttendeeRole.engineer,
      professionalInterests: const [],
      partner: matchPartner,
      weights: weights,
    );
    final matchTags = _service.overlapTags(
      userPrefs: preferences,
      professionalInterests: const [],
      partner: matchPartner,
    );
    final matchedAt = now.add(const Duration(minutes: 1));
    final meetId = 'meet-demo-${room.id}-${matchPartner.id}';
    final meet = FloMeet(
      id: meetId,
      slotKey: room.id,
      day: room.day,
      windowStart: room.windowStart,
      windowEnd: room.windowEnd,
      partnerId: matchPartner.id,
      partnerNickname: matchPartner.nickname,
      meetAmenityId: preferences.meetAmenityId.isNotEmpty
          ? preferences.meetAmenityId
          : room.amenityId,
      contactMedium: preferences.contactMedium,
      meetNote: preferences.meetNote,
      matchedAt: matchedAt,
    );
    meets = [...meets, meet];
    metPartnerIds = {...metPartnerIds, matchPartner.id};
    _upsertConnection(
      FloMeetConnection(
        id: 'conn-${room.id}-${matchPartner.id}',
        roomId: room.id,
        partnerId: matchPartner.id,
        partnerNickname: matchPartner.nickname,
        matchPercent: matchPercent,
        overlapTags: matchTags,
        iConnected: true,
        theyConnected: true,
        meetAmenityId: meet.meetAmenityId,
        meetId: meetId,
        createdAt: matchedAt,
        matchedAt: matchedAt,
      ),
    );

    demoSeedApplied = true;
    await _persist();
    notifyListeners();
  }

  /// Attendee view: published rooms only (seed + organizer overlay).
  Future<void> loadRooms({bool forOrganizer = false}) async {
    roomsLoading = true;
    roomsError = null;
    notifyListeners();
    try {
      rooms = await _roomCatalog.loadAll(publishedOnly: !forOrganizer);
    } catch (e) {
      roomsError = kDebugMode ? '$e' : 'Failed to load match rooms';
    } finally {
      roomsLoading = false;
      notifyListeners();
    }
    await applyDemoSeedIfNeeded();
  }

  FloMeetRoom? roomById(String id) {
    for (final room in rooms) {
      if (room.id == id) return room;
    }
    return null;
  }

  bool isJoined(String roomId) => joinedRoomIds.contains(roomId);

  int occupancyFor(FloMeetRoom room) {
    final self = isJoined(room.id) ? 1 : 0;
    return room.seedPartnerIds.length + self;
  }

  Future<bool> joinRoom(String roomId) async {
    final room = roomById(roomId) ?? await _roomCatalog.getById(roomId);
    if (room == null || !room.isPublished) return false;
    if (isJoined(roomId)) return true;
    if (occupancyFor(room) >= room.capacity) return false;
    joinedRoomIds = {...joinedRoomIds, roomId};
    if (!rooms.any((r) => r.id == roomId)) {
      rooms = [...rooms, room]
        ..sort((a, b) => a.windowStart.compareTo(b.windowStart));
    }
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> leaveRoom(String roomId) async {
    if (!isJoined(roomId)) return;
    joinedRoomIds = {...joinedRoomIds}..remove(roomId);
    await _persist();
    notifyListeners();
  }

  /// Seed partners for [roomId], ranked by match %. Requires prefs context.
  Future<List<RankedRoomMember>> membersForRoom({
    required String roomId,
    required AttendeeRole userRole,
    required List<String> professionalInterests,
  }) async {
    final room = roomById(roomId) ?? await _roomCatalog.getById(roomId);
    if (room == null) return [];
    final partners = await _service.loadMockPartners();
    final byId = {for (final p in partners) p.id: p};
    final inRoom = room.seedPartnerIds
        .map((id) => byId[id])
        .whereType<FloMeetPartner>()
        .toList();
    final weights = await _service.loadWeights();
    return _service.rankPartnersInRoom(
      userPrefs: preferences,
      userRole: userRole,
      professionalInterests: professionalInterests,
      partners: inRoom,
      weights: weights,
    );
  }

  FloMeetConnection? connectionFor(String roomId, String partnerId) {
    for (final c in connections) {
      if (c.roomId == roomId && c.partnerId == partnerId) return c;
    }
    return null;
  }

  List<FloMeetConnection> get waitingConnections =>
      connections.where((c) => c.isWaiting).toList();

  List<FloMeetConnection> get matches =>
      connections.where((c) => c.isMatch).toList();

  /// Symmetric Connect: sets [iConnected]. Mock partners reciprocate for demo.
  Future<FloMeetConnection?> connect({
    required String roomId,
    required String partnerId,
    required AttendeeRole userRole,
    required List<String> professionalInterests,
    NetworkingCard? networkingCard,
    bool reciprocateMockPartner = true,
  }) async {
    if (!preferences.isSetupComplete) return null;
    final room = roomById(roomId) ?? await _roomCatalog.getById(roomId);
    if (room == null) return null;

    final partners = await _service.loadMockPartners();
    FloMeetPartner? partner;
    for (final p in partners) {
      if (p.id == partnerId) {
        partner = p;
        break;
      }
    }
    if (partner == null) return null;

    final weights = await _service.loadWeights();
    final percent = _service.matchPercent(
      userPrefs: preferences,
      userRole: userRole,
      professionalInterests: professionalInterests,
      partner: partner,
      weights: weights,
    );
    final tags = _service.overlapTags(
      userPrefs: preferences,
      professionalInterests: professionalInterests,
      partner: partner,
    );
    final now = DateTime.now();
    final existing = connectionFor(roomId, partnerId);
    var connection =
        existing ??
        FloMeetConnection(
          id: 'conn-$roomId-$partnerId',
          roomId: roomId,
          partnerId: partnerId,
          partnerNickname: partner.nickname,
          matchPercent: percent,
          overlapTags: tags,
          meetAmenityId: preferences.meetAmenityId.isNotEmpty
              ? preferences.meetAmenityId
              : room.amenityId,
          createdAt: now,
        );

    connection = connection.copyWith(
      partnerNickname: partner.nickname,
      matchPercent: percent,
      overlapTags: tags,
      iConnected: true,
    );

    _upsertConnection(connection);
    await _persist();
    notifyListeners();

    if (reciprocateMockPartner && !connection.theyConnected) {
      if (demoReciprocateDelay > Duration.zero) {
        await Future<void>.delayed(demoReciprocateDelay);
      }
      connection = await _finalizeMatch(
        connection,
        room: room,
        networkingCard: networkingCard,
        matchedAt: DateTime.now(),
      );
    } else if (connection.isMatch && connection.meetId == null) {
      connection = await _finalizeMatch(
        connection,
        room: room,
        networkingCard: networkingCard,
        matchedAt: now,
      );
    }

    return connectionFor(roomId, partnerId) ?? connection;
  }

  Future<FloMeetConnection> _finalizeMatch(
    FloMeetConnection connection, {
    required FloMeetRoom room,
    NetworkingCard? networkingCard,
    required DateTime matchedAt,
  }) async {
    final withThem = connection.copyWith(
      theyConnected: true,
      matchedAt: matchedAt,
    );
    final contact = _contactSnapshot(networkingCard, preferences.contactMedium);
    final meet = FloMeet(
      id: 'meet-${room.id}-${connection.partnerId}-${matchedAt.millisecondsSinceEpoch}',
      slotKey: room.id,
      day: room.day,
      windowStart: room.windowStart,
      windowEnd: room.windowEnd,
      partnerId: connection.partnerId,
      partnerNickname: connection.partnerNickname,
      meetAmenityId: withThem.meetAmenityId,
      contactMedium: preferences.contactMedium,
      contactSnapshot: contact,
      meetNote: preferences.meetNote,
      matchedAt: matchedAt,
    );
    final finalized = withThem.copyWith(
      contactSnapshot: contact,
      meetId: meet.id,
      matchedAt: matchedAt,
    );
    _upsertConnection(finalized);
    if (!meets.any((m) => m.id == meet.id)) {
      meets = [...meets, meet];
    }
    metPartnerIds = {...metPartnerIds, meet.partnerId};
    await _persist();
    notifyListeners();
    return finalized;
  }

  void _upsertConnection(FloMeetConnection connection) {
    final index = connections.indexWhere(
      (c) =>
          c.roomId == connection.roomId && c.partnerId == connection.partnerId,
    );
    if (index < 0) {
      connections = [...connections, connection];
    } else {
      final next = [...connections];
      next[index] = connection;
      connections = next;
    }
  }

  static ShareField? _contactSnapshot(
    NetworkingCard? card,
    FloMeetContactMedium medium,
  ) {
    if (card == null || medium == FloMeetContactMedium.none) return null;
    final field = switch (medium) {
      FloMeetContactMedium.email => card.email,
      FloMeetContactMedium.phone => card.phoneE164,
      FloMeetContactMedium.linkedin => card.linkedInUrl,
      FloMeetContactMedium.none => null,
    };
    if (field == null || !field.visible || field.value.trim().isEmpty) {
      return null;
    }
    return field;
  }

  List<FloMeet> meetsForDay(String? day) {
    if (day == null) return [];
    return meets.where((m) => m.day == day).toList()
      ..sort((a, b) => a.windowStart.compareTo(b.windowStart));
  }

  FloMeet? meetById(String id) {
    for (final meet in meets) {
      if (meet.id == id) return meet;
    }
    return null;
  }

  bool hasMeetForSlot(String slotKey, String day) {
    return meets.any((m) => m.slotKey == slotKey && m.day == day);
  }

  FloMeet? nextMeetToday(String? day, DateTime now) {
    final today = meetsForDay(day);
    for (final meet in today) {
      if (!now.isAfter(meet.windowEnd)) return meet;
    }
    return null;
  }

  /// Deprecated T−30 auto-match path — no-op. Rooms + Connect are primary UX.
  Future<FloMeet?> runRoundTick({
    required DateTime now,
    required String? eventDay,
    required bool isAuthenticated,
    required AttendeeRole role,
    required List<String> professionalInterests,
    required NetworkingCard? networkingCard,
  }) async {
    return null;
  }

  /// Joins the first published room that still has capacity (demo).
  Future<FloMeetRoom?> joinFirstOpenRoom() async {
    if (rooms.isEmpty) await loadRooms();
    for (final room in rooms) {
      if (!room.isPublished) continue;
      if (isJoined(room.id)) return room;
      final ok = await joinRoom(room.id);
      if (ok) return roomById(room.id) ?? room;
    }
    return null;
  }

  Future<void> resetForTests() async {
    _resetInMemory();
    if (_authSubject != null) {
      await _persist();
    }
    notifyListeners();
  }
}
