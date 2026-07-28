import '../../core/auth/platform_role.dart';
import '../../domain/entities/audit_actor.dart';
import 'audit_log_service.dart';

export 'audit_log_service.dart' show AuditActions, AuditEvent, AuditLogService;

/// Legacy entry shape kept for backward-compatible reads.
class OpsAuditEntry {
  const OpsAuditEntry({
    required this.action,
    required this.actor,
    required this.timestamp,
    this.entityType,
    this.entityId,
  });

  final String action;
  final String actor;
  final int timestamp;
  final String? entityType;
  final String? entityId;

  factory OpsAuditEntry.fromAuditEvent(AuditEvent event) {
    return OpsAuditEntry(
      action: event.action,
      actor: event.actorLabel,
      timestamp: event.timestamp,
      entityType: event.entityType,
      entityId: event.entityId,
    );
  }

  factory OpsAuditEntry.fromJson(Map<String, dynamic> json) {
    return OpsAuditEntry.fromAuditEvent(AuditEvent.fromJson(json));
  }

  Map<String, dynamic> toJson() => AuditEvent.fromJson({
    'action': action,
    'actor': actor,
    'timestamp': timestamp,
    if (entityType != null) 'entityType': entityType,
    if (entityId != null) 'entityId': entityId,
  }).toJson();
}

/// Thin wrapper over [AuditLogService] for existing ops surfaces.
class OpsAuditService {
  OpsAuditService({AuditLogService? auditLog})
    : _auditLog = auditLog ?? AuditLogService();

  final AuditLogService _auditLog;

  static const maxEntries = AuditLogService.maxEntries;

  Future<List<AuditEvent>> loadRecent() => _auditLog.loadRecent();

  Future<List<OpsAuditEntry>> loadRecentLegacy() async {
    final events = await loadRecent();
    return events.map(OpsAuditEntry.fromAuditEvent).toList();
  }

  Future<void> append({
    required String action,
    required String actor,
    String? entityType,
    String? entityId,
  }) async {
    await _auditLog.record(
      action: action,
      actor: AuditActor(
        id: 'legacy',
        displayName: actor.trim().isEmpty ? 'unknown' : actor.trim(),
        role: PlatformRole.attendee,
      ),
      entityType: entityType,
      entityId: entityId,
    );
  }

  Future<void> record({
    required String action,
    required AuditActor actor,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? metadata,
  }) => _auditLog.record(
    action: action,
    actor: actor,
    entityType: entityType,
    entityId: entityId,
    metadata: metadata,
  );
}
