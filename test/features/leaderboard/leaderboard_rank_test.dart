import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/features/leaderboard/leaderboard_entries.dart';

void main() {
  group('buildLeaderboard', () {
    test('inserts user at last place with zero XP', () {
      final entries = buildLeaderboard(userXp: 0);
      expect(userLeaderboardRank(entries), entries.length);
      expect(entries.last.isCurrentUser, isTrue);
      expect(entries.last.xp, 0);
    });

    test('inserts user between Priya and Jordan at 350 XP', () {
      final entries = buildLeaderboard(userXp: 350);
      expect(userLeaderboardRank(entries), 3);
      expect(entries[2].isCurrentUser, isTrue);
      expect(entries[2].xp, 350);
      expect(entries[1].name, 'Priya Sharma');
      expect(entries[3].name, 'Jordan Lee');
    });

    test('inserts user at top when XP exceeds demo roster', () {
      final entries = buildLeaderboard(userXp: 500);
      expect(userLeaderboardRank(entries), 1);
      expect(entries.first.isCurrentUser, isTrue);
      expect(entries.first.xp, 500);
    });

    test('updates rank when XP changes', () {
      final low = buildLeaderboard(userXp: 130);
      final high = buildLeaderboard(userXp: 400);
      expect(userLeaderboardRank(low), greaterThan(userLeaderboardRank(high)));
    });
  });
}
