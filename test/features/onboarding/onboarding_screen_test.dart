import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/features/onboarding/onboarding_screen.dart';
import 'package:flo_compass/l10n/app_localizations.dart';
import 'package:flo_compass/providers/app_settings_provider.dart';
import 'package:flo_compass/providers/engagement_provider.dart';
import 'package:flo_compass/providers/flo_meets_provider.dart';
import 'package:flo_compass/providers/profile_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpOnboarding(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final profile = ProfileState(prefs: prefs);
    final engagement = EngagementState(prefs: prefs);
    final appSettings = AppSettingsState(prefs: prefs);
    final floMeets = FloMeetsState(prefs: prefs);
    await profile.init();
    await engagement.init();
    await appSettings.init();
    await floMeets.init();

    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
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

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: profile),
          ChangeNotifierProvider.value(value: engagement),
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: floMeets),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('default Engineer role chip is selected', (tester) async {
    await pumpOnboarding(tester);

    final engineerChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Engineer'),
    );
    expect(engineerChip.selected, isTrue);
    expect(engineerChip.showCheckmark, isTrue);
  });

  testWidgets('tapped interests show selected FilterChips', (tester) async {
    await pumpOnboarding(tester);

    for (final label in ['GenAI', 'Cloud', 'Cursor']) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    for (final label in ['GenAI', 'Cloud', 'Cursor']) {
      final chip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, label),
      );
      expect(chip.selected, isTrue, reason: '$label should be selected');
    }
  });

  testWidgets('completing onboarding with remote saves attendance mode', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final profile = ProfileState(prefs: prefs);
    final engagement = EngagementState(prefs: prefs);
    final appSettings = AppSettingsState(prefs: prefs);
    final floMeets = FloMeetsState(prefs: prefs);
    await profile.init();
    await engagement.init();
    await appSettings.init();
    await floMeets.init();

    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
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

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: profile),
          ChangeNotifierProvider.value(value: engagement),
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: floMeets),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remote / hub'));
    await tester.pumpAndSettle();

    for (final label in ['GenAI', 'Cloud', 'Cursor']) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.textContaining('Continue'));
    await tester.pumpAndSettle();

    expect(profile.profile.attendanceMode, AttendanceMode.remote);
    expect(profile.profile.onboardingComplete, isTrue);
    expect(floMeets.preferences.isSetupComplete, isFalse);
    expect(find.text('Skip Flo Meets for now'), findsNothing);
  });

  testWidgets('completing onboarding queues product tour', (tester) async {
    await pumpOnboarding(tester);

    for (final label in ['GenAI', 'Cloud', 'Cursor']) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    final appSettings = tester
        .element(find.byType(OnboardingScreen))
        .read<AppSettingsState>();

    await tester.tap(find.textContaining('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(appSettings.settings.tourAutoStartPending, isTrue);
    expect(appSettings.shouldAutoStartTour, isTrue);
    expect(find.text('Skip Flo Meets for now'), findsNothing);
  });
}
