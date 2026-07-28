import 'package:flo_compass/core/auth/platform_role.dart';
import 'package:flo_compass/data/services/audit_log_service.dart';
import 'package:flo_compass/domain/entities/audit_actor.dart';
import 'package:flo_compass/providers/ops_config_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuditLogService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('records structured events and loads them back', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = AuditLogService(prefs: prefs);
      const actor = AuditActor(
        id: 'admin-1',
        displayName: 'Admin User',
        role: PlatformRole.admin,
      );

      await service.record(
        action: AuditActions.opsAllowlistsUpdate,
        actor: actor,
        entityType: 'ops_config',
      );

      final entries = await service.loadRecent();
      expect(entries, hasLength(1));
      expect(entries.first.action, AuditActions.opsAllowlistsUpdate);
      expect(entries.first.actor.id, 'admin-1');
      expect(entries.first.entityType, 'ops_config');
    });

    test('migrates legacy unstructured actor strings on read', () async {
      SharedPreferences.setMockInitialValues({
        'flo_compass_ops_audit':
            '[{"action":"Published announcement ann-1","actor":"Organizer","timestamp":1000}]',
      });
      final service = AuditLogService();

      final entries = await service.loadRecent();

      expect(entries, hasLength(1));
      expect(entries.first.action, 'Published announcement ann-1');
      expect(entries.first.actor.displayName, 'Organizer');
    });
  });

  group('recordAudit helper', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('is best-effort and does not throw', () async {
      await expectLater(
        recordAudit(
          action: AuditActions.planToggle,
          entityType: 'plan',
          entityId: 's-001',
        ),
        completes,
      );
    });
  });
}
