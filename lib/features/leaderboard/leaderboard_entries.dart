class LeaderboardEntry {
  const LeaderboardEntry({
    required this.name,
    required this.xp,
    this.isCurrentUser = false,
  });

  final String name;
  final int xp;
  final bool isCurrentUser;
}

/// Fixed fictional demo roster — not real attendees.
const List<LeaderboardEntry> kDemoLeaderboardRoster = [
  LeaderboardEntry(name: 'Alex Chen', xp: 450),
  LeaderboardEntry(name: 'Priya Sharma', xp: 380),
  LeaderboardEntry(name: 'Jordan Lee', xp: 310),
  LeaderboardEntry(name: 'Sam Rivera', xp: 275),
  LeaderboardEntry(name: 'Morgan Taylor', xp: 220),
  LeaderboardEntry(name: 'Casey Kim', xp: 185),
  LeaderboardEntry(name: 'Riley Patel', xp: 150),
  LeaderboardEntry(name: 'Drew Nguyen', xp: 120),
];

/// Inserts [userXp] into the sorted demo roster and returns rank (1-based).
List<LeaderboardEntry> buildLeaderboard({
  required int userXp,
  String userName = 'You',
}) {
  final entries = [
    ...kDemoLeaderboardRoster,
    LeaderboardEntry(name: userName, xp: userXp, isCurrentUser: true),
  ]..sort((a, b) => b.xp.compareTo(a.xp));
  return entries;
}

int userLeaderboardRank(List<LeaderboardEntry> entries) {
  final index = entries.indexWhere((entry) => entry.isCurrentUser);
  return index < 0 ? entries.length : index + 1;
}
