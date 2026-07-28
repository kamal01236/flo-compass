import 'dart:async';

import '../models/models.dart';
import 'leave_now_scheduler.dart';
import '../../shared/utils/web_push.dart';

class LeaveNowNotificationService {
  LeaveNowNotificationService({LeaveNowScheduler? scheduler})
    : _scheduler = scheduler ?? LeaveNowScheduler();

  final LeaveNowScheduler _scheduler;

  void reschedule({
    required List<Session> plannedSessions,
    required List<Venue> venues,
    required bool pushEnabled,
    required DateTime now,
    String? currentDay,
  }) {
    _scheduler.scheduleAll(
      planned: plannedSessions,
      venues: venues,
      currentDay: currentDay,
      notificationsEnabled:
          pushEnabled &&
          isNotificationSupported &&
          isNotificationPermissionGranted,
      onAlert:
          pushEnabled &&
              isNotificationSupported &&
              isNotificationPermissionGranted
          ? (alert) {
              unawaited(
                showLocalNotification(
                  'Leave now',
                  'Head to ${alert.session.title} (${alert.walkMinutes} min walk + $kLeaveNowBufferMinutes min buffer)',
                  tag: 'leave-now-${alert.session.id}',
                ),
              );
            }
          : null,
    );
  }

  void dispose() => _scheduler.dispose();
}
