import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/core/analytics/analytics_event.dart';
import 'package:flo_compass/core/analytics/sinks/local_ring_buffer_sink.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalRingBufferSink', () {
    test('evicts oldest events when capacity exceeded', () async {
      final sink = LocalRingBufferSink(capacity: 3);
      for (var i = 0; i < 5; i++) {
        await sink.emit(
          AnalyticsEvent(
            name: 'event_$i',
            timestamp: DateTime.utc(2026, 7, 13, i),
          ),
        );
      }
      final all = await sink.readAll();
      expect(all, hasLength(3));
      expect(all.map((e) => e.name), ['event_2', 'event_3', 'event_4']);
    });

    test('exportJson round-trips events', () async {
      final sink = LocalRingBufferSink(capacity: 5);
      await sink.emit(
        AnalyticsEvent(
          name: 'screen_view',
          timestamp: DateTime.utc(2026, 7, 13),
          route: '/discover',
          properties: const {'route': '/discover'},
        ),
      );
      final json = await sink.exportJson();
      expect(json, contains('screen_view'));
      expect(json, contains('/discover'));
    });

    test('clear removes all events', () async {
      final sink = LocalRingBufferSink(capacity: 5);
      await sink.emit(
        AnalyticsEvent(name: 'ping', timestamp: DateTime.utc(2026)),
      );
      await sink.clear();
      expect(await sink.count(), 0);
    });
  });
}
