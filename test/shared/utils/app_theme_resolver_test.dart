import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/core/theme/app_theme_mode.dart';
import 'package:flo_compass/shared/utils/app_theme_resolver.dart';

void main() {
  group('materialThemeModeFor', () {
    test('maps each AppThemeMode to Flutter ThemeMode', () {
      expect(materialThemeModeFor(AppThemeMode.system), ThemeMode.system);
      expect(materialThemeModeFor(AppThemeMode.light), ThemeMode.light);
      expect(materialThemeModeFor(AppThemeMode.dark), ThemeMode.dark);
      expect(materialThemeModeFor(AppThemeMode.highContrast), ThemeMode.dark);
    });
  });

  group('isExplicitLightTheme', () {
    test('light mode is always light', () {
      expect(isExplicitLightTheme(AppThemeMode.light, Brightness.dark), isTrue);
      expect(
        isExplicitLightTheme(AppThemeMode.light, Brightness.light),
        isTrue,
      );
    });

    test('dark and high contrast are never light', () {
      expect(
        isExplicitLightTheme(AppThemeMode.dark, Brightness.light),
        isFalse,
      );
      expect(
        isExplicitLightTheme(AppThemeMode.highContrast, Brightness.light),
        isFalse,
      );
    });

    test('system follows platform brightness', () {
      expect(
        isExplicitLightTheme(AppThemeMode.system, Brightness.light),
        isTrue,
      );
      expect(
        isExplicitLightTheme(AppThemeMode.system, Brightness.dark),
        isFalse,
      );
    });
  });
}
