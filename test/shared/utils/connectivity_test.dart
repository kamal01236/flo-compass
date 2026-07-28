import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/shared/utils/connectivity.dart';

void main() {
  group('ConnectivityPlatform stub', () {
    test('isOnline is always true in VM tests', () {
      expect(ConnectivityPlatform.isOnline, isTrue);
    });

    test('onlineStream emits true', () async {
      await expectLater(ConnectivityPlatform.onlineStream, emits(true));
    });
  });
}
