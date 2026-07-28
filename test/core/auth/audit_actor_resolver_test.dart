import 'package:flo_compass/core/auth/audit_actor_resolver.dart';
import 'package:flo_compass/core/auth/auth_service.dart';
import 'package:flo_compass/core/auth/auth_session.dart';
import 'package:flo_compass/core/auth/platform_role.dart';
import 'package:flo_compass/core/config/runtime_config.dart';
import 'package:flo_compass/domain/entities/audit_actor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuditActorResolver', () {
    tearDown(() {
      RuntimeConfig.platformRoleOverride = null;
    });

    test('resolve uses signed-in session subject and role', () {
      final resolver = AuditActorResolver(
        authService: AuthService(
          initialSession: AuthSession(
            subject: 'user-42',
            displayName: 'Jane Organizer',
            email: 'jane@example.com',
            idToken: '',
            accessToken: 'token',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
            platformRole: PlatformRole.organizer,
          ),
        ),
      );

      final actor = resolver.resolve();

      expect(actor.id, 'user-42');
      expect(actor.displayName, 'Jane Organizer');
      expect(actor.role, PlatformRole.organizer);
    });

    test('resolve falls back to platform role override', () {
      RuntimeConfig.platformRoleOverride = PlatformRole.admin;
      final resolver = AuditActorResolver();

      final actor = resolver.resolve();

      expect(actor.id, 'demo-admin');
      expect(actor.displayName, 'Admin');
      expect(actor.role, PlatformRole.admin);
    });

    test('resolve returns anonymous when no auth context', () {
      final resolver = AuditActorResolver();

      final actor = resolver.resolve();

      expect(actor, AuditActor.anonymous);
    });
  });

  group('AuditActor JSON', () {
    test('fromJson defaults missing fields to anonymous', () {
      final actor = AuditActor.fromJson({});

      expect(actor.id, 'unknown');
      expect(actor.displayName, 'Unknown');
      expect(actor.role, PlatformRole.attendee);
    });

    test('fromJson accepts actorId alias from overlay schemas', () {
      final actor = AuditActor.fromJson({
        'actorId': 'oid-1',
        'displayName': 'Demo User',
        'role': 'organizer',
      });

      expect(actor.id, 'oid-1');
      expect(actor.role, PlatformRole.organizer);
    });

    test('round-trips through toJson', () {
      const actor = AuditActor(
        id: 'oid-1',
        displayName: 'Demo User',
        role: PlatformRole.organizer,
      );

      final restored = AuditActor.fromJson(actor.toJson());

      expect(restored.id, actor.id);
      expect(restored.displayName, actor.displayName);
      expect(restored.role, actor.role);
    });
  });
}
