import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/data/services/navigation_history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NavigationHistoryService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = NavigationHistoryService();
  });

  test('dedupes by route and keeps max 10', () async {
    for (var i = 0; i < 12; i++) {
      await service.record(route: '/session/s-$i', label: 'Session $i');
    }
    final entries = await service.load();
    expect(entries.length, 10);
    expect(entries.first.route, '/session/s-11');
  });

  test('duplicate route bumps to top', () async {
    await service.record(route: '/session/s-001', label: 'First');
    await service.record(route: '/session/s-002', label: 'Second');
    await service.record(route: '/session/s-001', label: 'First again');
    final entries = await service.load();
    expect(entries, hasLength(2));
    expect(entries.first.route, '/session/s-001');
    expect(entries.first.label, 'First again');
  });

  test('clear removes all entries', () async {
    await service.record(route: '/session/s-001', label: 'One');
    await service.clear();
    expect(await service.load(), isEmpty);
  });
}
