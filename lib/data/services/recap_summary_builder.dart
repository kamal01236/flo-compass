import '../../providers/engagement_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/plan_provider.dart';
import '../../shared/utils/session_note_excerpt.dart';

class RecapNoteExcerpt {
  const RecapNoteExcerpt({
    required this.sessionId,
    required this.title,
    required this.excerpt,
  });

  final String sessionId;
  final String title;
  final String excerpt;
}

class RecapSummary {
  const RecapSummary({
    required this.plannedSessionTitles,
    required this.attendedCount,
    required this.worthItSessions,
    required this.noteExcerpts,
  });

  final List<String> plannedSessionTitles;
  final int attendedCount;
  final List<String> worthItSessions;
  final List<RecapNoteExcerpt> noteExcerpts;

  String toText({String eventName = 'Flo Compass'}) {
    final buffer = StringBuffer()
      ..writeln('$eventName — Personal recap')
      ..writeln()
      ..writeln('Planned sessions (${plannedSessionTitles.length}):');
    for (final title in plannedSessionTitles.take(5)) {
      buffer.writeln('  • $title');
    }
    if (plannedSessionTitles.length > 5) {
      buffer.writeln('  … and ${plannedSessionTitles.length - 5} more');
    }
    buffer
      ..writeln()
      ..writeln('Attended: $attendedCount sessions');
    if (worthItSessions.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Worth it:');
      for (final title in worthItSessions) {
        buffer.writeln('  • $title');
      }
    }
    if (noteExcerpts.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Session notes:');
      for (final note in noteExcerpts) {
        buffer.writeln('  • ${note.title}: ${note.excerpt}');
      }
    }
    return buffer.toString();
  }
}

class RecapSummaryBuilder {
  static const _maxNotes = 3;

  RecapSummary build({
    required EngagementState engagement,
    required EventState event,
    required PlanState plan,
  }) {
    final planned = plan.plannedSessions(event.sessions);
    final titles = planned.map((s) => s.title).toList();

    final worthIt = <String>[];
    engagement.pulseBySessionId.forEach((sessionId, pulse) {
      if (pulse != 'worth_it') return;
      final session = event.sessionById(sessionId);
      if (session != null) worthIt.add(session.title);
    });

    final notes = <RecapNoteExcerpt>[];
    engagement.notesBySessionId.forEach((sessionId, note) {
      final trimmed = note.trim();
      if (trimmed.isEmpty) return;
      final session = event.sessionById(sessionId);
      if (session == null) return;
      final excerpt = excerptSessionNote(trimmed);
      notes.add(
        RecapNoteExcerpt(
          sessionId: sessionId,
          title: session.title,
          excerpt: excerpt,
        ),
      );
    });
    notes.sort((a, b) => a.title.compareTo(b.title));

    return RecapSummary(
      plannedSessionTitles: titles,
      attendedCount: engagement.attendedSessionIds.length,
      worthItSessions: worthIt,
      noteExcerpts: notes.take(_maxNotes).toList(),
    );
  }
}
