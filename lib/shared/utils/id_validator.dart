/// Validates Flo 2026 entity identifiers at repository and import boundaries.
class IdValidator {
  IdValidator._();

  static final RegExp _session = RegExp(r'^s-\d{3,4}$');
  static final RegExp _speaker = RegExp(r'^spk-\d{3}$');
  static final RegExp _venue = RegExp(r'^ven-[A-Z0-9]+$');
  static final RegExp _learningPath = RegExp(r'^path-[a-z0-9-]+$');
  static final RegExp _track = RegExp(r'^trk-\d{2}$');

  static bool isValidSessionId(String id) => _session.hasMatch(id);

  static String? sanitizeSessionId(String id) {
    final trimmed = id.trim();
    return isValidSessionId(trimmed) ? trimmed : null;
  }

  static bool isValidSpeakerId(String id) => _speaker.hasMatch(id);

  static String? sanitizeSpeakerId(String id) =>
      isValidSpeakerId(id) ? id : null;

  static bool isValidVenueId(String id) => _venue.hasMatch(id);

  static String? sanitizeVenueId(String id) => isValidVenueId(id) ? id : null;

  static bool isValidLearningPathId(String id) => _learningPath.hasMatch(id);

  static String? sanitizeLearningPathId(String id) =>
      isValidLearningPathId(id) ? id : null;

  static bool isValidTrackId(String id) => _track.hasMatch(id);

  static String? sanitizeTrackId(String id) => isValidTrackId(id) ? id : null;
}
