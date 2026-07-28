import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/services/agenda_change_detector.dart';
import 'package:flo_compass/data/services/agenda_session_fingerprint.dart';

void main() {
  final now = DateTime(2026, 11, 4, 9);

  Session session({
    required String id,
    String venueId = 'ven-G01',
    String start = '09:00',
    String end = '10:00',
    List<String> speakerIds = const ['spk-001'],
  }) {
    return Session(
      id: id,
      title: 'Session $id',
      abstract: '',
      day: 'Day 1',
      startTime: start,
      endTime: end,
      venueId: venueId,
      trackId: 'trk-01',
      speakerIds: speakerIds,
      tags: const [],
      format: 'Talk',
      level: 'beginner',
      featured: false,
      capacity: 50,
      building: 'Nagarro Gurgaon Office',
    );
  }

  test('no alert when no previous snapshot exists', () {
    final current = [session(id: 's-001')];
    final alerts = detectChanges(
      currentSessions: current,
      watchedSessionIds: {'s-001'},
      previousSnapshots: const {},
      planSessionIds: {'s-001'},
      followedSpeakerIds: const {},
      sessionTitles: const {'s-001': 'Session s-001'},
      now: now,
    );
    expect(alerts, isEmpty);
  });

  test('detects room change for planned session', () {
    final current = [session(id: 's-001', venueId: 'ven-7S305')];
    final previous = {
      's-001': AgendaSessionFingerprint.fromSession(
        session(id: 's-001', venueId: 'ven-6N201'),
      ),
    };
    final alerts = detectChanges(
      currentSessions: current,
      watchedSessionIds: {'s-001'},
      previousSnapshots: previous,
      planSessionIds: {'s-001'},
      followedSpeakerIds: const {},
      sessionTitles: const {'s-001': 'Session s-001'},
      now: now,
    );
    expect(alerts, hasLength(1));
    expect(alerts.first.type, AgendaChangeType.roomChanged);
    expect(alerts.first.reason, AgendaChangeReason.inPlan);
  });

  test('detects time change', () {
    final current = [session(id: 's-001', start: '14:00', end: '15:00')];
    final previous = {
      's-001': AgendaSessionFingerprint.fromSession(
        session(id: 's-001', start: '09:00', end: '10:00'),
      ),
    };
    final alerts = detectChanges(
      currentSessions: current,
      watchedSessionIds: {'s-001'},
      previousSnapshots: previous,
      planSessionIds: {'s-001'},
      followedSpeakerIds: const {},
      sessionTitles: const {'s-001': 'Session s-001'},
      now: now,
    );
    expect(alerts.single.type, AgendaChangeType.timeChanged);
  });

  test('detects cancellation when session id disappears', () {
    final previous = {
      's-001': AgendaSessionFingerprint.fromSession(session(id: 's-001')),
    };
    final alerts = detectChanges(
      currentSessions: const [],
      watchedSessionIds: {'s-001'},
      previousSnapshots: previous,
      planSessionIds: {'s-001'},
      followedSpeakerIds: const {},
      sessionTitles: const {'s-001': 'Session s-001'},
      now: now,
    );
    expect(alerts.single.type, AgendaChangeType.cancelled);
    expect(alerts.single.title, 'Session s-001');
  });

  test('ignores unwatched sessions', () {
    final current = [session(id: 's-999', venueId: 'ven-7S305')];
    final previous = {
      's-999': AgendaSessionFingerprint.fromSession(
        session(id: 's-999', venueId: 'ven-G01'),
      ),
    };
    final alerts = detectChanges(
      currentSessions: current,
      watchedSessionIds: const {},
      previousSnapshots: previous,
      planSessionIds: const {},
      followedSpeakerIds: const {},
      sessionTitles: const {'s-999': 'Session s-999'},
      now: now,
    );
    expect(alerts, isEmpty);
  });

  test('followed speaker sessions are watched', () {
    final current = [
      session(id: 's-042', speakerIds: const ['spk-007']),
    ];
    final previous = {
      's-042': AgendaSessionFingerprint.fromSession(
        session(id: 's-042', start: '10:00', speakerIds: const ['spk-007']),
      ),
    };
    final alerts = detectChanges(
      currentSessions: [
        session(id: 's-042', start: '11:00', speakerIds: const ['spk-007']),
      ],
      watchedSessionIds: watchedAgendaSessionIds(
        sessions: current,
        planSessionIds: const {},
        followedSpeakerIds: const {'spk-007'},
      ),
      previousSnapshots: previous,
      planSessionIds: const {},
      followedSpeakerIds: const {'spk-007'},
      sessionTitles: const {'s-042': 'Session s-042'},
      now: now,
    );
    expect(alerts.single.reason, AgendaChangeReason.followedSpeaker);
  });
}
