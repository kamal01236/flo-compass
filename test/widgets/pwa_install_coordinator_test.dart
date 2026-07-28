import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/providers/app_settings_provider.dart';
import 'package:flo_compass/providers/profile_provider.dart';
import 'package:flo_compass/routing/app_router.dart';
import '../support/consent_test_helpers.dart';
import '../support/test_agenda_alerts_provider.dart';
import '../support/test_localizations.dart';
import 'package:flo_compass/shared/a11y/keyboard_shortcuts.dart';
import 'package:flo_compass/shared/a11y/route_announcer.dart';
import 'package:flo_compass/shared/widgets/pwa_install_coordinator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'PwaInstallCoordinator inside MaterialApp builder pumps cleanly',
    (tester) async {
      final profileState = ProfileState();
      final appSettings = AppSettingsState();
      final consent = await acceptedConsentState();
      await Future.wait([profileState.init(), appSettings.init()]);
      final router = createAppRouter(profileState, consentState: consent);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: profileState),
            ChangeNotifierProvider.value(value: appSettings),
            testAgendaAlertsProvider(),
            ChangeNotifierProvider.value(value: consent),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: testLocalizationDelegates,
            supportedLocales: testSupportedLocales,
            builder: (context, child) {
              return PwaInstallCoordinator(
                router: router,
                child: KeyboardShortcuts(
                  child: RouteAnnouncer(
                    router: router,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    },
  );
}
