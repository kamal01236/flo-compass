// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabDiscover => 'Discover';

  @override
  String get tabCompanion => 'Ask Flo';

  @override
  String get tabMeets => 'Meets';

  @override
  String get tabMyPlan => 'My Plan';

  @override
  String get tabProfile => 'Profile';

  @override
  String get loading => 'Loading…';

  @override
  String get retry => 'Retry';

  @override
  String get emptyTitle => 'Nothing here yet';

  @override
  String get consentTitle => 'Privacy & data use';

  @override
  String get consentBody =>
      'Flo Compass stores your plan, interests, and settings locally in your browser. We use this data to personalize session recommendations. Accelevents handles official registration — this app does not replace it.';

  @override
  String get consentAccept => 'Accept and continue';

  @override
  String get consentDecline => 'Decline';

  @override
  String get consentReadPolicy => 'Read full privacy policy';

  @override
  String get consentRequiredTitle => 'Consent required';

  @override
  String get consentRequiredBody =>
      'You must accept the privacy policy to use Flo Compass. No personal data leaves your device without your consent.';

  @override
  String get consentOk => 'OK';

  @override
  String get profileLogin => 'Sign in';

  @override
  String get profileLogout => 'Sign out';

  @override
  String profileSignedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get profileScreenTitle => 'Profile';

  @override
  String get profileTabYou => 'You';

  @override
  String get profileTabProgress => 'Progress';

  @override
  String get profileTabSettings => 'Settings';

  @override
  String get profileTabOrganizer => 'Organizer';

  @override
  String get profileTabAdmin => 'Admin';

  @override
  String get profileMoreOptions => 'More options';

  @override
  String get profileInstallApp => 'Install app';

  @override
  String get profileInstallFallback =>
      'Use your browser menu to install this app';

  @override
  String get localeLabel => 'Language';

  @override
  String get localeEn => 'English';

  @override
  String get localeDe => 'Deutsch';

  @override
  String get localeEs => 'Español';

  @override
  String get sendFeedback => 'Send feedback';

  @override
  String get reportIssue => 'Report issue';

  @override
  String get commonDismiss => 'Dismiss';

  @override
  String aboutVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get accessibilityStatement => 'Accessibility statement';

  @override
  String get offlineBanner => 'You\'re offline — showing saved Flo 2026 data.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No upcoming alerts';

  @override
  String get notificationsEmptySubtitle =>
      'Your saved sessions will appear here.';

  @override
  String get notificationsTooltip => 'Notifications';

  @override
  String notificationsBellLabelWithCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notifications, $count alerts',
      one: 'Notifications, 1 alert',
      zero: 'No notifications',
    );
    return '$_temp0';
  }

  @override
  String get notificationsRefreshAgenda => 'Refresh agenda';

  @override
  String get notificationsDismiss => 'Dismiss';

  @override
  String get authCompletingSignIn => 'Completing sign-in…';

  @override
  String get authSignInFailed => 'Sign-in could not be completed.';

  @override
  String get tourNowNextTitle => 'See what\'s live';

  @override
  String get tourNowNextBody =>
      'Your event clock — what\'s live and what\'s up next.';

  @override
  String get tourDiscoverTitle => 'Search sessions';

  @override
  String get tourDiscoverBody =>
      'Find talks by title, speaker, or topic. Filters and recommendations update as you type.';

  @override
  String get tourRecoReasonTitle => 'Why we picked it';

  @override
  String get tourRecoReasonBody =>
      'Every recommendation shows its reasoning — no black box.';

  @override
  String get tourSessionTitle => 'Save to My Plan';

  @override
  String get tourSessionBody =>
      'Bookmark sessions you want to attend. Your shortlist stays on this device — separate from Accelevents registration.';

  @override
  String get tourLogisticsTitle => 'Open Logistics';

  @override
  String get tourLogisticsBody =>
      'Venue details, walk times, and campus actions live here.';

  @override
  String get tourVenueMapTitle => 'See it on the map';

  @override
  String get tourVenueMapBody => 'Tap Map to view this room on the campus.';

  @override
  String get tourCompanionTitle => 'Ask Flo';

  @override
  String get tourCompanionBody =>
      'Sessions, restrooms, parking, clashes — try \'Where can I park my car?\'';

  @override
  String get tourMyPlanTitle => 'Your shortlist';

  @override
  String get tourMyPlanBody =>
      'Review saved sessions, export your plan, and spot schedule conflicts before you head to a room.';

  @override
  String get tourNext => 'Next';

  @override
  String get tourBack => 'Back';

  @override
  String get tourSkip => 'Skip tour';

  @override
  String get tourDone => 'Done';

  @override
  String get replayTour => 'Replay tour';

  @override
  String tourStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingWelcomeTitle => 'Welcome to Flo Compass';

  @override
  String get onboardingEditTitle => 'Update your interests';

  @override
  String get onboardingWelcomeBody =>
      'Flo 2026 at Nagarro Gurgaon Office — ~640 sessions across 90 spaces (Ground + floors 6–13). We complement Accelevents by helping you choose what matters.';

  @override
  String get onboardingEditBody =>
      'Adjust your role and interests — Discover rankings will update when you save.';

  @override
  String get onboardingRoleTitle => 'Your role';

  @override
  String get onboardingAttendanceTitle => 'How are you attending?';

  @override
  String get onboardingAttendanceHint =>
      'Flo complements Accelevents. Remote mode hides walk directions on session detail and highlights stream-friendly sessions.';

  @override
  String get onboardingOnSite => 'On-site at Gurgaon';

  @override
  String get onboardingRemote => 'Remote / hub';

  @override
  String get onboardingInterestsTitle => 'Pick 3–7 interests';

  @override
  String get onboardingInterestGroupAiData => 'AI & Data';

  @override
  String get onboardingInterestGroupEngineering => 'Engineering';

  @override
  String get onboardingInterestGroupStrategy => 'Strategy';

  @override
  String get onboardingInterestGroupDomain => 'Domain';

  @override
  String get onboardingInterestGroupCrossCutting => 'Cross-cutting';

  @override
  String get onboardingSelectMin => 'Select at least 3 interests';

  @override
  String onboardingContinue(int count) {
    return 'Continue ($count/7)';
  }

  @override
  String onboardingSave(int count) {
    return 'Save changes ($count/7)';
  }

  @override
  String onboardingRoleSemantic(String label) {
    return 'Role $label';
  }

  @override
  String onboardingInterestSemantic(String label) {
    return 'Interest $label';
  }

  @override
  String get onboardingAttendanceSemantic => 'Attendance mode';

  @override
  String get profileAppearanceSection => 'Appearance and language';

  @override
  String get profileTheme => 'Theme';

  @override
  String get profileThemeSubtitle => 'Follow system, or override.';

  @override
  String get profileThemeSystem => 'System';

  @override
  String get profileThemeLight => 'Light';

  @override
  String get profileThemeDark => 'Dark';

  @override
  String get profileThemeHighContrast => 'High contrast';

  @override
  String get profileDyslexiaFont => 'Dyslexia-friendly font';

  @override
  String get profileDyslexiaFontSubtitle =>
      'OpenDyslexic (OFL) · adds ~120KB to download';

  @override
  String get profilePlainEnglish => 'Plain English summaries';

  @override
  String get profilePlainEnglishSubtitle =>
      'Short rule-based session summaries on Discover cards';

  @override
  String get profileEventExperienceSection => 'Event experience';

  @override
  String get profileAttendanceMode => 'Attendance mode';

  @override
  String get profileAttendanceModeSubtitle => 'On-site or remote viewing.';

  @override
  String get profileAttendanceOnSite => 'On-site';

  @override
  String get profileAttendanceRemote => 'Remote';

  @override
  String get profileEventDayMode => 'Event day mode';

  @override
  String get profileEventDayModeSubtitle =>
      'Auto, on, or off for the Now/Next bar.';

  @override
  String get profileEventDayAuto => 'Auto';

  @override
  String get profileEventDayOn => 'On';

  @override
  String get profileEventDayOff => 'Off';

  @override
  String get profileLowBandwidth => 'Low bandwidth mode';

  @override
  String get profileLowBandwidthSubtitle =>
      'Smaller images, no typing animation, list-only Discover.';

  @override
  String get profileNotificationsSection => 'Notifications';

  @override
  String get profileAgendaChangeAlerts => 'Agenda change alerts';

  @override
  String get profileAgendaChangeAlertsSubtitle =>
      'In-app alerts for sessions in My Plan or from speakers you follow.';

  @override
  String get profileAgendaChangeAlertsDisabledSnack =>
      'In-app agenda change alerts are off. Re-enable here when you want room, time, or cancellation updates.';

  @override
  String get profileAgendaChangePush => 'Agenda change push';

  @override
  String get profileAgendaChangePushSubtitle =>
      'Coming soon — browser push for agenda updates.';

  @override
  String get profileLeaveNowReminders => 'Leave-now reminders';

  @override
  String get profileLeaveNowReminderUnsupported =>
      'Not supported in this browser (e.g. iPhone Safari). In-app reminders still work.';

  @override
  String get profileLeaveNowReminderDenied =>
      'Enable in browser settings to receive walk-time alerts with a 5 min buffer.';

  @override
  String get profileLeaveNowReminderEnabled =>
      'Walk time plus 5 min buffer before planned sessions.';

  @override
  String get profileNotificationPermissionDeniedSnack =>
      'Notification permission was not granted.';

  @override
  String get profileEnableBusinessCard => 'Enable business card';

  @override
  String get profileDemoAccessTitle => 'Demo access';

  @override
  String get profileDemoAccessBody =>
      'Pick a mock user to preview organizer or admin tools.';

  @override
  String profileDemoPlatformAccess(String label, String organizationLabel) {
    return 'Platform access: $label$organizationLabel';
  }

  @override
  String get profileOpenOrganizerTab => 'Open Organizer tab';

  @override
  String get profileOpenAdminTab => 'Open Admin tab';

  @override
  String get profileSwitchUser => 'Switch user';

  @override
  String get sessionLeaveNow => 'Leave now';

  @override
  String get sessionAddToMyPlan => 'Add to My Plan';

  @override
  String get sessionAddToPlan => 'Add to plan';

  @override
  String get sessionJoinStream => 'Join stream';

  @override
  String get sessionMarkAsAttended => 'Mark as attended';

  @override
  String get sessionMarkAttended => 'Mark attended';

  @override
  String get sessionInPlan => 'In plan';

  @override
  String get sessionAdded => 'Added';

  @override
  String get sessionAddToCalendar => 'Add to calendar';

  @override
  String get sessionAddToCalendarTooltip => 'Add to calendar';

  @override
  String get myPlanEmptyTitle => 'Your shortlist is empty';

  @override
  String get myPlanEmptyMessage =>
      'Bookmark sessions from Discover. This is a local plan — not the official Accelevents agenda.';

  @override
  String get myPlanBrowseSessions => 'Browse sessions';

  @override
  String get myPlanAskFloDay1 => 'Ask Flo to build my Day 1';

  @override
  String get discoverEmptyFiltered => 'No sessions match your filters';

  @override
  String get discoverEmptyFilteredHint =>
      'Try clearing filters or broadening interests.';

  @override
  String get discoverHappeningNow => 'Happening now';

  @override
  String get discoverStartingSoon => 'Starting soon';

  @override
  String get floMeetsTitle => 'Flo Meets';

  @override
  String get floMeetsDetailTitle => 'Your Flo Meet';

  @override
  String get floMeetsEmptyTitle => 'No matches yet';

  @override
  String get floMeetsEmptyBody =>
      'When you\'re matched for a slot you selected, your meet will appear here.';

  @override
  String get floMeetsNotOptedInTitle => 'Set up Flo Meets';

  @override
  String get floMeetsNotOptedInBody =>
      'Add your matching preferences to join rooms and Connect with peers.';

  @override
  String get floMeetsEditPreferences => 'Preferences';

  @override
  String get floMeetsSavePreferences => 'Save';

  @override
  String get floMeetsSavingPreferences => 'Saving…';

  @override
  String get floMeetsSetupTitle => 'Set up Flo Meets';

  @override
  String get floMeetsSetupBody =>
      'Pick when you\'re free and how you\'d like to meet. You can change this anytime.';

  @override
  String get floMeetsSetupCta => 'Set up preferences';

  @override
  String get floMeetsSignInTitle => 'Sign in to use Flo Meets';

  @override
  String get floMeetsSignInBody =>
      'Flo Meets matching is available to signed-in attendees. Set your preferences here after you sign in.';

  @override
  String get floMeetsSignInUnavailable =>
      'Sign-in is not configured for this build.';

  @override
  String get floMeetsContinueWith => 'Continue with Flo Meets';

  @override
  String get floMeetsSkipOptIn => 'Skip Flo Meets for now';

  @override
  String get floMeetsViewMeets => 'View meets';

  @override
  String get floMeetsNotFound => 'Meet not found';

  @override
  String get floMeetsBackToList => 'Back to meets';

  @override
  String get floMeetsPartnerNickname => 'Nickname';

  @override
  String get floMeetsMeetLocation => 'Where to meet';

  @override
  String get floMeetsContactField => 'Contact';

  @override
  String get floMeetsMeetNote => 'Note';

  @override
  String floMeetsContactLine(String value) {
    return 'Contact: $value';
  }

  @override
  String get floMeetsOnboardingTitle => 'Flo Meets';

  @override
  String get floMeetsOnboardingBody =>
      'Meet people at Flo based on shared interests. Pick when you\'re free and where you\'d like to meet.';

  @override
  String get floMeetsOptInLabel => 'Join Flo Meets';

  @override
  String get floMeetsOptInHint =>
      'Opt in to get matched with other authenticated attendees.';

  @override
  String get floMeetsOnboardingFooter =>
      'You can update these anytime from Profile or Meets → Preferences.';

  @override
  String get meetNicknameLabel => 'Meet nickname';

  @override
  String get meetNicknameHint => '3–20 characters';

  @override
  String get meetNicknameSuggest => 'Suggest nickname';

  @override
  String get floMeetsIdentityTitle => 'I identify as';

  @override
  String get floMeetsOpenToTitle => 'Open to meet';

  @override
  String get floMeetsExperienceTitle => 'Years of experience';

  @override
  String get floMeetsExperienceRequired =>
      'Required for matching (±3 year band).';

  @override
  String get floMeetsExperienceYears => 'years';

  @override
  String get floMeetsPurposeTitle => 'Connection purpose';

  @override
  String get floMeetsPersonalInterestsTitle => 'Personal interests';

  @override
  String get floMeetsPersonalityTitle => 'Personality';

  @override
  String get floMeetsSlotsTitle => 'Availability (pick at least one)';

  @override
  String get floMeetsSlotsHint =>
      'Only the time slots you select here will be used for your Flo Meets.';

  @override
  String get floMeetsAmenityTitle => 'Where to meet';

  @override
  String get floMeetsAmenityHint => 'Pick a campus amenity';

  @override
  String get floMeetsContactMediumTitle => 'Share contact (optional)';

  @override
  String get floMeetsContactNone => 'None';

  @override
  String get floMeetsContactEmail => 'Email from Networking Card';

  @override
  String get floMeetsContactPhone => 'Phone from Networking Card';

  @override
  String get floMeetsContactLinkedin => 'LinkedIn from Networking Card';

  @override
  String get floMeetsContactEmptyWarning =>
      'Add this field in your Networking Card or clear your selection.';

  @override
  String get floMeetsMeetNoteTitle => 'Meet note (optional)';

  @override
  String get floMeetsMeetNoteHint =>
      'e.g. I\'ll be near registration in a blue jacket';

  @override
  String floMeetsProfileOptedIn(int count) {
    return '$count slots selected';
  }

  @override
  String floMeetsProfileSlotsReady(int count) {
    return '$count slots selected';
  }

  @override
  String get floMeetsProfileOptedOut => 'Preferences not set yet';

  @override
  String get floMeetsProfileSetupNeeded =>
      'Set up preferences to join match rooms and Connect.';

  @override
  String get floMeetsProfileDescription =>
      'Join match rooms, see match %, and Connect when both sides are ready.';

  @override
  String get floMeetsOpenOnCampusMap => 'Open on campus map';

  @override
  String get floMeetsPreviewDemoMatch => 'Preview demo match';

  @override
  String floMeetsDiscoverChip(String time) {
    return 'Flo Meet at $time';
  }

  @override
  String get floMeetsHubRooms => 'Rooms';

  @override
  String get floMeetsHubWaiting => 'Waiting';

  @override
  String get floMeetsHubMatches => 'Matches';

  @override
  String get floMeetsRoomsEmpty =>
      'No published match rooms yet. Check back soon.';

  @override
  String get floMeetsWaitingEmpty =>
      'No waiting connections. Connect with someone in a room to see them here.';

  @override
  String get floMeetsMatchesEmpty =>
      'No matches yet. Connect in a room — a match appears when both sides Connect.';

  @override
  String get floMeetsJoinedBadge => 'Joined';

  @override
  String floMeetsOccupancy(int current, int capacity) {
    return '$current / $capacity people';
  }

  @override
  String get floMeetsJoinRoom => 'Join room';

  @override
  String get floMeetsLeaveRoom => 'Leave room';

  @override
  String get floMeetsRoomFull => 'This room is full';

  @override
  String get floMeetsRoomNotFound => 'Room not found';

  @override
  String get floMeetsBackToHub => 'Back to Meets';

  @override
  String get floMeetsBackToRoom => 'Back to room';

  @override
  String get floMeetsPeopleInRoom => 'People in this room';

  @override
  String get floMeetsNoPeopleInRoom => 'No one else in this room yet.';

  @override
  String floMeetsMatchPercent(int percent) {
    return '$percent% match';
  }

  @override
  String get floMeetsMatchWindowTitle => 'Match window';

  @override
  String get floMeetsPartnerNotFound => 'Partner not found in this room';

  @override
  String get floMeetsOverlapTitle => 'Shared interests';

  @override
  String get floMeetsConnectCta => 'Connect';

  @override
  String get floMeetsConnecting => 'Connecting…';

  @override
  String get floMeetsWaitingForThem => 'Waiting for them…';

  @override
  String get floMeetsMatchedLabel => 'Matched';

  @override
  String get floMeetsMatchedContinue => 'View meet details';

  @override
  String get floMeetsOpenConnectShare => 'Open Connect share';

  @override
  String get consentFloMeetsBody =>
      'Flo Meets stores your meet nickname, chosen amenity meet point, slot preferences, and an optional single contact field from your Networking Card locally for peer matching. You can update preferences anytime from Profile or Meets.';

  @override
  String get consentFloMeetsBullet =>
      'Flo Meets uses nickname-only reveal — not your legal name or session interests.';
}
