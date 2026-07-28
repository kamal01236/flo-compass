import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/agenda_alerts_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/profile_provider.dart';
import '../utils/event_notifications.dart';

/// Unified notifications bell — always tappable; badge when [count] > 0.
class EventNotificationIconButton extends StatelessWidget {
  const EventNotificationIconButton({
    super.key,
    required this.count,
    required this.onTap,
    this.visualDensity,
  });

  final int count;
  final VoidCallback onTap;
  final VisualDensity? visualDensity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.notificationsBellLabelWithCount(count),
      button: true,
      child: Tooltip(
        message: l10n.notificationsTooltip,
        child: IconButton(
          visualDensity: visualDensity,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: onTap,
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            child: const Icon(Icons.notifications_none),
          ),
        ),
      ),
    );
  }
}

/// AppBar action that resolves live notification counts from providers.
class EventNotificationAppBarAction extends StatelessWidget {
  const EventNotificationAppBarAction({super.key, this.visualDensity});

  final VisualDensity? visualDensity;

  @override
  Widget build(BuildContext context) {
    final event = context.watch<EventState>();
    final plan = context.watch<PlanState>();
    final profileState = context.watch<ProfileState>();
    final settings = context.watch<AppSettingsState>();
    final agendaAlerts = context.watch<AgendaAlertsState>();
    final notifications = resolveLiveEventNotifications(
      event: event,
      plan: plan,
      followedSpeakerIds: profileState.profile.followedSpeakerIds,
      agendaChangeAlerts: agendaAlerts.unreadAlerts,
      agendaChangeAlertsEnabled: settings.agendaChangeAlertsEnabled,
    );

    return EventNotificationIconButton(
      count: notifications.count,
      visualDensity: visualDensity,
      onTap: () => showLiveEventNotificationsSheet(context),
    );
  }
}
