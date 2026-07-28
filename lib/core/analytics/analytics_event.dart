import '../config/build_info.dart';

/// Structured product analytics event (v1 schema).
///
/// Never include email, name, free-text user content, or auth subject.
class AnalyticsEvent {
  AnalyticsEvent({
    required this.name,
    this.properties = const {},
    this.timestamp,
    this.route,
    this.sessionId,
    this.buildSha,
    this.configProfile,
  });

  final String name;
  final Map<String, Object?> properties;
  final DateTime? timestamp;
  final String? route;
  final String? sessionId;
  final String? buildSha;
  final String? configProfile;

  DateTime resolvedTimestamp([DateTime? fallback]) =>
      timestamp ?? fallback ?? DateTime.now();

  Map<String, dynamic> toJson({DateTime? now}) => {
    'name': name,
    'properties': properties,
    'timestamp': resolvedTimestamp(now).toIso8601String(),
    if (route != null) 'route': route,
    if (sessionId != null) 'session_id': sessionId,
    'build_sha': buildSha ?? BuildInfo.buildSha,
    if (configProfile != null) 'config_profile': configProfile,
  };

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      name: json['name'] as String,
      properties: Map<String, Object?>.from(
        (json['properties'] as Map?)?.cast<String, Object?>() ?? {},
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      route: json['route'] as String?,
      sessionId: json['session_id'] as String?,
      buildSha: json['build_sha'] as String?,
      configProfile: json['config_profile'] as String?,
    );
  }
}
