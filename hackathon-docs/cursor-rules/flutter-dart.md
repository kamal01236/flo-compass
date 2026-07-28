# Flutter / Dart

| Field | Value |
|-------|-------|
| **File** | `.cursor/rules/flutter-dart.mdc` |
| **Purpose** | Flutter web conventions, theme palette, web-first |
| **Scope** | `globs: lib/**/*.dart,test/**/*.dart` |
| **When to @cite** | UI work, dependency changes, theme edits, widget structure, web compatibility |

## Key guardrails

- Flutter 3.44.0, Dart 3.10+; run `flutter pub get` after dependency changes
- Material 3; preserve starter palette (scaffold `0xFF0C0D12`, emerald accent, muted text `0xFFA1A1AA`)
- Provider for state — do not introduce Riverpod or Bloc
- Web-first: avoid mobile-only plugins; run Flutter inside WSL2 on `0.0.0.0:3000`
- `flutter analyze` before large UI rewrites
- Widget tests only when they cover real behavior

## Source

[`.cursor/rules/flutter-dart.mdc`](../../.cursor/rules/flutter-dart.mdc)
