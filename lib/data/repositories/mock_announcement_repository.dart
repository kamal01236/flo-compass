import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/audit_actor.dart';
import '../../domain/entities/organizer_announcement.dart';
import '../../domain/repositories/announcement_repository.dart';

class MockAnnouncementRepository implements AnnouncementRepository {
  MockAnnouncementRepository({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _storageKey = 'flo_organizer_announcements';

  @override
  Future<List<OrganizerAnnouncement>> listAll() async {
    final items = await _loadAll();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Future<List<OrganizerAnnouncement>> listPublished() async {
    final items = await listAll();
    return items
        .where((item) => item.status == AnnouncementStatus.published)
        .toList();
  }

  @override
  Future<OrganizerAnnouncement?> getById(String id) async {
    final items = await _loadAll();
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<OrganizerAnnouncement> save(
    OrganizerAnnouncement announcement, {
    required AuditActor actor,
  }) async {
    final items = await _loadAll();
    final now = DateTime.now();
    final index = items.indexWhere((item) => item.id == announcement.id);
    final isNew = index < 0;
    final saved = announcement.copyWith(
      updatedAt: now,
      updatedBy: actor,
      createdBy: isNew ? actor : (announcement.createdBy ?? actor),
    );
    if (isNew) {
      items.add(saved);
    } else {
      items[index] = saved;
    }
    await _persist(items);
    return saved;
  }

  @override
  Future<OrganizerAnnouncement> publish(
    String id, {
    required AuditActor actor,
  }) async {
    final existing = await getById(id);
    if (existing == null) {
      throw StateError('Announcement $id not found');
    }
    final now = DateTime.now();
    return save(
      existing.copyWith(
        status: AnnouncementStatus.published,
        publishedAt: now,
        publishedBy: actor,
      ),
      actor: actor,
    );
  }

  @override
  Future<OrganizerAnnouncement> archive(
    String id, {
    required AuditActor actor,
  }) async {
    final existing = await getById(id);
    if (existing == null) {
      throw StateError('Announcement $id not found');
    }
    return save(
      existing.copyWith(status: AnnouncementStatus.archived),
      actor: actor,
    );
  }

  @override
  Future<void> delete(String id, {required AuditActor actor}) async {
    final items = await _loadAll();
    items.removeWhere((item) => item.id == id);
    await _persist(items);
  }

  Future<List<OrganizerAnnouncement>> _loadAll() async {
    final prefs = await _ensurePrefs();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .map(
          (e) => OrganizerAnnouncement.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<void> _persist(List<OrganizerAnnouncement> items) async {
    final prefs = await _ensurePrefs();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }
}
