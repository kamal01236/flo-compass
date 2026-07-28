import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/providers/app_settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('defaults use system theme', () {
    expect(AppSettings.defaults.themeMode, AppThemeMode.system);
  });

  test(
    'themeMode and accessibility settings persist in JSON round-trip',
    () async {
      final settings = AppSettingsState(prefs: prefs);
      await settings.init();

      await settings.setThemeMode(AppThemeMode.highContrast);
      await settings.setUseDyslexiaFont(true);
      await settings.setShowPlainEnglishCards(true);
      expect(settings.themeMode, AppThemeMode.highContrast);
      expect(settings.useDyslexiaFont, isTrue);
      expect(settings.showPlainEnglishCards, isTrue);

      final reloaded = AppSettingsState(prefs: prefs);
      await reloaded.init();

      expect(reloaded.themeMode, AppThemeMode.highContrast);
      expect(reloaded.useDyslexiaFont, isTrue);
      expect(reloaded.showPlainEnglishCards, isTrue);

      final json = AppSettings.fromJson({
        'themeMode': 'light',
        'eventDayMode': 'on',
        'lowBandwidth': true,
        'leaveNowPushEnabled': true,
        'useDyslexiaFont': false,
        'showPlainEnglishCards': true,
      });
      expect(json.themeMode, AppThemeMode.light);
      expect(json.lowBandwidth, isTrue);
      expect(json.leaveNowPushEnabled, isTrue);
      expect(json.showPlainEnglishCards, isTrue);
      expect(json.leaderboardOptIn, isFalse);
      expect(json.toJson()['themeMode'], 'light');
    },
  );

  test('leaderboard opt-in and PWA dismiss persist', () async {
    final settings = AppSettingsState(prefs: prefs);
    await settings.init();
    expect(settings.leaderboardOptIn, isFalse);

    await settings.setLeaderboardOptIn(true);
    await settings.recordShellTabVisit(1);
    await settings.recordShellTabVisit(2);
    await settings.dismissPwaInstallPrompt();

    expect(settings.leaderboardOptIn, isTrue);
    expect(settings.shellTabVisitCount, 2);
    expect(settings.isPwaInstallDismissed, isTrue);

    final reloaded = AppSettingsState(prefs: prefs);
    await reloaded.init();
    expect(reloaded.leaderboardOptIn, isTrue);
    expect(reloaded.shellTabVisitCount, 2);
    expect(reloaded.isPwaInstallDismissed, isTrue);
  });

  test('tour state persists and shouldAutoStartTour logic', () async {
    final settings = AppSettingsState(prefs: prefs);
    await settings.init();

    await settings.queueTourStart();
    expect(settings.shouldAutoStartTour, isTrue);

    await settings.markTourCompleted(dismissed: true);
    expect(settings.shouldAutoStartTour, isFalse);
    expect(settings.settings.tourDismissedAt, isNotNull);

    await settings.resetTour();
    expect(settings.settings.tourLastSeenVersion, isNull);
    expect(settings.settings.tourDismissedAt, isNull);
  });
}
