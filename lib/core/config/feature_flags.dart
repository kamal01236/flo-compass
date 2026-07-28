class FeatureFlags {
  const FeatureFlags({
    required this.leaderboard,
    required this.bingo,
    required this.recap,
    required this.companionLlm,
    required this.lowBandwidthDefault,
    required this.analytics,
    required this.analyticsRemote,
  });

  final bool leaderboard;
  final bool bingo;
  final bool recap;
  final bool companionLlm;
  final bool lowBandwidthDefault;
  final bool analytics;
  final bool analyticsRemote;

  static const FeatureFlags defaults = FeatureFlags(
    leaderboard: true,
    bingo: true,
    recap: true,
    companionLlm: false,
    lowBandwidthDefault: false,
    analytics: false,
    analyticsRemote: false,
  );

  factory FeatureFlags.fromJson(Map<String, dynamic> json) {
    return FeatureFlags(
      leaderboard: json['leaderboard'] as bool? ?? true,
      bingo: json['bingo'] as bool? ?? true,
      recap: json['recap'] as bool? ?? true,
      companionLlm: json['companionLlm'] as bool? ?? false,
      lowBandwidthDefault: json['lowBandwidthDefault'] as bool? ?? false,
      analytics: json['analytics'] as bool? ?? false,
      analyticsRemote: json['analyticsRemote'] as bool? ?? false,
    );
  }
}
