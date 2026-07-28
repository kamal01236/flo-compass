import '../../data/services/agenda_change_detector.dart';

String agendaChangeAlertTitle(AgendaChangeAlert alert) {
  return switch (alert.type) {
    AgendaChangeType.roomChanged => 'Room changed',
    AgendaChangeType.timeChanged => 'Time changed',
    AgendaChangeType.cancelled => 'Session cancelled',
  };
}

String agendaChangeAlertSubtitle(
  AgendaChangeAlert alert, {
  required String? Function(String venueId) venueNameFor,
}) {
  return switch (alert.type) {
    AgendaChangeType.roomChanged =>
      '${alert.title} moved to ${venueNameFor(alert.newVenueId ?? '') ?? alert.newVenueId}',
    AgendaChangeType.timeChanged =>
      '${alert.title} now ${alert.newDay ?? alert.previousDay} ${alert.newStart ?? ''}',
    AgendaChangeType.cancelled => '${alert.title} was removed from the agenda',
  };
}

String agendaChangeReasonLabel(AgendaChangeReason reason) {
  return switch (reason) {
    AgendaChangeReason.inPlan => 'In plan',
    AgendaChangeReason.followedSpeaker => 'Following',
  };
}
