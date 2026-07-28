import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/data/repositories/mock_announcement_repository.dart';
import 'package:flo_compass/domain/entities/organizer_announcement.dart';

import '../../support/test_audit_actor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves draft and publishes announcement', () async {
    final prefs = await SharedPreferences.getInstance();
    final repository = MockAnnouncementRepository(prefs: prefs);
    final now = DateTime(2026, 7, 12, 10);

    final draft = await repository.save(
      OrganizerAnnouncement(
        id: 'ann-1',
        title: 'Room change',
        body: 'Keynote moved to Hall A.',
        status: AnnouncementStatus.draft,
        createdAt: now,
      ),
      actor: testAuditActor,
    );
    expect(draft.status, AnnouncementStatus.draft);
    expect(draft.createdBy?.id, testAuditActor.id);

    final published = await repository.publish('ann-1', actor: testAuditActor);
    expect(published.status, AnnouncementStatus.published);
    expect(published.publishedAt, isNotNull);
    expect(published.publishedBy?.id, testAuditActor.id);

    final listed = await repository.listPublished();
    expect(listed, hasLength(1));
    expect(listed.first.title, 'Room change');
  });

  test('archives published announcement', () async {
    final prefs = await SharedPreferences.getInstance();
    final repository = MockAnnouncementRepository(prefs: prefs);
    final now = DateTime(2026, 7, 12, 10);

    await repository.save(
      OrganizerAnnouncement(
        id: 'ann-2',
        title: 'Lunch update',
        body: 'Cafeteria opens at 12:30.',
        status: AnnouncementStatus.draft,
        createdAt: now,
      ),
      actor: testAuditActor,
    );
    await repository.publish('ann-2', actor: testAuditActor);
    final archived = await repository.archive('ann-2', actor: testAuditActor);

    expect(archived.status, AnnouncementStatus.archived);
    expect((await repository.listPublished()), isEmpty);
    expect((await repository.listAll()), hasLength(1));
  });
}
