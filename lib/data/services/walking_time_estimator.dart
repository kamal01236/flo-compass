import '../models/models.dart';
import 'vertical_movement_service.dart';

class WalkingTimeEstimate {
  const WalkingTimeEstimate({
    required this.minutes,
    required this.reason,
    this.recommendedMode,
    this.alternateMode,
    this.verticalTip,
  });

  final int minutes;
  final String reason;

  /// `stairs`, `lift`, or `walk`.
  final String? recommendedMode;
  final String? alternateMode;
  final String? verticalTip;
}

class WalkingTimeEstimator {
  WalkingTimeEstimator({
    CampusLayout? campus,
    this.isEventDayMode = false,
    VerticalMovementService? verticalService,
  }) : _campus = campus,
       _verticalService = verticalService ?? const VerticalMovementService();

  final CampusLayout? _campus;
  final bool isEventDayMode;
  final VerticalMovementService _verticalService;

  WalkingTimeEstimator withContext({
    CampusLayout? campus,
    bool? isEventDayMode,
  }) {
    return WalkingTimeEstimator(
      campus: campus ?? _campus,
      isEventDayMode: isEventDayMode ?? this.isEventDayMode,
      verticalService: _verticalService,
    );
  }

  WalkingTimeEstimate estimate({required Venue? from, required Venue? to}) {
    if (from == null || to == null) {
      return const WalkingTimeEstimate(minutes: 2, reason: 'same area');
    }
    if (from.id == to.id) {
      return const WalkingTimeEstimate(
        minutes: 1,
        reason: 'same room',
        recommendedMode: 'walk',
      );
    }

    final campus = _campus;
    if (campus != null) {
      return _estimateWithCampus(from: from, to: to, campus: campus);
    }

    return _legacyEstimate(from: from, to: to);
  }

  WalkingTimeEstimate _estimateWithCampus({
    required Venue from,
    required Venue to,
    required CampusLayout campus,
  }) {
    final primary = _verticalService.recommendForVenues(
      campus: campus,
      from: from,
      to: to,
      isEventDayMode: isEventDayMode,
    );

    String? alternateMode;
    String? verticalTip = primary.tip;
    if (primary.mode == 'stairs') {
      alternateMode = 'lift';
    } else if (primary.mode == 'lift') {
      final delta = campus.floorDelta(from.floor, to.floor);
      final goingUp =
          campus.floorIndex(to.floor) > campus.floorIndex(from.floor);
      final rules = campus.verticalMovement;
      final couldStairs =
          !from.stepFree &&
          !to.stepFree &&
          ((goingUp && delta <= rules.preferStairsWhen.floorsUpMax) ||
              (!goingUp && delta <= rules.preferStairsWhen.floorsDownMax));
      if (couldStairs) alternateMode = 'stairs';
    }

    final sameFloorWingOnly = from.floor == to.floor && from.wing != to.wing;
    final minutes = sameFloorWingOnly && primary.minutes == 0
        ? 1
        : primary.minutes;

    return WalkingTimeEstimate(
      minutes: minutes.clamp(1, 20),
      reason: primary.reason,
      recommendedMode: primary.mode,
      alternateMode: alternateMode,
      verticalTip: verticalTip,
    );
  }

  WalkingTimeEstimate _legacyEstimate({
    required Venue from,
    required Venue to,
  }) {
    final floorDelta =
        (_legacyFloorNumber(from.floor) - _legacyFloorNumber(to.floor)).abs();
    final wingDelta = from.wing == to.wing ? 0 : 1;
    final receptionDelta = (from.floor == 'G' || to.floor == 'G') ? 2 : 0;

    final seconds =
        (floorDelta * 30) + (wingDelta * 15) + (receptionDelta * 60);
    final minutes = (seconds / 60).ceil().clamp(1, 20);
    return WalkingTimeEstimate(
      minutes: minutes,
      reason: 'floor $floorDelta · wing $wingDelta',
      recommendedMode: floorDelta == 0 ? 'walk' : 'lift',
    );
  }

  int _legacyFloorNumber(String floor) =>
      floor == 'G' ? 0 : int.tryParse(floor) ?? 0;
}
