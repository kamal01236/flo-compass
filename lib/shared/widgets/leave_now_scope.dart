import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/leave_now_notification_service.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/plan_provider.dart';

class LeaveNowScope extends StatefulWidget {
  const LeaveNowScope({super.key, required this.child});

  final Widget child;

  @override
  State<LeaveNowScope> createState() => _LeaveNowScopeState();
}

class _LeaveNowScopeState extends State<LeaveNowScope> {
  late final LeaveNowNotificationService _service;
  bool _initialized = false;
  bool _listening = false;
  late PlanState _plan;
  late EventState _event;
  late AppSettingsState _settings;

  @override
  void initState() {
    super.initState();
    _service = LeaveNowNotificationService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_listening) return;
    _listening = true;
    _plan = context.read<PlanState>();
    _event = context.read<EventState>();
    _settings = context.read<AppSettingsState>();
    _plan.addListener(_syncSchedules);
    _event.addListener(_syncSchedules);
    _settings.addListener(_syncSchedules);
    _initialized = true;
    _syncSchedules();
  }

  @override
  void dispose() {
    if (_listening) {
      _plan.removeListener(_syncSchedules);
      _event.removeListener(_syncSchedules);
      _settings.removeListener(_syncSchedules);
    }
    _service.dispose();
    super.dispose();
  }

  void _syncSchedules() {
    if (!_initialized) return;
    _service.reschedule(
      plannedSessions: _plan.plannedSessions(_event.sessions),
      venues: _event.venues,
      pushEnabled: _settings.leaveNowPushEnabled,
      now: _event.currentTime ?? DateTime.now(),
      currentDay: _event.currentDay,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
