enum PlatformRole { attendee, organizer, admin }

extension PlatformRoleX on PlatformRole {
  String get label => switch (this) {
    PlatformRole.attendee => 'Attendee',
    PlatformRole.organizer => 'Organizer',
    PlatformRole.admin => 'Admin',
  };

  bool get canModerateQa =>
      this == PlatformRole.organizer || this == PlatformRole.admin;

  bool get canPublishAnnouncement =>
      this == PlatformRole.organizer || this == PlatformRole.admin;

  bool get canManageOpsConfig => this == PlatformRole.admin;

  static PlatformRole? tryParse(String? raw) {
    if (raw == null) return null;
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    return switch (normalized) {
      'attendee' || 'user' || 'viewer' => PlatformRole.attendee,
      'organizer' ||
      'moderator' ||
      'ops' ||
      'operations' => PlatformRole.organizer,
      'admin' ||
      'administrator' ||
      'platform_admin' ||
      'platform-admin' ||
      'superadmin' => PlatformRole.admin,
      _ => null,
    };
  }
}
