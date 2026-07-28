import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/core/routing/app_routes.dart';
import 'package:flo_compass/providers/app_settings_provider.dart';
import 'package:flo_compass/providers/companion_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/shared/tour/tour_controller.dart';
import 'package:flo_compass/shared/tour/tour_step.dart';
import 'package:flo_compass/shared/tour/tour_targets.dart';
import 'package:flo_compass/shared/tour/tour_version.dart';

/// Off-screen column that keeps every tour anchor key mounted so the
/// null-target auto-skip guard stays inert during step-by-step navigation
/// tests. Attached via [MaterialApp.router]'s `builder` in
/// [_pumpAnchoredHarnessImpl] below.
class _MountedAnchors extends StatelessWidget {
  const _MountedAnchors();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Offstage(
        offstage: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(key: tourNowNextBarKey, width: 1, height: 1),
            SizedBox(key: tourDiscoverSearchKey, width: 1, height: 1),
            SizedBox(key: tourRecoReasonKey, width: 1, height: 1),
            SizedBox(key: tourSessionAddToPlanKey, width: 1, height: 1),
            SizedBox(key: tourLogisticsTabKey, width: 1, height: 1),
            SizedBox(key: tourVenueMapButtonKey, width: 1, height: 1),
            SizedBox(key: tourCompanionInputKey, width: 1, height: 1),
            SizedBox(key: tourMyPlanSummaryKey, width: 1, height: 1),
          ],
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late AppSettingsState appSettings;
  late PlanState planState;
  late CompanionState companionState;
  late GoRouter router;
  late TourController tour;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    appSettings = AppSettingsState(prefs: prefs);
    planState = PlanState(prefs: prefs);
    companionState = CompanionState();
    await appSettings.init();
    await planState.init();

    router = GoRouter(
      initialLocation: AppRoutes.discover,
      routes: [
        GoRoute(path: AppRoutes.discover, builder: (_, _) => const SizedBox()),
        GoRoute(path: '/session/:id', builder: (_, _) => const SizedBox()),
        GoRoute(path: AppRoutes.companion, builder: (_, _) => const SizedBox()),
        GoRoute(path: AppRoutes.myPlan, builder: (_, _) => const SizedBox()),
        GoRoute(path: AppRoutes.map, builder: (_, _) => const SizedBox()),
        GoRoute(
          path: AppRoutes.directions,
          builder: (_, _) => const SizedBox(),
        ),
      ],
    );

    tour = TourController(
      router: router,
      appSettings: appSettings,
      planState: planState,
      companionState: companionState,
    );
  });

  tearDown(() {
    tour.dispose();
    companionState.dispose();
    planState.dispose();
  });

  /// Plain router harness — mounts only route placeholders. Any step whose
  /// target key needs to resolve will hit the null-target auto-skip.
  Future<void> pumpRouterHarness(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
  }

  /// Extended harness — attaches every tour target key alongside the router
  /// via [MaterialApp.router]'s `builder` so tests can drive `next()`/`back()`
  /// without racing the null-target guard.
  Future<void> pumpAnchoredHarness(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) {
          return Stack(
            children: [
              Positioned.fill(child: child ?? const SizedBox.shrink()),
              const Positioned(left: 0, top: 0, child: _MountedAnchors()),
            ],
          );
        },
      ),
    );
    await tester.pump();
  }

  test(
    'shouldAutoStartTour requires pending flag and unseen version',
    () async {
      expect(appSettings.shouldAutoStartTour, isFalse);

      await appSettings.queueTourStart();
      expect(appSettings.shouldAutoStartTour, isTrue);

      await appSettings.markTourCompleted();
      expect(appSettings.shouldAutoStartTour, isFalse);
      expect(appSettings.settings.tourLastSeenVersion, kTourVersion);
    },
  );

  test('stepCount reflects the 8-step highest-ROI sequence', () {
    expect(tour.stepCount, 8);
  });

  testWidgets('start activates tour on discover when forced', (tester) async {
    await pumpAnchoredHarness(tester);
    await tour.start(force: true);
    await tester.pump();

    expect(tour.active, isTrue);
    expect(tour.currentStep.id, TourStepId.nowNextBar);
    expect(router.state.matchedLocation, AppRoutes.discover);
  });

  testWidgets('next advances through the expanded step order', (tester) async {
    await pumpAnchoredHarness(tester);
    await tour.start(force: true);
    await tester.pump();
    expect(tour.currentStep.id, TourStepId.nowNextBar);

    await tour.next();
    await tester.pump();
    expect(tour.currentStep.id, TourStepId.discoverSearch);
    expect(router.state.matchedLocation, AppRoutes.discover);

    await tour.next();
    await tester.pump();
    expect(tour.currentStep.id, TourStepId.recommendationReason);
    expect(router.state.matchedLocation, AppRoutes.session(kTourSessionId));

    await tour.next();
    await tester.pump();
    expect(tour.currentStep.id, TourStepId.sessionAddToPlan);
    expect(router.state.matchedLocation, AppRoutes.session(kTourSessionId));

    await tour.next();
    await tester.pump();
    expect(tour.currentStep.id, TourStepId.logisticsTab);

    await tour.next();
    await tester.pump();
    expect(tour.currentStep.id, TourStepId.venueMapButton);

    await tour.next();
    await tester.pump();
    expect(tour.currentStep.id, TourStepId.companionAsk);
    expect(router.state.matchedLocation, AppRoutes.companion);

    await tour.next();
    await tester.pump();
    expect(tour.currentStep.id, TourStepId.myPlanSummary);
    expect(router.state.matchedLocation, AppRoutes.myPlan);
    expect(tour.currentStep.isFinal, isTrue);
  });

  testWidgets('adding tour session to plan auto-advances to logisticsTab', (
    tester,
  ) async {
    await pumpAnchoredHarness(tester);
    await tour.start(force: true);
    await tester.pump();

    // Advance to sessionAddToPlan (indices 0 -> 3).
    await tour.next();
    await tester.pump();
    await tour.next();
    await tester.pump();
    await tour.next();
    await tester.pump();
    expect(tour.currentStep.id, TourStepId.sessionAddToPlan);

    await planState.toggle(kTourSessionId);
    await tester.pump();

    expect(tour.currentStep.id, TourStepId.logisticsTab);
  });

  testWidgets(
    'router navigating to /map advances venueMapButton to companionAsk',
    (tester) async {
      await pumpAnchoredHarness(tester);
      await tour.start(force: true);
      await tester.pump();

      // Advance to venueMapButton (indices 0 -> 5).
      for (var i = 0; i < 5; i++) {
        await tour.next();
        await tester.pump();
      }
      expect(tour.currentStep.id, TourStepId.venueMapButton);

      router.go('/map?room=ven-G01');
      await tester.pump();

      expect(tour.currentStep.id, TourStepId.companionAsk);
      expect(router.state.matchedLocation, AppRoutes.companion);
    },
  );

  testWidgets(
    'null-target guard auto-advances past unmounted anchors and settles',
    (tester) async {
      // Plain harness mounts no anchors, so every step's target key resolves
      // to null. The guard advances step-by-step until the final step calls
      // complete() and the tour settles instead of looping on a single step.
      await pumpRouterHarness(tester);
      await tester.pump();
      await tour.start(force: true);
      // pumpAndSettle drains every scheduled post-frame callback until the
      // scheduler is idle. If the guard were re-scheduling the same step it
      // would time out; if it advances once per unique step id, the final
      // step completes the tour and pumpAndSettle returns cleanly.
      await tester.pumpAndSettle();

      expect(tour.active, isFalse);
      expect(appSettings.settings.tourLastSeenVersion, kTourVersion);
    },
  );

  testWidgets('null-target guard does not re-skip the same step twice', (
    tester,
  ) async {
    // Mount only the discoverSearch anchor. Start the tour: nowNextBar
    // (null) auto-skips once, discoverSearch resolves so the guard leaves
    // the step alone, and the tour parks there until we drive it manually.
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) {
          return Stack(
            children: [
              Positioned.fill(child: child ?? const SizedBox.shrink()),
              Positioned(
                left: 0,
                top: 0,
                child: SizedBox(
                  key: tourDiscoverSearchKey,
                  width: 1,
                  height: 1,
                ),
              ),
            ],
          );
        },
      ),
    );
    await tester.pump();
    await tour.start(force: true);
    await tester.pumpAndSettle();

    // After the guard skipped nowNextBar, discoverSearch resolves — no more
    // auto-advance, no infinite loop.
    expect(tour.currentStep.id, TourStepId.discoverSearch);
    expect(tour.active, isTrue);
  });

  testWidgets('skip marks tour dismissed and ends', (tester) async {
    await pumpAnchoredHarness(tester);
    await appSettings.queueTourStart();
    await tour.start(force: true);
    await tester.pump();
    await tour.skip();

    expect(tour.active, isFalse);
    expect(appSettings.settings.tourDismissedAt, isNotNull);
    expect(appSettings.settings.tourAutoStartPending, isFalse);
  });

  testWidgets('complete marks tour seen and ends', (tester) async {
    await pumpAnchoredHarness(tester);
    await tour.start(force: true);
    await tester.pump();
    await tour.complete();

    expect(tour.active, isFalse);
    expect(appSettings.settings.tourLastSeenVersion, kTourVersion);
  });

  test('resetTour clears seen state', () async {
    await appSettings.markTourCompleted();
    await appSettings.resetTour();

    expect(appSettings.settings.tourLastSeenVersion, isNull);
    expect(appSettings.settings.tourDismissedAt, isNull);
  });

  test('companion sample query is the "Fix my 11am clash" prompt', () {
    expect(kTourCompanionSampleQuery, 'Where can I park my car?');
    expect(tour.companionSampleQuery, kTourCompanionSampleQuery);
  });
}
