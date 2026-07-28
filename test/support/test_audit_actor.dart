import 'package:flo_compass/core/auth/platform_role.dart';
import 'package:flo_compass/domain/entities/audit_actor.dart';

const testAuditActor = AuditActor(
  id: 'test-user',
  displayName: 'Test User',
  role: PlatformRole.organizer,
);
