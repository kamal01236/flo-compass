import '../models/engagement_snapshot.dart';
import '../models/models.dart';

class TrackPassportProgress {
  const TrackPassportProgress({
    required this.trackId,
    required this.trackName,
    required this.bookmarkedCount,
    required this.attendedCount,
    required this.combinedCount,
    required this.target,
    required this.progress,
  });

  final String trackId;
  final String trackName;
  final int bookmarkedCount;
  final int attendedCount;
  final int combinedCount;
  final int target;
  final double progress;
}

class TrackPassportService {
  static const targetSessions = 3;

  List<TrackPassportProgress> compute({
    required List<Track> tracks,
    required List<Session> plannedSessions,
    required List<Session> allSessions,
    required EngagementSnapshot engagement,
  }) {
    final attendedIds = engagement.attendedSessionIds.toSet();
    final sessionById = {for (final s in allSessions) s.id: s};

    return tracks.map((track) {
      final sessionIds = <String>{};
      var bookmarked = 0;
      for (final s in plannedSessions) {
        if (s.trackId == track.id) {
          sessionIds.add(s.id);
          bookmarked++;
        }
      }
      var attended = 0;
      for (final id in attendedIds) {
        final session = sessionById[id];
        if (session?.trackId == track.id) {
          sessionIds.add(id);
          if (!plannedSessions.any((p) => p.id == id)) attended++;
        }
      }
      final combined = sessionIds.length;
      return TrackPassportProgress(
        trackId: track.id,
        trackName: track.name,
        bookmarkedCount: bookmarked,
        attendedCount: attended,
        combinedCount: combined,
        target: targetSessions,
        progress: (combined / targetSessions).clamp(0.0, 1.0),
      );
    }).toList();
  }
}
