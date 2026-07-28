import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/core/auth/mock_user.dart';
import 'package:flo_compass/core/auth/platform_role.dart';
import 'package:flo_compass/core/config/auth_config.dart';
import 'package:flo_compass/core/config/runtime_config.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/data/models/networking_card.dart';
import 'package:flo_compass/features/connect/business_card_preview.dart';
import 'package:flo_compass/features/onboarding/onboarding_screen.dart';
import 'package:flo_compass/features/profile/profile_screen.dart';
import 'package:flo_compass/l10n/app_localizations.dart';
import 'package:flo_compass/providers/app_settings_provider.dart';
import 'package:flo_compass/providers/auth_provider.dart';
import 'package:flo_compass/providers/engagement_provider.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/providers/flo_meets_provider.dart';
import 'package:flo_compass/providers/profile_provider.dart';
import 'package:flo_compass/providers/announcement_provider.dart';
import 'package:flo_compass/providers/organizer_dashboard_provider.dart';
import 'package:flo_compass/providers/ops_config_provider.dart';
import 'package:flo_compass/providers/companion_provider.dart';
import 'package:flo_compass/shared/tour/tour_controller.dart';
import '../../support/test_agenda_alerts_provider.dart';

TourController? profileTestTourController;

Finder profileVerticalScrollable() => find.byWidgetPredicate(
  (widget) =>
      widget is Scrollable && widget.axisDirection == AxisDirection.down,
);

Finder activeProfileScrollable({int preferredTabIndex = 0}) {
  final scrollables = profileVerticalScrollable();
  final count = scrollables.evaluate().length;
  if (count <= 1) return scrollables.first;
  if (preferredTabIndex < count) return scrollables.at(preferredTabIndex);
  return scrollables.last;
}

void enableMockLogin(List<MockUser> users) {
  RuntimeConfig.mockUsers = users;
  RuntimeConfig.mockLoginEnabledForTests = true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AuthConfig originalAuth;
  late PlatformRole? originalRoleOverride;
  late Set<String> originalOrganizerAllowlist;
  late Set<String> originalAdminAllowlist;
  late List<MockUser> originalMockUsers;
  late bool originalMockLoginEnabledForTests;

  const testMockUsers = [
    MockUser(
      id: 'kamlesh',
      name: 'Kamlesh Kumar',
      email: 'kamlesh.kumar@demo.flo-compass.example',
      organization: 'ai-avengers',
      role: PlatformRole.admin,
    ),
    MockUser(
      id: 'kishan',
      name: 'Kishan',
      email: 'kishan@demo.flo-compass.example',
      organization: 'ai-avengers',
      role: PlatformRole.organizer,
    ),
    MockUser(
      id: 'ashish',
      name: 'Ashish',
      email: 'ashish@demo.flo-compass.example',
      organization: 'ai-avengers',
      role: PlatformRole.attendee,
    ),
  ];

  setUp(() {
    originalAuth = RuntimeConfig.auth;
    originalRoleOverride = RuntimeConfig.platformRoleOverride;
    originalOrganizerAllowlist = RuntimeConfig.organizerAllowlist;
    originalAdminAllowlist = RuntimeConfig.adminAllowlist;
    originalMockUsers = RuntimeConfig.mockUsers;
    originalMockLoginEnabledForTests = RuntimeConfig.mockLoginEnabledForTests;
    RuntimeConfig.auth = AuthConfig.disabled;
    RuntimeConfig.platformRoleOverride = null;
    RuntimeConfig.organizerAllowlist = <String>{};
    RuntimeConfig.adminAllowlist = <String>{};
    RuntimeConfig.mockUsers = <MockUser>[];
    RuntimeConfig.mockLoginEnabledForTests = false;
  });

  tearDown(() {
    RuntimeConfig.auth = originalAuth;
    RuntimeConfig.platformRoleOverride = originalRoleOverride;
    RuntimeConfig.organizerAllowlist = originalOrganizerAllowlist;
    RuntimeConfig.adminAllowlist = originalAdminAllowlist;
    RuntimeConfig.mockUsers = originalMockUsers;
    RuntimeConfig.mockLoginEnabledForTests = originalMockLoginEnabledForTests;
  });

  Future<EventState> pumpProfile(
    WidgetTester tester, {
    bool onboardingComplete = false,
    List<MockUser>? mockUsers,
    NetworkingCard? networkingCard,
    String initialLocation = '/profile',
  }) async {
    final engagementSnapshot = EngagementSnapshot.empty.copyWith(
      achievements: ['bogus_legacy_id', 'keynote_hunter'],
    );
    final initialPrefs = <String, Object>{
      'flo_compass_engagement': jsonEncode(engagementSnapshot.toJson()),
    };
    if (onboardingComplete) {
      initialPrefs['flo_compass_profile'] = jsonEncode({
        'role': AttendeeRole.engineer.name,
        'interests': const ['ai'],
        'onboardingComplete': true,
        'firstName': '',
        'recommendationMode': RecommendationMode.balanced.name,
        'energyFilter': EnergyFilter.all.name,
        'followedSpeakerIds': <String>[],
        'attendanceMode': AttendanceMode.onSite.name,
      });
    }
    SharedPreferences.setMockInitialValues(initialPrefs);
    final prefs = await SharedPreferences.getInstance();

    final profile = ProfileState(prefs: prefs);
    final engagement = EngagementState(prefs: prefs);
    final plan = PlanState(prefs: prefs);
    final appSettings = AppSettingsState(prefs: prefs);
    final auth = AuthState();
    final event = EventState();
    final dashboard = OrganizerDashboardState();
    final announcements = AnnouncementState();
    final opsConfig = OpsConfigState(prefs: prefs);
    final companion = CompanionState();
    final floMeets = FloMeetsState(prefs: prefs);
    event.loading = false;

    await profile.init();
    if (onboardingComplete) {
      await profile.saveProfile(
        role: AttendeeRole.engineer,
        interests: const ['ai'],
        complete: true,
      );
    }
    if (networkingCard != null) {
      await profile.saveNetworkingCard(networkingCard);
    }
    if (mockUsers != null) {
      enableMockLogin(mockUsers);
    }
    await engagement.init();
    await plan.init();
    await appSettings.init();
    await auth.init();
    await opsConfig.init();
    await floMeets.init();

    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/discover',
          builder: (context, state) => const SizedBox(),
        ),
      ],
    );

    profileTestTourController = TourController(
      router: router,
      appSettings: appSettings,
      planState: plan,
      companionState: companion,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: profile),
          ChangeNotifierProvider.value(value: engagement),
          ChangeNotifierProvider.value(value: plan),
          ChangeNotifierProvider.value(value: appSettings),
          testAgendaAlertsProvider(),
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: event),
          ChangeNotifierProvider.value(value: dashboard),
          ChangeNotifierProvider.value(value: announcements),
          ChangeNotifierProvider.value(value: opsConfig),
          ChangeNotifierProvider.value(value: companion),
          ChangeNotifierProvider.value(value: floMeets),
          ChangeNotifierProvider.value(value: profileTestTourController),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    if (mockUsers != null) {
      enableMockLogin(mockUsers);
    }
    return event;
  }

  Future<void> tapProfileTab(WidgetTester tester, String label) async {
    final tab = find.descendant(
      of: find.byType(TabBar),
      matching: find.text(label),
    );
    await tester.ensureVisible(tab);
    await tester.tap(tab);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  Future<void> scrollProfileTabTo(
    WidgetTester tester, {
    required int tabIndex,
    required Finder finder,
  }) async {
    if (finder.evaluate().isEmpty) return;
    final scrollable = activeProfileScrollable(preferredTabIndex: tabIndex);
    if (scrollable.evaluate().isEmpty) return;
    await tester.scrollUntilVisible(finder, 200, scrollable: scrollable);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  Future<void> ensureOnScreen(
    WidgetTester tester,
    Finder finder, {
    int tabIndex = 0,
  }) async {
    if (finder.evaluate().isEmpty) return;
    final scrollable = activeProfileScrollable(preferredTabIndex: tabIndex);
    if (scrollable.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(finder, 200, scrollable: scrollable);
    } else {
      await tester.ensureVisible(finder.first);
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  Future<void> tapMockSignIn(WidgetTester tester) async {
    await ensureOnScreen(tester, find.text('Sign in'), tabIndex: 0);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders Profile title with bogus achievement id in prefs', (
    tester,
  ) async {
    final event = await pumpProfile(tester);

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Keynote Hunter'), findsNothing);

    await tapProfileTab(tester, 'Progress');

    expect(find.text('Engagement'), findsOneWidget);
    await scrollProfileTabTo(
      tester,
      tabIndex: 1,
      finder: find.text('Keynote Hunter'),
    );
    expect(find.text('Keynote Hunter'), findsOneWidget);
    expect(find.text('bogus_legacy_id'), findsNothing);
    expect(find.textContaining('Session Bingo'), findsOneWidget);
    expect(find.text('Engagement'), findsOneWidget);
    expect(find.text('Attendance streaks'), findsOneWidget);
    expect(find.text('Track passport'), findsOneWidget);
    expect(find.text('Event tools'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('Share PNG'), findsOneWidget);

    event.dispose();
  });

  testWidgets('tab=progress selects Progress tab via query param', (
    tester,
  ) async {
    final event = await pumpProfile(
      tester,
      initialLocation: '/profile?tab=progress',
    );

    expect(find.text('Attendance streaks'), findsOneWidget);
    expect(find.text('Engagement'), findsOneWidget);

    event.dispose();
  });

  testWidgets(
    'Progress tab shows achievements empty state when none unlocked',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final profile = ProfileState(prefs: prefs);
      final engagement = EngagementState(prefs: prefs);
      final plan = PlanState(prefs: prefs);
      final appSettings = AppSettingsState(prefs: prefs);
      final auth = AuthState();
      final event = EventState();
      final dashboard = OrganizerDashboardState();
      final announcements = AnnouncementState();
      final opsConfig = OpsConfigState(prefs: prefs);
      final floMeets = FloMeetsState(prefs: prefs);
      event.loading = false;

      await profile.init();
      await engagement.init();
      await plan.init();
      await appSettings.init();
      await auth.init();
      await opsConfig.init();
      await floMeets.init();

      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: profile),
            ChangeNotifierProvider.value(value: engagement),
            ChangeNotifierProvider.value(value: plan),
            ChangeNotifierProvider.value(value: appSettings),
            testAgendaAlertsProvider(),
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider.value(value: event),
            ChangeNotifierProvider.value(value: dashboard),
            ChangeNotifierProvider.value(value: announcements),
            ChangeNotifierProvider.value(value: opsConfig),
            ChangeNotifierProvider.value(value: floMeets),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tapProfileTab(tester, 'Progress');

      expect(find.text('Achievements'), findsOneWidget);
      await scrollProfileTabTo(
        tester,
        tabIndex: 1,
        finder: find.textContaining(
          'Complete sessions, quests, and event tools',
        ),
      );
      expect(
        find.textContaining('Complete sessions, quests, and event tools'),
        findsOneWidget,
      );
      expect(find.text('Share PNG'), findsNothing);

      event.dispose();
    },
  );

  testWidgets('leave-now toggle shows unsupported copy on stub platform', (
    tester,
  ) async {
    final event = await pumpProfile(tester);
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Not supported in this browser'),
      findsOneWidget,
    );

    event.dispose();
  });

  testWidgets('Reset progress shows confirmation dialog', (tester) async {
    final event = await pumpProfile(tester);
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    final verticalScrollable = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    );
    await tester.scrollUntilVisible(
      find.text('Advanced'),
      100,
      scrollable: verticalScrollable.first,
    );
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Reset progress'),
      100,
      scrollable: verticalScrollable.first,
    );
    await tester.tap(find.text('Reset progress'));
    await tester.pumpAndSettle();

    expect(find.text('Reset progress?'), findsOneWidget);
    expect(
      find.textContaining(
        'Clears XP, achievements, streaks, and bingo progress',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Reset progress?'), findsNothing);

    event.dispose();
  });

  testWidgets('operations tabs hidden for attendee role', (tester) async {
    RuntimeConfig.platformRoleOverride = PlatformRole.attendee;
    final event = await pumpProfile(tester);

    expect(find.text('Organizer'), findsNothing);
    expect(find.text('Admin'), findsNothing);

    event.dispose();
  });

  testWidgets('organizer role shows Organizer tab only', (tester) async {
    RuntimeConfig.platformRoleOverride = PlatformRole.organizer;
    final event = await pumpProfile(tester);

    expect(find.text('Organizer'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);

    event.dispose();
  });

  testWidgets('wide layout renders Advanced in section card', (tester) async {
    final event = await pumpProfile(tester);
    await tester.binding.setSurfaceSize(const Size(1024, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();

    expect(find.text('Advanced'), findsWidgets);
    expect(find.byType(Card), findsWidgets);
    expect(find.text('Reset progress'), findsOneWidget);
    expect(find.text('Danger zone'), findsOneWidget);

    event.dispose();
  });

  testWidgets('admin role shows Organizer and Admin tabs', (tester) async {
    RuntimeConfig.platformRoleOverride = PlatformRole.admin;
    final event = await pumpProfile(tester);

    expect(find.text('Organizer'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);

    event.dispose();
  });

  testWidgets(
    'You tab sections appear in Personalization, Networking, Demo order',
    (tester) async {
      final event = await pumpProfile(
        tester,
        onboardingComplete: true,
        mockUsers: testMockUsers,
      );

      final personalization = find.text('Personalization');
      final networking = find.text('Networking');
      final demoSignIn = find.text('Demo access');

      expect(personalization, findsOneWidget);
      expect(networking, findsOneWidget);
      await ensureOnScreen(tester, demoSignIn, tabIndex: 0);
      expect(demoSignIn, findsOneWidget);
      expect(
        tester.getTopLeft(personalization).dy,
        lessThan(tester.getTopLeft(networking).dy),
      );
      expect(
        tester.getTopLeft(networking).dy,
        lessThan(tester.getTopLeft(demoSignIn).dy),
      );

      event.dispose();
    },
  );

  testWidgets('You tab hides shared_preferences jargon', (tester) async {
    final event = await pumpProfile(tester, onboardingComplete: true);

    expect(find.textContaining('shared_preferences'), findsNothing);

    event.dispose();
  });

  testWidgets('Edit profile opens onboarding edit mode', (tester) async {
    final event = await pumpProfile(tester, onboardingComplete: true);

    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();

    expect(find.text('Update your interests'), findsOneWidget);

    event.dispose();
  });

  testWidgets('You tab shows networking card preview when enabled', (
    tester,
  ) async {
    final event = await pumpProfile(
      tester,
      onboardingComplete: true,
      networkingCard: const NetworkingCard(
        enabled: true,
        displayName: 'Jordan Lee',
        email: ShareField(value: 'jordan@example.com', visible: true),
      ),
    );

    expect(find.byType(BusinessCardPreview), findsOneWidget);
    expect(find.text('My QR card'), findsOneWidget);
    expect(find.text('Edit card'), findsOneWidget);

    event.dispose();
  });

  testWidgets('You tab shows business card off helper when card disabled', (
    tester,
  ) async {
    final event = await pumpProfile(
      tester,
      onboardingComplete: true,
      networkingCard: const NetworkingCard(enabled: false),
    );

    expect(find.textContaining('Business card is off'), findsOneWidget);
    expect(find.byType(BusinessCardPreview), findsNothing);
    expect(find.text('Enable business card'), findsOneWidget);

    event.dispose();
  });

  testWidgets('enabling business card from You tab persists via ProfileState', (
    tester,
  ) async {
    final event = await pumpProfile(
      tester,
      onboardingComplete: true,
      networkingCard: const NetworkingCard(enabled: false),
    );

    final profileState = Provider.of<ProfileState>(
      tester.element(find.byType(ProfileScreen)),
      listen: false,
    );
    expect(profileState.profile.networkingCard?.enabled, isFalse);

    await ensureOnScreen(
      tester,
      find.text('Enable business card'),
      tabIndex: 0,
    );
    await tester.tap(find.text('Enable business card'));
    await tester.pumpAndSettle();

    expect(profileState.profile.networkingCard?.enabled, isTrue);

    event.dispose();
  });

  testWidgets('My QR card shows snackbar when card is off', (tester) async {
    final event = await pumpProfile(
      tester,
      onboardingComplete: true,
      networkingCard: const NetworkingCard(enabled: false),
    );

    await ensureOnScreen(tester, find.text('My QR card'), tabIndex: 0);
    await tester.tap(find.text('My QR card'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('Finish your card in Edit card before sharing your QR.'),
      findsOneWidget,
    );

    event.dispose();
  });

  testWidgets('mock admin login ops shortcuts switch Profile tabs', (
    tester,
  ) async {
    final event = await pumpProfile(
      tester,
      onboardingComplete: true,
      mockUsers: testMockUsers,
    );

    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tapMockSignIn(tester);
    await tester.tap(find.text('Kamlesh Kumar'));
    await tester.pumpAndSettle();
    enableMockLogin(testMockUsers);

    expect(find.text('Open Organizer tab'), findsOneWidget);
    expect(find.text('Open Admin tab'), findsOneWidget);
    expect(find.textContaining('Platform access:'), findsOneWidget);

    await ensureOnScreen(tester, find.text('Open Organizer tab'), tabIndex: 0);
    await tester.tap(find.text('Open Organizer tab'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('Flo Compass organizer tools'), findsOneWidget);

    await tapProfileTab(tester, 'You');
    await ensureOnScreen(tester, find.text('Open Admin tab'), tabIndex: 0);
    await tester.tap(find.text('Open Admin tab'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    await scrollProfileTabTo(
      tester,
      tabIndex: 4,
      finder: find.text('Feature flags'),
    );
    expect(find.text('Feature flags'), findsOneWidget);

    event.dispose();
  });

  testWidgets('mock login card hidden before onboarding completes', (
    tester,
  ) async {
    final event = await pumpProfile(tester, mockUsers: testMockUsers);

    expect(find.text('Demo access'), findsNothing);

    event.dispose();
  });

  testWidgets('mock login card shows after onboarding completes', (
    tester,
  ) async {
    final event = await pumpProfile(
      tester,
      onboardingComplete: true,
      mockUsers: testMockUsers,
    );

    await ensureOnScreen(tester, find.text('Demo access'), tabIndex: 0);
    expect(find.text('Demo access'), findsOneWidget);
    await ensureOnScreen(tester, find.text('Sign in'), tabIndex: 0);
    expect(find.text('Sign in'), findsOneWidget);

    event.dispose();
  });

  testWidgets('mock admin login reveals Organizer and Admin tabs', (
    tester,
  ) async {
    final event = await pumpProfile(
      tester,
      onboardingComplete: true,
      mockUsers: testMockUsers,
    );

    await tapMockSignIn(tester);
    await tester.tap(find.text('Kamlesh Kumar'));
    await tester.pumpAndSettle();

    expect(find.text('Signed in as Kamlesh Kumar'), findsOneWidget);
    expect(find.text('kamlesh.kumar@demo.flo-compass.example'), findsOneWidget);
    expect(find.text('Organizer'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);

    event.dispose();
  });

  testWidgets('You tab mock sign-in reachable on narrow viewport', (
    tester,
  ) async {
    final event = await pumpProfile(
      tester,
      onboardingComplete: true,
      mockUsers: testMockUsers,
    );
    await tester.binding.setSurfaceSize(const Size(400, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final signIn = find.text('Sign in');
    await scrollProfileTabTo(tester, tabIndex: 0, finder: signIn);
    await tester.ensureVisible(signIn);
    expect(signIn, findsOneWidget);

    event.dispose();
  });

  testWidgets('mock logout hides operations tabs', (tester) async {
    final event = await pumpProfile(
      tester,
      onboardingComplete: true,
      mockUsers: testMockUsers,
    );
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tapMockSignIn(tester);
    await tester.tap(find.text('Kishan'));
    await tester.pumpAndSettle();

    expect(find.text('Organizer'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);

    await ensureOnScreen(tester, find.text('Sign out'));
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Organizer'), findsNothing);
    expect(find.text('Admin'), findsNothing);

    event.dispose();
  });

  testWidgets('profile menu includes replay tour action', (tester) async {
    final event = await pumpProfile(tester, onboardingComplete: true);

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();

    expect(find.text('Replay tour'), findsOneWidget);

    // Capture whether tour.active flipped to true at any point during the
    // tap-and-settle window. The null-target auto-skip guard in
    // TourController can walk the tour to completion during pumpAndSettle
    // when the profile test's router doesn't mount tour anchors, so the
    // pre-tap listener is the reliable way to verify the tour actually
    // started.
    var tourWentActive = false;
    void listener() {
      if (profileTestTourController?.active == true) tourWentActive = true;
    }

    profileTestTourController?.addListener(listener);
    await tester.tap(find.text('Replay tour'));
    await tester.pumpAndSettle();
    profileTestTourController?.removeListener(listener);

    expect(tourWentActive, isTrue);

    event.dispose();
  });

  testWidgets('advanced settings includes replay tour button', (tester) async {
    final event = await pumpProfile(tester);
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    final verticalScrollable = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    );
    await tester.scrollUntilVisible(
      find.text('Advanced'),
      100,
      scrollable: verticalScrollable.first,
    );
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Replay tour'),
      100,
      scrollable: verticalScrollable.first,
    );
    expect(find.text('Replay tour'), findsOneWidget);

    // Capture whether tour.active flipped to true at any point during the
    // tap-and-settle window (see profile-menu variant above for rationale).
    var tourWentActive = false;
    void listener() {
      if (profileTestTourController?.active == true) tourWentActive = true;
    }

    profileTestTourController?.addListener(listener);
    await tester.tap(find.text('Replay tour'));
    await tester.pumpAndSettle();
    profileTestTourController?.removeListener(listener);

    expect(tourWentActive, isTrue);

    event.dispose();
  });
}
