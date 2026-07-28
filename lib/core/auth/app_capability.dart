/// Capabilities gated when OAuth is enabled.
enum AppCapability {
  earnXp,
  registerEvent,
  attributedFeedback,
  moderateQa,
  publishAnnouncement,
  manageOpsConfig,
}

extension AppCapabilityLabel on AppCapability {
  String get denialMessage => switch (this) {
    AppCapability.earnXp => 'Sign in to earn XP and appear on the leaderboard.',
    AppCapability.registerEvent =>
      'Sign in to register interest in official event sessions.',
    AppCapability.attributedFeedback =>
      'Sign in to attach your identity to feedback.',
    AppCapability.moderateQa =>
      'Organizer access is required to moderate session Q&A overlays.',
    AppCapability.publishAnnouncement =>
      'Organizer access is required to publish Flo announcements.',
    AppCapability.manageOpsConfig =>
      'Admin access is required to manage Flo operations settings.',
  };
}
