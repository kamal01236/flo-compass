import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../auth/mock_user.dart';
import '../auth/platform_role.dart';
import 'app_config.dart';
import 'auth_config.dart';
import 'data_source.dart';
import 'feature_flags.dart';

class RuntimeConfig {
  RuntimeConfig._();

  static FeatureFlags flags = FeatureFlags.defaults;
  static DataSource dataSource = DataSource.mock;
  static String apiBaseUrl = '';
  static AuthConfig auth = AuthConfig.disabled;
  static PlatformRole? platformRoleOverride;
  static Set<String> organizerAllowlist = <String>{};
  static Set<String> adminAllowlist = <String>{};
  static List<MockUser> mockUsers = <MockUser>[];

  @visibleForTesting
  static bool mockLoginEnabledForTests = false;

  /// Maps a config profile name to its bundled JSON asset path.
  static String configAssetPathForProfile(String profile) {
    switch (AppConfig.normalizedConfigProfile(profile)) {
      case 'dev':
        return 'assets/config/config.dev.json';
      case 'prod':
        return 'assets/config/config.prod.json';
      default:
        return 'assets/config/config.default.json';
    }
  }

  static Future<void> load() async {
    final assetPath = configAssetPathForProfile(AppConfig.configProfile);
    try {
      final raw = await rootBundle.loadString(assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final flagMap = json['featureFlags'] as Map<String, dynamic>? ?? {};
      final platformRoles =
          json['platformRoles'] as Map<String, dynamic>? ?? {};
      flags = FeatureFlags.fromJson(flagMap);
      dataSource = DataSource.fromJson(json['dataSource'] as String?);
      apiBaseUrl = _resolveApiBaseUrl(json['apiBaseUrl'] as String?);
      auth = AuthConfig.fromJson(json['auth'] as Map<String, dynamic>?);
      platformRoleOverride = resolvePlatformRoleOverride(
        platformRoles['mockRole'] as String?,
      );
      organizerAllowlist = _parseAllowlist(platformRoles['organizerAllowlist']);
      adminAllowlist = _parseAllowlist(platformRoles['adminAllowlist']);
      mockUsers = _parseMockUsers(platformRoles['mockUsers']);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to load runtime config: $e');
      }
      flags = FeatureFlags.defaults;
      dataSource = DataSource.mock;
      apiBaseUrl = '';
      auth = AuthConfig.disabled;
      platformRoleOverride = null;
      organizerAllowlist = <String>{};
      adminAllowlist = <String>{};
      mockUsers = <MockUser>[];
    }
  }

  static String _resolveApiBaseUrl(String? fromJson) {
    const define = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (define.isNotEmpty) return define;
    return fromJson ?? '';
  }

  @visibleForTesting
  static PlatformRole? resolvePlatformRoleOverride(
    String? fromJson, {
    String? profile,
  }) {
    final effectiveProfile = AppConfig.normalizedConfigProfile(
      profile ?? AppConfig.configProfile,
    );
    if (effectiveProfile != 'dev') return null;
    const define = String.fromEnvironment(
      'MOCK_PLATFORM_ROLE',
      defaultValue: '',
    );
    final raw = define.isNotEmpty ? define : (fromJson ?? '');
    return PlatformRoleX.tryParse(raw);
  }

  static Set<String> _parseAllowlist(dynamic raw) {
    if (raw is! List) return <String>{};
    return raw
        .map((entry) => entry.toString().trim().toLowerCase())
        .where((entry) => entry.isNotEmpty)
        .toSet();
  }

  static List<MockUser> _parseMockUsers(dynamic raw) {
    if (raw is! List) return <MockUser>[];
    return raw
        .whereType<Map>()
        .map((entry) => MockUser.fromJson(Map<String, dynamic>.from(entry)))
        .whereType<MockUser>()
        .toList();
  }

  static bool get authEnabled => auth.isConfigured;

  /// Mock picker when [mockUsers] is non-empty (any config profile).
  static bool get mockLoginEnabled =>
      mockLoginEnabledForTests || mockUsers.isNotEmpty;
}
