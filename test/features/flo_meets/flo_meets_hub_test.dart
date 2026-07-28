import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flo_compass/core/auth/mock_user.dart';
import 'package:flo_compass/core/auth/platform_role.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/features/flo_meets/flo_meets_hub_screen.dart';
import 'package:flo_compass/providers/auth_provider.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/flo_meets_provider.dart';
import 'package:flo_compass/providers/profile_provider.dart';

import '../../support/test_flo_meets_helpers.dart';
import '../../support/test_localizations.dart';
import '../../support/test_widget_helpers.dart';

const _mockAttendee = MockUser(
  id: 'hub-test-user',
  name: 'Hub Tester',
  email: 'hub@example.com',
  organization: 'Nagarro',
  role: PlatformRole.attendee,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hub shows Rooms Waiting Matches without request/accept', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = AuthState();
    await auth.init();
    await auth.signInMock(_mockAttendee);
    final floMeets = FloMeetsState(
      prefs: prefs,
      demoReciprocateDelay: Duration.zero,
      enableDemoSeed: false,
    );
    await initFloMeetsForTests(floMeets, subject: _mockAttendee.id);
    await floMeets.savePreferences(
      buildValidFloMeetsPreferences(enabledSlots: const ['Day_1_0900']),
    );
    await floMeets.loadRooms();

    final event = EventState()..loading = false;
    final profile = ProfileState()
      ..profile = const UserProfile(
        role: AttendeeRole.engineer,
        interests: ['genai', 'cloud'],
        onboardingComplete: true,
      );

    try {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider.value(value: floMeets),
            ChangeNotifierProvider.value(value: event),
            ChangeNotifierProvider.value(value: profile),
          ],
          child: MaterialApp(
            localizationsDelegates: testLocalizationDelegates,
            supportedLocales: testSupportedLocales,
            home: const FloMeetsHubScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Rooms'), findsWidgets);
      expect(find.text('Waiting'), findsOneWidget);
      expect(find.text('Matches'), findsOneWidget);
      expect(find.text('Request'), findsNothing);
      expect(find.text('Accept'), findsNothing);
      expect(find.text('Decline'), findsNothing);
    } finally {
      await disposeEventState(event, tester);
    }
  });
}
