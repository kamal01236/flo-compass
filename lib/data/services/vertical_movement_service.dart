import '../models/models.dart';

class VerticalRouteRecommendation {
  const VerticalRouteRecommendation({
    required this.minutes,
    required this.mode,
    required this.reason,
    this.tip,
  });

  final int minutes;

  /// `stairs` or `lift`.
  final String mode;
  final String reason;
  final String? tip;
}

class VerticalMovementService {
  const VerticalMovementService();

  VerticalRouteRecommendation recommend({
    required CampusLayout campus,
    required String fromFloor,
    required String toFloor,
    bool stepFree = false,
    bool isEventDayMode = false,
    bool wingCross = false,
  }) {
    final delta = campus.floorDelta(fromFloor, toFloor);
    if (delta == 0) {
      final wingMinutes = wingCross ? 1 : 0;
      return VerticalRouteRecommendation(
        minutes: wingMinutes.clamp(0, 20),
        mode: 'walk',
        reason: wingCross ? 'same floor · wing cross' : 'same floor',
      );
    }

    final rules = campus.verticalMovement;
    final goingUp = campus.floorIndex(toFloor) > campus.floorIndex(fromFloor);
    final preferStairs =
        !stepFree &&
        ((goingUp && delta <= rules.preferStairsWhen.floorsUpMax) ||
            (!goingUp && delta <= rules.preferStairsWhen.floorsDownMax));

    if (preferStairs) {
      final stairsMinutes =
          (delta * rules.stairsMinutesPerFloor) + (wingCross ? 1 : 0);
      final liftMinutes = isEventDayMode
          ? rules.eventDayLiftMinutes
          : rules.offPeakLiftMinutes;
      return VerticalRouteRecommendation(
        minutes: stairsMinutes.clamp(1, 20),
        mode: 'stairs',
        reason: '$delta floor${delta == 1 ? '' : 's'} via stairs',
        tip: isEventDayMode
            ? 'Lifts ~$liftMinutes min during event rush'
            : 'Lifts ~$liftMinutes min off-peak',
      );
    }

    final liftMinutes = isEventDayMode
        ? rules.eventDayLiftMinutes
        : rules.offPeakLiftMinutes;
    final total = liftMinutes + (wingCross ? 1 : 0);
    return VerticalRouteRecommendation(
      minutes: total.clamp(1, 20),
      mode: 'lift',
      reason: '$delta floor${delta == 1 ? '' : 's'} via central lifts',
      tip: isEventDayMode ? 'Lifts ~$liftMinutes min during event rush' : null,
    );
  }

  VerticalRouteRecommendation recommendForVenues({
    required CampusLayout? campus,
    required Venue? from,
    required Venue? to,
    bool isEventDayMode = false,
  }) {
    if (campus == null || from == null || to == null) {
      return const VerticalRouteRecommendation(
        minutes: 2,
        mode: 'walk',
        reason: 'same area',
      );
    }
    final wingCross =
        from.wing != to.wing &&
        from.wing.toLowerCase() != 'central' &&
        to.wing.toLowerCase() != 'central' &&
        from.floor == to.floor;
    final stepFree = from.stepFree || to.stepFree;
    return recommend(
      campus: campus,
      fromFloor: from.floor,
      toFloor: to.floor,
      stepFree: stepFree,
      isEventDayMode: isEventDayMode,
      wingCross: wingCross || (from.floor == to.floor && from.wing != to.wing),
    );
  }
}
