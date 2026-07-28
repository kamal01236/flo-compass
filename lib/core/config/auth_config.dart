class AuthConfig {
  const AuthConfig({
    required this.enabled,
    required this.tenantId,
    required this.clientId,
    required this.redirectUri,
    required this.scopes,
  });

  final bool enabled;
  final String tenantId;
  final String clientId;
  final String redirectUri;
  final List<String> scopes;

  static const AuthConfig disabled = AuthConfig(
    enabled: false,
    tenantId: '',
    clientId: '',
    redirectUri: '',
    scopes: ['openid', 'profile', 'email', 'offline_access'],
  );

  bool get isConfigured =>
      enabled &&
      tenantId.isNotEmpty &&
      clientId.isNotEmpty &&
      redirectUri.isNotEmpty;

  factory AuthConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AuthConfig.disabled;
    final scopes = json['scopes'];
    return AuthConfig(
      enabled: json['enabled'] as bool? ?? false,
      tenantId: json['tenantId'] as String? ?? '',
      clientId: json['clientId'] as String? ?? '',
      redirectUri: json['redirectUri'] as String? ?? '',
      scopes: scopes is List
          ? scopes.map((e) => e.toString()).toList()
          : const ['openid', 'profile', 'email', 'offline_access'],
    );
  }
}
