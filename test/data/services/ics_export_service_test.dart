import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/services/ics_export_service.dart';

void main() {
  final service = IcsExportService();

  const session = Session(
    id: 's-001',
    title: 'Keynote; Opening',
    abstract: 'Welcome, everyone',
    day: 'Day 1',
    startTime: '09:00',
    endTime: '10:00',
    venueId: 'ven-G01',
    trackId: 'trk-01',
    speakerIds: ['spk-001'],
    tags: [],
    format: 'Keynote',
    level: 'all',
    featured: true,
    capacity: 200,
    building: 'Nagarro Gurgaon Office',
  );

  test('escapes semicolon and comma in ICS text fields', () {
    final ics = service.buildForSession(
      session: session,
      meta: null,
      location: 'Ground, North',
    );

    expect(ics, contains('SUMMARY:Keynote\\; Opening'));
    expect(ics, contains('LOCATION:Ground\\, North'));
  });

  test('escapes newline in description', () {
    const evil = Session(
      id: 's-001',
      title: 'Keynote; Opening',
      abstract: 'Line1\nLine2',
      day: 'Day 1',
      startTime: '09:00',
      endTime: '10:00',
      venueId: 'ven-G01',
      trackId: 'trk-01',
      speakerIds: ['spk-001'],
      tags: [],
      format: 'Keynote',
      level: 'all',
      featured: true,
      capacity: 200,
      building: 'Nagarro Gurgaon Office',
    );
    final ics = service.buildForSession(
      session: evil,
      meta: null,
      location: 'Hall',
    );

    expect(ics, contains('DESCRIPTION:Line1\\nLine2'));
    expect(ics.split('\n'), isNot(contains('Line2')));
  });

  test('buildForSessions uses venue name resolver when provided', () {
    const second = Session(
      id: 's-002',
      title: 'Panel',
      abstract: 'Discussion',
      day: 'Day 1',
      startTime: '11:00',
      endTime: '12:00',
      venueId: 'ven-G02',
      trackId: 'trk-01',
      speakerIds: ['spk-002'],
      tags: [],
      format: 'Panel',
      level: 'all',
      featured: false,
      capacity: 50,
      building: 'Nagarro Gurgaon Office',
    );

    final ics = service.buildForSessions(
      sessions: [session, second],
      meta: null,
      resolveVenueName: (id) => switch (id) {
        'ven-G01' => 'Ground, North',
        'ven-G02' => 'Ground Pod 2',
        _ => id,
      },
    );

    expect(ics, contains('LOCATION:Ground\\, North'));
    expect(ics, contains('LOCATION:Ground Pod 2'));
    expect(ics, isNot(contains('LOCATION:ven-G01')));
    expect(ics, isNot(contains('LOCATION:ven-G02')));
  });

  test('buildForSessions falls back to venue id without resolver', () {
    final ics = service.buildForSessions(sessions: [session], meta: null);

    expect(ics, contains('LOCATION:ven-G01'));
  });
}
