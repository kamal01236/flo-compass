enum FloMeetRoomStatus { draft, published, archived }

enum FloMeetRoomSource { seed, organizer }

extension FloMeetRoomStatusX on FloMeetRoomStatus {
  String get label => switch (this) {
    FloMeetRoomStatus.draft => 'Draft',
    FloMeetRoomStatus.published => 'Published',
    FloMeetRoomStatus.archived => 'Archived',
  };

  static FloMeetRoomStatus fromJson(String? raw) {
    return switch (raw) {
      'published' => FloMeetRoomStatus.published,
      'archived' => FloMeetRoomStatus.archived,
      _ => FloMeetRoomStatus.draft,
    };
  }

  String toJson() => name;
}

extension FloMeetRoomSourceX on FloMeetRoomSource {
  static FloMeetRoomSource fromJson(String? raw) {
    return switch (raw) {
      'organizer' => FloMeetRoomSource.organizer,
      _ => FloMeetRoomSource.seed,
    };
  }

  String toJson() => name;
}

/// A Flo Meets match room (seeded catalog or organizer-created).
class FloMeetRoom {
  const FloMeetRoom({
    required this.id,
    required this.title,
    required this.purposeTags,
    required this.amenityId,
    required this.day,
    required this.windowStart,
    required this.windowEnd,
    required this.capacity,
    this.seedPartnerIds = const [],
    this.status = FloMeetRoomStatus.published,
    this.source = FloMeetRoomSource.seed,
  });

  final String id;
  final String title;
  final List<String> purposeTags;
  final String amenityId;
  final String day;
  final DateTime windowStart;
  final DateTime windowEnd;
  final int capacity;
  final List<String> seedPartnerIds;
  final FloMeetRoomStatus status;
  final FloMeetRoomSource source;

  bool get isPublished => status == FloMeetRoomStatus.published;

  FloMeetRoom copyWith({
    String? id,
    String? title,
    List<String>? purposeTags,
    String? amenityId,
    String? day,
    DateTime? windowStart,
    DateTime? windowEnd,
    int? capacity,
    List<String>? seedPartnerIds,
    FloMeetRoomStatus? status,
    FloMeetRoomSource? source,
  }) {
    return FloMeetRoom(
      id: id ?? this.id,
      title: title ?? this.title,
      purposeTags: purposeTags ?? this.purposeTags,
      amenityId: amenityId ?? this.amenityId,
      day: day ?? this.day,
      windowStart: windowStart ?? this.windowStart,
      windowEnd: windowEnd ?? this.windowEnd,
      capacity: capacity ?? this.capacity,
      seedPartnerIds: seedPartnerIds ?? this.seedPartnerIds,
      status: status ?? this.status,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'purposeTags': purposeTags,
    'amenityId': amenityId,
    'day': day,
    'windowStart': windowStart.toIso8601String(),
    'windowEnd': windowEnd.toIso8601String(),
    'capacity': capacity,
    'seedPartnerIds': seedPartnerIds,
    'status': status.toJson(),
    'source': source.toJson(),
  };

  factory FloMeetRoom.fromJson(Map<String, dynamic> json) {
    return FloMeetRoom(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      purposeTags: (json['purposeTags'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      amenityId: json['amenityId'] as String? ?? '',
      day: json['day'] as String? ?? 'Day 1',
      windowStart: DateTime.parse(json['windowStart'] as String),
      windowEnd: DateTime.parse(json['windowEnd'] as String),
      capacity: json['capacity'] as int? ?? 10,
      seedPartnerIds: (json['seedPartnerIds'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      status: FloMeetRoomStatusX.fromJson(json['status'] as String?),
      source: FloMeetRoomSourceX.fromJson(json['source'] as String?),
    );
  }
}
