import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/core/auth/platform_role.dart';
import 'package:flo_compass/core/config/auth_config.dart';
import 'package:flo_compass/core/config/runtime_config.dart';
import 'package:flo_compass/core/routing/app_routes.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/l10n/app_localizations.dart';
import 'package:flo_compass/providers/announcement_provider.dart';
import 'package:flo_compass/providers/app_settings_provider.dart';
import 'package:flo_compass/providers/organizer_dashboard_provider.dart';
import 'package:flo_compass/providers/prompt_curation_provider.dart';
import 'package:flo_compass/providers/auth_provider.dart';
import 'package:flo_compass/providers/engagement_provider.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/flo_meets_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/providers/profile_provider.dart';
import 'package:flo_compass/routing/app_router.dart';
import '../support/test_agenda_alerts_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthConfig originalAuth;
  late PlatformRole? originalOverride;
  late Set<String> originalOrganizerAllowlist;
  late Set<String> originalAdminAllowlist;

  setUp(() {
    originalAuth = RuntimeConfig.auth;
    originalOverride = RuntimeConfig.platformRoleOverride;
    originalOrganizerAllowlist = RuntimeConfig.organizerAllowlist;
    originalAdminAllowlist = RuntimeConfig.adminAllowlist;
    RuntimeConfig.auth = AuthConfig.disabled;
    RuntimeConfig.platformRoleOverride = null;
    RuntimeConfig.organizerAllowlist = <String>{};
    RuntimeConfig.adminAllowlist = <String>{};
  });

  tearDown(() {
    RuntimeConfig.auth = originalAuth;
    RuntimeConfig.platformRoleOverride = originalOverride;
    RuntimeConfig.organizerAllowlist = originalOrganizerAllowlist;
    RuntimeConfig.adminAllowlist = originalAdminAllowlist;
  });

  testWidgets('attendee gets redirected from organizer route', (tester) async {
    final setup = await _pumpRouter(tester, PlatformRole.attendee);
    addTearDown(setup.router.dispose);

    try {
      setup.router.go(AppRoutes.organizer);
      await tester.pumpAndSettle();
      expect(setup.router.state.matchedLocation, AppRoutes.profile);
    } finally {
      setup.event.dispose();
    }
  });

  testWidgets('organizer gets redirected from admin route', (tester) async {
    final setup = await _pumpRouter(tester, PlatformRole.organizer);
    addTearDown(setup.router.dispose);

    try {
      setup.router.go(AppRoutes.admin);
      await tester.pumpAndSettle();
      expect(setup.router.state.matchedLocation, AppRoutes.profile);
    } finally {
      setup.event.dispose();
    }
  });

  testWidgets('attendee gets redirected from organizer announcements route', (
    tester,
  ) async {
    final setup = await _pumpRouter(tester, PlatformRole.attendee);
    addTearDown(setup.router.dispose);

    try {
      setup.router.go(AppRoutes.organizerAnnouncements);
      await tester.pumpAndSettle();
      expect(setup.router.state.matchedLocation, AppRoutes.profile);
    } finally {
      setup.event.dispose();
    }
  });

  testWidgets('organizer can open organizer announcements route', (
    tester,
  ) async {
    final setup = await _pumpRouter(tester, PlatformRole.organizer);
    addTearDown(setup.router.dispose);

    try {
      setup.router.go(AppRoutes.organizerAnnouncements);
      await tester.pumpAndSettle();
      expect(
        setup.router.state.matchedLocation,
        AppRoutes.organizerAnnouncements,
      );
      expect(find.text('Announcements'), findsOneWidget);
    } finally {
      setup.event.dispose();
    }
  });
}

Future<({GoRouter router, EventState event})> _pumpRouter(
  WidgetTester tester,
  PlatformRole role,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final profile = ProfileState(prefs: prefs);
  final event = EventState()..loading = false;
  final plan = PlanState(prefs: prefs);
  final appSettings = AppSettingsState(prefs: prefs);
  final engagement = EngagementState(prefs: prefs);
  final auth = AuthState();
  RuntimeConfig.platformRoleOverride = role;

  await profile.init();
  profile.profile = const UserProfile(
    role: AttendeeRole.engineer,
    interests: [],
    onboardingComplete: true,
  );
  await plan.init();
  await appSettings.init();
  await engagement.init();
  await auth.init();

  final floMeets = FloMeetsState(prefs: prefs);
  await floMeets.init();

  final router = createAppRouter(profile, authState: auth);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: profile),
        ChangeNotifierProvider.value(value: event),
        ChangeNotifierProvider.value(value: plan),
        ChangeNotifierProvider.value(value: appSettings),
        testAgendaAlertsProvider(),
        ChangeNotifierProvider.value(value: engagement),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: floMeets),
        ChangeNotifierProvider(create: (_) => AnnouncementState()),
        ChangeNotifierProvider(create: (_) => PromptCurationState()),
        ChangeNotifierProvider(create: (_) => OrganizerDashboardState()),
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
  await tester.pumpAndSettle();
  return (router: router, event: event);
}
