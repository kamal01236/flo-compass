class EngagementSnapshot {
  const EngagementSnapshot({
    required this.xp,
    required this.streakDays,
    required this.achievements,
    required this.attendedSessionIds,
    required this.ratings,
    required this.bingoMarks,
    required this.companionQuestions,
    required this.detailViews,
    this.reactions = const {},
    this.pulseBySessionId = const {},
    this.notesBySessionId = const {},
    this.questProgress = const {},
    this.lastQuestDay,
    this.completedQuestIds = const [],
    this.visitedFloors = const [],
    this.bingoRowBonuses = const [],
    this.todayTracksViewed = const [],
    this.todayBookmarksBeforeNoon = 0,
  });

  final int xp;
  final List<String> streakDays;
  final List<String> achievements;
  final List<String> attendedSessionIds;
  final Map<String, int> ratings;
  final List<int> bingoMarks;
  final int companionQuestions;
  final int detailViews;
  final Map<String, String> reactions;
  final Map<String, String> pulseBySessionId;
  final Map<String, String> notesBySessionId;
  final Map<String, int> questProgress;
  final String? lastQuestDay;
  final List<String> completedQuestIds;
  final List<String> visitedFloors;
  final List<int> bingoRowBonuses;
  final List<String> todayTracksViewed;
  final int todayBookmarksBeforeNoon;

  Map<String, dynamic> toJson() => {
    'xp': xp,
    'streakDays': streakDays,
    'achievements': achievements,
    'attendedSessionIds': attendedSessionIds,
    'ratings': ratings,
    'bingoMarks': bingoMarks,
    'companionQuestions': companionQuestions,
    'detailViews': detailViews,
    'reactions': reactions,
    'pulseBySessionId': pulseBySessionId,
    'notesBySessionId': notesBySessionId,
    'questProgress': questProgress,
    'lastQuestDay': lastQuestDay,
    'completedQuestIds': completedQuestIds,
    'visitedFloors': visitedFloors,
    'bingoRowBonuses': bingoRowBonuses,
    'todayTracksViewed': todayTracksViewed,
    'todayBookmarksBeforeNoon': todayBookmarksBeforeNoon,
  };

  factory EngagementSnapshot.fromJson(Map<String, dynamic> json) {
    return EngagementSnapshot(
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      streakDays: (json['streakDays'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      achievements: (json['achievements'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      attendedSessionIds: (json['attendedSessionIds'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .take(100)
          .toList(),
      ratings: (json['ratings'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
      bingoMarks: (json['bingoMarks'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      companionQuestions: (json['companionQuestions'] as num?)?.toInt() ?? 0,
      detailViews: (json['detailViews'] as num?)?.toInt() ?? 0,
      reactions: (json['reactions'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, value as String),
      ),
      pulseBySessionId:
          (json['pulseBySessionId'] as Map<String, dynamic>? ?? {}).map(
            (key, value) => MapEntry(key, value as String),
          ),
      notesBySessionId: _trimNotesMap(
        (json['notesBySessionId'] as Map<String, dynamic>? ?? {}).map((
          key,
          value,
        ) {
          final text = value as String;
          return MapEntry(
            key,
            text.length > 500 ? text.substring(0, 500) : text,
          );
        }),
      ),
      questProgress: (json['questProgress'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
      lastQuestDay: json['lastQuestDay'] as String?,
      completedQuestIds: (json['completedQuestIds'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      visitedFloors: (json['visitedFloors'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      bingoRowBonuses: (json['bingoRowBonuses'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      todayTracksViewed: (json['todayTracksViewed'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      todayBookmarksBeforeNoon:
          (json['todayBookmarksBeforeNoon'] as num?)?.toInt() ?? 0,
    );
  }

  static Map<String, String> _trimNotesMap(Map<String, String> notes) {
    if (notes.length <= 50) return notes;
    final keys = notes.keys.toList()..sort();
    return {for (final k in keys.skip(keys.length - 50)) k: notes[k]!};
  }

  EngagementSnapshot copyWith({
    int? xp,
    List<String>? streakDays,
    List<String>? achievements,
    List<String>? attendedSessionIds,
    Map<String, int>? ratings,
    List<int>? bingoMarks,
    int? companionQuestions,
    int? detailViews,
    Map<String, String>? reactions,
    Map<String, String>? pulseBySessionId,
    Map<String, String>? notesBySessionId,
    Map<String, int>? questProgress,
    String? lastQuestDay,
    List<String>? completedQuestIds,
    List<String>? visitedFloors,
    List<int>? bingoRowBonuses,
    List<String>? todayTracksViewed,
    int? todayBookmarksBeforeNoon,
  }) {
    return EngagementSnapshot(
      xp: xp ?? this.xp,
      streakDays: streakDays ?? this.streakDays,
      achievements: achievements ?? this.achievements,
      attendedSessionIds: attendedSessionIds ?? this.attendedSessionIds,
      ratings: ratings ?? this.ratings,
      bingoMarks: bingoMarks ?? this.bingoMarks,
      companionQuestions: companionQuestions ?? this.companionQuestions,
      detailViews: detailViews ?? this.detailViews,
      reactions: reactions ?? this.reactions,
      pulseBySessionId: pulseBySessionId ?? this.pulseBySessionId,
      notesBySessionId: notesBySessionId ?? this.notesBySessionId,
      questProgress: questProgress ?? this.questProgress,
      lastQuestDay: lastQuestDay ?? this.lastQuestDay,
      completedQuestIds: completedQuestIds ?? this.completedQuestIds,
      visitedFloors: visitedFloors ?? this.visitedFloors,
      bingoRowBonuses: bingoRowBonuses ?? this.bingoRowBonuses,
      todayTracksViewed: todayTracksViewed ?? this.todayTracksViewed,
      todayBookmarksBeforeNoon:
          todayBookmarksBeforeNoon ?? this.todayBookmarksBeforeNoon,
    );
  }

  static const empty = EngagementSnapshot(
    xp: 0,
    streakDays: [],
    achievements: [],
    attendedSessionIds: [],
    ratings: {},
    bingoMarks: [],
    companionQuestions: 0,
    detailViews: 0,
  );
}
