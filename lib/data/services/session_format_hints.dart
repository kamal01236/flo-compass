/// Format-specific decision hints for session detail overview.
class SessionFormatHints {
  const SessionFormatHints();

  List<String> hintsFor(String format) {
    final lower = format.toLowerCase();
    if (lower.contains('keynote')) {
      return const [
        'Best for orientation and executive context',
        'Arrive early — seating fills quickly',
        'Recording usually available for remote viewers',
      ];
    }
    if (lower.contains('panel')) {
      return const [
        'Bring questions — panels thrive on audience prompts',
        'Multiple perspectives in one slot',
      ];
    }
    if (lower.contains('workshop') || lower.contains('lab')) {
      return const [
        'Hands-on — laptop recommended',
        'Limited seats; plan to stay for the full block',
      ];
    }
    if (lower.contains('lightning')) {
      return const [
        'Quick hits — great between longer sessions',
        'Cafeteria format — informal seating',
      ];
    }
    if (lower.contains('fireside') || lower.contains('ama')) {
      return const [
        'Conversational format — Q&A friendly',
        'Often streamed for remote attendees',
      ];
    }
    if (lower.contains('round')) {
      return const ['Small-group discussion — participate actively'];
    }
    return const ['Check logistics tab for room and walk time'];
  }

  List<String> resourceHintsFor(String format) {
    final lower = format.toLowerCase();
    if (lower.contains('keynote') || lower.contains('panel')) {
      return const ['Slide deck (post-event)', 'Session recording'];
    }
    if (lower.contains('workshop') || lower.contains('lab')) {
      return const ['Lab workbook PDF', 'Starter repo link'];
    }
    return const ['Session summary notes'];
  }
}
