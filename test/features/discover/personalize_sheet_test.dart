import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/features/discover/personalize_sheet.dart';
import 'package:flo_compass/providers/profile_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProfileState profileState;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    profileState = ProfileState(prefs: prefs);
    await profileState.init();
  });

  test('personalizeSummary reflects default profile', () {
    expect(personalizeSummary(profileState.profile), 'Balanced · All');
  });

  testWidgets('sheet renders recommendation mode and energy sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: profileState,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showPersonalizeSheet(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Personalize recommendations'), findsOneWidget);
    expect(find.text('Recommendation mode'), findsOneWidget);
    expect(find.text('Energy'), findsOneWidget);
    expect(find.text('Focused'), findsOneWidget);
    expect(find.text('Light keynotes'), findsOneWidget);
  });

  testWidgets('toggling mode updates profile summary', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: profileState,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showPersonalizeSheet(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Adventurous'));
    await tester.pumpAndSettle();

    expect(
      profileState.profile.recommendationMode,
      RecommendationMode.adventurous,
    );
    expect(personalizeSummary(profileState.profile), 'Adventurous · All');
  });
}
