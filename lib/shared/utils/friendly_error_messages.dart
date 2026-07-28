import 'dart:math';

enum FriendlyErrorKind {
  loadFailure,
  runtime,
  sessionNotFound,
  speakerNotFound,
  pathNotFound,
  invalidShareLink,
}

class FriendlyErrorCopy {
  const FriendlyErrorCopy({
    required this.title,
    required this.message,
    required this.semanticLabel,
  });

  final String title;
  final String message;
  final String semanticLabel;

  static FriendlyErrorCopy random(FriendlyErrorKind kind, {Random? random}) {
    final pool = _pools[kind]!;
    final rng = random ?? Random();
    return pool[rng.nextInt(pool.length)];
  }
}

const Map<FriendlyErrorKind, List<FriendlyErrorCopy>> _pools = {
  FriendlyErrorKind.loadFailure: [
    FriendlyErrorCopy(
      title: 'The venue Wi-Fi took a coffee break.',
      message: "Flo Compass is still here — tap Retry when you're back online.",
      semanticLabel: 'Error loading event data. Retry available.',
    ),
    FriendlyErrorCopy(
      title: "Flo's data is taking the scenic route through Gurgaon.",
      message: "We couldn't load sessions right now. Retry is safe.",
      semanticLabel: 'Error loading event data. Retry available.',
    ),
    FriendlyErrorCopy(
      title: '640 sessions… just not the bundle we needed.',
      message: "Event data didn't load. Try again in a moment.",
      semanticLabel: 'Error loading event data. Retry available.',
    ),
    FriendlyErrorCopy(
      title: 'The agenda packet got stuck in the elevator.',
      message: "Tap Retry — your saved plan won't be affected.",
      semanticLabel: 'Error loading event data. Retry available.',
    ),
    FriendlyErrorCopy(
      title: 'Mock server is networking in the hallway.',
      message: "Couldn't refresh Flo 2026 data. Please retry.",
      semanticLabel: 'Error loading event data. Retry available.',
    ),
  ],
  FriendlyErrorKind.runtime: [
    FriendlyErrorCopy(
      title: 'Our compass spun north, south, and into the parking lot.',
      message: 'Something unexpected happened. Retry is safe.',
      semanticLabel: 'Unexpected application error. Retry available.',
    ),
    FriendlyErrorCopy(
      title: 'Unscripted moment — not on the official schedule.',
      message: 'The app hit an error. You can retry without losing your plan.',
      semanticLabel: 'Unexpected application error. Retry available.',
    ),
    FriendlyErrorCopy(
      title: 'We tripped over a cable in Ballroom A.',
      message: 'Unexpected error. Tap Retry to continue.',
      semanticLabel: 'Unexpected application error. Retry available.',
    ),
    FriendlyErrorCopy(
      title: 'Plot twist: the UI took an unplanned intermission.',
      message: 'Retry reloads the app safely.',
      semanticLabel: 'Unexpected application error. Retry available.',
    ),
    FriendlyErrorCopy(
      title: 'Even the best demos have a dress rehearsal.',
      message: 'Something broke. Retry should fix it.',
      semanticLabel: 'Unexpected application error. Retry available.',
    ),
  ],
  FriendlyErrorKind.sessionNotFound: [
    FriendlyErrorCopy(
      title: 'This session vanished into one of 640 parallel rooms.',
      message:
          "We couldn't find that session. Head back to Discover or ask Flo.",
      semanticLabel: 'Session not found.',
    ),
    FriendlyErrorCopy(
      title: 'Session not on this floor — or any floor we checked.',
      message: 'That link may be outdated. Try Discover or Companion.',
      semanticLabel: 'Session not found.',
    ),
    FriendlyErrorCopy(
      title: 'GPS for sessions says: recalculating…',
      message: 'Session ID not in Flo 2026 data.',
      semanticLabel: 'Session not found.',
    ),
    FriendlyErrorCopy(
      title: 'That talk may have merged with another track.',
      message: "Couldn't load this session. Browse Discover instead.",
      semanticLabel: 'Session not found.',
    ),
    FriendlyErrorCopy(
      title: 'Lost in the crowd — even for Flo Compass.',
      message: 'Session not found. Back to Discover is one tap away.',
      semanticLabel: 'Session not found.',
    ),
  ],
  FriendlyErrorKind.speakerNotFound: [
    FriendlyErrorCopy(
      title: 'That speaker stepped out for a bio break.',
      message: 'Speaker not in the lineup. Return to Discover.',
      semanticLabel: 'Speaker not found.',
    ),
    FriendlyErrorCopy(
      title: 'Name badge not in our Gurgaon roster.',
      message: "We couldn't find this speaker.",
      semanticLabel: 'Speaker not found.',
    ),
    FriendlyErrorCopy(
      title: "Maybe they're still on slide 1.",
      message: 'Speaker not found — try Discover or search in Companion.',
      semanticLabel: 'Speaker not found.',
    ),
    FriendlyErrorCopy(
      title: "This presenter isn't in the Flo 2026 program.",
      message: 'Check the link or browse speakers from Discover.',
      semanticLabel: 'Speaker not found.',
    ),
    FriendlyErrorCopy(
      title: 'Keynoting in a parallel universe, perhaps.',
      message: 'Speaker ID not recognized.',
      semanticLabel: 'Speaker not found.',
    ),
  ],
  FriendlyErrorKind.pathNotFound: [
    FriendlyErrorCopy(
      title: 'This learning path took a detour.',
      message: 'Path not found. Head back to Discover.',
      semanticLabel: 'Learning path not found.',
    ),
    FriendlyErrorCopy(
      title: 'Curated track wandered off the map.',
      message: "That learning path isn't in Flo 2026 data.",
      semanticLabel: 'Learning path not found.',
    ),
    FriendlyErrorCopy(
      title: 'We lost the thread between sessions.',
      message: "Couldn't load this path — try Discover.",
      semanticLabel: 'Learning path not found.',
    ),
    FriendlyErrorCopy(
      title: 'Self-guided wander — path not listed.',
      message: 'Learning path not found.',
      semanticLabel: 'Learning path not found.',
    ),
    FriendlyErrorCopy(
      title: 'Not in the Flo 2026 booklet.',
      message: 'Return to Discover to browse paths.',
      semanticLabel: 'Learning path not found.',
    ),
  ],
  FriendlyErrorKind.invalidShareLink: [
    FriendlyErrorCopy(
      title: 'That share link looks photocopied one time too many.',
      message: 'Ask your colleague for a fresh link from My Plan.',
      semanticLabel: 'Invalid plan share link.',
    ),
    FriendlyErrorCopy(
      title: "The link survived the group chat; the sessions didn't.",
      message: "Couldn't decode this plan share.",
      semanticLabel: 'Invalid plan share link.',
    ),
    FriendlyErrorCopy(
      title: 'Share link arrived empty-handed.',
      message: 'Invalid or expired share — request a new one.',
      semanticLabel: 'Invalid plan share link.',
    ),
    FriendlyErrorCopy(
      title: 'We unpacked the link and found zero sessions.',
      message: 'Try copying the share link again from My Plan.',
      semanticLabel: 'Invalid plan share link.',
    ),
    FriendlyErrorCopy(
      title: 'Plan teleportation failed.',
      message: "This import link isn't valid.",
      semanticLabel: 'Invalid plan share link.',
    ),
  ],
};
