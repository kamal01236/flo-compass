import 'audit_actor.dart';

enum AnnouncementStatus { draft, published, archived }

extension AnnouncementStatusX on AnnouncementStatus {
  String get label => switch (this) {
    AnnouncementStatus.draft => 'Draft',
    AnnouncementStatus.published => 'Published',
    AnnouncementStatus.archived => 'Archived',
  };

  static AnnouncementStatus fromJson(String? raw) {
    return switch (raw) {
      'published' => AnnouncementStatus.published,
      'archived' => AnnouncementStatus.archived,
      _ => AnnouncementStatus.draft,
    };
  }

  String toJson() => name;
}

class OrganizerAnnouncement {
  const OrganizerAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.status,
    required this.createdAt,
    this.publishedAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.publishedBy,
  });

  final String id;
  final String title;
  final String body;
  final AnnouncementStatus status;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final DateTime? updatedAt;
  final AuditActor? createdBy;
  final AuditActor? updatedBy;
  final AuditActor? publishedBy;

  bool get isPublished => status == AnnouncementStatus.published;

  OrganizerAnnouncement copyWith({
    String? id,
    String? title,
    String? body,
    AnnouncementStatus? status,
    DateTime? createdAt,
    DateTime? publishedAt,
    DateTime? updatedAt,
    AuditActor? createdBy,
    AuditActor? updatedBy,
    AuditActor? publishedBy,
  }) {
    return OrganizerAnnouncement(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      publishedBy: publishedBy ?? this.publishedBy,
    );
  }

  factory OrganizerAnnouncement.fromJson(Map<String, dynamic> json) {
    return OrganizerAnnouncement(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      status: AnnouncementStatusX.fromJson(json['status'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      publishedAt: json['publishedAt'] == null
          ? null
          : DateTime.parse(json['publishedAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      createdBy: json['createdBy'] == null
          ? null
          : AuditActor.fromJson(
              Map<String, dynamic>.from(json['createdBy'] as Map),
            ),
      updatedBy: json['updatedBy'] == null
          ? null
          : AuditActor.fromJson(
              Map<String, dynamic>.from(json['updatedBy'] as Map),
            ),
      publishedBy: json['publishedBy'] == null
          ? null
          : AuditActor.fromJson(
              Map<String, dynamic>.from(json['publishedBy'] as Map),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'status': status.toJson(),
      'createdAt': createdAt.toIso8601String(),
      if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (createdBy != null) 'createdBy': createdBy!.toJson(),
      if (updatedBy != null) 'updatedBy': updatedBy!.toJson(),
      if (publishedBy != null) 'publishedBy': publishedBy!.toJson(),
    };
  }
}
