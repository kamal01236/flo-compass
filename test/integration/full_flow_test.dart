import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/features/shell/main_shell.dart';
import 'package:flo_compass/providers/app_settings_provider.dart';
import 'package:flo_compass/providers/engagement_provider.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/providers/profile_provider.dart';
import 'package:flo_compass/routing/app_router.dart';
import '../support/consent_test_helpers.dart';
import '../support/test_agenda_alerts_provider.dart';
import '../support/test_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boot shows discover shell when consent accepted', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final profile = ProfileState(prefs: prefs);
    profile.profile = const UserProfile(
      role: AttendeeRole.engineer,
      interests: ['genai'],
      onboardingComplete: true,
    );

    final event = EventState();
    event.loading = false;
    final plan = PlanState(prefs: prefs);
    await plan.init();
    final engagement = EngagementState(prefs: prefs);
    await engagement.init();
    final appSettings = AppSettingsState(prefs: prefs);
    await appSettings.init();
    final consent = await acceptedConsentState();

    final router = createAppRouter(profile, consentState: consent);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: event),
          ChangeNotifierProvider.value(value: profile),
          ChangeNotifierProvider.value(value: plan),
          ChangeNotifierProvider.value(value: engagement),
          ChangeNotifierProvider.value(value: appSettings),
          testAgendaAlertsProvider(),
          ChangeNotifierProvider.value(value: consent),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: testLocalizationDelegates,
          supportedLocales: testSupportedLocales,
        ),
      ),
    );
    router.go('/discover');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    event.dispose();
    router.dispose();
  });
}
