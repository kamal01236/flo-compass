import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/core/auth/mock_user.dart';
import 'package:flo_compass/core/auth/platform_role.dart';
import 'package:flo_compass/core/config/app_config.dart';
import 'package:flo_compass/core/config/runtime_config.dart';

const _sampleMockUser = MockUser(
  id: 'demo-user',
  name: 'Demo User',
  email: 'demo@example.com',
  organization: 'ai-avengers',
  role: PlatformRole.attendee,
);

void main() {
  group('AppConfig.normalizedConfigProfile', () {
    test('lowercases Dev to dev', () {
      expect(AppConfig.normalizedConfigProfile('Dev'), 'dev');
    });

    test('trims whitespace', () {
      expect(AppConfig.normalizedConfigProfile('  prod  '), 'prod');
    });
  });

  group('RuntimeConfig.configAssetPathForProfile', () {
    test('Dev resolves to dev config asset', () {
      expect(
        RuntimeConfig.configAssetPathForProfile('Dev'),
        'assets/config/config.dev.json',
      );
    });

    test('unknown profile resolves to default config asset', () {
      expect(
        RuntimeConfig.configAssetPathForProfile('staging'),
        'assets/config/config.default.json',
      );
    });
  });

  group('RuntimeConfig.resolvePlatformRoleOverride', () {
    test('mockRole admin applies only on dev profile', () {
      expect(
        RuntimeConfig.resolvePlatformRoleOverride('admin', profile: 'dev'),
        PlatformRole.admin,
      );
      expect(
        RuntimeConfig.resolvePlatformRoleOverride('admin', profile: 'Dev'),
        PlatformRole.admin,
      );
      expect(
        RuntimeConfig.resolvePlatformRoleOverride('admin', profile: 'default'),
        isNull,
      );
    });
  });

  group('RuntimeConfig.mockLoginEnabled', () {
    tearDown(() {
      RuntimeConfig.mockUsers = <MockUser>[];
      RuntimeConfig.mockLoginEnabledForTests = false;
    });

    test('is true when mockUsers is non-empty on any profile', () {
      RuntimeConfig.mockUsers = const [_sampleMockUser];
      RuntimeConfig.mockLoginEnabledForTests = false;

      expect(RuntimeConfig.mockLoginEnabled, isTrue);
    });

    test('is false when mockUsers is empty and test override off', () {
      RuntimeConfig.mockUsers = <MockUser>[];
      RuntimeConfig.mockLoginEnabledForTests = false;

      expect(RuntimeConfig.mockLoginEnabled, isFalse);
    });

    test('is true when mockLoginEnabledForTests is set', () {
      RuntimeConfig.mockUsers = <MockUser>[];
      RuntimeConfig.mockLoginEnabledForTests = true;

      expect(RuntimeConfig.mockLoginEnabled, isTrue);
    });
  });
}
