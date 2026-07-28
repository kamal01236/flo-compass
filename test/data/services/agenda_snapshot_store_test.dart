import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/data/services/agenda_session_fingerprint.dart';
import 'package:flo_compass/data/services/agenda_snapshot_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late AgendaSnapshotStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = AgendaSnapshotStore(prefs: prefs);
  });

  test('persists and restores snapshots', () async {
    final fp = AgendaSessionFingerprint(
      title: 'Keynote',
      venueId: 'ven-G01',
      startTime: '09:00',
      endTime: '10:00',
      day: 'Day 1',
      exists: true,
    );
    await store.set('s-001', fp);
    final loaded = await store.loadAll();
    expect(loaded['s-001']?.venueId, 'ven-G01');
    expect(loaded['s-001']?.title, 'Keynote');
  });

  test('prune removes ids outside watched set', () async {
    await store.set(
      's-001',
      AgendaSessionFingerprint(
        title: 'A',
        venueId: 'ven-G01',
        startTime: '09:00',
        endTime: '10:00',
        day: 'Day 1',
        exists: true,
      ),
    );
    await store.set(
      's-002',
      AgendaSessionFingerprint(
        title: 'B',
        venueId: 'ven-G02',
        startTime: '10:00',
        endTime: '11:00',
        day: 'Day 1',
        exists: true,
      ),
    );
    await store.prune({'s-001'});
    final loaded = await store.loadAll();
    expect(loaded.keys, {'s-001'});
  });

  test('remove deletes a single snapshot', () async {
    await store.set(
      's-001',
      AgendaSessionFingerprint(
        title: 'A',
        venueId: 'ven-G01',
        startTime: '09:00',
        endTime: '10:00',
        day: 'Day 1',
        exists: true,
      ),
    );
    await store.remove('s-001');
    expect(await store.loadAll(), isEmpty);
  });
}
