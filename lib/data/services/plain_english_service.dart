import '../models/models.dart';

/// Rule-based plain-English summaries for Discover cards (no LLM).
class PlainEnglishService {
  const PlainEnglishService();

  String summarize(Session session) {
    final format = _formatLabel(session.format);
    final topic = session.tags.isNotEmpty
        ? _topicLabel(session.tags.first)
        : 'general topics';
    final level = _levelLabel(session.level);
    final minutes = _durationMinutes(session);
    return '$format about $topic. $level. $minutes minutes.';
  }

  String _formatLabel(String format) {
    final lower = format.toLowerCase();
    if (lower.contains('lab') || lower.contains('workshop')) {
      return 'Hands-on lab';
    }
    if (lower.contains('panel')) return 'Panel discussion';
    if (lower.contains('lightning')) return 'Quick lightning talk';
    if (lower.contains('keynote')) return 'Keynote talk';
    if (lower.contains('round')) return 'Group discussion';
    return 'Session';
  }

  String _topicLabel(String tag) {
    final key = tag.toLowerCase();
    if (key == 'genai') return 'GenAI';
    if (key == 'ceo_vision') return 'CEO vision';
    return tag
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _levelLabel(String level) {
    final lower = level.toLowerCase();
    if (lower.contains('begin')) return 'Beginner';
    if (lower.contains('inter')) return 'Intermediate';
    if (lower.contains('adv')) return 'Advanced';
    if (lower.contains('exec')) return 'Executive';
    return level.isEmpty ? 'All levels' : level;
  }

  int _durationMinutes(Session session) {
    final start = _parseMinutes(session.startTime);
    final end = _parseMinutes(session.endTime);
    final delta = end - start;
    return delta > 0 ? delta : 60;
  }

  int _parseMinutes(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
