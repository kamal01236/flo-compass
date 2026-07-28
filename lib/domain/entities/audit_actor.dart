import '../../core/auth/platform_role.dart';

/// Identifies who performed an auditable action.
class AuditActor {
  const AuditActor({
    required this.id,
    required this.displayName,
    required this.role,
    this.email,
  });

  final String id;
  final String displayName;
  final PlatformRole role;
  final String? email;

  static const system = AuditActor(
    id: 'system',
    displayName: 'System',
    role: PlatformRole.admin,
  );

  static const anonymous = AuditActor(
    id: 'anonymous',
    displayName: 'Anonymous',
    role: PlatformRole.attendee,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'actorId': id,
    'displayName': displayName,
    'role': role.name,
    if (email != null) 'email': email,
  };

  factory AuditActor.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AuditActor.anonymous;
    return AuditActor(
      id: json['id'] as String? ?? json['actorId'] as String? ?? 'unknown',
      displayName: json['displayName'] as String? ?? 'Unknown',
      role:
          PlatformRoleX.tryParse(json['role'] as String?) ??
          PlatformRole.attendee,
      email: json['email'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditActor &&
          id == other.id &&
          displayName == other.displayName &&
          role == other.role &&
          email == other.email;

  @override
  int get hashCode => Object.hash(id, displayName, role, email);
}
