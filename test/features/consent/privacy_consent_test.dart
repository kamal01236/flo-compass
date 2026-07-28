import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flo_compass/features/consent/privacy_consent_screen.dart';
import 'package:flo_compass/providers/consent_provider.dart';
import '../../support/test_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('privacy consent screen renders accept button', (tester) async {
    final consent = ConsentState();
    await consent.init();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: consent,
        child: MaterialApp(
          localizationsDelegates: testLocalizationDelegates,
          supportedLocales: testSupportedLocales,
          home: const PrivacyConsentScreen(),
        ),
      ),
    );
    expect(find.text('Accept and continue'), findsOneWidget);
    expect(find.text('Privacy & data use'), findsOneWidget);
  });
}
