import 'platform_role.dart';

class AuthSession {
  const AuthSession({
    required this.subject,
    required this.displayName,
    this.email,
    required this.idToken,
    required this.accessToken,
    required this.expiresAt,
    required this.platformRole,
  });

  final String subject;
  final String displayName;
  final String? email;
  final String idToken;
  final String accessToken;
  final DateTime expiresAt;
  final PlatformRole platformRole;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isValid => !isExpired && accessToken.isNotEmpty;
}
