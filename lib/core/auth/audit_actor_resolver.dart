import '../../core/config/runtime_config.dart';
import '../../core/di/service_locator.dart';
import '../../domain/entities/audit_actor.dart';
import 'auth_service.dart';
import 'platform_role.dart';

/// Resolves the current [AuditActor] from auth session or demo overrides.
class AuditActorResolver {
  const AuditActorResolver({AuthService? authService})
    : _authService = authService;

  final AuthService? _authService;

  AuditActor resolve() {
    final auth = _authService ?? _tryAuthService();
    if (auth != null) {
      final session = auth.session;
      if (session != null) {
        return AuditActor(
          id: session.subject,
          displayName: session.displayName,
          role: session.platformRole,
          email: session.email,
        );
      }
    }

    final override = RuntimeConfig.platformRoleOverride;
    if (override != null) {
      return AuditActor(
        id: 'demo-${override.name}',
        displayName: override.label,
        role: override,
      );
    }

    return AuditActor.anonymous;
  }

  AuthService? _tryAuthService() {
    if (!sl.isRegistered<AuthService>()) return null;
    return sl<AuthService>();
  }
}

/// Shared resolver instance for providers.
const auditActorResolver = AuditActorResolver();

AuditActor resolveAuditActor() => auditActorResolver.resolve();
