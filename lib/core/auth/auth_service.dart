import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../data/local/local_user_store.dart';
import '../../shared/utils/oauth_redirect.dart';
import '../config/runtime_config.dart';
import 'app_capability.dart';
import 'auth_session.dart';
import 'auth_token_provider.dart';
import 'mock_user.dart';
import 'platform_role.dart';

/// OAuth2 PKCE flow for optional Azure AD login.
class AuthService implements AuthTokenProvider {
  AuthService({LocalUserStore? store, AuthSession? initialSession})
    : _store = store ?? LocalUserStore(),
      _session = initialSession;

  final LocalUserStore _store;
  AuthSession? _session;
  String? _pendingVerifier;
  String? _pendingReturnUrl;
  String? _pendingAuthUrl;

  AuthSession? get session => _session?.isValid == true ? _session : null;
  bool get isAuthenticated => session != null;
  bool get isEnabled => RuntimeConfig.authEnabled;
  PlatformRole get platformRole =>
      session?.platformRole ??
      RuntimeConfig.platformRoleOverride ??
      PlatformRole.attendee;

  @override
  Future<String?> getAccessToken() => ensureFreshAccessToken();

  Future<void> restoreSession() async {
    try {
      final meta = await _store.readAuthMetadata();
      if (meta == null) {
        _session = null;
        return;
      }

      final platformRole = _platformRoleFromStored(meta.platformRole);
      _session = AuthSession(
        subject: meta.subject,
        displayName: meta.displayName,
        email: meta.email,
        idToken: meta.idToken ?? '',
        accessToken: meta.accessToken ?? '',
        expiresAt: meta.expiresAt,
        platformRole: platformRole,
      );

      if (_session!.accessToken.isEmpty) {
        _session = null;
        return;
      }

      if (_session!.isExpired) {
        final refreshToken = meta.refreshToken;
        if (refreshToken == null || refreshToken.isEmpty) {
          _session = null;
          await _store.clearAuthMetadata();
          return;
        }
        final refreshed = await _refresh(refreshToken);
        if (refreshed == null) {
          _session = null;
        }
      }
    } catch (_) {
      _session = null;
      await _store.clearAuthMetadata();
    }
  }

  @override
  Future<bool> refresh() async {
    final meta = await _store.readAuthMetadata();
    final refreshToken = meta?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }
    final refreshed = await _refresh(refreshToken);
    return refreshed != null;
  }

  Future<String?> ensureFreshAccessToken() async {
    final current = _session;
    if (current == null) return null;

    final expiresSoon =
        current.expiresAt.difference(DateTime.now()) <
        const Duration(seconds: 60);
    if (!current.isExpired && !expiresSoon) {
      return current.accessToken;
    }

    final meta = await _store.readAuthMetadata();
    final refreshToken = meta?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      if (current.isExpired) {
        await logout();
      }
      return current.isExpired ? null : current.accessToken;
    }

    final refreshed = await _refresh(refreshToken);
    return refreshed?.accessToken;
  }

  Future<AuthSession?> _refresh(String refreshToken) async {
    final config = RuntimeConfig.auth;
    final tokenUri = Uri.https(
      'login.microsoftonline.com',
      '/${config.tenantId}/oauth2/v2.0/token',
    );
    final body = {
      'client_id': config.clientId,
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
      'scope': config.scopes.join(' '),
    };

    final response = await OAuthRedirect.exchangeToken(tokenUri, body);
    if (response == null) {
      await logout();
      return null;
    }

    final expiresIn = response['expires_in'] as int? ?? 3600;
    final idToken = response['id_token'] as String? ?? _session?.idToken ?? '';
    final accessToken = response['access_token'] as String? ?? '';
    if (accessToken.isEmpty) {
      await logout();
      return null;
    }

    final subject = _subjectFromIdToken(idToken) ?? _session?.subject ?? 'user';
    final displayName =
        _nameFromIdToken(idToken) ?? _session?.displayName ?? subject;
    final email = _emailFromIdToken(idToken) ?? _session?.email;
    final platformRole = resolvePlatformRole(
      subject: subject,
      idToken: idToken,
    );
    final nextRefresh = response['refresh_token'] as String? ?? refreshToken;

    final session = AuthSession(
      subject: subject,
      displayName: displayName,
      email: email,
      idToken: idToken,
      accessToken: accessToken,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      platformRole: platformRole,
    );
    _session = session;
    await _store.saveAuthMetadata(
      subject: subject,
      displayName: displayName,
      email: email,
      expiresAt: session.expiresAt,
      idToken: idToken,
      accessToken: accessToken,
      refreshToken: nextRefresh,
      platformRole: platformRole.name,
    );
    return session;
  }

  PlatformRole _platformRoleFromStored(String? stored) {
    final parsed = PlatformRoleX.tryParse(stored);
    if (parsed != null) return parsed;
    return RuntimeConfig.platformRoleOverride ?? PlatformRole.attendee;
  }

  bool hasCapability(AppCapability capability) {
    if (!isEnabled) {
      if (_isRoleScoped(capability)) {
        return _roleHasCapability(platformRole, capability);
      }
      return true;
    }
    if (!isAuthenticated) return false;
    return _roleHasCapability(platformRole, capability);
  }

  String beginLogin({String returnUrl = '/profile'}) {
    final config = RuntimeConfig.auth;
    if (_pendingAuthUrl != null) return _pendingAuthUrl!;
    _pendingVerifier = _generateVerifier();
    _pendingReturnUrl = returnUrl;
    final challenge = _challengeFor(_pendingVerifier!);
    final state = _randomString(16);
    OAuthRedirect.storePkceState(
      verifier: _pendingVerifier!,
      returnUrl: returnUrl,
      state: state,
    );
    final query = {
      'client_id': config.clientId,
      'response_type': 'code',
      'redirect_uri': config.redirectUri,
      'response_mode': 'query',
      'scope': config.scopes.join(' '),
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      'state': state,
    };
    final uri = Uri.https(
      'login.microsoftonline.com',
      '/${config.tenantId}/oauth2/v2.0/authorize',
      query,
    );
    _pendingAuthUrl = uri.toString();
    return _pendingAuthUrl!;
  }

  Future<AuthSession?> handleCallback({
    required String? code,
    required String? state,
    required String? error,
  }) async {
    void clearPending() {
      _pendingVerifier = null;
      _pendingReturnUrl = null;
      _pendingAuthUrl = null;
      OAuthRedirect.clearPkceState();
    }

    if (error != null) {
      clearPending();
      return null;
    }
    if (code == null || code.isEmpty) {
      clearPending();
      return null;
    }

    final stored = OAuthRedirect.readPkceState();
    if (!validateOAuthState(state, stored?.state)) {
      clearPending();
      return null;
    }
    final verifier = stored?.verifier ?? _pendingVerifier;
    final returnUrl = stored?.returnUrl ?? _pendingReturnUrl ?? '/profile';
    if (verifier == null) {
      clearPending();
      return null;
    }

    final config = RuntimeConfig.auth;
    final tokenUri = Uri.https(
      'login.microsoftonline.com',
      '/${config.tenantId}/oauth2/v2.0/token',
    );

    final body = {
      'client_id': config.clientId,
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': config.redirectUri,
      'code_verifier': verifier,
    };

    final response = await OAuthRedirect.exchangeToken(tokenUri, body);
    if (response == null) {
      clearPending();
      return null;
    }

    final expiresIn = response['expires_in'] as int? ?? 3600;
    final idToken = response['id_token'] as String? ?? '';
    final accessToken = response['access_token'] as String? ?? '';
    final refreshToken = response['refresh_token'] as String?;
    final subject = _subjectFromIdToken(idToken) ?? 'user';
    final displayName = _nameFromIdToken(idToken) ?? subject;
    final email = _emailFromIdToken(idToken);
    final platformRole = resolvePlatformRole(
      subject: subject,
      idToken: idToken,
    );

    final session = AuthSession(
      subject: subject,
      displayName: displayName,
      email: email,
      idToken: idToken,
      accessToken: accessToken,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      platformRole: platformRole,
    );
    _session = session;
    await _store.saveAuthMetadata(
      subject: subject,
      displayName: displayName,
      email: email,
      expiresAt: session.expiresAt,
      idToken: idToken,
      accessToken: accessToken,
      refreshToken: refreshToken,
      platformRole: platformRole.name,
    );
    OAuthRedirect.clearPkceState();
    _pendingVerifier = null;
    _pendingReturnUrl = returnUrl;
    _pendingAuthUrl = null;
    return session;
  }

  String? consumeReturnUrl() {
    final url = _pendingReturnUrl ?? OAuthRedirect.readPkceState()?.returnUrl;
    _pendingReturnUrl = null;
    return url;
  }

  Future<void> logout() async {
    _session = null;
    await _store.clearAuthMetadata();
    OAuthRedirect.clearPkceState();
    _pendingAuthUrl = null;
  }

  /// Dev-only mock sign-in without OAuth (persists role in local storage).
  Future<void> signInMock(MockUser user) async {
    final expiresAt = DateTime.now().add(const Duration(days: 30));
    final accessToken = 'mock-${user.id}';
    final session = AuthSession(
      subject: user.id,
      displayName: user.name,
      email: user.email,
      idToken: '',
      accessToken: accessToken,
      expiresAt: expiresAt,
      platformRole: user.role,
    );
    _session = session;
    await _store.saveAuthMetadata(
      subject: user.id,
      displayName: user.name,
      email: user.email,
      expiresAt: expiresAt,
      idToken: '',
      accessToken: accessToken,
      platformRole: user.role.name,
    );
  }

  void setSessionForTesting(AuthSession? session) {
    _session = session;
  }

  /// Returns true when callback [state] matches [storedState] from PKCE storage.
  static bool validateOAuthState(String? state, String? storedState) {
    if (state == null || state.isEmpty) return false;
    if (storedState == null || storedState.isEmpty) return false;
    return state == storedState;
  }

  static String _generateVerifier() => _randomString(64);

  static String _challengeFor(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  static String _randomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  static String? _subjectFromIdToken(String idToken) {
    final payload = _decodeJwtPayload(idToken);
    return payload?['sub'] as String? ?? payload?['oid'] as String?;
  }

  static String? _nameFromIdToken(String idToken) {
    final payload = _decodeJwtPayload(idToken);
    return payload?['name'] as String? ??
        payload?['preferred_username'] as String?;
  }

  static String? _emailFromIdToken(String idToken) {
    final payload = _decodeJwtPayload(idToken);
    return payload?['email'] as String? ??
        payload?['preferred_username'] as String?;
  }

  PlatformRole resolvePlatformRole({
    required String subject,
    required String idToken,
  }) {
    final override = RuntimeConfig.platformRoleOverride;
    if (override != null) return override;

    final payload = _decodeJwtPayload(idToken);
    final roleFromClaims = _roleFromClaims(payload);
    if (roleFromClaims != null) return roleFromClaims;

    final identities = _roleIdentities(subject, payload);
    if (identities.any(RuntimeConfig.adminAllowlist.contains)) {
      return PlatformRole.admin;
    }
    if (identities.any(RuntimeConfig.organizerAllowlist.contains)) {
      return PlatformRole.organizer;
    }
    return PlatformRole.attendee;
  }

  static bool _isRoleScoped(AppCapability capability) {
    return switch (capability) {
      AppCapability.moderateQa ||
      AppCapability.publishAnnouncement ||
      AppCapability.manageOpsConfig => true,
      _ => false,
    };
  }

  static bool _roleHasCapability(PlatformRole role, AppCapability capability) {
    return switch (capability) {
      AppCapability.earnXp ||
      AppCapability.registerEvent ||
      AppCapability.attributedFeedback => true,
      AppCapability.moderateQa => role.canModerateQa,
      AppCapability.publishAnnouncement => role.canPublishAnnouncement,
      AppCapability.manageOpsConfig => role.canManageOpsConfig,
    };
  }

  static PlatformRole? _roleFromClaims(Map<String, dynamic>? payload) {
    if (payload == null) return null;
    PlatformRole? resolved;
    for (final raw in _claimRoleValues(payload)) {
      final next = PlatformRoleX.tryParse(raw);
      if (next == null) continue;
      if (next == PlatformRole.admin) return next;
      if (next == PlatformRole.organizer) resolved = next;
      resolved ??= next;
    }
    return resolved;
  }

  static Set<String> _roleIdentities(
    String subject,
    Map<String, dynamic>? payload,
  ) {
    final ids = <String>{subject.trim().toLowerCase()};
    if (payload == null) return ids;
    for (final key in ['oid', 'sub', 'email', 'upn', 'preferred_username']) {
      final value = payload[key];
      if (value is String && value.trim().isNotEmpty) {
        ids.add(value.trim().toLowerCase());
      }
    }
    return ids;
  }

  static Iterable<String> _claimRoleValues(Map<String, dynamic> payload) sync* {
    const roleKeys = [
      'platform_role',
      'platformRole',
      'flo_role',
      'floRole',
      'role',
      'roles',
      'app_roles',
      'extension_platformRole',
    ];
    for (final key in roleKeys) {
      final value = payload[key];
      if (value is String) {
        yield* value
            .split(RegExp(r'[, ]+'))
            .where((entry) => entry.trim().isNotEmpty);
      } else if (value is List) {
        for (final entry in value) {
          final asString = entry.toString().trim();
          if (asString.isNotEmpty) {
            yield asString;
          }
        }
      }
    }
  }

  static Map<String, dynamic>? _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
