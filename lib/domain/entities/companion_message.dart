import 'companion_navigation.dart';

export 'companion_navigation.dart';

class CompanionMessage {
  const CompanionMessage({
    required this.text,
    this.sessionIds = const [],
    this.usedLlm = false,
    this.followUps = const [],
    this.referencedSessionId,
    this.referencedTrack,
    this.referencedVenueId,
    this.referencedAmenityId,
    this.venueIds = const [],
    this.amenityIds = const [],
    this.navigationAction = CompanionNavigationAction.none,
    this.sources = const [],
  });

  final String text;
  final List<String> sessionIds;
  final bool usedLlm;
  final List<String> followUps;
  final String? referencedSessionId;
  final String? referencedTrack;
  final String? referencedVenueId;
  final String? referencedAmenityId;
  final List<String> venueIds;
  final List<String> amenityIds;
  final CompanionNavigationAction navigationAction;
  final List<CompanionSource> sources;
}
