import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models.dart';
import '../../data/services/agenda_change_detector.dart';
import '../../data/services/leave_now_scheduler.dart';
import '../../l10n/app_localizations.dart';
import '../utils/agenda_change_messages.dart';
import '../utils/event_notification_resolver.dart';
import 'map_chip_button.dart';

Future<void> showEventNotificationsSheet(
  BuildContext context, {
  List<AgendaChangeAlert> agendaChangeAlerts = const [],
  required List<SessionNotificationAlert> sessionAlerts,
  required List<LeaveNowAlert> leaveNowAlerts,
  required int Function(Session session) minutesUntil,
  required String? Function(String venueId) venueNameFor,
  void Function(String alertId)? onDismissAgendaAlert,
  Future<void> Function()? onRefreshAgenda,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx);
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text(l10n.notificationsTitle)),
            if (agendaChangeAlerts.isEmpty &&
                leaveNowAlerts.isEmpty &&
                sessionAlerts.isEmpty)
              ListTile(
                title: Text(l10n.notificationsEmpty),
                subtitle: Text(l10n.notificationsEmptySubtitle),
              ),
            for (final alert in agendaChangeAlerts)
              ListTile(
                leading: Icon(switch (alert.type) {
                  AgendaChangeType.roomChanged => Icons.meeting_room_outlined,
                  AgendaChangeType.timeChanged => Icons.schedule,
                  AgendaChangeType.cancelled => Icons.event_busy,
                }, color: Colors.orangeAccent),
                title: Text(agendaChangeAlertTitle(alert)),
                subtitle: Text(
                  agendaChangeAlertSubtitle(alert, venueNameFor: venueNameFor),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(agendaChangeReasonLabel(alert.reason)),
                      visualDensity: VisualDensity.compact,
                    ),
                    if (onDismissAgendaAlert != null)
                      IconButton(
                        tooltip: l10n.notificationsDismiss,
                        icon: const Icon(Icons.close),
                        onPressed: () => onDismissAgendaAlert(alert.id),
                      ),
                  ],
                ),
                onTap: alert.type == AgendaChangeType.cancelled
                    ? null
                    : () {
                        Navigator.of(ctx).pop();
                        if (alert.type == AgendaChangeType.roomChanged) {
                          context.push(
                            '/directions?session=${alert.sessionId}',
                          );
                        } else {
                          context.push('/session/${alert.sessionId}');
                        }
                      },
              ),
            for (final alert in leaveNowAlerts)
              ListTile(
                leading: const Icon(Icons.directions_walk, color: Colors.amber),
                title: Text('Leave now for ${alert.session.title}'),
                subtitle: Text(
                  '${alert.walkMinutes} min walk + $kLeaveNowBufferMinutes min buffer',
                ),
                trailing: MapChipButton(
                  venueId: alert.session.venueId,
                  venueName:
                      venueNameFor(alert.session.venueId) ??
                      alert.session.venueId,
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push('/directions?session=${alert.session.id}');
                },
              ),
            for (final alert in sessionAlerts)
              ListTile(
                title: Text(alert.session.title),
                subtitle: Text('Starts in ${minutesUntil(alert.session)} min'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (alert.isFollowing)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Chip(
                          label: Text('Following'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    if (alert.isInPlan)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Chip(
                          label: Text('In plan'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    MapChipButton(
                      venueId: alert.session.venueId,
                      venueName:
                          venueNameFor(alert.session.venueId) ??
                          alert.session.venueId,
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push('/session/${alert.session.id}');
                },
              ),
            if (onRefreshAgenda != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await onRefreshAgenda();
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.notificationsRefreshAgenda),
                ),
              ),
          ],
        ),
      );
    },
  );
}
