import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/companion_provider.dart';
import '../../providers/plan_provider.dart';
import 'tour_step.dart';
import 'tour_targets.dart';

/// Demo session used for the Add-to-My-Plan tour step.
const kTourSessionId = 's-001';

const kTourCompanionSampleQuery = 'Where can I park my car?';

class TourController extends ChangeNotifier {
  TourController({
    required GoRouter router,
    required AppSettingsState appSettings,
    required PlanState planState,
    required CompanionState companionState,
  }) : _router = router,
       _appSettings = appSettings,
       _planState = planState,
       _companionState = companionState {
    _planState.addListener(_onPlanChanged);
    _companionState.addListener(_onCompanionChanged);
    _router.routerDelegate.addListener(_onRouteChanged);
  }

  final GoRouter _router;
  final AppSettingsState _appSettings;
  final PlanState _planState;
  final CompanionState _companionState;

  bool _active = false;
  bool _disposed = false;
  int _stepIndex = 0;
  bool _companionSendSeen = false;
  bool _companionPrefillApplied = false;
  // Guards the null-target auto-skip so we skip a missing anchor at most
  // once per step id and never recurse infinitely.
  TourStepId? _lastAutoSkippedStepId;

  bool get active => _active;
  bool get tourActive => _active;
  int get stepIndex => _stepIndex;
  int get stepCount => _steps.length;
  TourStep get currentStep => _steps[_stepIndex];
  bool get shouldPrefillCompanion =>
      _active &&
      currentStep.id == TourStepId.companionAsk &&
      !_companionPrefillApplied;
  String get companionSampleQuery => kTourCompanionSampleQuery;

  static final List<TourStep> _steps = [
    TourStep(
      id: TourStepId.nowNextBar,
      route: AppRoutes.discover,
      targetKey: tourNowNextBarKey,
      title: 'tourNowNextTitle',
      body: 'tourNowNextBody',
    ),
    TourStep(
      id: TourStepId.discoverSearch,
      route: AppRoutes.discover,
      targetKey: tourDiscoverSearchKey,
      title: 'tourDiscoverTitle',
      body: 'tourDiscoverBody',
    ),
    TourStep(
      id: TourStepId.recommendationReason,
      route: AppRoutes.session(kTourSessionId),
      targetKey: tourRecoReasonKey,
      title: 'tourRecoReasonTitle',
      body: 'tourRecoReasonBody',
    ),
    TourStep(
      id: TourStepId.sessionAddToPlan,
      route: AppRoutes.session(kTourSessionId),
      targetKey: tourSessionAddToPlanKey,
      title: 'tourSessionTitle',
      body: 'tourSessionBody',
    ),
    TourStep(
      id: TourStepId.logisticsTab,
      route: AppRoutes.session(kTourSessionId),
      targetKey: tourLogisticsTabKey,
      title: 'tourLogisticsTitle',
      body: 'tourLogisticsBody',
    ),
    TourStep(
      id: TourStepId.venueMapButton,
      route: AppRoutes.session(kTourSessionId),
      targetKey: tourVenueMapButtonKey,
      title: 'tourVenueMapTitle',
      body: 'tourVenueMapBody',
    ),
    TourStep(
      id: TourStepId.companionAsk,
      route: AppRoutes.companion,
      targetKey: tourCompanionInputKey,
      title: 'tourCompanionTitle',
      body: 'tourCompanionBody',
    ),
    TourStep(
      id: TourStepId.myPlanSummary,
      route: AppRoutes.myPlan,
      targetKey: tourMyPlanSummaryKey,
      title: 'tourMyPlanTitle',
      body: 'tourMyPlanBody',
      isFinal: true,
    ),
  ];

  Future<void> start({bool force = false}) async {
    if (_active) return;
    if (!force && !_appSettings.shouldAutoStartTour) return;

    _active = true;
    _stepIndex = 0;
    _companionSendSeen = false;
    _companionPrefillApplied = false;
    _lastAutoSkippedStepId = null;
    notifyListeners();
    await _goToCurrentStep();
  }

  void markCompanionPrefillApplied() {
    if (_companionPrefillApplied) return;
    _companionPrefillApplied = true;
  }

  Future<void> next() async {
    if (!_active) return;
    if (_stepIndex >= _steps.length - 1) {
      await complete();
      return;
    }
    _stepIndex++;
    if (currentStep.id == TourStepId.companionAsk) {
      _companionSendSeen = _companionState.history.isNotEmpty;
    }
    notifyListeners();
    await _goToCurrentStep();
  }

  Future<void> back() async {
    if (!_active || _stepIndex <= 0) return;
    _stepIndex--;
    _lastAutoSkippedStepId = null;
    notifyListeners();
    await _goToCurrentStep();
  }

  Future<void> skip() async {
    if (!_active) return;
    _lastAutoSkippedStepId = null;
    await _appSettings.markTourCompleted(dismissed: true);
    _end();
  }

  Future<void> complete() async {
    if (!_active) return;
    _lastAutoSkippedStepId = null;
    await _appSettings.markTourCompleted();
    _end();
  }

  void _end() {
    _active = false;
    _stepIndex = 0;
    _companionSendSeen = false;
    _companionPrefillApplied = false;
    _lastAutoSkippedStepId = null;
    notifyListeners();
  }

  Future<void> _goToCurrentStep() async {
    final route = currentStep.route;
    final current = _safeMatchedLocation();
    if (current != route) {
      _router.go(route);
    }
    notifyListeners();
    _scheduleNullTargetSkip();
  }

  /// Reads [GoRouter.state.matchedLocation] defensively — during tests or
  /// transitional router states the match list can be empty and `state`
  /// throws `Bad state: No element`. Falling back to `null` lets callers
  /// treat that as "unknown" instead of crashing.
  String? _safeMatchedLocation() {
    try {
      return _router.state.matchedLocation;
    } catch (_) {
      return null;
    }
  }

  /// If the current step's target widget is not mounted after one frame,
  /// auto-advance once. Steps that resolve to a real context reset the guard
  /// so a later re-visit can skip again if needed.
  void _scheduleNullTargetSkip() {
    if (!_active || _disposed) return;
    final stepAtSchedule = currentStep.id;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      if (_disposed || !_active) return;
      if (currentStep.id != stepAtSchedule) return;
      final ctx = currentStep.targetKey.currentContext;
      if (ctx != null) {
        if (_lastAutoSkippedStepId == currentStep.id) {
          _lastAutoSkippedStepId = null;
        }
        return;
      }
      if (_lastAutoSkippedStepId == currentStep.id) return;
      _lastAutoSkippedStepId = currentStep.id;
      unawaited(next());
    });
    // Nudge the scheduler so the post-frame callback fires even when no
    // watcher marks the tree dirty (common inside tests).
    binding.scheduleFrame();
  }

  void _onPlanChanged() {
    if (!_active || currentStep.id != TourStepId.sessionAddToPlan) return;
    if (_planState.sessionIds.contains(kTourSessionId)) {
      unawaited(next());
    }
  }

  void _onCompanionChanged() {
    if (!_active || currentStep.id != TourStepId.companionAsk) return;
    if (_companionState.history.isNotEmpty && !_companionSendSeen) {
      _companionSendSeen = true;
      unawaited(next());
    }
  }

  void _onRouteChanged() {
    if (!_active) return;
    if (currentStep.id != TourStepId.venueMapButton) return;
    final location = _safeMatchedLocation();
    if (location != null && location.startsWith(AppRoutes.map)) {
      unawaited(next());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _active = false;
    _planState.removeListener(_onPlanChanged);
    _companionState.removeListener(_onCompanionChanged);
    _router.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }
}
