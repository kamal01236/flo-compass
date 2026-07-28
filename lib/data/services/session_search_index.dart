import '../../data/models/models.dart';

/// In-memory search index built once after event data loads.
class SessionSearchIndex {
  SessionSearchIndex._({
    required this.sessionIds,
    required this.tokensBySessionId,
    required this.speakerNamesBySessionId,
    required this.trackNamesBySessionId,
  });

  final List<String> sessionIds;
  final Map<String, List<String>> tokensBySessionId;
  final Map<String, List<String>> speakerNamesBySessionId;
  final Map<String, String> trackNamesBySessionId;

  factory SessionSearchIndex.build({
    required List<Session> sessions,
    required List<Speaker> speakers,
    required List<Track> tracks,
  }) {
    final speakerById = {for (final s in speakers) s.id: s};
    final trackById = {for (final t in tracks) t.id: t};
    final tokensBySessionId = <String, List<String>>{};
    final speakerNamesBySessionId = <String, List<String>>{};
    final trackNamesBySessionId = <String, String>{};

    for (final session in sessions) {
      final tokens = <String>{
        session.id.toLowerCase(),
        session.title.toLowerCase(),
        ...session.tags.map((t) => t.toLowerCase()),
      };
      tokensBySessionId[session.id] = tokens.toList();

      speakerNamesBySessionId[session.id] = session.speakerIds
          .map((id) => speakerById[id]?.name.toLowerCase())
          .whereType<String>()
          .toList();

      trackNamesBySessionId[session.id] =
          trackById[session.trackId]?.name.toLowerCase() ?? '';
    }

    return SessionSearchIndex._(
      sessionIds: sessions.map((s) => s.id).toList(),
      tokensBySessionId: tokensBySessionId,
      speakerNamesBySessionId: speakerNamesBySessionId,
      trackNamesBySessionId: trackNamesBySessionId,
    );
  }

  static final empty = SessionSearchIndex._(
    sessionIds: const [],
    tokensBySessionId: const {},
    speakerNamesBySessionId: const {},
    trackNamesBySessionId: const {},
  );

  bool get isReady => sessionIds.isNotEmpty;

  List<String> matchingSessionIds(String query) {
    final lower = query.trim().toLowerCase();
    if (lower.isEmpty) return sessionIds;
    final matches = <String>[];
    for (final id in sessionIds) {
      if (_matchesSession(id, lower)) matches.add(id);
    }
    return matches;
  }

  bool matchesSession(Session session, String query) {
    final lower = query.trim().toLowerCase();
    if (lower.isEmpty) return true;
    return _matchesSession(session.id, lower);
  }

  bool _matchesSession(String sessionId, String lower) {
    final tokens = tokensBySessionId[sessionId] ?? const [];
    for (final token in tokens) {
      if (token.startsWith(lower) || token.contains(lower)) return true;
    }
    for (final name in speakerNamesBySessionId[sessionId] ?? const []) {
      if (name.startsWith(lower) || name.contains(lower)) return true;
    }
    final track = trackNamesBySessionId[sessionId] ?? '';
    if (track.startsWith(lower) || track.contains(lower)) return true;
    return false;
  }
}
