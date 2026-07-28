// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get tabDiscover => 'Entdecken';

  @override
  String get tabCompanion => 'Flo fragen';

  @override
  String get tabMeets => 'Meets';

  @override
  String get tabMyPlan => 'Mein Plan';

  @override
  String get tabProfile => 'Profil';

  @override
  String get loading => 'Wird geladen…';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get emptyTitle => 'Noch nichts hier';

  @override
  String get consentTitle => 'Datenschutz & Datennutzung';

  @override
  String get consentBody =>
      'Flo Compass speichert deinen Plan, deine Interessen und Einstellungen lokal im Browser. Wir nutzen diese Daten, um Sitzungsempfehlungen zu personalisieren. Accelevents übernimmt die offizielle Registrierung — diese App ersetzt sie nicht.';

  @override
  String get consentAccept => 'Akzeptieren und fortfahren';

  @override
  String get consentDecline => 'Ablehnen';

  @override
  String get consentReadPolicy => 'Vollständige Datenschutzerklärung lesen';

  @override
  String get consentRequiredTitle => 'Zustimmung erforderlich';

  @override
  String get consentRequiredBody =>
      'Du musst der Datenschutzerklärung zustimmen, um Flo Compass zu nutzen. Ohne deine Zustimmung verlassen keine persönlichen Daten dein Gerät.';

  @override
  String get consentOk => 'OK';

  @override
  String get profileLogin => 'Anmelden';

  @override
  String get profileLogout => 'Abmelden';

  @override
  String profileSignedInAs(String name) {
    return 'Angemeldet als $name';
  }

  @override
  String get profileScreenTitle => 'Profil';

  @override
  String get profileTabYou => 'Du';

  @override
  String get profileTabProgress => 'Fortschritt';

  @override
  String get profileTabSettings => 'Einstellungen';

  @override
  String get profileTabOrganizer => 'Organisator';

  @override
  String get profileTabAdmin => 'Admin';

  @override
  String get profileMoreOptions => 'Weitere Optionen';

  @override
  String get profileInstallApp => 'App installieren';

  @override
  String get profileInstallFallback =>
      'Verwende das Browsermenü, um diese App zu installieren';

  @override
  String get localeLabel => 'Sprache';

  @override
  String get localeEn => 'English';

  @override
  String get localeDe => 'Deutsch';

  @override
  String get localeEs => 'Español';

  @override
  String get sendFeedback => 'Feedback senden';

  @override
  String get reportIssue => 'Problem melden';

  @override
  String get commonDismiss => 'Verwerfen';

  @override
  String aboutVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get accessibilityStatement => 'Barrierefreiheitserklärung';

  @override
  String get offlineBanner =>
      'Du bist offline — gespeicherte Flo 2026-Daten werden angezeigt.';

  @override
  String get notificationsTitle => 'Benachrichtigungen';

  @override
  String get notificationsEmpty => 'Keine anstehenden Hinweise';

  @override
  String get notificationsEmptySubtitle =>
      'Deine gespeicherten Sitzungen erscheinen hier.';

  @override
  String get notificationsTooltip => 'Benachrichtigungen';

  @override
  String notificationsBellLabelWithCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Benachrichtigungen, $count Hinweise',
      one: 'Benachrichtigungen, 1 Hinweis',
      zero: 'Keine Benachrichtigungen',
    );
    return '$_temp0';
  }

  @override
  String get notificationsRefreshAgenda => 'Agenda aktualisieren';

  @override
  String get notificationsDismiss => 'Verwerfen';

  @override
  String get authCompletingSignIn => 'Anmeldung wird abgeschlossen…';

  @override
  String get authSignInFailed => 'Anmeldung konnte nicht abgeschlossen werden.';

  @override
  String get tourNowNextTitle => 'Was läuft gerade';

  @override
  String get tourNowNextBody =>
      'Deine Event-Uhr — was jetzt läuft und was als nächstes kommt.';

  @override
  String get tourDiscoverTitle => 'Sitzungen suchen';

  @override
  String get tourDiscoverBody =>
      'Finde Vorträge nach Titel, Speaker oder Thema. Filter und Empfehlungen aktualisieren sich beim Tippen.';

  @override
  String get tourRecoReasonTitle => 'Warum wir das vorschlagen';

  @override
  String get tourRecoReasonBody =>
      'Jede Empfehlung zeigt ihre Begründung — keine Black Box.';

  @override
  String get tourSessionTitle => 'In Mein Plan speichern';

  @override
  String get tourSessionBody =>
      'Markiere Sitzungen, die du besuchen möchtest. Deine Liste bleibt auf diesem Gerät — getrennt von der Accelevents-Registrierung.';

  @override
  String get tourLogisticsTitle => 'Logistik öffnen';

  @override
  String get tourLogisticsBody =>
      'Ort, Laufzeiten und Campus-Aktionen findest du hier.';

  @override
  String get tourVenueMapTitle => 'Auf der Karte sehen';

  @override
  String get tourVenueMapBody =>
      'Tippe auf Karte, um diesen Raum auf dem Campus zu sehen.';

  @override
  String get tourCompanionTitle => 'Flo fragen';

  @override
  String get tourCompanionBody =>
      'Sitzungen, Toiletten, Parken, Konflikte — probiere \'Where can I park my car?\'';

  @override
  String get tourMyPlanTitle => 'Deine Liste';

  @override
  String get tourMyPlanBody =>
      'Überprüfe gespeicherte Sitzungen, exportiere deinen Plan und erkenne Terminkonflikte vor dem Raumwechsel.';

  @override
  String get tourNext => 'Weiter';

  @override
  String get tourBack => 'Zurück';

  @override
  String get tourSkip => 'Tour überspringen';

  @override
  String get tourDone => 'Fertig';

  @override
  String get replayTour => 'Tour wiederholen';

  @override
  String tourStepOf(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get onboardingWelcomeTitle => 'Willkommen bei Flo Compass';

  @override
  String get onboardingEditTitle => 'Interessen aktualisieren';

  @override
  String get onboardingWelcomeBody =>
      'Flo 2026 im Nagarro Gurgaon Office — ~640 Sitzungen in 90 Räumen (Erdgeschoss + Etagen 6–13). Wir ergänzen Accelevents, indem wir dir helfen, das Wichtige zu wählen.';

  @override
  String get onboardingEditBody =>
      'Passe Rolle und Interessen an — Entdecken-Rankings aktualisieren sich nach dem Speichern.';

  @override
  String get onboardingRoleTitle => 'Deine Rolle';

  @override
  String get onboardingAttendanceTitle => 'Wie nimmst du teil?';

  @override
  String get onboardingAttendanceHint =>
      'Flo ergänzt Accelevents. Im Remote-Modus werden Wegbeschreibungen auf der Sitzungsdetailseite ausgeblendet und stream-freundliche Sitzungen hervorgehoben.';

  @override
  String get onboardingOnSite => 'Vor Ort in Gurgaon';

  @override
  String get onboardingRemote => 'Remote / Hub';

  @override
  String get onboardingInterestsTitle => 'Wähle 3–7 Interessen';

  @override
  String get onboardingInterestGroupAiData => 'KI & Daten';

  @override
  String get onboardingInterestGroupEngineering => 'Engineering';

  @override
  String get onboardingInterestGroupStrategy => 'Strategie';

  @override
  String get onboardingInterestGroupDomain => 'Domäne';

  @override
  String get onboardingInterestGroupCrossCutting => 'Querschnitt';

  @override
  String get onboardingSelectMin => 'Wähle mindestens 3 Interessen';

  @override
  String onboardingContinue(int count) {
    return 'Weiter ($count/7)';
  }

  @override
  String onboardingSave(int count) {
    return 'Änderungen speichern ($count/7)';
  }

  @override
  String onboardingRoleSemantic(String label) {
    return 'Rolle $label';
  }

  @override
  String onboardingInterestSemantic(String label) {
    return 'Interesse $label';
  }

  @override
  String get onboardingAttendanceSemantic => 'Teilnahmemodus';

  @override
  String get profileAppearanceSection => 'Erscheinungsbild und Sprache';

  @override
  String get profileTheme => 'Design';

  @override
  String get profileThemeSubtitle => 'System folgen oder überschreiben.';

  @override
  String get profileThemeSystem => 'System';

  @override
  String get profileThemeLight => 'Hell';

  @override
  String get profileThemeDark => 'Dunkel';

  @override
  String get profileThemeHighContrast => 'Hoher Kontrast';

  @override
  String get profileDyslexiaFont => 'Legasthenie-freundliche Schrift';

  @override
  String get profileDyslexiaFontSubtitle =>
      'OpenDyslexic (OFL) · ~120 KB zusätzlicher Download';

  @override
  String get profilePlainEnglish => 'Einfache Zusammenfassungen';

  @override
  String get profilePlainEnglishSubtitle =>
      'Kurze regelbasierte Sitzungszusammenfassungen auf Entdecken-Karten';

  @override
  String get profileEventExperienceSection => 'Event-Erlebnis';

  @override
  String get profileAttendanceMode => 'Teilnahmemodus';

  @override
  String get profileAttendanceModeSubtitle => 'Vor Ort oder Remote.';

  @override
  String get profileAttendanceOnSite => 'Vor Ort';

  @override
  String get profileAttendanceRemote => 'Remote';

  @override
  String get profileEventDayMode => 'Event-Tag-Modus';

  @override
  String get profileEventDayModeSubtitle =>
      'Auto, Ein oder Aus für die Jetzt/Als-Nächstes-Leiste.';

  @override
  String get profileEventDayAuto => 'Auto';

  @override
  String get profileEventDayOn => 'Ein';

  @override
  String get profileEventDayOff => 'Aus';

  @override
  String get profileLowBandwidth => 'Niedrige Bandbreite';

  @override
  String get profileLowBandwidthSubtitle =>
      'Kleinere Bilder, keine Tipp-Animation, nur Listen in Entdecken.';

  @override
  String get profileNotificationsSection => 'Benachrichtigungen';

  @override
  String get profileAgendaChangeAlerts => 'Agenda-Änderungsbenachrichtigungen';

  @override
  String get profileAgendaChangeAlertsSubtitle =>
      'In-App-Hinweise für Sitzungen in Mein Plan oder von gefolgten Speakern.';

  @override
  String get profileAgendaChangeAlertsDisabledSnack =>
      'Agenda-Änderungsbenachrichtigungen sind aus. Hier wieder aktivieren für Raum-, Zeit- oder Absage-Updates.';

  @override
  String get profileAgendaChangePush => 'Agenda-Änderungs-Push';

  @override
  String get profileAgendaChangePushSubtitle =>
      'Demnächst — Browser-Push für Agenda-Updates.';

  @override
  String get profileLeaveNowReminders => 'Jetzt-los-Erinnerungen';

  @override
  String get profileLeaveNowReminderUnsupported =>
      'In diesem Browser nicht unterstützt (z. B. iPhone Safari). In-App-Erinnerungen funktionieren weiterhin.';

  @override
  String get profileLeaveNowReminderDenied =>
      'In den Browser-Einstellungen aktivieren, um Laufzeit-Hinweise mit 5 Min. Puffer zu erhalten.';

  @override
  String get profileLeaveNowReminderEnabled =>
      'Laufzeit plus 5 Min. Puffer vor geplanten Sitzungen.';

  @override
  String get profileNotificationPermissionDeniedSnack =>
      'Benachrichtigungsberechtigung wurde nicht erteilt.';

  @override
  String get profileEnableBusinessCard => 'Visitenkarte aktivieren';

  @override
  String get profileDemoAccessTitle => 'Demo-Zugang';

  @override
  String get profileDemoAccessBody =>
      'Wähle einen Mock-Benutzer, um Organisator- oder Admin-Tools zu testen.';

  @override
  String profileDemoPlatformAccess(String label, String organizationLabel) {
    return 'Plattformzugang: $label$organizationLabel';
  }

  @override
  String get profileOpenOrganizerTab => 'Organisator-Tab öffnen';

  @override
  String get profileOpenAdminTab => 'Admin-Tab öffnen';

  @override
  String get profileSwitchUser => 'Benutzer wechseln';

  @override
  String get sessionLeaveNow => 'Jetzt los';

  @override
  String get sessionAddToMyPlan => 'Zu Mein Plan hinzufügen';

  @override
  String get sessionAddToPlan => 'Zum Plan hinzufügen';

  @override
  String get sessionJoinStream => 'Stream beitreten';

  @override
  String get sessionMarkAsAttended => 'Als besucht markieren';

  @override
  String get sessionMarkAttended => 'Besucht markieren';

  @override
  String get sessionInPlan => 'Im Plan';

  @override
  String get sessionAdded => 'Hinzugefügt';

  @override
  String get sessionAddToCalendar => 'Zum Kalender hinzufügen';

  @override
  String get sessionAddToCalendarTooltip => 'Zum Kalender hinzufügen';

  @override
  String get myPlanEmptyTitle => 'Deine Liste ist leer';

  @override
  String get myPlanEmptyMessage =>
      'Markiere Sitzungen in Entdecken. Dies ist ein lokaler Plan — nicht die offizielle Accelevents-Agenda.';

  @override
  String get myPlanBrowseSessions => 'Sitzungen durchsuchen';

  @override
  String get myPlanAskFloDay1 => 'Flo bitten, meinen Tag 1 zu planen';

  @override
  String get discoverEmptyFiltered =>
      'Keine Sitzungen entsprechen deinen Filtern';

  @override
  String get discoverEmptyFilteredHint =>
      'Versuche, Filter zu löschen oder Interessen zu erweitern.';

  @override
  String get discoverHappeningNow => 'Gerade live';

  @override
  String get discoverStartingSoon => 'Beginnt bald';

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
      'Flo Meets stores your meet nickname, amenity meet point, and optional contact locally. Update preferences anytime from Profile or Meets.';

  @override
  String get consentFloMeetsBullet => 'Flo Meets uses nickname-only reveal.';
}
