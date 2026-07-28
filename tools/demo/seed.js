// seed.js — injected via Playwright addInitScript before Flutter boots (v3).
//
// shared_preferences_web:2.4.3 encoding rules (verified against
// lib/providers/*_provider.dart):
//   - setString(key, jsonEncode(map))  -> localStorage[flutter.<key>] is a
//     JSON string wrapping the already-JSON-encoded map (DOUBLE encoded).
//   - setStringList(key, list)         -> localStorage[flutter.<key>] is a
//     single JSON.stringify(list) (SINGLE encoded).
//   - setBool / setInt                 -> single JSON encode of the value.
//
// The seed below matches those contracts so:
//   * consent + profile skip the redirect chain,
//   * onboarding is complete (no /onboarding gate),
//   * the product tour has been seen (no overlay),
//   * My Plan has 3 bookmarked sessions (2 overlap for the conflict card),
//   * private session notes render in My Plan and Session Detail,
//   * Connect edit + share show a filled sample business card,
//   * Discover shows a live PublishedAnnouncementBanner.
//
// Storage-key references (line numbers accurate at v3 authoring):
//   flo_compass_plan          -> lib/providers/plan_provider.dart L25, L152
//                                (setStringList, single JSON)
//   flo_compass_engagement    -> lib/providers/engagement_provider.dart L25, L414
//                                (setString(jsonEncode(...)), double JSON)
//   flo_compass_profile       -> lib/providers/profile_provider.dart L75-78
//                                (setString(jsonEncode(...)), double JSON)
//   flo_organizer_announcements -> lib/data/repositories/mock_announcement_repository.dart L12, L108
//                                (setString(jsonEncode(list)), double JSON)
(() => {
  // -------- (1) NetworkingCard nested inside PROFILE -----------------------
  // Shape from lib/data/models/networking_card.dart L89-101 (toJson).
  const NETWORKING_CARD = {
    enabled: true,
    displayName: 'Demo Attendee',
    jobTitle: 'Senior Engineer',
    company: 'Nagarro',
    email:       { value: 'demo.attendee@example.com',            visible: true },
    phoneE164:   { value: '+919999900000',                         visible: false },
    linkedInUrl: { value: 'https://linkedin.com/in/demo-attendee', visible: true },
    facebookUrl: { value: '',                                      visible: false },
    whatsApp:    { value: '',                                      visible: false },
    showRole: true,
    showTopInterests: true,
  };

  const PROFILE = {
    role: 'engineer',
    interests: ['genai', 'cursor', 'leadership'],
    onboardingComplete: true,
    firstName: 'Demo',
    recommendationMode: 'balanced',
    energyFilter: 'all',
    followedSpeakerIds: [],
    attendanceMode: 'onSite',
    networkingCard: NETWORKING_CARD,
  };

  const APP_SETTINGS = {
    themeMode: 'dark',
    eventDayMode: 'auto',
    lowBandwidth: false,
    leaveNowPushEnabled: false,
    agendaChangeAlertsEnabled: true,
    agendaChangePushEnabled: false,
    useDyslexiaFont: false,
    showPlainEnglishCards: false,
    leaderboardOptIn: false,
    shellTabsVisited: [0, 1, 2, 3],
    tourLastSeenVersion: 1,
    tourAutoStartPending: false,
  };

  // -------- (2) My Plan bookmarks (fixes v2 wrong key) ---------------------
  // s-001: Day 1 09:00-10:00 ven-G01 Chairman's Ignite
  // s-011: Day 1 09:00-10:00 ven-T601 Innovation at Enterprise Scale
  //        --> overlaps with s-001 so ConflictCard renders
  // s-025: Day 1 10:00-11:00 ven-9N5 Launch scorecard (no conflict)
  const PLAN_SESSION_IDS = ['s-001', 's-011', 's-025'];

  // -------- (3) Private session notes (feeds MyPlanNotesSection + detail) --
  // Shape from lib/data/models/engagement_snapshot.dart toJson().
  const ENGAGEMENT = {
    xp: 120,
    streakDays: ['2026-11-04'],
    achievements: [],
    attendedSessionIds: [],
    ratings: {},
    bingoMarks: [],
    companionQuestions: 2,
    detailViews: 5,
    reactions: {},
    pulseBySessionId: {},
    notesBySessionId: {
      's-001': "Ask about Plan Mode for large refactors. Follow up with Kirti after.",
      's-025': 'Slot this into our GenAI adoption roadmap for Q1.',
    },
    questProgress: {},
    lastQuestDay: null,
    completedQuestIds: [],
    visitedFloors: [],
    bingoRowBonuses: [],
    todayTracksViewed: [],
    todayBookmarksBeforeNoon: 0,
  };

  // -------- (4) Published organizer announcement (Discover banner) ---------
  // Shape from lib/domain/entities/organizer_announcement.dart L78-92 (toJson).
  const now = Date.now();
  const ANNOUNCEMENTS = [
    {
      id: 'demo-ann-1',
      title: 'Keynote moved to Reception Hall',
      body: 'CEO fireside now in the Reception and Welcome Hall on the ground floor.',
      status: 'published',
      createdAt: new Date(now - 15 * 60 * 1000).toISOString(),
      publishedAt: new Date(now - 5 * 60 * 1000).toISOString(),
      updatedAt: new Date(now - 5 * 60 * 1000).toISOString(),
    },
  ];

  // -------- writer helpers --------------------------------------------------
  const setPrefRaw = (key, encodedValue) => {
    try {
      // setString / setStringList / setBool all wrap the value once more
      // via JSON.stringify at the plugin layer.
      window.localStorage.setItem('flutter.' + key, JSON.stringify(encodedValue));
    } catch (err) {
      console.warn('[seed] failed to set', key, err);
    }
  };

  // For setString(key, jsonEncode(obj)) the plugin sees a string, so we hand
  // it a pre-encoded JSON string and let setPrefRaw wrap it again (double).
  const setPrefDoubleJson = (key, obj) => setPrefRaw(key, JSON.stringify(obj));
  // For setStringList and primitive types the plugin single-encodes.
  const setPrefValue = (key, value) => setPrefRaw(key, value);

  // Consent
  setPrefValue('flo_consent_version', '2026-07-11');
  setPrefValue('flo_consent_accepted_at', now);

  // Profile + app settings (double-encoded because Dart calls jsonEncode first)
  setPrefDoubleJson('flo_compass_profile', PROFILE);
  setPrefDoubleJson('flo_compass_app_settings', APP_SETTINGS);

  // Bookmarks (single-encoded via setStringList)
  setPrefValue('flo_compass_plan', PLAN_SESSION_IDS);

  // Engagement snapshot including notesBySessionId (double-encoded)
  setPrefDoubleJson('flo_compass_engagement', ENGAGEMENT);

  // Organizer announcements (double-encoded list)
  setPrefDoubleJson('flo_organizer_announcements', ANNOUNCEMENTS);

  // Legacy tour sentinel; harmless if the app ignores it.
  setPrefValue('flo_tour_seen_v1', true);

  console.info(
    '[seed] Flo Compass demo state injected:',
    'plan=' + PLAN_SESSION_IDS.length,
    'notes=' + Object.keys(ENGAGEMENT.notesBySessionId).length,
    'announcements=' + ANNOUNCEMENTS.length,
    'networkingCard=' + NETWORKING_CARD.enabled,
  );
})();
