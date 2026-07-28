import '../models/models.dart';
import '../models/user_profile.dart';
import '../models/engagement_snapshot.dart';

enum BingoAutoRule {
  firstBookmark,
  thirdBookmark,
  companionQuestion,
  viewFiveDetails,
  bookmarkGenAi,
  attendFeatured,
  rateSession,
  visitFloor7,
  planThreeDay1,
  attendThree,
  bookmarkFeatured,
  fiveCompanionQuestions,
  exploreFiveTracks,
  visitFloor10,
  marathonPlan,
  earlyBirdBookmark,
  bookmarkCloud,
  attendDay2,
  bookmarkLeadership,
  viewTenDetails,
  visitFloor13,
  renaissanceTracks,
  companionCurious,
  floExplorer,
  blackoutManual,
}

class BingoCell {
  const BingoCell({
    required this.index,
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.autoRule,
  });

  final int index;
  final String id;
  final String label;
  final String shortLabel;
  final BingoAutoRule? autoRule;
}

class BingoService {
  static const gridSize = 25;

  static const cells = <BingoCell>[
    BingoCell(
      index: 0,
      id: 'first_bookmark',
      label: 'Add your first bookmark',
      shortLabel: '1st bookmark',
      autoRule: BingoAutoRule.firstBookmark,
    ),
    BingoCell(
      index: 1,
      id: 'third_bookmark',
      label: 'Bookmark 3 sessions',
      shortLabel: '3 bookmarks',
      autoRule: BingoAutoRule.thirdBookmark,
    ),
    BingoCell(
      index: 2,
      id: 'companion_question',
      label: 'Ask Flo a question',
      shortLabel: 'Ask Flo',
      autoRule: BingoAutoRule.companionQuestion,
    ),
    BingoCell(
      index: 3,
      id: 'view_five',
      label: 'Open 5 session details',
      shortLabel: '5 details',
      autoRule: BingoAutoRule.viewFiveDetails,
    ),
    BingoCell(
      index: 4,
      id: 'bookmark_genai',
      label: 'Bookmark a GenAI session',
      shortLabel: 'GenAI',
      autoRule: BingoAutoRule.bookmarkGenAi,
    ),
    BingoCell(
      index: 5,
      id: 'attend_featured',
      label: 'Mark a featured session attended',
      shortLabel: 'Featured',
      autoRule: BingoAutoRule.attendFeatured,
    ),
    BingoCell(
      index: 6,
      id: 'rate_session',
      label: 'Rate a session',
      shortLabel: 'Rate',
      autoRule: BingoAutoRule.rateSession,
    ),
    BingoCell(
      index: 7,
      id: 'visit_floor7',
      label: 'Visit floor 7 on the map',
      shortLabel: 'Floor 7',
      autoRule: BingoAutoRule.visitFloor7,
    ),
    BingoCell(
      index: 8,
      id: 'plan_three_day1',
      label: 'Plan 3 Day 1 sessions',
      shortLabel: 'Day 1 ×3',
      autoRule: BingoAutoRule.planThreeDay1,
    ),
    BingoCell(
      index: 9,
      id: 'attend_three',
      label: 'Mark 3 sessions attended',
      shortLabel: '3 attended',
      autoRule: BingoAutoRule.attendThree,
    ),
    BingoCell(
      index: 10,
      id: 'bookmark_featured',
      label: 'Bookmark a featured session',
      shortLabel: 'Feat. plan',
      autoRule: BingoAutoRule.bookmarkFeatured,
    ),
    BingoCell(
      index: 11,
      id: 'five_companion',
      label: 'Ask Flo 5 questions',
      shortLabel: '5 questions',
      autoRule: BingoAutoRule.fiveCompanionQuestions,
    ),
    BingoCell(
      index: 12,
      id: 'explore_five_tracks',
      label: 'Explore 5 different tracks',
      shortLabel: '5 tracks',
      autoRule: BingoAutoRule.exploreFiveTracks,
    ),
    BingoCell(
      index: 13,
      id: 'visit_floor10',
      label: 'Visit floor 10 on the map',
      shortLabel: 'Floor 10',
      autoRule: BingoAutoRule.visitFloor10,
    ),
    BingoCell(
      index: 14,
      id: 'marathon_plan',
      label: 'Build a 7-session plan',
      shortLabel: '7 in plan',
      autoRule: BingoAutoRule.marathonPlan,
    ),
    BingoCell(
      index: 15,
      id: 'early_bird',
      label: 'Bookmark a 09:00 session',
      shortLabel: '09:00',
      autoRule: BingoAutoRule.earlyBirdBookmark,
    ),
    BingoCell(
      index: 16,
      id: 'bookmark_cloud',
      label: 'Bookmark a cloud session',
      shortLabel: 'Cloud',
      autoRule: BingoAutoRule.bookmarkCloud,
    ),
    BingoCell(
      index: 17,
      id: 'attend_day2',
      label: 'Attend a Day 2 session',
      shortLabel: 'Day 2',
      autoRule: BingoAutoRule.attendDay2,
    ),
    BingoCell(
      index: 18,
      id: 'bookmark_leadership',
      label: 'Bookmark a leadership session',
      shortLabel: 'Leadership',
      autoRule: BingoAutoRule.bookmarkLeadership,
    ),
    BingoCell(
      index: 19,
      id: 'view_ten',
      label: 'Open 10 session details',
      shortLabel: '10 details',
      autoRule: BingoAutoRule.viewTenDetails,
    ),
    BingoCell(
      index: 20,
      id: 'visit_floor13',
      label: 'Visit floor 13 on the map',
      shortLabel: 'Floor 13',
      autoRule: BingoAutoRule.visitFloor13,
    ),
    BingoCell(
      index: 21,
      id: 'renaissance',
      label: 'Plan across 5 tracks',
      shortLabel: '5 tracks',
      autoRule: BingoAutoRule.renaissanceTracks,
    ),
    BingoCell(
      index: 22,
      id: 'companion_curious',
      label: 'Companion Curious (5 questions)',
      shortLabel: 'Curious',
      autoRule: BingoAutoRule.companionCurious,
    ),
    BingoCell(
      index: 23,
      id: 'flo_explorer',
      label: 'View 10 session details',
      shortLabel: 'Explorer',
      autoRule: BingoAutoRule.floExplorer,
    ),
    BingoCell(
      index: 24,
      id: 'blackout',
      label: 'Complete the full bingo card',
      shortLabel: 'Blackout',
      autoRule: BingoAutoRule.blackoutManual,
    ),
  ];

  BingoCell? cellAt(int index) {
    if (index < 0 || index >= gridSize) return null;
    return cells[index];
  }

  bool isRowComplete(int rowIndex, List<int> marks) {
    if (rowIndex < 0 || rowIndex > 4) return false;
    final start = rowIndex * 5;
    for (var i = 0; i < 5; i++) {
      if (!marks.contains(start + i)) return false;
    }
    return true;
  }

  List<int> evaluateAutoMarks({
    required EngagementSnapshot engagement,
    required List<Session> plannedSessions,
    required List<Session> allSessions,
    required UserProfile profile,
  }) {
    final marks = engagement.bingoMarks.toSet();
    final attended = engagement.attendedSessionIds.toSet();
    final newlySatisfied = <int>[];

    for (final cell in cells) {
      if (marks.contains(cell.index)) continue;
      final rule = cell.autoRule;
      if (rule == null) continue;
      if (_isRuleSatisfied(
        rule,
        engagement: engagement,
        plannedSessions: plannedSessions,
        allSessions: allSessions,
        attended: attended,
        marks: marks,
      )) {
        newlySatisfied.add(cell.index);
      }
    }

    return newlySatisfied;
  }

  bool _isRuleSatisfied(
    BingoAutoRule rule, {
    required EngagementSnapshot engagement,
    required List<Session> plannedSessions,
    required List<Session> allSessions,
    required Set<String> attended,
    required Set<int> marks,
  }) {
    Session? sessionById(String id) {
      for (final s in allSessions) {
        if (s.id == id) return s;
      }
      return null;
    }

    final attendedSessions = attended
        .map(sessionById)
        .whereType<Session>()
        .toList();

    return switch (rule) {
      BingoAutoRule.firstBookmark => plannedSessions.isNotEmpty,
      BingoAutoRule.thirdBookmark => plannedSessions.length >= 3,
      BingoAutoRule.companionQuestion => engagement.companionQuestions >= 1,
      BingoAutoRule.viewFiveDetails => engagement.detailViews >= 5,
      BingoAutoRule.bookmarkGenAi => plannedSessions.any(
        (s) => s.tags.contains('genai') || s.trackId == 'trk-01',
      ),
      BingoAutoRule.attendFeatured => attendedSessions.any((s) => s.featured),
      BingoAutoRule.rateSession => engagement.ratings.isNotEmpty,
      BingoAutoRule.visitFloor7 => engagement.visitedFloors.contains('7'),
      BingoAutoRule.planThreeDay1 =>
        plannedSessions.where((s) => s.day == 'Day 1').length >= 3,
      BingoAutoRule.attendThree => attended.length >= 3,
      BingoAutoRule.bookmarkFeatured => plannedSessions.any((s) => s.featured),
      BingoAutoRule.fiveCompanionQuestions =>
        engagement.companionQuestions >= 5,
      BingoAutoRule.exploreFiveTracks =>
        engagement.todayTracksViewed.toSet().length >= 5 ||
            plannedSessions.map((s) => s.trackId).toSet().length >= 5,
      BingoAutoRule.visitFloor10 => engagement.visitedFloors.contains('10'),
      BingoAutoRule.marathonPlan => plannedSessions.length >= 7,
      BingoAutoRule.earlyBirdBookmark => plannedSessions.any(
        (s) => s.startTime == '09:00',
      ),
      BingoAutoRule.bookmarkCloud => plannedSessions.any(
        (s) => s.tags.contains('cloud') || s.trackId == 'trk-03',
      ),
      BingoAutoRule.attendDay2 => attendedSessions.any((s) => s.day == 'Day 2'),
      BingoAutoRule.bookmarkLeadership => plannedSessions.any(
        (s) =>
            s.tags.contains('leadership') ||
            s.trackId == 'trk-05' ||
            s.trackId == 'trk-06',
      ),
      BingoAutoRule.viewTenDetails => engagement.detailViews >= 10,
      BingoAutoRule.visitFloor13 => engagement.visitedFloors.contains('13'),
      BingoAutoRule.renaissanceTracks =>
        plannedSessions.map((s) => s.trackId).toSet().length >= 5,
      BingoAutoRule.companionCurious => engagement.companionQuestions >= 5,
      BingoAutoRule.floExplorer => engagement.detailViews >= 10,
      BingoAutoRule.blackoutManual => marks.length >= 24,
    };
  }
}
