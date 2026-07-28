import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @tabDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get tabDiscover;

  /// No description provided for @tabCompanion.
  ///
  /// In en, this message translates to:
  /// **'Ask Flo'**
  String get tabCompanion;

  /// No description provided for @tabMeets.
  ///
  /// In en, this message translates to:
  /// **'Meets'**
  String get tabMeets;

  /// No description provided for @tabMyPlan.
  ///
  /// In en, this message translates to:
  /// **'My Plan'**
  String get tabMyPlan;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyTitle;

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data use'**
  String get consentTitle;

  /// No description provided for @consentBody.
  ///
  /// In en, this message translates to:
  /// **'Flo Compass stores your plan, interests, and settings locally in your browser. We use this data to personalize session recommendations. Accelevents handles official registration — this app does not replace it.'**
  String get consentBody;

  /// No description provided for @consentAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept and continue'**
  String get consentAccept;

  /// No description provided for @consentDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get consentDecline;

  /// No description provided for @consentReadPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read full privacy policy'**
  String get consentReadPolicy;

  /// No description provided for @consentRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Consent required'**
  String get consentRequiredTitle;

  /// No description provided for @consentRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'You must accept the privacy policy to use Flo Compass. No personal data leaves your device without your consent.'**
  String get consentRequiredBody;

  /// No description provided for @consentOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get consentOk;

  /// No description provided for @profileLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get profileLogin;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileLogout;

  /// No description provided for @profileSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String profileSignedInAs(String name);

  /// No description provided for @profileScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileScreenTitle;

  /// No description provided for @profileTabYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get profileTabYou;

  /// No description provided for @profileTabProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get profileTabProgress;

  /// No description provided for @profileTabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileTabSettings;

  /// No description provided for @profileTabOrganizer.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get profileTabOrganizer;

  /// No description provided for @profileTabAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get profileTabAdmin;

  /// No description provided for @profileMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get profileMoreOptions;

  /// No description provided for @profileInstallApp.
  ///
  /// In en, this message translates to:
  /// **'Install app'**
  String get profileInstallApp;

  /// No description provided for @profileInstallFallback.
  ///
  /// In en, this message translates to:
  /// **'Use your browser menu to install this app'**
  String get profileInstallFallback;

  /// No description provided for @localeLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get localeLabel;

  /// No description provided for @localeEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get localeEn;

  /// No description provided for @localeDe.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get localeDe;

  /// No description provided for @localeEs.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get localeEs;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedback;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report issue'**
  String get reportIssue;

  /// No description provided for @commonDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get commonDismiss;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({build})'**
  String aboutVersion(String version, String build);

  /// No description provided for @accessibilityStatement.
  ///
  /// In en, this message translates to:
  /// **'Accessibility statement'**
  String get accessibilityStatement;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — showing saved Flo 2026 data.'**
  String get offlineBanner;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No upcoming alerts'**
  String get notificationsEmpty;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your saved sessions will appear here.'**
  String get notificationsEmptySubtitle;

  /// No description provided for @notificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTooltip;

  /// No description provided for @notificationsBellLabelWithCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No notifications} =1{Notifications, 1 alert} other{Notifications, {count} alerts}}'**
  String notificationsBellLabelWithCount(int count);

  /// No description provided for @notificationsRefreshAgenda.
  ///
  /// In en, this message translates to:
  /// **'Refresh agenda'**
  String get notificationsRefreshAgenda;

  /// No description provided for @notificationsDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get notificationsDismiss;

  /// No description provided for @authCompletingSignIn.
  ///
  /// In en, this message translates to:
  /// **'Completing sign-in…'**
  String get authCompletingSignIn;

  /// No description provided for @authSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in could not be completed.'**
  String get authSignInFailed;

  /// No description provided for @tourNowNextTitle.
  ///
  /// In en, this message translates to:
  /// **'See what\'s live'**
  String get tourNowNextTitle;

  /// No description provided for @tourNowNextBody.
  ///
  /// In en, this message translates to:
  /// **'Your event clock — what\'s live and what\'s up next.'**
  String get tourNowNextBody;

  /// No description provided for @tourDiscoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Search sessions'**
  String get tourDiscoverTitle;

  /// No description provided for @tourDiscoverBody.
  ///
  /// In en, this message translates to:
  /// **'Find talks by title, speaker, or topic. Filters and recommendations update as you type.'**
  String get tourDiscoverBody;

  /// No description provided for @tourRecoReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Why we picked it'**
  String get tourRecoReasonTitle;

  /// No description provided for @tourRecoReasonBody.
  ///
  /// In en, this message translates to:
  /// **'Every recommendation shows its reasoning — no black box.'**
  String get tourRecoReasonBody;

  /// No description provided for @tourSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Save to My Plan'**
  String get tourSessionTitle;

  /// No description provided for @tourSessionBody.
  ///
  /// In en, this message translates to:
  /// **'Bookmark sessions you want to attend. Your shortlist stays on this device — separate from Accelevents registration.'**
  String get tourSessionBody;

  /// No description provided for @tourLogisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Open Logistics'**
  String get tourLogisticsTitle;

  /// No description provided for @tourLogisticsBody.
  ///
  /// In en, this message translates to:
  /// **'Venue details, walk times, and campus actions live here.'**
  String get tourLogisticsBody;

  /// No description provided for @tourVenueMapTitle.
  ///
  /// In en, this message translates to:
  /// **'See it on the map'**
  String get tourVenueMapTitle;

  /// No description provided for @tourVenueMapBody.
  ///
  /// In en, this message translates to:
  /// **'Tap Map to view this room on the campus.'**
  String get tourVenueMapBody;

  /// No description provided for @tourCompanionTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask Flo'**
  String get tourCompanionTitle;

  /// No description provided for @tourCompanionBody.
  ///
  /// In en, this message translates to:
  /// **'Sessions, restrooms, parking, clashes — try \'Where can I park my car?\''**
  String get tourCompanionBody;

  /// No description provided for @tourMyPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Your shortlist'**
  String get tourMyPlanTitle;

  /// No description provided for @tourMyPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Review saved sessions, export your plan, and spot schedule conflicts before you head to a room.'**
  String get tourMyPlanBody;

  /// No description provided for @tourNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tourNext;

  /// No description provided for @tourBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tourBack;

  /// No description provided for @tourSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip tour'**
  String get tourSkip;

  /// No description provided for @tourDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tourDone;

  /// No description provided for @replayTour.
  ///
  /// In en, this message translates to:
  /// **'Replay tour'**
  String get replayTour;

  /// No description provided for @tourStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String tourStepOf(int current, int total);

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Flo Compass'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Update your interests'**
  String get onboardingEditTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Flo 2026 at Nagarro Gurgaon Office — ~640 sessions across 90 spaces (Ground + floors 6–13). We complement Accelevents by helping you choose what matters.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingEditBody.
  ///
  /// In en, this message translates to:
  /// **'Adjust your role and interests — Discover rankings will update when you save.'**
  String get onboardingEditBody;

  /// No description provided for @onboardingRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Your role'**
  String get onboardingRoleTitle;

  /// No description provided for @onboardingAttendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'How are you attending?'**
  String get onboardingAttendanceTitle;

  /// No description provided for @onboardingAttendanceHint.
  ///
  /// In en, this message translates to:
  /// **'Flo complements Accelevents. Remote mode hides walk directions on session detail and highlights stream-friendly sessions.'**
  String get onboardingAttendanceHint;

  /// No description provided for @onboardingOnSite.
  ///
  /// In en, this message translates to:
  /// **'On-site at Gurgaon'**
  String get onboardingOnSite;

  /// No description provided for @onboardingRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote / hub'**
  String get onboardingRemote;

  /// No description provided for @onboardingInterestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick 3–7 interests'**
  String get onboardingInterestsTitle;

  /// No description provided for @onboardingInterestGroupAiData.
  ///
  /// In en, this message translates to:
  /// **'AI & Data'**
  String get onboardingInterestGroupAiData;

  /// No description provided for @onboardingInterestGroupEngineering.
  ///
  /// In en, this message translates to:
  /// **'Engineering'**
  String get onboardingInterestGroupEngineering;

  /// No description provided for @onboardingInterestGroupStrategy.
  ///
  /// In en, this message translates to:
  /// **'Strategy'**
  String get onboardingInterestGroupStrategy;

  /// No description provided for @onboardingInterestGroupDomain.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get onboardingInterestGroupDomain;

  /// No description provided for @onboardingInterestGroupCrossCutting.
  ///
  /// In en, this message translates to:
  /// **'Cross-cutting'**
  String get onboardingInterestGroupCrossCutting;

  /// No description provided for @onboardingSelectMin.
  ///
  /// In en, this message translates to:
  /// **'Select at least 3 interests'**
  String get onboardingSelectMin;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue ({count}/7)'**
  String onboardingContinue(int count);

  /// No description provided for @onboardingSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes ({count}/7)'**
  String onboardingSave(int count);

  /// No description provided for @onboardingRoleSemantic.
  ///
  /// In en, this message translates to:
  /// **'Role {label}'**
  String onboardingRoleSemantic(String label);

  /// No description provided for @onboardingInterestSemantic.
  ///
  /// In en, this message translates to:
  /// **'Interest {label}'**
  String onboardingInterestSemantic(String label);

  /// No description provided for @onboardingAttendanceSemantic.
  ///
  /// In en, this message translates to:
  /// **'Attendance mode'**
  String get onboardingAttendanceSemantic;

  /// No description provided for @profileAppearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance and language'**
  String get profileAppearanceSection;

  /// No description provided for @profileTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get profileTheme;

  /// No description provided for @profileThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow system, or override.'**
  String get profileThemeSubtitle;

  /// No description provided for @profileThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get profileThemeSystem;

  /// No description provided for @profileThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get profileThemeLight;

  /// No description provided for @profileThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get profileThemeDark;

  /// No description provided for @profileThemeHighContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get profileThemeHighContrast;

  /// No description provided for @profileDyslexiaFont.
  ///
  /// In en, this message translates to:
  /// **'Dyslexia-friendly font'**
  String get profileDyslexiaFont;

  /// No description provided for @profileDyslexiaFontSubtitle.
  ///
  /// In en, this message translates to:
  /// **'OpenDyslexic (OFL) · adds ~120KB to download'**
  String get profileDyslexiaFontSubtitle;

  /// No description provided for @profilePlainEnglish.
  ///
  /// In en, this message translates to:
  /// **'Plain English summaries'**
  String get profilePlainEnglish;

  /// No description provided for @profilePlainEnglishSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Short rule-based session summaries on Discover cards'**
  String get profilePlainEnglishSubtitle;

  /// No description provided for @profileEventExperienceSection.
  ///
  /// In en, this message translates to:
  /// **'Event experience'**
  String get profileEventExperienceSection;

  /// No description provided for @profileAttendanceMode.
  ///
  /// In en, this message translates to:
  /// **'Attendance mode'**
  String get profileAttendanceMode;

  /// No description provided for @profileAttendanceModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On-site or remote viewing.'**
  String get profileAttendanceModeSubtitle;

  /// No description provided for @profileAttendanceOnSite.
  ///
  /// In en, this message translates to:
  /// **'On-site'**
  String get profileAttendanceOnSite;

  /// No description provided for @profileAttendanceRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get profileAttendanceRemote;

  /// No description provided for @profileEventDayMode.
  ///
  /// In en, this message translates to:
  /// **'Event day mode'**
  String get profileEventDayMode;

  /// No description provided for @profileEventDayModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Auto, on, or off for the Now/Next bar.'**
  String get profileEventDayModeSubtitle;

  /// No description provided for @profileEventDayAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get profileEventDayAuto;

  /// No description provided for @profileEventDayOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get profileEventDayOn;

  /// No description provided for @profileEventDayOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get profileEventDayOff;

  /// No description provided for @profileLowBandwidth.
  ///
  /// In en, this message translates to:
  /// **'Low bandwidth mode'**
  String get profileLowBandwidth;

  /// No description provided for @profileLowBandwidthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Smaller images, no typing animation, list-only Discover.'**
  String get profileLowBandwidthSubtitle;

  /// No description provided for @profileNotificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotificationsSection;

  /// No description provided for @profileAgendaChangeAlerts.
  ///
  /// In en, this message translates to:
  /// **'Agenda change alerts'**
  String get profileAgendaChangeAlerts;

  /// No description provided for @profileAgendaChangeAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'In-app alerts for sessions in My Plan or from speakers you follow.'**
  String get profileAgendaChangeAlertsSubtitle;

  /// No description provided for @profileAgendaChangeAlertsDisabledSnack.
  ///
  /// In en, this message translates to:
  /// **'In-app agenda change alerts are off. Re-enable here when you want room, time, or cancellation updates.'**
  String get profileAgendaChangeAlertsDisabledSnack;

  /// No description provided for @profileAgendaChangePush.
  ///
  /// In en, this message translates to:
  /// **'Agenda change push'**
  String get profileAgendaChangePush;

  /// No description provided for @profileAgendaChangePushSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon — browser push for agenda updates.'**
  String get profileAgendaChangePushSubtitle;

  /// No description provided for @profileLeaveNowReminders.
  ///
  /// In en, this message translates to:
  /// **'Leave-now reminders'**
  String get profileLeaveNowReminders;

  /// No description provided for @profileLeaveNowReminderUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Not supported in this browser (e.g. iPhone Safari). In-app reminders still work.'**
  String get profileLeaveNowReminderUnsupported;

  /// No description provided for @profileLeaveNowReminderDenied.
  ///
  /// In en, this message translates to:
  /// **'Enable in browser settings to receive walk-time alerts with a 5 min buffer.'**
  String get profileLeaveNowReminderDenied;

  /// No description provided for @profileLeaveNowReminderEnabled.
  ///
  /// In en, this message translates to:
  /// **'Walk time plus 5 min buffer before planned sessions.'**
  String get profileLeaveNowReminderEnabled;

  /// No description provided for @profileNotificationPermissionDeniedSnack.
  ///
  /// In en, this message translates to:
  /// **'Notification permission was not granted.'**
  String get profileNotificationPermissionDeniedSnack;

  /// No description provided for @profileEnableBusinessCard.
  ///
  /// In en, this message translates to:
  /// **'Enable business card'**
  String get profileEnableBusinessCard;

  /// No description provided for @profileDemoAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Demo access'**
  String get profileDemoAccessTitle;

  /// No description provided for @profileDemoAccessBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a mock user to preview organizer or admin tools.'**
  String get profileDemoAccessBody;

  /// No description provided for @profileDemoPlatformAccess.
  ///
  /// In en, this message translates to:
  /// **'Platform access: {label}{organizationLabel}'**
  String profileDemoPlatformAccess(String label, String organizationLabel);

  /// No description provided for @profileOpenOrganizerTab.
  ///
  /// In en, this message translates to:
  /// **'Open Organizer tab'**
  String get profileOpenOrganizerTab;

  /// No description provided for @profileOpenAdminTab.
  ///
  /// In en, this message translates to:
  /// **'Open Admin tab'**
  String get profileOpenAdminTab;

  /// No description provided for @profileSwitchUser.
  ///
  /// In en, this message translates to:
  /// **'Switch user'**
  String get profileSwitchUser;

  /// No description provided for @sessionLeaveNow.
  ///
  /// In en, this message translates to:
  /// **'Leave now'**
  String get sessionLeaveNow;

  /// No description provided for @sessionAddToMyPlan.
  ///
  /// In en, this message translates to:
  /// **'Add to My Plan'**
  String get sessionAddToMyPlan;

  /// No description provided for @sessionAddToPlan.
  ///
  /// In en, this message translates to:
  /// **'Add to plan'**
  String get sessionAddToPlan;

  /// No description provided for @sessionJoinStream.
  ///
  /// In en, this message translates to:
  /// **'Join stream'**
  String get sessionJoinStream;

  /// No description provided for @sessionMarkAsAttended.
  ///
  /// In en, this message translates to:
  /// **'Mark as attended'**
  String get sessionMarkAsAttended;

  /// No description provided for @sessionMarkAttended.
  ///
  /// In en, this message translates to:
  /// **'Mark attended'**
  String get sessionMarkAttended;

  /// No description provided for @sessionInPlan.
  ///
  /// In en, this message translates to:
  /// **'In plan'**
  String get sessionInPlan;

  /// No description provided for @sessionAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get sessionAdded;

  /// No description provided for @sessionAddToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to calendar'**
  String get sessionAddToCalendar;

  /// No description provided for @sessionAddToCalendarTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add to calendar'**
  String get sessionAddToCalendarTooltip;

  /// No description provided for @myPlanEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your shortlist is empty'**
  String get myPlanEmptyTitle;

  /// No description provided for @myPlanEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Bookmark sessions from Discover. This is a local plan — not the official Accelevents agenda.'**
  String get myPlanEmptyMessage;

  /// No description provided for @myPlanBrowseSessions.
  ///
  /// In en, this message translates to:
  /// **'Browse sessions'**
  String get myPlanBrowseSessions;

  /// No description provided for @myPlanAskFloDay1.
  ///
  /// In en, this message translates to:
  /// **'Ask Flo to build my Day 1'**
  String get myPlanAskFloDay1;

  /// No description provided for @discoverEmptyFiltered.
  ///
  /// In en, this message translates to:
  /// **'No sessions match your filters'**
  String get discoverEmptyFiltered;

  /// No description provided for @discoverEmptyFilteredHint.
  ///
  /// In en, this message translates to:
  /// **'Try clearing filters or broadening interests.'**
  String get discoverEmptyFilteredHint;

  /// No description provided for @discoverHappeningNow.
  ///
  /// In en, this message translates to:
  /// **'Happening now'**
  String get discoverHappeningNow;

  /// No description provided for @discoverStartingSoon.
  ///
  /// In en, this message translates to:
  /// **'Starting soon'**
  String get discoverStartingSoon;

  /// No description provided for @floMeetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Flo Meets'**
  String get floMeetsTitle;

  /// No description provided for @floMeetsDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Flo Meet'**
  String get floMeetsDetailTitle;

  /// No description provided for @floMeetsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get floMeetsEmptyTitle;

  /// No description provided for @floMeetsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'When you\'re matched for a slot you selected, your meet will appear here.'**
  String get floMeetsEmptyBody;

  /// No description provided for @floMeetsNotOptedInTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up Flo Meets'**
  String get floMeetsNotOptedInTitle;

  /// No description provided for @floMeetsNotOptedInBody.
  ///
  /// In en, this message translates to:
  /// **'Add your matching preferences to join rooms and Connect with peers.'**
  String get floMeetsNotOptedInBody;

  /// No description provided for @floMeetsEditPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get floMeetsEditPreferences;

  /// No description provided for @floMeetsSavePreferences.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get floMeetsSavePreferences;

  /// No description provided for @floMeetsSavingPreferences.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get floMeetsSavingPreferences;

  /// No description provided for @floMeetsSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up Flo Meets'**
  String get floMeetsSetupTitle;

  /// No description provided for @floMeetsSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Pick when you\'re free and how you\'d like to meet. You can change this anytime.'**
  String get floMeetsSetupBody;

  /// No description provided for @floMeetsSetupCta.
  ///
  /// In en, this message translates to:
  /// **'Set up preferences'**
  String get floMeetsSetupCta;

  /// No description provided for @floMeetsSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use Flo Meets'**
  String get floMeetsSignInTitle;

  /// No description provided for @floMeetsSignInBody.
  ///
  /// In en, this message translates to:
  /// **'Flo Meets matching is available to signed-in attendees. Set your preferences here after you sign in.'**
  String get floMeetsSignInBody;

  /// No description provided for @floMeetsSignInUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sign-in is not configured for this build.'**
  String get floMeetsSignInUnavailable;

  /// No description provided for @floMeetsContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Continue with Flo Meets'**
  String get floMeetsContinueWith;

  /// No description provided for @floMeetsSkipOptIn.
  ///
  /// In en, this message translates to:
  /// **'Skip Flo Meets for now'**
  String get floMeetsSkipOptIn;

  /// No description provided for @floMeetsViewMeets.
  ///
  /// In en, this message translates to:
  /// **'View meets'**
  String get floMeetsViewMeets;

  /// No description provided for @floMeetsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Meet not found'**
  String get floMeetsNotFound;

  /// No description provided for @floMeetsBackToList.
  ///
  /// In en, this message translates to:
  /// **'Back to meets'**
  String get floMeetsBackToList;

  /// No description provided for @floMeetsPartnerNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get floMeetsPartnerNickname;

  /// No description provided for @floMeetsMeetLocation.
  ///
  /// In en, this message translates to:
  /// **'Where to meet'**
  String get floMeetsMeetLocation;

  /// No description provided for @floMeetsContactField.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get floMeetsContactField;

  /// No description provided for @floMeetsMeetNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get floMeetsMeetNote;

  /// No description provided for @floMeetsContactLine.
  ///
  /// In en, this message translates to:
  /// **'Contact: {value}'**
  String floMeetsContactLine(String value);

  /// No description provided for @floMeetsOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Flo Meets'**
  String get floMeetsOnboardingTitle;

  /// No description provided for @floMeetsOnboardingBody.
  ///
  /// In en, this message translates to:
  /// **'Meet people at Flo based on shared interests. Pick when you\'re free and where you\'d like to meet.'**
  String get floMeetsOnboardingBody;

  /// No description provided for @floMeetsOptInLabel.
  ///
  /// In en, this message translates to:
  /// **'Join Flo Meets'**
  String get floMeetsOptInLabel;

  /// No description provided for @floMeetsOptInHint.
  ///
  /// In en, this message translates to:
  /// **'Opt in to get matched with other authenticated attendees.'**
  String get floMeetsOptInHint;

  /// No description provided for @floMeetsOnboardingFooter.
  ///
  /// In en, this message translates to:
  /// **'You can update these anytime from Profile or Meets → Preferences.'**
  String get floMeetsOnboardingFooter;

  /// No description provided for @meetNicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Meet nickname'**
  String get meetNicknameLabel;

  /// No description provided for @meetNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'3–20 characters'**
  String get meetNicknameHint;

  /// No description provided for @meetNicknameSuggest.
  ///
  /// In en, this message translates to:
  /// **'Suggest nickname'**
  String get meetNicknameSuggest;

  /// No description provided for @floMeetsIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'I identify as'**
  String get floMeetsIdentityTitle;

  /// No description provided for @floMeetsOpenToTitle.
  ///
  /// In en, this message translates to:
  /// **'Open to meet'**
  String get floMeetsOpenToTitle;

  /// No description provided for @floMeetsExperienceTitle.
  ///
  /// In en, this message translates to:
  /// **'Years of experience'**
  String get floMeetsExperienceTitle;

  /// No description provided for @floMeetsExperienceRequired.
  ///
  /// In en, this message translates to:
  /// **'Required for matching (±3 year band).'**
  String get floMeetsExperienceRequired;

  /// No description provided for @floMeetsExperienceYears.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get floMeetsExperienceYears;

  /// No description provided for @floMeetsPurposeTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection purpose'**
  String get floMeetsPurposeTitle;

  /// No description provided for @floMeetsPersonalInterestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal interests'**
  String get floMeetsPersonalInterestsTitle;

  /// No description provided for @floMeetsPersonalityTitle.
  ///
  /// In en, this message translates to:
  /// **'Personality'**
  String get floMeetsPersonalityTitle;

  /// No description provided for @floMeetsSlotsTitle.
  ///
  /// In en, this message translates to:
  /// **'Availability (pick at least one)'**
  String get floMeetsSlotsTitle;

  /// No description provided for @floMeetsSlotsHint.
  ///
  /// In en, this message translates to:
  /// **'Only the time slots you select here will be used for your Flo Meets.'**
  String get floMeetsSlotsHint;

  /// No description provided for @floMeetsAmenityTitle.
  ///
  /// In en, this message translates to:
  /// **'Where to meet'**
  String get floMeetsAmenityTitle;

  /// No description provided for @floMeetsAmenityHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a campus amenity'**
  String get floMeetsAmenityHint;

  /// No description provided for @floMeetsContactMediumTitle.
  ///
  /// In en, this message translates to:
  /// **'Share contact (optional)'**
  String get floMeetsContactMediumTitle;

  /// No description provided for @floMeetsContactNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get floMeetsContactNone;

  /// No description provided for @floMeetsContactEmail.
  ///
  /// In en, this message translates to:
  /// **'Email from Networking Card'**
  String get floMeetsContactEmail;

  /// No description provided for @floMeetsContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone from Networking Card'**
  String get floMeetsContactPhone;

  /// No description provided for @floMeetsContactLinkedin.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn from Networking Card'**
  String get floMeetsContactLinkedin;

  /// No description provided for @floMeetsContactEmptyWarning.
  ///
  /// In en, this message translates to:
  /// **'Add this field in your Networking Card or clear your selection.'**
  String get floMeetsContactEmptyWarning;

  /// No description provided for @floMeetsMeetNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Meet note (optional)'**
  String get floMeetsMeetNoteTitle;

  /// No description provided for @floMeetsMeetNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. I\'ll be near registration in a blue jacket'**
  String get floMeetsMeetNoteHint;

  /// No description provided for @floMeetsProfileOptedIn.
  ///
  /// In en, this message translates to:
  /// **'{count} slots selected'**
  String floMeetsProfileOptedIn(int count);

  /// No description provided for @floMeetsProfileSlotsReady.
  ///
  /// In en, this message translates to:
  /// **'{count} slots selected'**
  String floMeetsProfileSlotsReady(int count);

  /// No description provided for @floMeetsProfileOptedOut.
  ///
  /// In en, this message translates to:
  /// **'Preferences not set yet'**
  String get floMeetsProfileOptedOut;

  /// No description provided for @floMeetsProfileSetupNeeded.
  ///
  /// In en, this message translates to:
  /// **'Set up preferences to join match rooms and Connect.'**
  String get floMeetsProfileSetupNeeded;

  /// No description provided for @floMeetsProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Join match rooms, see match %, and Connect when both sides are ready.'**
  String get floMeetsProfileDescription;

  /// No description provided for @floMeetsOpenOnCampusMap.
  ///
  /// In en, this message translates to:
  /// **'Open on campus map'**
  String get floMeetsOpenOnCampusMap;

  /// No description provided for @floMeetsPreviewDemoMatch.
  ///
  /// In en, this message translates to:
  /// **'Preview demo match'**
  String get floMeetsPreviewDemoMatch;

  /// No description provided for @floMeetsDiscoverChip.
  ///
  /// In en, this message translates to:
  /// **'Flo Meet at {time}'**
  String floMeetsDiscoverChip(String time);

  /// No description provided for @floMeetsHubRooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get floMeetsHubRooms;

  /// No description provided for @floMeetsHubWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get floMeetsHubWaiting;

  /// No description provided for @floMeetsHubMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get floMeetsHubMatches;

  /// No description provided for @floMeetsRoomsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No published match rooms yet. Check back soon.'**
  String get floMeetsRoomsEmpty;

  /// No description provided for @floMeetsWaitingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No waiting connections. Connect with someone in a room to see them here.'**
  String get floMeetsWaitingEmpty;

  /// No description provided for @floMeetsMatchesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matches yet. Connect in a room — a match appears when both sides Connect.'**
  String get floMeetsMatchesEmpty;

  /// No description provided for @floMeetsJoinedBadge.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get floMeetsJoinedBadge;

  /// No description provided for @floMeetsOccupancy.
  ///
  /// In en, this message translates to:
  /// **'{current} / {capacity} people'**
  String floMeetsOccupancy(int current, int capacity);

  /// No description provided for @floMeetsJoinRoom.
  ///
  /// In en, this message translates to:
  /// **'Join room'**
  String get floMeetsJoinRoom;

  /// No description provided for @floMeetsLeaveRoom.
  ///
  /// In en, this message translates to:
  /// **'Leave room'**
  String get floMeetsLeaveRoom;

  /// No description provided for @floMeetsRoomFull.
  ///
  /// In en, this message translates to:
  /// **'This room is full'**
  String get floMeetsRoomFull;

  /// No description provided for @floMeetsRoomNotFound.
  ///
  /// In en, this message translates to:
  /// **'Room not found'**
  String get floMeetsRoomNotFound;

  /// No description provided for @floMeetsBackToHub.
  ///
  /// In en, this message translates to:
  /// **'Back to Meets'**
  String get floMeetsBackToHub;

  /// No description provided for @floMeetsBackToRoom.
  ///
  /// In en, this message translates to:
  /// **'Back to room'**
  String get floMeetsBackToRoom;

  /// No description provided for @floMeetsPeopleInRoom.
  ///
  /// In en, this message translates to:
  /// **'People in this room'**
  String get floMeetsPeopleInRoom;

  /// No description provided for @floMeetsNoPeopleInRoom.
  ///
  /// In en, this message translates to:
  /// **'No one else in this room yet.'**
  String get floMeetsNoPeopleInRoom;

  /// No description provided for @floMeetsMatchPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% match'**
  String floMeetsMatchPercent(int percent);

  /// No description provided for @floMeetsMatchWindowTitle.
  ///
  /// In en, this message translates to:
  /// **'Match window'**
  String get floMeetsMatchWindowTitle;

  /// No description provided for @floMeetsPartnerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Partner not found in this room'**
  String get floMeetsPartnerNotFound;

  /// No description provided for @floMeetsOverlapTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared interests'**
  String get floMeetsOverlapTitle;

  /// No description provided for @floMeetsConnectCta.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get floMeetsConnectCta;

  /// No description provided for @floMeetsConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get floMeetsConnecting;

  /// No description provided for @floMeetsWaitingForThem.
  ///
  /// In en, this message translates to:
  /// **'Waiting for them…'**
  String get floMeetsWaitingForThem;

  /// No description provided for @floMeetsMatchedLabel.
  ///
  /// In en, this message translates to:
  /// **'Matched'**
  String get floMeetsMatchedLabel;

  /// No description provided for @floMeetsMatchedContinue.
  ///
  /// In en, this message translates to:
  /// **'View meet details'**
  String get floMeetsMatchedContinue;

  /// No description provided for @floMeetsOpenConnectShare.
  ///
  /// In en, this message translates to:
  /// **'Open Connect share'**
  String get floMeetsOpenConnectShare;

  /// No description provided for @consentFloMeetsBody.
  ///
  /// In en, this message translates to:
  /// **'Flo Meets stores your meet nickname, chosen amenity meet point, slot preferences, and an optional single contact field from your Networking Card locally for peer matching. You can update preferences anytime from Profile or Meets.'**
  String get consentFloMeetsBody;

  /// No description provided for @consentFloMeetsBullet.
  ///
  /// In en, this message translates to:
  /// **'Flo Meets uses nickname-only reveal — not your legal name or session interests.'**
  String get consentFloMeetsBullet;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
