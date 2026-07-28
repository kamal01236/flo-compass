/// Shared excerpt length for session note previews (recap, Discover, etc.).
const sessionNoteExcerptLength = 80;

String excerptSessionNote(
  String note, {
  int maxLength = sessionNoteExcerptLength,
}) {
  final trimmed = note.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.length <= maxLength) return trimmed;
  return '${trimmed.substring(0, maxLength)}…';
}
