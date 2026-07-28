import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/providers/app_settings_provider.dart';
import 'package:flo_compass/shared/theme/app_theme.dart';

void main() {
  test('high contrast theme compiles with expected contrast tokens', () {
    final theme = AppTheme.highContrast;

    expect(theme.scaffoldBackgroundColor, AppColors.highContrastBackground);
    expect(theme.focusColor, AppColors.highContrastFocus);
    expect(theme.chipTheme.side?.width, 2);
    expect(theme.textTheme.bodyMedium?.color, AppColors.highContrastText);
  });

  test('themeFor applies dyslexia font family when enabled', () {
    final theme = AppTheme.themeFor(
      AppThemeMode.highContrast,
      useDyslexiaFont: true,
    );

    expect(theme.textTheme.bodyMedium?.fontFamily, AppTheme.dyslexiaFontFamily);
  });

  testWidgets('high contrast chip border is visible', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.highContrast,
        home: const Scaffold(body: Chip(label: Text('Track'))),
      ),
    );

    final chipTheme = Theme.of(tester.element(find.byType(Chip))).chipTheme;
    expect(chipTheme.side?.width, 2);
    expect(chipTheme.side?.color, AppColors.highContrastText);
  });
}
