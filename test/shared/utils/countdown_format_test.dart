import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/shared/utils/countdown_format.dart';

void main() {
  group('formatUntil', () {
    test('returns minutes for under one hour', () {
      expect(CountdownFormat.formatUntil(5), 'Starts in 5m');
      expect(CountdownFormat.formatUntil(42), 'Starts in 42m');
    });

    test('returns hours and minutes between one and twelve hours', () {
      expect(CountdownFormat.formatUntil(65), 'Starts in 1h 5m');
      expect(CountdownFormat.formatUntil(390), 'Starts in 6h 30m');
      expect(CountdownFormat.formatUntil(120), 'Starts in 2h');
    });

    test('returns tomorrow label when target is next calendar day', () {
      final now = DateTime(2026, 11, 3, 12, 30);
      final target = DateTime(2026, 11, 4, 11, 0);
      expect(
        CountdownFormat.formatUntil(1350, now: now, target: target),
        'Tomorrow · 11:00',
      );
    });

    test('returns weekday label when target is more than one day away', () {
      final now = DateTime(2026, 11, 3, 10, 0);
      final target = DateTime(2026, 11, 5, 14, 30);
      expect(
        CountdownFormat.formatUntil(3150, now: now, target: target),
        'Thu · 14:30',
      );
    });

    test('returns starting soon for non-positive minutes', () {
      expect(CountdownFormat.formatUntil(0), 'Starting soon');
      expect(CountdownFormat.formatUntil(-5), 'Starting soon');
    });
  });

  group('formatRemaining', () {
    test('returns minutes for under one hour', () {
      expect(CountdownFormat.formatRemaining(30), 'Ends in 30m');
    });

    test('returns hours for longer sessions', () {
      expect(CountdownFormat.formatRemaining(90), 'Ends in 1h 30m');
    });

    test('returns ending soon for non-positive minutes', () {
      expect(CountdownFormat.formatRemaining(0), 'Ending soon');
    });
  });

  group('wingLabel', () {
    test('maps known wing codes', () {
      expect(CountdownFormat.wingLabel('N'), 'North');
      expect(CountdownFormat.wingLabel('S'), 'South');
      expect(CountdownFormat.wingLabel('central'), 'Central');
      expect(CountdownFormat.wingLabel('c'), 'Central');
    });
  });
}
