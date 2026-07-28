import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/services/conflict_detector.dart';

void main() {
  final detector = ConflictDetector();

  Session sess({
    required String id,
    required String day,
    required String start,
    required String end,
  }) {
    return Session(
      id: id,
      title: id,
      abstract: '',
      day: day,
      startTime: start,
      endTime: end,
      venueId: 'ven-G01',
      trackId: 'trk-01',
      speakerIds: ['spk-001'],
      tags: [],
      format: 'Panel',
      level: 'beginner',
      featured: false,
      capacity: 50,
      building: 'Nagarro Gurgaon Office',
    );
  }

  test('detects overlapping sessions on same day', () {
    final a = sess(id: 's-1', day: 'Day 1', start: '10:00', end: '11:00');
    final b = sess(id: 's-2', day: 'Day 1', start: '10:30', end: '11:30');
    final conflicts = detector.findConflicts([a, b]);
    expect(conflicts, hasLength(1));
  });

  test('no conflict on different days', () {
    final a = sess(id: 's-1', day: 'Day 1', start: '10:00', end: '11:00');
    final b = sess(id: 's-2', day: 'Day 2', start: '10:00', end: '11:00');
    expect(detector.findConflicts([a, b]), isEmpty);
  });

  test('adjacent non-overlapping sessions', () {
    final a = sess(id: 's-1', day: 'Day 1', start: '10:00', end: '11:00');
    final b = sess(id: 's-2', day: 'Day 1', start: '11:00', end: '12:00');
    expect(detector.findConflicts([a, b]), isEmpty);
  });
}
