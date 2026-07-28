import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/core/analytics/analytics_config.dart';
import 'package:flo_compass/core/analytics/analytics_property_allowlist.dart';
import 'package:flo_compass/core/analytics/analytics_service.dart';
import 'package:flo_compass/core/analytics/sinks/local_ring_buffer_sink.dart';
import 'package:flo_compass/core/config/feature_flags.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('filterAnalyticsProperties', () {
    test('strips disallowed PII keys', () {
      final filtered = filterAnalyticsProperties({
        'session_id': 's-001',
        'email': 'secret@example.com',
        'userId': 'u-123',
      });
      expect(filtered['session_id'], 's-001');
      expect(filtered.containsKey('email'), isFalse);
      expect(filtered.containsKey('userId'), isFalse);
    });
  });

  group('AnalyticsService', () {
    test('blocks ring buffer without consent', () async {
      final ring = LocalRingBufferSink(capacity: 10);
      final service = AnalyticsService(
        config: const AnalyticsConfig(
          enabled: true,
          remoteEnabled: false,
          isDevProfile: true,
          localBufferEnabled: true,
          consoleEnabled: false,
          apiUrl: '',
        ),
        consentChecker: () async => false,
        ringBufferSink: ring,
      );

      await service.track('screen_view', route: '/discover');
      expect(await ring.count(), 0);
    });

    test('records to ring buffer with consent on dev profile', () async {
      final ring = LocalRingBufferSink(capacity: 10);
      final service = AnalyticsService(
        config: const AnalyticsConfig(
          enabled: true,
          remoteEnabled: false,
          isDevProfile: true,
          localBufferEnabled: true,
          consoleEnabled: false,
          apiUrl: '',
        ),
        consentChecker: () async => true,
        ringBufferSink: ring,
      );

      await service.track(
        'bookmark_add',
        properties: {'session_id': 's-001'},
        sessionId: 's-001',
      );
      expect(await ring.count(), 1);
      final stored = await ring.readAll();
      expect(stored.single.name, 'bookmark_add');
    });

    test('no-ops when analytics disabled', () async {
      final ring = LocalRingBufferSink(capacity: 10);
      final service = AnalyticsService(
        config: const AnalyticsConfig(
          enabled: false,
          remoteEnabled: false,
          isDevProfile: false,
          localBufferEnabled: false,
          consoleEnabled: false,
          apiUrl: '',
        ),
        consentChecker: () async => true,
        ringBufferSink: ring,
      );

      await service.track('screen_view', route: '/');
      expect(await ring.count(), 0);
    });
  });

  group('AnalyticsConfig.resolve', () {
    test('enables remote when flag and URL present', () {
      final config = AnalyticsConfig.resolve(
        flags: const FeatureFlags(
          leaderboard: true,
          bingo: true,
          recap: true,
          companionLlm: false,
          lowBandwidthDefault: false,
          analytics: true,
          analyticsRemote: true,
        ),
        configProfile: 'dev',
        apiUrl: 'https://example.com/analytics',
        analyticsEnabledOverride: true,
      );
      expect(config.remoteEnabled, isTrue);
      expect(config.localBufferEnabled, isTrue);
    });
  });
}
