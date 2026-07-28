import '../models/models.dart';

/// Serializes a [CompanionKnowledgePack] into stable-ID text blocks for LLM
/// prompts and post-validation.
class CompanionContextBuilder {
  String build(CompanionKnowledgePack pack, CompanionContext context) {
    final buffer = StringBuffer();
    for (final venue in pack.venues) {
      buffer.writeln(
        'VENUE ${venue.id}: ${venue.name} | wing ${venue.wing} | '
        'floor ${venue.floor} | capacity ${venue.capacity}'
        '${venue.landmarks.isNotEmpty ? ' | landmarks: ${venue.landmarks.join('; ')}' : ''}'
        '${venue.stepFree ? ' | step-free' : ''}',
      );
    }
    for (final session in pack.sessions) {
      buffer.writeln(
        'SESSION ${session.id}: ${session.title} | venue ${session.venueId} | '
        'day ${session.day} ${session.startTime}',
      );
    }
    for (final speaker in pack.speakers) {
      buffer.writeln(
        'SPEAKER ${speaker.id}: ${speaker.name} | ${speaker.title}',
      );
    }
    for (final amenity in pack.amenities) {
      buffer.writeln(
        'AMENITY ${amenity.id}: ${amenity.label} | type ${amenity.type} | '
        'floor ${amenity.floor} wing ${amenity.wing}',
      );
    }
    for (final story in pack.floorStories) {
      buffer.writeln('FLOOR_STORY: $story');
    }
    for (final hint in pack.navigationHints) {
      buffer.writeln('NAV_HINT ${hint.id}: ${hint.text}');
    }
    final plan = pack.planSnapshot;
    if (plan?.nextSession != null) {
      final next = plan!.nextSession!;
      buffer.writeln(
        'PLAN_NEXT: ${next.id} "${next.title}" starts in ${plan.minutesUntilNext ?? '?'} min'
        '${plan.leaveInMinutes != null ? ' | leave in ${plan.leaveInMinutes} min' : ''}'
        '${plan.conflictCount > 0 ? ' | ${plan.conflictCount} conflicts' : ''}',
      );
    }
    if (context.currentDay != null) {
      buffer.writeln('EVENT_CLOCK: ${context.currentDay} at ${context.now}');
    }
    return buffer.toString().trim();
  }
}
