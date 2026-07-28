import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flo_compass/core/auth/auth_service.dart';
import 'package:flo_compass/core/auth/mock_user.dart';
import 'package:flo_compass/core/auth/platform_role.dart';
import 'package:flo_compass/core/config/auth_config.dart';
import 'package:flo_compass/core/config/runtime_config.dart';
import 'package:flo_compass/data/local/local_user_store.dart';

void main() {
  const kamlesh = MockUser(
    id: 'kamlesh',
    name: 'Kamlesh Kumar',
    email: 'kamlesh.kumar@demo.flo-compass.example',
    organization: 'ai-avengers',
    role: PlatformRole.admin,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RuntimeConfig.auth = AuthConfig.disabled;
    RuntimeConfig.platformRoleOverride = null;
  });

  test('signInMock persists session and platform role', () async {
    final store = LocalUserStore();
    final service = AuthService(store: store);

    await service.signInMock(kamlesh);

    expect(service.isAuthenticated, isTrue);
    expect(service.platformRole, PlatformRole.admin);
    expect(service.session?.displayName, 'Kamlesh Kumar');
    expect(service.session?.email, 'kamlesh.kumar@demo.flo-compass.example');

    final restored = AuthService(store: store);
    await restored.restoreSession();

    expect(restored.isAuthenticated, isTrue);
    expect(restored.platformRole, PlatformRole.admin);
    expect(restored.session?.email, 'kamlesh.kumar@demo.flo-compass.example');
  });

  test('logout clears mock session', () async {
    final service = AuthService();
    await service.signInMock(kamlesh);
    await service.logout();

    expect(service.isAuthenticated, isFalse);
    expect(service.platformRole, PlatformRole.attendee);
  });
}
