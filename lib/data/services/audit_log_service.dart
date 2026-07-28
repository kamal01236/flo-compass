import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/auth/platform_role.dart';
import '../../domain/entities/audit_actor.dart';

/// Canonical action identifiers for structured audit logging.
abstract final class AuditActions {
  static const qaAsk = 'qa.ask';
  static const qaReply = 'qa.reply';
  static const qaUpvote = 'qa.upvote';
  static const qaUnupvote = 'qa.unupvote';
  static const qaMarkAnswered = 'qa.mark_answered';
  static const qaMarkUnanswered = 'qa.mark_unanswered';
  static const qaPin = 'qa.pin';
  static const qaUnpin = 'qa.unpin';
  static const qaHide = 'qa.hide';
  static const qaUnhide = 'qa.unhide';

  static const planToggle = 'plan.toggle';
  static const planClear = 'plan.clear';

  static const profileReset = 'profile.reset';

  static const consentAccept = 'consent.accept';
  static const consentDecline = 'consent.decline';

  static const announcementDraftSave = 'announcement.draft_save';
  static const announcementDelete = 'announcement.delete';
  static const announcementPublish = 'announcement.publish';
  static const announcementArchive = 'announcement.archive';

  static const qaPromptSave = 'qa_prompt.save';
  static const qaPromptReset = 'qa_prompt.reset';

  static const opsAllowlistsUpdate = 'ops.allowlists.update';
}

/// Structured audit event persisted locally for organizer/admin review.
class AuditEvent {
  const AuditEvent({
    required this.action,
    required this.actor,
    required this.timestamp,
    this.entityType,
    this.entityId,
    this.metadata,
  });

  final String action;
  final AuditActor actor;
  final int timestamp;
  final String? entityType;
  final String? entityId;
  final Map<String, dynamic>? metadata;

  String get actorLabel => actor.displayName;

  Map<String, dynamic> toJson() => {
    'action': action,
    'actor': actor.toJson(),
    'timestamp': timestamp,
    if (entityType != null) 'entityType': entityType,
    if (entityId != null) 'entityId': entityId,
    if (metadata != null && metadata!.isNotEmpty) 'metadata': metadata,
  };

  factory AuditEvent.fromJson(Map<String, dynamic> json) {
    final actorRaw = json['actor'];
    final AuditActor actor;
    if (actorRaw is Map) {
      actor = AuditActor.fromJson(Map<String, dynamic>.from(actorRaw));
    } else {
      actor = AuditActor(
        id: 'legacy',
        displayName: actorRaw?.toString() ?? 'unknown',
        role: PlatformRole.attendee,
      );
    }
    return AuditEvent(
      action: json['action'] as String? ?? '',
      actor: actor,
      timestamp: json['timestamp'] as int? ?? 0,
      entityType: json['entityType'] as String?,
      entityId: json['entityId'] as String?,
      metadata: json['metadata'] == null
          ? null
          : Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }
}

class AuditLogService {
  AuditLogService({SharedPreferences? prefs}) : _prefs = prefs;

  static const _storageKey = 'flo_compass_ops_audit';
  static const maxEntries = 100;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _storage async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<AuditEvent>> loadRecent() async {
    final prefs = await _storage;
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => AuditEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> record({
    required String action,
    required AuditActor actor,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? metadata,
  }) async {
    if (action.trim().isEmpty) return;
    final prefs = await _storage;
    final existing = await loadRecent();
    final entry = AuditEvent(
      action: action.trim(),
      actor: actor,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      entityType: entityType,
      entityId: entityId,
      metadata: metadata,
    );
    final updated = [entry, ...existing].take(maxEntries).toList();
    await prefs.setString(
      _storageKey,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }
}
