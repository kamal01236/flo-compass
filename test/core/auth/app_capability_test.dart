import 'package:flutter_test/flutter_test.dart';

import 'package:flo_compass/core/auth/app_capability.dart';
import 'package:flo_compass/core/auth/auth_service.dart';
import 'package:flo_compass/data/local/local_user_store.dart';

void main() {
  test('disabled auth grants all capabilities', () {
    final service = AuthService(store: LocalUserStore());
    expect(service.hasCapability(AppCapability.earnXp), isTrue);
    expect(service.hasCapability(AppCapability.registerEvent), isTrue);
  });
}
