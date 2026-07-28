import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/models.dart';
import '../../providers/agenda_alerts_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/profile_provider.dart';
import 'event_notification_resolver.dart';
import '../widgets/agenda_change_scope.dart';
import '../widgets/event_notifications_sheet.dart';

export 'event_notification_resolver.dart';
export '../widgets/event_notifications_sheet.dart';

EventNotificationSnapshot resolveLiveEventNotifications({
  required EventState event,
  required PlanState plan,
  required List<String> followedSpeakerIds,
  required List<AgendaChangeAlert> agendaChangeAlerts,
  required bool agendaChangeAlertsEnabled,
}) {
  return resolveEventNotifications(
    sessionsStartingSoon30: event.startingSoon(withinMinutes: 30),
    sessionsStartingSoon20: event.startingSoon(withinMinutes: 20),
    plannedSessions: plan.plannedSessions(event.sessions),
    followedSpeakerIds: followedSpeakerIds,
    venues: event.venues,
    minutesUntil: event.minutesUntil,
    now: event.currentTime ?? DateTime.now(),
    currentDay: event.currentDay,
    agendaChangeAlerts: agendaChangeAlerts,
    agendaChangeAlertsEnabled: agendaChangeAlertsEnabled,
  );
}

EventNotificationSnapshot resolveEventNotificationsFromContext(
  BuildContext context,
) {
  final event = context.watch<EventState>();
  final plan = context.watch<PlanState>();
  final profile = context.watch<ProfileState>();
  final settings = context.watch<AppSettingsState>();
  AgendaAlertsState? agendaAlerts;
  try {
    agendaAlerts = context.watch<AgendaAlertsState>();
  } on ProviderNotFoundException {
    agendaAlerts = null;
  }
  return resolveLiveEventNotifications(
    event: event,
    plan: plan,
    followedSpeakerIds: profile.profile.followedSpeakerIds,
    agendaChangeAlerts: agendaAlerts?.unreadAlerts ?? const [],
    agendaChangeAlertsEnabled: settings.agendaChangeAlertsEnabled,
  );
}

Future<void> showLiveEventNotificationsSheet(BuildContext context) {
  final notifications = resolveEventNotificationsFromContext(context);
  final event = context.read<EventState>();
  return showEventNotificationsSheetFromContext(
    context,
    notifications: notifications,
    minutesUntil: event.minutesUntil,
    venueNameFor: (id) => event.venueById(id)?.name,
  );
}

Future<void> showEventNotificationsSheetFromContext(
  BuildContext context, {
  required EventNotificationSnapshot notifications,
  required int Function(Session session) minutesUntil,
  required String? Function(String venueId) venueNameFor,
}) {
  AgendaAlertsState? agendaAlerts;
  try {
    agendaAlerts = context.read<AgendaAlertsState>();
  } on ProviderNotFoundException {
    agendaAlerts = null;
  }
  final settings = context.read<AppSettingsState>();

  return showEventNotificationsSheet(
    context,
    sessionAlerts: notifications.sessionAlerts,
    leaveNowAlerts: notifications.leaveNowAlerts,
    agendaChangeAlerts: notifications.agendaChangeAlerts,
    minutesUntil: minutesUntil,
    venueNameFor: venueNameFor,
    onDismissAgendaAlert:
        agendaAlerts != null && settings.agendaChangeAlertsEnabled
        ? agendaAlerts.dismiss
        : null,
    onRefreshAgenda: agendaAlerts == null
        ? null
        : () => refreshAgendaAndScan(context),
  );
}
