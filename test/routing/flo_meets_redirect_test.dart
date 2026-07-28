import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flo_compass/core/auth/mock_user.dart';
import 'package:flo_compass/core/auth/platform_role.dart';
import 'package:flo_compass/core/routing/app_routes.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/features/flo_meets/flo_meets_hub_screen.dart';
import 'package:flo_compass/features/flo_meets/flo_meets_preferences_screen.dart';
import 'package:flo_compass/features/flo_meets/flo_meets_sign_in_gate.dart';
import 'package:flo_compass/providers/app_settings_provider.dart';
import 'package:flo_compass/providers/auth_provider.dart';
import 'package:flo_compass/providers/engagement_provider.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/flo_meets_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/providers/profile_provider.dart';
import 'package:flo_compass/routing/app_router.dart';
import '../support/consent_test_helpers.dart';
import '../support/test_agenda_alerts_provider.dart';
import '../support/test_flo_meets_helpers.dart';
import '../support/test_localizations.dart';

const _mockAttendee = MockUser(
  id: 'mock-attendee',
  name: 'Test Attendee',
  email: 'attendee@example.com',
  organization: 'Nagarro',
  role: PlatformRole.attendee,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('unauthenticated /meets stays on meets with sign-in gate', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final consent = await acceptedConsentState();
    final profile = ProfileState(prefs: prefs);
    profile.profile = const UserProfile(
      role: AttendeeRole.engineer,
      interests: ['genai', 'cloud', 'cursor'],
      onboardingComplete: true,
    );
    final auth = AuthState();
    await auth.init();
    final floMeets = FloMeetsState(prefs: prefs, enableDemoSeed: false);
    await floMeets.init();
    final event = EventState()..loading = false;
    final plan = PlanState(prefs: prefs);
    final appSettings = AppSettingsState(prefs: prefs);
    final engagement = EngagementState(prefs: prefs);
    await plan.init();
    await appSettings.init();
    await engagement.init();

    final router = createAppRouter(
      profile,
      consentState: consent,
      authState: auth,
      floMeetsState: floMeets,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: profile),
          ChangeNotifierProvider.value(value: consent),
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: floMeets),
          ChangeNotifierProvider.value(value: event),
          ChangeNotifierProvider.value(value: plan),
          ChangeNotifierProvider.value(value: appSettings),
          testAgendaAlertsProvider(),
          ChangeNotifierProvider.value(value: engagement),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: testLocalizationDelegates,
          supportedLocales: testSupportedLocales,
        ),
      ),
    );

    router.go(AppRoutes.floMeetsRoot);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(FloMeetsHubScreen), findsOneWidget);
    expect(find.byType(FloMeetsSignInGate), findsOneWidget);
    expect(router.state.matchedLocation, AppRoutes.floMeetsRoot);
    expect(router.state.matchedLocation.startsWith(AppRoutes.profile), isFalse);

    event.dispose();
  });

  testWidgets('legacy onboarding flo-meets edit redirects to preferences', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final consent = await acceptedConsentState();
    final profile = ProfileState(prefs: prefs);
    profile.profile = const UserProfile(
      role: AttendeeRole.engineer,
      interests: ['genai', 'cloud', 'cursor'],
      onboardingComplete: true,
    );
    final auth = AuthState();
    await auth.init();
    await auth.signInMock(_mockAttendee);
    final floMeets = FloMeetsState(prefs: prefs, enableDemoSeed: false);
    await floMeets.init();
    await floMeets.bindAuthSubject(_mockAttendee.id);
    final event = EventState()..loading = false;
    final plan = PlanState(prefs: prefs);
    final appSettings = AppSettingsState(prefs: prefs);
    final engagement = EngagementState(prefs: prefs);
    await plan.init();
    await appSettings.init();
    await engagement.init();

    final router = createAppRouter(
      profile,
      consentState: consent,
      authState: auth,
      floMeetsState: floMeets,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: profile),
          ChangeNotifierProvider.value(value: consent),
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: floMeets),
          ChangeNotifierProvider.value(value: event),
          ChangeNotifierProvider.value(value: plan),
          ChangeNotifierProvider.value(value: appSettings),
          testAgendaAlertsProvider(),
          ChangeNotifierProvider.value(value: engagement),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: testLocalizationDelegates,
          supportedLocales: testSupportedLocales,
        ),
      ),
    );

    router.go('${AppRoutes.onboarding}?step=flo-meets&edit=1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(router.state.matchedLocation, AppRoutes.floMeetsPreferences);
    // Avoid pumping taxonomy/amenities UI (dropdown overflow in default test viewport).
    expect(find.byType(FloMeetsPreferencesScreen), findsOneWidget);

    event.dispose();
  });

  testWidgets('incomplete setup redirects /meets to preferences', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final consent = await acceptedConsentState();
    final profile = ProfileState(prefs: prefs);
    profile.profile = const UserProfile(
      role: AttendeeRole.engineer,
      interests: ['genai', 'cloud', 'cursor'],
      onboardingComplete: true,
    );
    final auth = AuthState();
    await auth.init();
    await auth.signInMock(_mockAttendee);
    final floMeets = FloMeetsState(prefs: prefs, enableDemoSeed: false);
    await floMeets.init();
    await floMeets.bindAuthSubject(_mockAttendee.id);
    expect(floMeets.preferences.isSetupComplete, isFalse);

    final event = EventState()..loading = false;
    final plan = PlanState(prefs: prefs);
    final appSettings = AppSettingsState(prefs: prefs);
    final engagement = EngagementState(prefs: prefs);
    await plan.init();
    await appSettings.init();
    await engagement.init();

    final router = createAppRouter(
      profile,
      consentState: consent,
      authState: auth,
      floMeetsState: floMeets,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: profile),
          ChangeNotifierProvider.value(value: consent),
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: floMeets),
          ChangeNotifierProvider.value(value: event),
          ChangeNotifierProvider.value(value: plan),
          ChangeNotifierProvider.value(value: appSettings),
          testAgendaAlertsProvider(),
          ChangeNotifierProvider.value(value: engagement),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: testLocalizationDelegates,
          supportedLocales: testSupportedLocales,
        ),
      ),
    );

    router.go(AppRoutes.floMeetsRoot);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(router.state.matchedLocation, AppRoutes.floMeetsPreferences);
    expect(find.byType(FloMeetsHubScreen), findsNothing);

    await floMeets.savePreferences(
      buildValidFloMeetsPreferences(enabledSlots: const ['Day_1_0900']),
    );
    router.go(AppRoutes.floMeetsRoot);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(router.state.matchedLocation, AppRoutes.floMeetsRoot);
    expect(find.byType(FloMeetsHubScreen), findsOneWidget);

    event.dispose();
  });
}
