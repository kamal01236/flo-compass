import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/core/auth/app_capability.dart';
import 'package:flo_compass/core/auth/auth_service.dart';
import 'package:flo_compass/core/auth/auth_session.dart';
import 'package:flo_compass/core/auth/platform_role.dart';
import 'package:flo_compass/core/config/auth_config.dart';
import 'package:flo_compass/core/config/runtime_config.dart';

void main() {
  late AuthConfig originalAuth;
  late PlatformRole? originalOverride;
  late Set<String> originalOrganizerAllowlist;
  late Set<String> originalAdminAllowlist;

  setUp(() {
    originalAuth = RuntimeConfig.auth;
    originalOverride = RuntimeConfig.platformRoleOverride;
    originalOrganizerAllowlist = RuntimeConfig.organizerAllowlist;
    originalAdminAllowlist = RuntimeConfig.adminAllowlist;
    RuntimeConfig.organizerAllowlist = <String>{};
    RuntimeConfig.adminAllowlist = <String>{};
    RuntimeConfig.platformRoleOverride = null;
  });

  tearDown(() {
    RuntimeConfig.auth = originalAuth;
    RuntimeConfig.platformRoleOverride = originalOverride;
    RuntimeConfig.organizerAllowlist = originalOrganizerAllowlist;
    RuntimeConfig.adminAllowlist = originalAdminAllowlist;
  });

  group('AuthService role resolution', () {
    test('resolves organizer/admin from claims', () {
      final service = AuthService();

      final organizerToken = _jwtWithPayload({
        'sub': 'user-1',
        'roles': ['organizer'],
      });
      final adminToken = _jwtWithPayload({
        'sub': 'user-1',
        'roles': ['organizer', 'admin'],
      });

      expect(
        service.resolvePlatformRole(subject: 'user-1', idToken: organizerToken),
        PlatformRole.organizer,
      );
      expect(
        service.resolvePlatformRole(subject: 'user-1', idToken: adminToken),
        PlatformRole.admin,
      );
    });

    test('falls back to allowlists when claims are missing', () {
      final service = AuthService();
      RuntimeConfig.organizerAllowlist = {'ops@example.com'};
      RuntimeConfig.adminAllowlist = {'admin@example.com'};
      final token = _jwtWithPayload({
        'sub': 'user-2',
        'preferred_username': 'admin@example.com',
      });

      expect(
        service.resolvePlatformRole(subject: 'user-2', idToken: token),
        PlatformRole.admin,
      );
    });

    test('prefers explicit runtime role override', () {
      final service = AuthService();
      RuntimeConfig.platformRoleOverride = PlatformRole.organizer;
      RuntimeConfig.adminAllowlist = {'admin@example.com'};
      final token = _jwtWithPayload({
        'sub': 'user-2',
        'preferred_username': 'admin@example.com',
        'roles': ['admin'],
      });

      expect(
        service.resolvePlatformRole(subject: 'user-2', idToken: token),
        PlatformRole.organizer,
      );
    });
  });

  group('AuthService capability matrix', () {
    test('auth disabled keeps attendee capabilities and role-gates ops', () {
      RuntimeConfig.auth = AuthConfig.disabled;
      RuntimeConfig.platformRoleOverride = PlatformRole.organizer;
      final service = AuthService();

      expect(service.hasCapability(AppCapability.earnXp), isTrue);
      expect(service.hasCapability(AppCapability.registerEvent), isTrue);
      expect(service.hasCapability(AppCapability.moderateQa), isTrue);
      expect(service.hasCapability(AppCapability.manageOpsConfig), isFalse);
    });

    test('auth enabled denies all capabilities for anonymous users', () {
      RuntimeConfig.auth = _enabledAuthConfig;
      final service = AuthService();

      expect(service.hasCapability(AppCapability.earnXp), isFalse);
      expect(service.hasCapability(AppCapability.moderateQa), isFalse);
    });

    test('authenticated attendee gets attendee-only capabilities', () {
      RuntimeConfig.auth = _enabledAuthConfig;
      final service = AuthService(
        initialSession: _session(PlatformRole.attendee),
      );

      expect(service.hasCapability(AppCapability.earnXp), isTrue);
      expect(service.hasCapability(AppCapability.moderateQa), isFalse);
      expect(service.hasCapability(AppCapability.manageOpsConfig), isFalse);
    });

    test('authenticated admin gets organizer and admin capabilities', () {
      RuntimeConfig.auth = _enabledAuthConfig;
      final service = AuthService(initialSession: _session(PlatformRole.admin));

      expect(service.hasCapability(AppCapability.earnXp), isTrue);
      expect(service.hasCapability(AppCapability.moderateQa), isTrue);
      expect(service.hasCapability(AppCapability.publishAnnouncement), isTrue);
      expect(service.hasCapability(AppCapability.manageOpsConfig), isTrue);
    });
  });
}

const _enabledAuthConfig = AuthConfig(
  enabled: true,
  tenantId: 'tenant',
  clientId: 'client',
  redirectUri: 'https://example.com/auth/callback',
  scopes: ['openid', 'profile'],
);

AuthSession _session(PlatformRole role) {
  return AuthSession(
    subject: 'user-1',
    displayName: 'Test User',
    idToken: 'id-token',
    accessToken: 'access-token',
    expiresAt: DateTime.now().add(const Duration(minutes: 30)),
    platformRole: role,
  );
}

String _jwtWithPayload(Map<String, Object?> payload) {
  final header = base64Url.encode(utf8.encode('{"alg":"none","typ":"JWT"}'));
  final body = base64Url.encode(utf8.encode(jsonEncode(payload)));
  return '$header.$body.signature';
}
