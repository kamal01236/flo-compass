import '../entities/audit_actor.dart';
import '../entities/organizer_announcement.dart';

abstract class AnnouncementRepository {
  Future<List<OrganizerAnnouncement>> listAll();
  Future<List<OrganizerAnnouncement>> listPublished();
  Future<OrganizerAnnouncement?> getById(String id);
  Future<OrganizerAnnouncement> save(
    OrganizerAnnouncement announcement, {
    required AuditActor actor,
  });
  Future<OrganizerAnnouncement> publish(String id, {required AuditActor actor});
  Future<OrganizerAnnouncement> archive(String id, {required AuditActor actor});
  Future<void> delete(String id, {required AuditActor actor});
}
