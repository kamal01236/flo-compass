import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/services/leave_now_scheduler.dart';
import 'package:flo_compass/data/services/walking_time_estimator.dart';

void main() {
  final venueG = Venue(
    id: 'ven-G01',
    name: 'Ground Reception',
    floor: 'G',
    zone: 'reception',
    wing: 'central',
    capacity: 100,
    building: 'Nagarro Gurgaon Office',
  );
  final venue6N = Venue(
    id: 'ven-601',
    name: 'Room 601',
    floor: '6',
    zone: 'meeting',
    wing: 'N',
    capacity: 40,
    building: 'Nagarro Gurgaon Office',
  );
  final venue13S = Venue(
    id: 'ven-1301',
    name: 'Room 1301',
    floor: '13',
    zone: 'meeting',
    wing: 'S',
    capacity: 40,
    building: 'Nagarro Gurgaon Office',
  );

  const sessionA = Session(
    id: 's-a',
    title: 'Morning keynote',
    abstract: 'a',
    day: 'Day 1',
    startTime: '10:00',
    endTime: '11:00',
    venueId: 'ven-G01',
    trackId: 'trk-01',
    speakerIds: ['spk-001'],
    tags: ['genai'],
    format: 'Keynote',
    level: 'beginner',
    featured: true,
    capacity: 100,
    building: 'Nagarro Gurgaon Office',
  );

  const sessionB = Session(
    id: 's-b',
    title: 'Workshop upstairs',
    abstract: 'b',
    day: 'Day 1',
    startTime: '11:00',
    endTime: '12:00',
    venueId: 'ven-601',
    trackId: 'trk-02',
    speakerIds: ['spk-002'],
    tags: ['cloud'],
    format: 'Workshop',
    level: 'intermediate',
    featured: false,
    capacity: 40,
    building: 'Nagarro Gurgaon Office',
  );

  const sessionC = Session(
    id: 's-c',
    title: 'Top floor panel',
    abstract: 'c',
    day: 'Day 1',
    startTime: '14:00',
    endTime: '15:00',
    venueId: 'ven-1301',
    trackId: 'trk-03',
    speakerIds: ['spk-003'],
    tags: ['leadership'],
    format: 'Panel',
    level: 'advanced',
    featured: false,
    capacity: 40,
    building: 'Nagarro Gurgaon Office',
  );

  test('leaveAt uses walk minutes and buffer from first planned session', () {
    final now = DateTime(2026, 11, 4, 9, 30);
    final alerts = LeaveNowScheduler.planAlerts(
      planned: [sessionB],
      venues: [venueG, venue6N],
      now: now,
      currentDay: 'Day 1',
    );

    expect(alerts, hasLength(1));
    final walk = WalkingTimeEstimator().estimate(from: venueG, to: venue6N);
    final sessionStart = DateTime(2026, 11, 4, 11, 0);
    final expectedLeave = sessionStart.subtract(
      Duration(minutes: walk.minutes + kLeaveNowBufferMinutes),
    );
    expect(alerts.first.leaveAt, expectedLeave);
    expect(alerts.first.walkMinutes, walk.minutes);
  });

  test('leaveAt walks from previous planned session venue on same day', () {
    final now = DateTime(2026, 11, 4, 10, 30);
    final alerts = LeaveNowScheduler.planAlerts(
      planned: [sessionA, sessionC],
      venues: [venueG, venue6N, venue13S],
      now: now,
      currentDay: 'Day 1',
    );

    expect(alerts, hasLength(1));
    final walk = WalkingTimeEstimator().estimate(from: venueG, to: venue13S);
    final sessionStart = DateTime(2026, 11, 4, 14, 0);
    final expectedLeave = sessionStart.subtract(
      Duration(minutes: walk.minutes + kLeaveNowBufferMinutes),
    );
    expect(alerts.first.session.id, sessionC.id);
    expect(alerts.first.leaveAt, expectedLeave);
    expect(walk.minutes, greaterThan(1));
  });

  test('same room walk uses minimal minutes in leave window', () {
    final now = DateTime(2026, 11, 4, 10, 30);
    const sameRoom = Session(
      id: 's-d',
      title: 'Follow-up keynote',
      abstract: 'd',
      day: 'Day 1',
      startTime: '11:30',
      endTime: '12:30',
      venueId: 'ven-G01',
      trackId: 'trk-01',
      speakerIds: ['spk-001'],
      tags: ['genai'],
      format: 'Keynote',
      level: 'beginner',
      featured: false,
      capacity: 100,
      building: 'Nagarro Gurgaon Office',
    );
    final alerts = LeaveNowScheduler.planAlerts(
      planned: [sessionA, sameRoom],
      venues: [venueG],
      now: now,
      currentDay: 'Day 1',
    );

    expect(alerts, hasLength(1));
    final sameRoomAlert = alerts.first;
    expect(sameRoomAlert.walkMinutes, 1);
    expect(
      sameRoomAlert.leaveAt,
      DateTime(2026, 11, 4, 11, 30).subtract(const Duration(minutes: 6)),
    );
  });

  test('isWithinLeaveWindow includes sessions in leave window only', () {
    final now = DateTime(2026, 11, 4, 10, 53);
    final alerts = LeaveNowScheduler.planAlerts(
      planned: [sessionB],
      venues: [venueG, venue6N],
      now: DateTime(2026, 11, 4, 9, 0),
      currentDay: 'Day 1',
    );

    expect(alerts, hasLength(1));
    expect(LeaveNowScheduler.isWithinLeaveWindow(alerts.first, now), isTrue);
    expect(
      LeaveNowScheduler.isWithinLeaveWindow(
        alerts.first,
        DateTime(2026, 11, 4, 9, 0),
      ),
      isFalse,
    );
  });
}
