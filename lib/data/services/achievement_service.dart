import '../models/engagement_snapshot.dart';
import '../models/models.dart';
import 'bingo_service.dart';
import 'track_passport_service.dart';

class Achievement {
  const Achievement({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;
}

class AchievementService {
  static List<Achievement> unlockedFromIds(Iterable<String> ids) {
    final byId = {
      for (final achievement in catalog) achievement.id: achievement,
    };
    return [
      for (final id in ids)
        if (byId.containsKey(id)) byId[id]!,
    ];
  }

  static const catalog = <Achievement>[
    Achievement(
      id: 'keynote_hunter',
      name: 'Keynote Hunter',
      description: 'Bookmarked two featured sessions',
    ),
    Achievement(
      id: 'cursor_ninja',
      name: 'Cursor Ninja',
      description: 'Added three Cursor/DevEx sessions',
    ),
    Achievement(
      id: 'marathon',
      name: 'Marathon',
      description: 'Built a plan with seven sessions',
    ),
    Achievement(
      id: 'companion_curious',
      name: 'Companion Curious',
      description: 'Asked five companion questions',
    ),
    Achievement(
      id: 'renaissance',
      name: 'Renaissance',
      description: 'Planned sessions across five tracks',
    ),
    Achievement(
      id: 'early_bird',
      name: 'Early Bird',
      description: 'Bookmarked a 09:00 session',
    ),
    Achievement(
      id: 'flo_explorer',
      name: 'Flo Explorer',
      description: 'Viewed ten session details',
    ),
    Achievement(
      id: 'bingo_row',
      name: 'Bingo Row',
      description: 'Completed a row on Session Bingo',
    ),
    Achievement(
      id: 'bingo_blackout',
      name: 'Bingo Blackout',
      description: 'Marked all 25 bingo cells',
    ),
    Achievement(
      id: 'track_explorer',
      name: 'Track Explorer',
      description: 'Explored 3+ sessions in one track',
    ),
  ];

  List<Achievement> evaluate({
    required EngagementSnapshot engagement,
    required List<Session> plannedSessions,
    required List<Session> allSessions,
    required List<Track> tracks,
  }) {
    final unlocked = <Achievement>[];
    final achieved = engagement.achievements.toSet();
    final plannedSet = plannedSessions.toSet();
    final bingo = BingoService();
    final passport = TrackPassportService().compute(
      tracks: tracks,
      plannedSessions: plannedSessions,
      allSessions: allSessions,
      engagement: engagement,
    );

    void addIf(bool condition, String id) {
      if (condition && !achieved.contains(id)) {
        unlocked.add(catalog.firstWhere((item) => item.id == id));
      }
    }

    addIf(
      plannedSessions.where((s) => s.featured).length >= 2,
      'keynote_hunter',
    );
    addIf(
      plannedSessions
              .where(
                (s) => s.tags.contains('cursor') || s.tags.contains('devex'),
              )
              .length >=
          3,
      'cursor_ninja',
    );
    addIf(plannedSet.length >= 7, 'marathon');
    addIf(engagement.companionQuestions >= 5, 'companion_curious');
    addIf(
      plannedSessions.map((s) => s.trackId).toSet().length >= 5,
      'renaissance',
    );
    addIf(plannedSessions.any((s) => s.startTime == '09:00'), 'early_bird');
    addIf(engagement.detailViews >= 10, 'flo_explorer');
    addIf(
      List.generate(
        5,
        (row) => bingo.isRowComplete(row, engagement.bingoMarks),
      ).any((complete) => complete),
      'bingo_row',
    );
    addIf(
      engagement.bingoMarks.length >= BingoService.gridSize,
      'bingo_blackout',
    );
    addIf(
      passport.any(
        (p) => p.combinedCount >= TrackPassportService.targetSessions,
      ),
      'track_explorer',
    );

    return unlocked;
  }
}
