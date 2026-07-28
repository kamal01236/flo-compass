import 'package:flutter/material.dart';

import '../../core/theme/app_theme_mode.dart';

ThemeMode materialThemeModeFor(AppThemeMode mode) {
  return switch (mode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.highContrast => ThemeMode.dark,
  };
}

bool isExplicitLightTheme(AppThemeMode mode, Brightness platform) {
  return switch (mode) {
    AppThemeMode.light => true,
    AppThemeMode.dark => false,
    AppThemeMode.highContrast => false,
    AppThemeMode.system => platform == Brightness.light,
  };
}
