import 'package:flutter/foundation.dart';

import '../core/auth/audit_actor_resolver.dart';
import '../core/di/service_locator.dart';
import '../data/repositories/mock_announcement_repository.dart';
import '../data/services/audit_log_service.dart';
import '../domain/entities/organizer_announcement.dart';
import '../domain/repositories/announcement_repository.dart';
import 'ops_config_provider.dart';

AnnouncementRepository _defaultAnnouncementRepository() {
  if (sl.isRegistered<AnnouncementRepository>()) {
    return sl<AnnouncementRepository>();
  }
  return MockAnnouncementRepository();
}

class AnnouncementState extends ChangeNotifier {
  AnnouncementState({AnnouncementRepository? repository})
    : _repository = repository ?? _defaultAnnouncementRepository();

  final AnnouncementRepository _repository;

  bool loading = false;
  String? error;
  List<OrganizerAnnouncement> announcements = [];
  List<OrganizerAnnouncement> publishedAnnouncements = [];

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      announcements = await _repository.listAll();
      publishedAnnouncements = await _repository.listPublished();
    } catch (e) {
      error = kDebugMode ? '$e' : 'Failed to load announcements';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<OrganizerAnnouncement?> getById(String id) => _repository.getById(id);

  Future<OrganizerAnnouncement> saveDraft({
    String? id,
    required String title,
    required String body,
  }) async {
    final actor = resolveAuditActor();
    final now = DateTime.now();
    final announcement = OrganizerAnnouncement(
      id: id ?? 'ann-${now.millisecondsSinceEpoch}',
      title: title.trim(),
      body: body.trim(),
      status: AnnouncementStatus.draft,
      createdAt: now,
      updatedAt: now,
      createdBy: actor,
    );
    final saved = await _repository.save(announcement, actor: actor);
    await load();
    await recordAudit(
      action: AuditActions.announcementDraftSave,
      entityType: 'announcement',
      entityId: saved.id,
    );
    return saved;
  }

  Future<OrganizerAnnouncement> publish(String id) async {
    final actor = resolveAuditActor();
    final saved = await _repository.publish(id, actor: actor);
    await load();
    await recordAudit(
      action: AuditActions.announcementPublish,
      entityType: 'announcement',
      entityId: id,
    );
    return saved;
  }

  Future<OrganizerAnnouncement> archive(String id) async {
    final actor = resolveAuditActor();
    final saved = await _repository.archive(id, actor: actor);
    await load();
    await recordAudit(
      action: AuditActions.announcementArchive,
      entityType: 'announcement',
      entityId: id,
    );
    return saved;
  }

  Future<void> delete(String id) async {
    final actor = resolveAuditActor();
    await _repository.delete(id, actor: actor);
    await load();
    await recordAudit(
      action: AuditActions.announcementDelete,
      entityType: 'announcement',
      entityId: id,
    );
  }

  int get recentPublishedCount => publishedAnnouncements.length;
}
