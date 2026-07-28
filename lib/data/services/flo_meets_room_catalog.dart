import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/flo_meet_room.dart';

/// Loads seeded Flo Meets rooms and merges organizer CRUD overlay from prefs.
class FloMeetsRoomCatalog {
  FloMeetsRoomCatalog({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _storageKey = 'flo_organizer_meet_rooms';
  static const _seedAsset = 'assets/data/flo_meets_rooms.json';

  List<FloMeetRoom>? _seedCache;

  Future<List<FloMeetRoom>> loadSeedRooms() async {
    if (_seedCache != null) return List.unmodifiable(_seedCache!);
    final raw = await rootBundle.loadString(_seedAsset);
    final list = jsonDecode(raw) as List<dynamic>;
    _seedCache = list
        .map((e) => FloMeetRoom.fromJson(e as Map<String, dynamic>))
        .toList();
    return List.unmodifiable(_seedCache!);
  }

  /// Seed rooms plus organizer overlay. Organizer entries replace seed by id.
  Future<List<FloMeetRoom>> loadAll({bool publishedOnly = false}) async {
    final seed = await loadSeedRooms();
    final overlay = await _loadOverlay();
    final byId = <String, FloMeetRoom>{for (final room in seed) room.id: room};
    for (final room in overlay) {
      byId[room.id] = room;
    }
    var rooms = byId.values.toList()
      ..sort((a, b) => a.windowStart.compareTo(b.windowStart));
    if (publishedOnly) {
      rooms = rooms.where((r) => r.isPublished).toList();
    }
    return rooms;
  }

  Future<List<FloMeetRoom>> listOrganizerRooms() async {
    final overlay = await _loadOverlay();
    return overlay..sort((a, b) => b.windowStart.compareTo(a.windowStart));
  }

  Future<FloMeetRoom?> getById(String id) async {
    final all = await loadAll();
    for (final room in all) {
      if (room.id == id) return room;
    }
    return null;
  }

  Future<FloMeetRoom> save(FloMeetRoom room) async {
    final items = await _loadOverlay();
    final index = items.indexWhere((item) => item.id == room.id);
    final saved = room.copyWith(source: FloMeetRoomSource.organizer);
    if (index < 0) {
      items.add(saved);
    } else {
      items[index] = saved;
    }
    await _persistOverlay(items);
    return saved;
  }

  Future<FloMeetRoom> publish(String id) async {
    final existing = await _overlayOrSeed(id);
    if (existing == null) {
      throw StateError('Meet room $id not found');
    }
    return save(
      existing.copyWith(
        status: FloMeetRoomStatus.published,
        source: FloMeetRoomSource.organizer,
      ),
    );
  }

  Future<FloMeetRoom> archive(String id) async {
    final existing = await _overlayOrSeed(id);
    if (existing == null) {
      throw StateError('Meet room $id not found');
    }
    return save(
      existing.copyWith(
        status: FloMeetRoomStatus.archived,
        source: FloMeetRoomSource.organizer,
      ),
    );
  }

  Future<void> delete(String id) async {
    final items = await _loadOverlay();
    items.removeWhere((item) => item.id == id);
    await _persistOverlay(items);
  }

  Future<FloMeetRoom?> _overlayOrSeed(String id) async {
    final overlay = await _loadOverlay();
    for (final room in overlay) {
      if (room.id == id) return room;
    }
    return getById(id);
  }

  Future<List<FloMeetRoom>> _loadOverlay() async {
    final prefs = await _ensurePrefs();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .map((e) => FloMeetRoom.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _persistOverlay(List<FloMeetRoom> items) async {
    final prefs = await _ensurePrefs();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Test helper: clear in-memory seed cache.
  void clearCacheForTests() {
    _seedCache = null;
  }
}
