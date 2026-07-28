import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flo_compass/core/theme/app_theme_mode.dart';
import 'package:flo_compass/shared/theme/app_theme.dart';

void main() {
  double luminance(Color c) {
    double channel(double v) {
      v /= 255;
      return v <= 0.03928
          ? v / 12.92
          : pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = channel(c.r * 255);
    final g = channel(c.g * 255);
    final b = channel(c.b * 255);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  double contrastRatio(Color a, Color b) {
    final l1 = luminance(a);
    final l2 = luminance(b);
    final lighter = max(l1, l2);
    final darker = min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  test('dark theme text meets WCAG AA on scaffold', () {
    final theme = AppTheme.themeFor(AppThemeMode.dark);
    final ratio = contrastRatio(
      theme.colorScheme.onSurface,
      theme.scaffoldBackgroundColor,
    );
    expect(ratio, greaterThanOrEqualTo(4.5));
  });

  test('light theme onSurface meets WCAG AA on scaffold', () {
    final theme = AppTheme.themeFor(AppThemeMode.light);
    final ratio = contrastRatio(
      theme.colorScheme.onSurface,
      theme.scaffoldBackgroundColor,
    );
    expect(ratio, greaterThanOrEqualTo(4.5));
  });

  test('light theme onSurfaceVariant meets WCAG AA on surface', () {
    final theme = AppTheme.themeFor(AppThemeMode.light);
    final ratio = contrastRatio(
      theme.colorScheme.onSurfaceVariant,
      theme.colorScheme.surface,
    );
    expect(ratio, greaterThanOrEqualTo(4.5));
  });

  test('light chrome skeleton is distinguishable from surface', () {
    final theme = AppTheme.themeFor(AppThemeMode.light);
    final chrome = theme.extension<AppChromeColors>()!;
    final ratio = contrastRatio(chrome.skeleton, theme.colorScheme.surface);
    expect(ratio, greaterThan(1.05));
  });

  test('high contrast theme meets WCAG AA', () {
    final theme = AppTheme.themeFor(AppThemeMode.highContrast);
    final ratio = contrastRatio(
      theme.colorScheme.onSurface,
      theme.scaffoldBackgroundColor,
    );
    expect(ratio, greaterThanOrEqualTo(4.5));
  });

  test('accent on scaffold meets AA for large text threshold', () {
    final ratio = contrastRatio(
      AppColors.accentStart,
      AppColors.scaffoldBackground,
    );
    expect(ratio, greaterThanOrEqualTo(3.0));
  });
}
