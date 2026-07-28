import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/core/auth/platform_role.dart';
import 'package:flo_compass/data/services/ops_audit_service.dart';
import 'package:flo_compass/domain/entities/audit_actor.dart';
import 'package:flo_compass/features/operations/widgets/audit_event_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'OpsAuditService loads structured events from shared audit log',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final auditLog = AuditLogService(prefs: prefs);
      await auditLog.record(
        action: AuditActions.announcementPublish,
        actor: const AuditActor(
          id: 'admin-1',
          displayName: 'Admin User',
          role: PlatformRole.admin,
        ),
        entityType: 'announcement',
        entityId: 'ann-42',
      );

      final entries = await OpsAuditService(auditLog: auditLog).loadRecent();
      expect(entries, hasLength(1));
      expect(entries.first.action, AuditActions.announcementPublish);
      expect(entries.first.actor.displayName, 'Admin User');
      expect(entries.first.entityId, 'ann-42');
    },
  );

  testWidgets('audit event tile shows action, actor chip, and entity', (
    tester,
  ) async {
    const entry = AuditEvent(
      action: AuditActions.announcementPublish,
      actor: AuditActor(
        id: 'admin-1',
        displayName: 'Admin User',
        role: PlatformRole.admin,
      ),
      timestamp: 1_752_378_600000,
      entityType: 'announcement',
      entityId: 'ann-42',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AuditEventTile(entry: entry)),
      ),
    );

    expect(find.text(AuditActions.announcementPublish), findsOneWidget);
    expect(find.textContaining('Admin User · Admin'), findsOneWidget);
    expect(find.textContaining('announcement · ann-42'), findsOneWidget);
  });
}
