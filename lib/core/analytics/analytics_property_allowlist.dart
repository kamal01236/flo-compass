/// Allowed custom property keys — blocks PII and high-cardinality free text.
const Set<String> kAnalyticsAllowedPropertyKeys = {
  'step',
  'edit_mode',
  'role',
  'interest_count',
  'attendance_mode',
  'session_id',
  'track_id',
  'source',
  'previous_route',
  'route',
  'question_length_bucket',
  'category',
  'error_type',
  'fatal',
  'action',
  'flag',
  'value',
  'app_version',
  'build_sha',
  'config_profile',
  'platform_role',
  'anonymous_session_key',
};

Map<String, Object?> filterAnalyticsProperties(Map<String, Object?> raw) {
  final filtered = <String, Object?>{};
  for (final entry in raw.entries) {
    if (!kAnalyticsAllowedPropertyKeys.contains(entry.key)) continue;
    final value = entry.value;
    if (value is String && value.length > 200) continue;
    filtered[entry.key] = value;
  }
  return filtered;
}

/// Bucket companion question length without logging the question body.
String questionLengthBucket(int length) {
  if (length <= 20) return 'short';
  if (length <= 80) return 'medium';
  return 'long';
}
