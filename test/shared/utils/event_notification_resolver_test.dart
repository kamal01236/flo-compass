import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/services/agenda_change_detector.dart';
import 'package:flo_compass/shared/utils/event_notification_resolver.dart';

void main() {
  final now = DateTime(2026, 11, 4, 9, 45);

  Session plannedSession() {
    return Session(
      id: 's-001',
      title: 'Keynote',
      abstract: '',
      day: 'Day 1',
      startTime: '10:00',
      endTime: '11:00',
      venueId: 'ven-G01',
      trackId: 'trk-01',
      speakerIds: const ['spk-001'],
      tags: const [],
      format: 'Keynote',
      level: 'beginner',
      featured: true,
      capacity: 100,
      building: 'Nagarro Gurgaon Office',
    );
  }

  AgendaChangeAlert agendaAlert({
    required DateTime detectedAt,
    AgendaChangeType type = AgendaChangeType.roomChanged,
  }) {
    return AgendaChangeAlert(
      id: 's-001-${type.name}-${detectedAt.millisecondsSinceEpoch}',
      sessionId: 's-001',
      title: 'Keynote',
      type: type,
      detectedAt: detectedAt,
      reason: AgendaChangeReason.inPlan,
      previousVenueId: 'ven-G01',
      newVenueId: 'ven-7S305',
    );
  }

  test('count includes agenda alerts when enabled', () {
    final session = plannedSession();
    final snapshot = resolveEventNotifications(
      sessionsStartingSoon30: [session],
      sessionsStartingSoon20: const [],
      plannedSessions: [session],
      followedSpeakerIds: const ['spk-001'],
      venues: const [],
      minutesUntil: (_) => 15,
      now: now,
      agendaChangeAlerts: [agendaAlert(detectedAt: now)],
      agendaChangeAlertsEnabled: true,
    );
    expect(snapshot.count, 2);
    expect(snapshot.agendaChangeAlerts, hasLength(1));
  });

  test('agenda alerts excluded from count when disabled', () {
    final session = plannedSession();
    final snapshot = resolveEventNotifications(
      sessionsStartingSoon30: [session],
      sessionsStartingSoon20: const [],
      plannedSessions: [session],
      followedSpeakerIds: const ['spk-001'],
      venues: const [],
      minutesUntil: (_) => 15,
      now: now,
      agendaChangeAlerts: [agendaAlert(detectedAt: now)],
      agendaChangeAlertsEnabled: false,
    );
    expect(snapshot.count, 1);
    expect(snapshot.agendaChangeAlerts, isEmpty);
  });

  test('agenda alerts sorted newest first', () {
    final older = agendaAlert(
      detectedAt: now.subtract(const Duration(hours: 1)),
    );
    final newer = agendaAlert(detectedAt: now);
    final snapshot = resolveEventNotifications(
      sessionsStartingSoon30: const [],
      sessionsStartingSoon20: const [],
      plannedSessions: const [],
      followedSpeakerIds: const [],
      venues: const [],
      minutesUntil: (_) => 0,
      now: now,
      agendaChangeAlerts: [older, newer],
    );
    expect(snapshot.agendaChangeAlerts.first.id, newer.id);
  });
}
