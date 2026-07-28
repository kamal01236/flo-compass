import 'package:flutter_test/flutter_test.dart';

import 'package:flo_compass/core/consent/consent_service.dart';
import 'package:flo_compass/data/local/local_user_store.dart';
import 'package:flo_compass/providers/consent_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('acceptPrivacy sets hasAcceptedPrivacy', () async {
    final store = LocalUserStore();
    final state = ConsentState(service: ConsentService(store: store));
    await state.init();
    expect(state.hasAcceptedPrivacy, isFalse);
    await state.acceptPrivacy();
    expect(state.hasAcceptedPrivacy, isTrue);
    expect(state.acceptedAt, isNotNull);
  });
}
