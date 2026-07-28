import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/services/meet_nickname_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('suggest returns nickname from pool', () async {
    final service = MeetNicknameService(random: _FixedRandom(0));
    final nickname = await service.suggest();
    expect(nickname, isNotEmpty);
    expect(nickname.length, greaterThanOrEqualTo(3));
  });

  test('validate rejects short nicknames', () {
    final service = MeetNicknameService();
    expect(service.validate('ab'), isNotEmpty);
  });

  test('validate detects collision', () {
    final service = MeetNicknameService();
    expect(service.validate('Nova', taken: {'Nova'}), isNotEmpty);
    expect(service.isCollision('Nova', {'Nova'}), isTrue);
  });
}

class _FixedRandom implements Random {
  _FixedRandom(this.value);
  final int value;
  @override
  int nextInt(int max) => value % max;
  @override
  double nextDouble() => 0;
  @override
  bool nextBool() => false;
}
