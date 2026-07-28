enum EventDayMode { auto, on, off }

enum AppThemeMode { system, dark, light, highContrast }

class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.eventDayMode = EventDayMode.auto,
    this.lowBandwidth = false,
    this.leaveNowPushEnabled = false,
    this.agendaChangeAlertsEnabled = true,
    this.agendaChangePushEnabled = false,
    this.useDyslexiaFont = false,
    this.showPlainEnglishCards = false,
    this.leaderboardOptIn = false,
    this.shellTabsVisited = const [],
    this.pwaInstallDismissedAt,
    this.tourLastSeenVersion,
    this.tourDismissedAt,
    this.tourAutoStartPending = false,
  });

  final AppThemeMode themeMode;
  final EventDayMode eventDayMode;
  final bool lowBandwidth;
  final bool leaveNowPushEnabled;
  final bool agendaChangeAlertsEnabled;
  final bool agendaChangePushEnabled;
  final bool useDyslexiaFont;
  final bool showPlainEnglishCards;
  final bool leaderboardOptIn;
  final List<int> shellTabsVisited;
  final DateTime? pwaInstallDismissedAt;
  final int? tourLastSeenVersion;
  final DateTime? tourDismissedAt;
  final bool tourAutoStartPending;

  /// Legacy getter for tests and migration.
  bool get useLightTheme => themeMode == AppThemeMode.light;

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'eventDayMode': eventDayMode.name,
    'lowBandwidth': lowBandwidth,
    'leaveNowPushEnabled': leaveNowPushEnabled,
    'agendaChangeAlertsEnabled': agendaChangeAlertsEnabled,
    'agendaChangePushEnabled': agendaChangePushEnabled,
    'useDyslexiaFont': useDyslexiaFont,
    'showPlainEnglishCards': showPlainEnglishCards,
    'leaderboardOptIn': leaderboardOptIn,
    'shellTabsVisited': shellTabsVisited,
    if (pwaInstallDismissedAt != null)
      'pwaInstallDismissedAt': pwaInstallDismissedAt!.millisecondsSinceEpoch,
    if (tourLastSeenVersion != null) 'tourLastSeenVersion': tourLastSeenVersion,
    if (tourDismissedAt != null)
      'tourDismissedAt': tourDismissedAt!.millisecondsSinceEpoch,
    'tourAutoStartPending': tourAutoStartPending,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: _themeModeFromJson(json),
      eventDayMode: _eventDayModeFromJson(json['eventDayMode']),
      lowBandwidth: json['lowBandwidth'] as bool? ?? false,
      leaveNowPushEnabled: json['leaveNowPushEnabled'] as bool? ?? false,
      agendaChangeAlertsEnabled:
          json['agendaChangeAlertsEnabled'] as bool? ?? true,
      agendaChangePushEnabled:
          json['agendaChangePushEnabled'] as bool? ?? false,
      useDyslexiaFont: json['useDyslexiaFont'] as bool? ?? false,
      showPlainEnglishCards: json['showPlainEnglishCards'] as bool? ?? false,
      leaderboardOptIn: json['leaderboardOptIn'] as bool? ?? false,
      shellTabsVisited: _tabsFromJson(json['shellTabsVisited']),
      pwaInstallDismissedAt: _dateFromJson(json['pwaInstallDismissedAt']),
      tourLastSeenVersion: (json['tourLastSeenVersion'] as num?)?.toInt(),
      tourDismissedAt: _dateFromJson(json['tourDismissedAt']),
      tourAutoStartPending: json['tourAutoStartPending'] as bool? ?? false,
    );
  }

  static List<int> _tabsFromJson(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<num>().map((n) => n.toInt()).toList();
  }

  static DateTime? _dateFromJson(dynamic value) {
    if (value is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }

  static AppThemeMode _themeModeFromJson(Map<String, dynamic> json) {
    final raw = json['themeMode'] as String?;
    if (raw != null) {
      return AppThemeMode.values.firstWhere(
        (m) => m.name == raw,
        orElse: () => AppThemeMode.system,
      );
    }
    final legacyLight = json['useLightTheme'] as bool? ?? false;
    return legacyLight ? AppThemeMode.light : AppThemeMode.dark;
  }

  static EventDayMode _eventDayModeFromJson(dynamic value) {
    return switch (value) {
      'on' => EventDayMode.on,
      'off' => EventDayMode.off,
      _ => EventDayMode.auto,
    };
  }

  AppSettings copyWith({
    AppThemeMode? themeMode,
    EventDayMode? eventDayMode,
    bool? lowBandwidth,
    bool? leaveNowPushEnabled,
    bool? agendaChangeAlertsEnabled,
    bool? agendaChangePushEnabled,
    bool? useDyslexiaFont,
    bool? showPlainEnglishCards,
    bool? leaderboardOptIn,
    List<int>? shellTabsVisited,
    DateTime? pwaInstallDismissedAt,
    bool clearPwaInstallDismissedAt = false,
    int? tourLastSeenVersion,
    DateTime? tourDismissedAt,
    bool? tourAutoStartPending,
    bool clearTourLastSeenVersion = false,
    bool clearTourDismissedAt = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      eventDayMode: eventDayMode ?? this.eventDayMode,
      lowBandwidth: lowBandwidth ?? this.lowBandwidth,
      leaveNowPushEnabled: leaveNowPushEnabled ?? this.leaveNowPushEnabled,
      agendaChangeAlertsEnabled:
          agendaChangeAlertsEnabled ?? this.agendaChangeAlertsEnabled,
      agendaChangePushEnabled:
          agendaChangePushEnabled ?? this.agendaChangePushEnabled,
      useDyslexiaFont: useDyslexiaFont ?? this.useDyslexiaFont,
      showPlainEnglishCards:
          showPlainEnglishCards ?? this.showPlainEnglishCards,
      leaderboardOptIn: leaderboardOptIn ?? this.leaderboardOptIn,
      shellTabsVisited: shellTabsVisited ?? this.shellTabsVisited,
      pwaInstallDismissedAt: clearPwaInstallDismissedAt
          ? null
          : (pwaInstallDismissedAt ?? this.pwaInstallDismissedAt),
      tourLastSeenVersion: clearTourLastSeenVersion
          ? null
          : (tourLastSeenVersion ?? this.tourLastSeenVersion),
      tourDismissedAt: clearTourDismissedAt
          ? null
          : (tourDismissedAt ?? this.tourDismissedAt),
      tourAutoStartPending: tourAutoStartPending ?? this.tourAutoStartPending,
    );
  }

  static const defaults = AppSettings();
}
