import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/engagement_snapshot.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/data/services/bingo_service.dart';

void main() {
  final service = BingoService();

  Session session({
    required String id,
    String trackId = 'trk-01',
    List<String> tags = const ['genai'],
    bool featured = false,
    String day = 'Day 1',
    String startTime = '10:00',
  }) => Session(
    id: id,
    title: 'Test $id',
    abstract: 'abstract',
    day: day,
    startTime: startTime,
    endTime: '11:00',
    venueId: 'ven-7N1',
    trackId: trackId,
    speakerIds: const [],
    tags: tags,
    format: 'Talk',
    level: 'beginner',
    featured: featured,
    capacity: 40,
    building: 'Nagarro Gurgaon Office',
  );

  test('isRowComplete detects full row', () {
    expect(service.isRowComplete(0, const [0, 1, 2, 3, 4]), isTrue);
    expect(service.isRowComplete(0, const [0, 1, 2, 3]), isFalse);
    expect(service.isRowComplete(5, const [0, 1, 2, 3, 4]), isFalse);
  });

  test('evaluateAutoMarks returns first bookmark cell', () {
    final marks = service.evaluateAutoMarks(
      engagement: EngagementSnapshot.empty,
      plannedSessions: [session(id: 's-1')],
      allSessions: [session(id: 's-1')],
      profile: const UserProfile(
        role: AttendeeRole.engineer,
        interests: [],
        onboardingComplete: true,
      ),
    );
    expect(marks, contains(0));
  });

  test('evaluateAutoMarks skips already marked cells', () {
    final marks = service.evaluateAutoMarks(
      engagement: const EngagementSnapshot(
        xp: 0,
        streakDays: [],
        achievements: [],
        attendedSessionIds: [],
        ratings: {},
        bingoMarks: [0],
        companionQuestions: 0,
        detailViews: 0,
      ),
      plannedSessions: [session(id: 's-1')],
      allSessions: [session(id: 's-1')],
      profile: const UserProfile(
        role: AttendeeRole.engineer,
        interests: [],
        onboardingComplete: true,
      ),
    );
    expect(marks, isNot(contains(0)));
  });

  test('cell indices stay within bounds', () {
    for (final cell in BingoService.cells) {
      expect(cell.index, inInclusiveRange(0, 24));
    }
    expect(BingoService.cells.length, 25);
  });
}
