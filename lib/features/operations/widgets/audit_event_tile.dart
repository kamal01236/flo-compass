import 'package:flutter/material.dart';

import '../../../core/auth/platform_role.dart';
import '../../../data/services/ops_audit_service.dart';
import '../../../domain/entities/audit_actor.dart';

class AuditEventTile extends StatelessWidget {
  const AuditEventTile({super.key, required this.entry});

  final AuditEvent entry;

  @override
  Widget build(BuildContext context) {
    final when = DateTime.fromMillisecondsSinceEpoch(entry.timestamp);
    final stamp =
        '${when.year}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')} '
        '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
    final entityLabel = entry.entityType == null
        ? null
        : entry.entityId == null
        ? entry.entityType
        : '${entry.entityType} · ${entry.entityId}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.rule_folder_outlined),
        title: Text(entry.action),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(stamp, style: const TextStyle(fontSize: 12)),
                AuditActorRoleChip(actor: entry.actor),
              ],
            ),
            if (entityLabel != null) ...[
              const SizedBox(height: 4),
              Text(entityLabel, style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
        isThreeLine: entityLabel != null,
      ),
    );
  }
}

class AuditActorRoleChip extends StatelessWidget {
  const AuditActorRoleChip({super.key, required this.actor});

  final AuditActor actor;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text('${actor.displayName} · ${actor.role.label}'),
      labelStyle: const TextStyle(fontSize: 11),
    );
  }
}
