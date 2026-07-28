import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/core/analytics/analytics_config.dart';
import 'package:flo_compass/core/analytics/analytics_event.dart';
import 'package:flo_compass/core/analytics/sinks/http_batch_sink.dart';
import 'package:flo_compass/data/local/local_user_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HttpBatchSink', () {
    test('enqueues payload when POST fails', () async {
      final store = LocalUserStore();
      final client = MockClient((_) async => http.Response('error', 500));
      final sink = HttpBatchSink(
        config: const AnalyticsConfig(
          enabled: true,
          remoteEnabled: true,
          isDevProfile: false,
          localBufferEnabled: false,
          consoleEnabled: false,
          apiUrl: 'https://example.test/analytics',
          batchSize: 1,
        ),
        store: store,
        client: client,
      );
      await sink.emit(
        AnalyticsEvent(name: 'ping', timestamp: DateTime.utc(2026)),
      );
      await sink.flush();
      final queue = await store.getAnalyticsQueue();
      expect(queue, hasLength(1));
      expect(queue.first, contains('"ping"'));
    });

    test('enqueues when API URL is not configured', () async {
      final store = LocalUserStore();
      final sink = HttpBatchSink(
        config: const AnalyticsConfig(
          enabled: true,
          remoteEnabled: true,
          isDevProfile: false,
          localBufferEnabled: false,
          consoleEnabled: false,
          apiUrl: '',
          batchSize: 1,
        ),
        store: store,
      );
      await sink.emit(
        AnalyticsEvent(name: 'ping', timestamp: DateTime.utc(2026)),
      );
      await sink.flush();
      final queue = await store.getAnalyticsQueue();
      expect(queue, hasLength(1));
    });
  });
}
