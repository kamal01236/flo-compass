import 'package:flutter/material.dart';

import '../../core/theme/app_theme_mode.dart';

/// Flo Compass brand palette extracted from the starter kit.
abstract final class AppColors {
  static const Color scaffoldBackground = Color(0xFF0C0D12);
  static const Color accentStart = Color(0xFF10B981);
  static const Color accentEnd = Color(0xFF059669);
  static const Color mutedText = Color(0xFFA1A1AA);
  static const Color secondaryText = Color(0xFFC4C4CC);
  static const Color skeleton = Color(0xFF1E2030);
  static const Color disabledStar = Color(0xFF6B7280);
  static const Color highContrastFocus = Color(0xFFFFD600);
  static const Color highContrastBackground = Color(0xFF000000);
  static const Color highContrastText = Color(0xFFE5E5E5);
}

abstract final class AppTheme {
  static const String dyslexiaFontFamily = 'OpenDyslexic';
  static const String defaultFontFamily = 'Roboto';

  static const Map<String, Color> trackPalette = {
    'trk-01': Color(0xFF10B981),
    'trk-02': Color(0xFF06B6D4),
    'trk-03': Color(0xFF6366F1),
    'trk-04': Color(0xFFF59E0B),
    'trk-05': Color(0xFFEC4899),
    'trk-06': Color(0xFF22C55E),
    'trk-07': Color(0xFFEF4444),
    'trk-08': Color(0xFF14B8A6),
    'trk-09': Color(0xFF8B5CF6),
    'trk-10': Color(0xFF84CC16),
  };

  static Color colorForTrack(String trackId, [String? schemaColor]) {
    if (schemaColor != null &&
        schemaColor.startsWith('#') &&
        schemaColor.length == 7) {
      final value = int.tryParse(schemaColor.substring(1), radix: 16);
      if (value != null) return Color(0xFF000000 | value);
    }
    return trackPalette[trackId] ?? AppColors.accentStart;
  }

  static ThemeData get dark => _baseTheme(
    brightness: Brightness.dark,
    scaffold: AppColors.scaffoldBackground,
    surface: AppColors.scaffoldBackground,
    onSurface: Colors.white,
    muted: AppColors.mutedText,
    chipBorderWidth: 1,
  ).copyWith(extensions: const [AppConflictTheme.standard, AppChromeColors.dark]);

  static ThemeData get light => _baseTheme(
    brightness: Brightness.light,
    scaffold: const Color(0xFFF5F5F7),
    surface: Colors.white,
    onSurface: const Color(0xFF111827),
    muted: const Color(0xFF4B5563),
    chipBorderWidth: 1,
  ).copyWith(extensions: const [AppConflictTheme.standard, AppChromeColors.light]);

  static ThemeData get highContrast => _baseTheme(
    brightness: Brightness.dark,
    scaffold: AppColors.highContrastBackground,
    surface: AppColors.highContrastBackground,
    onSurface: Colors.white,
    muted: AppColors.highContrastText,
    chipBorderWidth: 2,
    focusColor: AppColors.highContrastFocus,
    chipBorderColor: AppColors.highContrastText,
  ).copyWith(
    extensions: const [AppConflictTheme.highContrast, AppChromeColors.dark],
  );

  static ThemeData themeFor(AppThemeMode mode, {bool useDyslexiaFont = false}) {
    final base = switch (mode) {
      AppThemeMode.system => dark,
      AppThemeMode.light => light,
      AppThemeMode.highContrast => highContrast,
      AppThemeMode.dark => dark,
    };
    return useDyslexiaFont ? withDyslexiaFont(base) : base;
  }

  static ThemeData withDyslexiaFont(ThemeData base) {
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: dyslexiaFontFamily),
      primaryTextTheme: base.primaryTextTheme.apply(
        fontFamily: dyslexiaFontFamily,
      ),
    );
  }

  static ThemeData _baseTheme({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color onSurface,
    required Color muted,
    required double chipBorderWidth,
    Color focusColor = AppColors.accentStart,
    Color? chipBorderColor,
  }) {
    final isDark = brightness == Brightness.dark;
    final borderColor = chipBorderColor ?? muted.withValues(alpha: 0.5);
    final navBackground = isDark ? const Color(0xFF14151C) : Colors.white;
    final outlineVariant = isDark
        ? muted.withValues(alpha: 0.35)
        : const Color(0xFFD1D5DB);
    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: AppColors.accentStart,
            onPrimary: Colors.white,
            secondary: AppColors.accentEnd,
            onSecondary: Colors.white,
            error: const Color(0xFFF87171),
            onError: Colors.white,
            errorContainer: const Color(0xFF7F1D1D),
            onErrorContainer: const Color(0xFFFECACA),
            surface: surface,
            onSurface: onSurface,
            onSurfaceVariant: muted,
            outline: borderColor,
            outlineVariant: outlineVariant,
            surfaceContainerHighest: navBackground,
          )
        : ColorScheme.light(
            primary: AppColors.accentStart,
            onPrimary: Colors.white,
            secondary: AppColors.accentEnd,
            onSecondary: Colors.white,
            surface: surface,
            onSurface: onSurface,
            onSurfaceVariant: muted,
            outline: const Color(0xFFD1D5DB),
            outlineVariant: outlineVariant,
            surfaceContainerHighest: Colors.white,
          );
    final baseText = TextTheme(
      bodySmall: TextStyle(color: muted, fontFamily: defaultFontFamily),
      bodyMedium: TextStyle(color: muted, fontFamily: defaultFontFamily),
      bodyLarge: TextStyle(color: onSurface, fontFamily: defaultFontFamily),
      labelLarge: TextStyle(color: onSurface, fontFamily: defaultFontFamily),
      labelMedium: TextStyle(color: muted, fontFamily: defaultFontFamily),
      labelSmall: TextStyle(color: muted, fontFamily: defaultFontFamily),
      titleLarge: TextStyle(color: onSurface, fontFamily: defaultFontFamily),
      titleMedium: TextStyle(color: onSurface, fontFamily: defaultFontFamily),
      titleSmall: TextStyle(color: onSurface, fontFamily: defaultFontFamily),
      headlineMedium: TextStyle(
        color: onSurface,
        fontFamily: defaultFontFamily,
      ),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: defaultFontFamily,
      scaffoldBackgroundColor: scaffold,
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 1 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? borderColor : outlineVariant,
            width: 1,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBackground,
        indicatorColor: AppColors.accentStart.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.accentStart);
          }
          return IconThemeData(color: muted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: onSurface,
              fontSize: 12,
              fontFamily: defaultFontFamily,
            );
          }
          return TextStyle(
            color: muted,
            fontSize: 12,
            fontFamily: defaultFontFamily,
          );
        }),
      ),
      textTheme: baseText,
      primaryTextTheme: baseText,
      focusColor: focusColor,
      chipTheme: ChipThemeData(
        side: BorderSide(color: borderColor, width: chipBorderWidth),
        labelStyle: TextStyle(color: onSurface, fontFamily: defaultFontFamily),
        selectedColor: focusColor == AppColors.highContrastFocus
            ? AppColors.highContrastFocus.withValues(alpha: 0.25)
            : AppColors.accentStart.withValues(alpha: isDark ? 0.22 : 0.14),
        secondarySelectedColor: focusColor == AppColors.highContrastFocus
            ? AppColors.highContrastFocus.withValues(alpha: 0.35)
            : AppColors.accentStart.withValues(alpha: isDark ? 0.32 : 0.22),
        checkmarkColor: focusColor == AppColors.highContrastFocus
            ? AppColors.highContrastFocus
            : AppColors.accentStart,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(foregroundColor: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: muted, fontFamily: defaultFontFamily),
        labelStyle: TextStyle(color: muted, fontFamily: defaultFontFamily),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: focusColor, width: 2),
        ),
      ),
    );
  }

  static AppConflictTheme conflictTheme(BuildContext context) {
    return Theme.of(context).extension<AppConflictTheme>() ??
        AppConflictTheme.standard;
  }

  static AppChromeColors chromeColors(BuildContext context) {
    return Theme.of(context).extension<AppChromeColors>() ??
        AppChromeColors.dark;
  }

  static LinearGradient get accentGradient => const LinearGradient(
    colors: [AppColors.accentStart, AppColors.accentEnd],
  );
}

@immutable
class AppChromeColors extends ThemeExtension<AppChromeColors> {
  const AppChromeColors({
    required this.skeleton,
    required this.elevatedPanel,
  });

  final Color skeleton;
  final Color elevatedPanel;

  static const dark = AppChromeColors(
    skeleton: AppColors.skeleton,
    elevatedPanel: Color(0xFF14151C),
  );

  static const light = AppChromeColors(
    skeleton: Color(0xFFE5E7EB),
    elevatedPanel: Colors.white,
  );

  static AppChromeColors of(BuildContext context) {
    return Theme.of(context).extension<AppChromeColors>() ?? dark;
  }

  @override
  AppChromeColors copyWith({Color? skeleton, Color? elevatedPanel}) {
    return AppChromeColors(
      skeleton: skeleton ?? this.skeleton,
      elevatedPanel: elevatedPanel ?? this.elevatedPanel,
    );
  }

  @override
  AppChromeColors lerp(AppChromeColors? other, double t) {
    if (other == null) return this;
    return AppChromeColors(
      skeleton: Color.lerp(skeleton, other.skeleton, t) ?? skeleton,
      elevatedPanel:
          Color.lerp(elevatedPanel, other.elevatedPanel, t) ?? elevatedPanel,
    );
  }
}

@immutable
class AppConflictTheme extends ThemeExtension<AppConflictTheme> {
  const AppConflictTheme({
    required this.icon,
    required this.label,
    required this.background,
    required this.border,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color border;

  static const standard = AppConflictTheme(
    icon: Icons.warning_amber,
    label: 'Time conflicts detected',
    background: Color(0x1FFF9800),
    border: Color(0xFFFF9800),
  );

  static const highContrast = AppConflictTheme(
    icon: Icons.warning_amber,
    label: 'Time conflicts detected',
    background: Color(0x33000000),
    border: AppColors.highContrastFocus,
  );

  @override
  AppConflictTheme copyWith({
    IconData? icon,
    String? label,
    Color? background,
    Color? border,
  }) {
    return AppConflictTheme(
      icon: icon ?? this.icon,
      label: label ?? this.label,
      background: background ?? this.background,
      border: border ?? this.border,
    );
  }

  @override
  AppConflictTheme lerp(AppConflictTheme? other, double t) {
    if (other == null) return this;
    return AppConflictTheme(
      icon: t < 0.5 ? icon : other.icon,
      label: t < 0.5 ? label : other.label,
      background: Color.lerp(background, other.background, t) ?? background,
      border: Color.lerp(border, other.border, t) ?? border,
    );
  }
}
