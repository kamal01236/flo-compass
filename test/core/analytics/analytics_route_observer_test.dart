import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/core/analytics/analytics_config.dart';
import 'package:flo_compass/core/analytics/analytics_route_observer.dart';
import 'package:flo_compass/core/analytics/analytics_service.dart';
import 'package:flo_compass/core/analytics/sinks/local_ring_buffer_sink.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AnalyticsService analyticsWithConsent(LocalRingBufferSink ring) {
    return AnalyticsService(
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
  }

  group('AnalyticsRouteObserver', () {
    test('deduplicates consecutive identical routes', () async {
      final ring = LocalRingBufferSink(capacity: 10);
      final analytics = analyticsWithConsent(ring);
      final observer = AnalyticsRouteObserver(analytics);

      observer.didChangeRoute('/discover');
      observer.didChangeRoute('/discover');
      observer.didChangeRoute('/profile');
      await Future<void>.delayed(Duration.zero);

      final events = await ring.readAll();
      final screenViews = events.where((e) => e.name == 'screen_view').toList();
      expect(screenViews, hasLength(2));
      expect(screenViews.last.properties['route'], '/discover');
      expect(screenViews.first.properties['route'], '/profile');
    });

    test('navigator didPush records screen_view', () async {
      final ring = LocalRingBufferSink(capacity: 10);
      final analytics = analyticsWithConsent(ring);
      final observer = AnalyticsRouteObserver(analytics);
      final route = MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/companion'),
        builder: (_) => const SizedBox.shrink(),
      );

      observer.didPush(route, null);
      await Future<void>.delayed(Duration.zero);

      final events = await ring.readAll();
      expect(events, hasLength(1));
      expect(events.single.name, 'screen_view');
      expect(events.single.properties['route'], '/companion');
    });
  });
}
