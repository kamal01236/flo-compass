import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme_mode.dart';
import '../data/local/local_user_store.dart';
import '../shared/tour/tour_version.dart';
import '../shared/utils/web_push.dart';

export '../core/theme/app_theme_mode.dart'
    show AppSettings, AppThemeMode, EventDayMode;

class AppSettingsState extends ChangeNotifier {
  AppSettingsState({SharedPreferences? prefs, LocalUserStore? userStore})
    : _prefs = prefs,
      _userStore = userStore ?? LocalUserStore();

  SharedPreferences? _prefs;
  final LocalUserStore _userStore;
  static const _key = 'flo_compass_app_settings';
  AppSettings settings = AppSettings.defaults;
  String? localeCode;

  bool get isLightTheme => settings.themeMode == AppThemeMode.light;
  AppThemeMode get themeMode => settings.themeMode;
  EventDayMode get eventDayMode => settings.eventDayMode;
  bool get isLowBandwidth => settings.lowBandwidth;
  bool get leaveNowPushEnabled => settings.leaveNowPushEnabled;
  bool get agendaChangeAlertsEnabled => settings.agendaChangeAlertsEnabled;
  bool get agendaChangePushEnabled => settings.agendaChangePushEnabled;
  bool get useDyslexiaFont => settings.useDyslexiaFont;
  bool get showPlainEnglishCards => settings.showPlainEnglishCards;
  bool get leaderboardOptIn => settings.leaderboardOptIn;
  int get shellTabVisitCount => settings.shellTabsVisited.length;
  bool get shouldAutoStartTour =>
      settings.tourAutoStartPending &&
      settings.tourLastSeenVersion != kTourVersion;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw != null) {
      try {
        settings = AppSettings.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to decode app settings: $e');
        }
      }
    }
    notifyListeners();
  }

  Future<void> loadLocaleFromStore() async {
    localeCode = await _userStore.getLocaleCode();
    notifyListeners();
  }

  Future<void> setLocaleCode(String? code) async {
    localeCode = code;
    if (code != null) {
      await _userStore.setLocaleCode(code);
    }
    notifyListeners();
  }

  Future<void> _persist(AppSettings next) async {
    _prefs ??= await SharedPreferences.getInstance();
    settings = next;
    await _prefs!.setString(_key, jsonEncode(settings.toJson()));
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    await _persist(settings.copyWith(themeMode: mode));
  }

  Future<void> setLightTheme(bool enabled) async {
    await setThemeMode(enabled ? AppThemeMode.light : AppThemeMode.dark);
  }

  Future<void> setEventDayMode(EventDayMode mode) async {
    await _persist(settings.copyWith(eventDayMode: mode));
  }

  Future<void> setLowBandwidth(bool enabled) async {
    await _persist(settings.copyWith(lowBandwidth: enabled));
  }

  Future<void> setAgendaChangeAlertsEnabled(bool enabled) async {
    await _persist(settings.copyWith(agendaChangeAlertsEnabled: enabled));
  }

  Future<void> setUseDyslexiaFont(bool enabled) async {
    await _persist(settings.copyWith(useDyslexiaFont: enabled));
  }

  Future<void> setShowPlainEnglishCards(bool enabled) async {
    await _persist(settings.copyWith(showPlainEnglishCards: enabled));
  }

  Future<void> setLeaderboardOptIn(bool enabled) async {
    await _persist(settings.copyWith(leaderboardOptIn: enabled));
  }

  Future<void> recordShellTabVisit(int tabIndex) async {
    if (settings.shellTabsVisited.contains(tabIndex)) return;
    await _persist(
      settings.copyWith(
        shellTabsVisited: [...settings.shellTabsVisited, tabIndex],
      ),
    );
  }

  bool get isPwaInstallDismissed {
    final dismissedAt = settings.pwaInstallDismissedAt;
    if (dismissedAt == null) return false;
    return DateTime.now().difference(dismissedAt) < const Duration(days: 7);
  }

  Future<void> dismissPwaInstallPrompt() async {
    await _persist(settings.copyWith(pwaInstallDismissedAt: DateTime.now()));
  }

  Future<void> queueTourStart() async {
    await _persist(settings.copyWith(tourAutoStartPending: true));
  }

  Future<void> markTourCompleted({bool dismissed = false}) async {
    await _persist(
      settings.copyWith(
        tourLastSeenVersion: kTourVersion,
        tourAutoStartPending: false,
        tourDismissedAt: dismissed ? DateTime.now() : null,
        clearTourDismissedAt: !dismissed,
      ),
    );
  }

  Future<void> resetTour() async {
    await _persist(
      settings.copyWith(
        clearTourLastSeenVersion: true,
        clearTourDismissedAt: true,
        tourAutoStartPending: false,
      ),
    );
  }

  Future<bool> setLeaveNowPushEnabled(bool enabled) async {
    if (enabled && !isNotificationSupported) {
      await _persist(settings.copyWith(leaveNowPushEnabled: false));
      return false;
    }

    if (enabled) {
      final permission = await getNotificationPermission();
      if (permission == 'default') {
        final result = await requestNotificationPermission();
        if (result != 'granted') {
          await _persist(settings.copyWith(leaveNowPushEnabled: false));
          return false;
        }
      } else if (permission == 'denied') {
        return false;
      }
    }

    await _persist(
      settings.copyWith(
        leaveNowPushEnabled: enabled && isNotificationPermissionGranted,
      ),
    );
    return settings.leaveNowPushEnabled;
  }
}
