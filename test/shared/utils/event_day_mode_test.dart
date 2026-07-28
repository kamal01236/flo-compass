import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/services/event_clock_service.dart';
import 'package:flo_compass/providers/app_settings_provider.dart';
import 'package:flo_compass/shared/utils/event_day_mode.dart';

void main() {
  group('resolveEventDayMode', () {
    test('on always resolves true', () {
      final clock = EventClockService();
      clock.setOverride(DateTime(2026, 12, 1));

      expect(
        resolveEventDayMode(
          const AppSettings(
            themeMode: AppThemeMode.dark,
            eventDayMode: EventDayMode.on,
          ),
          clock,
        ),
        isTrue,
      );
    });

    test('off always resolves false', () {
      final clock = EventClockService();
      clock.setOverride(DateTime(2026, 11, 4, 10, 30));

      expect(
        resolveEventDayMode(
          const AppSettings(
            themeMode: AppThemeMode.dark,
            eventDayMode: EventDayMode.off,
          ),
          clock,
        ),
        isFalse,
      );
    });

    test('auto resolves true on Day 1', () {
      final clock = EventClockService();
      clock.setOverride(DateTime(2026, 11, 4, 10, 30));

      expect(
        resolveEventDayMode(
          const AppSettings(
            themeMode: AppThemeMode.dark,
            eventDayMode: EventDayMode.auto,
          ),
          clock,
        ),
        isTrue,
      );
      expect(clock.currentDay(), 'Day 1');
    });

    test('auto resolves false when currentDay is null', () {
      final clock = EventClockService();
      clock.setOverride(DateTime(2026, 12, 1));

      expect(clock.currentDay(), isNull);
      expect(
        resolveEventDayMode(
          const AppSettings(
            themeMode: AppThemeMode.dark,
            eventDayMode: EventDayMode.auto,
          ),
          clock,
        ),
        isFalse,
      );
    });
  });

  group('AppSettings eventDayMode persistence', () {
    test('fromJson missing eventDayMode defaults to auto', () {
      final settings = AppSettings.fromJson({'themeMode': 'light'});

      expect(settings.eventDayMode, EventDayMode.auto);
      expect(settings.themeMode, AppThemeMode.light);
    });

    test('toJson and fromJson round-trip eventDayMode', () {
      const original = AppSettings(
        themeMode: AppThemeMode.light,
        eventDayMode: EventDayMode.on,
      );

      final restored = AppSettings.fromJson(original.toJson());

      expect(restored.eventDayMode, EventDayMode.on);
      expect(restored.themeMode, AppThemeMode.light);
    });

    test('fromJson migrates legacy useLightTheme bool', () {
      expect(
        AppSettings.fromJson({'useLightTheme': true}).themeMode,
        AppThemeMode.light,
      );
      expect(
        AppSettings.fromJson({'useLightTheme': false}).themeMode,
        AppThemeMode.dark,
      );
    });

    test('fromJson unknown themeMode value defaults to system', () {
      final settings = AppSettings.fromJson({'themeMode': 'invalid'});

      expect(settings.themeMode, AppThemeMode.system);
    });

    test('fromJson unknown eventDayMode value defaults to auto', () {
      final settings = AppSettings.fromJson({
        'themeMode': 'dark',
        'eventDayMode': 'invalid',
      });

      expect(settings.eventDayMode, EventDayMode.auto);
    });
  });
}
