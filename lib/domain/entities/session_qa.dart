import 'audit_actor.dart';

class SessionQaModerationOverride {
  const SessionQaModerationOverride({
    this.answered,
    this.pinned,
    this.hidden,
    this.moderatedBy,
    this.moderatedAt,
    this.moderationAction,
  });

  final bool? answered;
  final bool? pinned;
  final bool? hidden;
  final AuditActor? moderatedBy;
  final DateTime? moderatedAt;
  final String? moderationAction;

  SessionQaModerationOverride copyWith({
    bool? answered,
    bool? pinned,
    bool? hidden,
    AuditActor? moderatedBy,
    DateTime? moderatedAt,
    String? moderationAction,
  }) {
    return SessionQaModerationOverride(
      answered: answered ?? this.answered,
      pinned: pinned ?? this.pinned,
      hidden: hidden ?? this.hidden,
      moderatedBy: moderatedBy ?? this.moderatedBy,
      moderatedAt: moderatedAt ?? this.moderatedAt,
      moderationAction: moderationAction ?? this.moderationAction,
    );
  }

  factory SessionQaModerationOverride.fromJson(Map<String, dynamic> json) {
    return SessionQaModerationOverride(
      answered: json['answered'] as bool?,
      pinned: json['pinned'] as bool?,
      hidden: json['hidden'] as bool?,
      moderatedBy: json['moderatedBy'] == null
          ? null
          : AuditActor.fromJson(
              Map<String, dynamic>.from(json['moderatedBy'] as Map),
            ),
      moderatedAt: json['moderatedAt'] == null
          ? null
          : DateTime.parse(json['moderatedAt'] as String),
      moderationAction: json['moderationAction'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (answered != null) 'answered': answered,
      if (pinned != null) 'pinned': pinned,
      if (hidden != null) 'hidden': hidden,
      if (moderatedBy != null) 'moderatedBy': moderatedBy!.toJson(),
      if (moderatedAt != null) 'moderatedAt': moderatedAt!.toIso8601String(),
      if (moderationAction != null) 'moderationAction': moderationAction,
    };
  }
}

class SessionQaPromptOverride {
  const SessionQaPromptOverride({
    required this.prompts,
    this.updatedBy,
    this.updatedAt,
  });

  final List<String> prompts;
  final AuditActor? updatedBy;
  final DateTime? updatedAt;

  SessionQaPromptOverride copyWith({
    List<String>? prompts,
    AuditActor? updatedBy,
    DateTime? updatedAt,
  }) {
    return SessionQaPromptOverride(
      prompts: prompts ?? this.prompts,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory SessionQaPromptOverride.fromJson(dynamic json) {
    if (json is List) {
      return SessionQaPromptOverride(
        prompts: json.whereType<String>().toList(),
      );
    }
    final map = json is Map<String, dynamic>
        ? json
        : Map<String, dynamic>.from(json as Map);
    return SessionQaPromptOverride(
      prompts: (map['prompts'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      updatedBy: map['updatedBy'] == null
          ? null
          : AuditActor.fromJson(
              Map<String, dynamic>.from(map['updatedBy'] as Map),
            ),
      updatedAt: map['updatedAt'] == null
          ? null
          : DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'prompts': prompts,
    if (updatedBy != null) 'updatedBy': updatedBy!.toJson(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };
}

class SessionQuestion {
  const SessionQuestion({
    required this.id,
    required this.sessionId,
    required this.authorName,
    required this.question,
    required this.createdAt,
    required this.upvotes,
    required this.replies,
    required this.answered,
    this.authorId,
    this.viewerHasUpvoted = false,
    this.pinned = false,
    this.hidden = false,
    this.moderatedBy,
    this.moderatedAt,
    this.moderationAction,
  });

  final String id;
  final String sessionId;
  final String authorName;
  final String? authorId;
  final String question;
  final DateTime createdAt;
  final int upvotes;
  final List<SessionReply> replies;
  final bool answered;
  final bool viewerHasUpvoted;
  final bool pinned;
  final bool hidden;
  final AuditActor? moderatedBy;
  final DateTime? moderatedAt;
  final String? moderationAction;

  int get replyCount => replies.length;

  SessionQuestion copyWith({
    String? id,
    String? sessionId,
    String? authorName,
    String? authorId,
    String? question,
    DateTime? createdAt,
    int? upvotes,
    List<SessionReply>? replies,
    bool? answered,
    bool? viewerHasUpvoted,
    bool? pinned,
    bool? hidden,
    AuditActor? moderatedBy,
    DateTime? moderatedAt,
    String? moderationAction,
  }) {
    return SessionQuestion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      authorName: authorName ?? this.authorName,
      authorId: authorId ?? this.authorId,
      question: question ?? this.question,
      createdAt: createdAt ?? this.createdAt,
      upvotes: upvotes ?? this.upvotes,
      replies: replies ?? this.replies,
      answered: answered ?? this.answered,
      viewerHasUpvoted: viewerHasUpvoted ?? this.viewerHasUpvoted,
      pinned: pinned ?? this.pinned,
      hidden: hidden ?? this.hidden,
      moderatedBy: moderatedBy ?? this.moderatedBy,
      moderatedAt: moderatedAt ?? this.moderatedAt,
      moderationAction: moderationAction ?? this.moderationAction,
    );
  }

  factory SessionQuestion.fromJson(Map<String, dynamic> json) {
    final replies = (json['replies'] as List<dynamic>? ?? [])
        .map((e) => SessionReply.fromJson(e as Map<String, dynamic>))
        .toList();
    return SessionQuestion(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      authorName: (json['authorName'] as String?) ?? 'Anonymous',
      authorId: json['authorId'] as String?,
      question: json['question'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
      replies: replies,
      answered: json['answered'] as bool? ?? replies.isNotEmpty,
      pinned: json['pinned'] as bool? ?? false,
      hidden: json['hidden'] as bool? ?? false,
      moderatedBy: json['moderatedBy'] == null
          ? null
          : AuditActor.fromJson(json['moderatedBy'] as Map<String, dynamic>),
      moderatedAt: json['moderatedAt'] == null
          ? null
          : DateTime.parse(json['moderatedAt'] as String),
      moderationAction: json['moderationAction'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'authorName': authorName,
      if (authorId != null) 'authorId': authorId,
      'question': question,
      'createdAt': createdAt.toIso8601String(),
      'upvotes': upvotes,
      'answered': answered,
      'pinned': pinned,
      'hidden': hidden,
      if (moderatedBy != null) 'moderatedBy': moderatedBy!.toJson(),
      if (moderatedAt != null) 'moderatedAt': moderatedAt!.toIso8601String(),
      if (moderationAction != null) 'moderationAction': moderationAction,
      'replies': replies.map((e) => e.toJson()).toList(),
    };
  }
}

class SessionReply {
  const SessionReply({
    required this.id,
    required this.questionId,
    required this.authorName,
    required this.message,
    required this.createdAt,
    this.authorId,
    this.fromFlo = false,
  });

  final String id;
  final String questionId;
  final String authorName;
  final String? authorId;
  final String message;
  final DateTime createdAt;
  final bool fromFlo;

  SessionReply copyWith({
    String? id,
    String? questionId,
    String? authorName,
    String? authorId,
    String? message,
    DateTime? createdAt,
    bool? fromFlo,
  }) {
    return SessionReply(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      authorName: authorName ?? this.authorName,
      authorId: authorId ?? this.authorId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      fromFlo: fromFlo ?? this.fromFlo,
    );
  }

  factory SessionReply.fromJson(Map<String, dynamic> json) {
    return SessionReply(
      id: json['id'] as String,
      questionId: json['questionId'] as String,
      authorName: (json['authorName'] as String?) ?? 'Flo',
      authorId: json['authorId'] as String?,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      fromFlo: json['fromFlo'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionId': questionId,
      'authorName': authorName,
      if (authorId != null) 'authorId': authorId,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'fromFlo': fromFlo,
    };
  }
}

class SessionQaBundle {
  const SessionQaBundle({required this.prompts, required this.questions});

  final List<String> prompts;
  final List<SessionQuestion> questions;
}
