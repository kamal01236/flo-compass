import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/agenda_alerts_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/profile_provider.dart';

/// Seeds agenda fingerprints on plan/follow changes; scans after agenda refresh.
class AgendaChangeScope extends StatefulWidget {
  const AgendaChangeScope({super.key, required this.child});

  final Widget child;

  @override
  State<AgendaChangeScope> createState() => _AgendaChangeScopeState();
}

class _AgendaChangeScopeState extends State<AgendaChangeScope> {
  bool _listening = false;
  int _lastAgendaRevision = 0;
  late PlanState _plan;
  late EventState _event;
  late ProfileState _profile;
  late AppSettingsState _settings;
  late AgendaAlertsState _agendaAlerts;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_listening) return;
    _listening = true;
    _plan = context.read<PlanState>();
    _event = context.read<EventState>();
    _profile = context.read<ProfileState>();
    _settings = context.read<AppSettingsState>();
    _agendaAlerts = context.read<AgendaAlertsState>();
    _lastAgendaRevision = _event.agendaRevision;
    _plan.addListener(_onPlanOrProfileChanged);
    _profile.addListener(_onPlanOrProfileChanged);
    _event.addListener(_onEventChanged);
  }

  @override
  void dispose() {
    if (_listening) {
      _plan.removeListener(_onPlanOrProfileChanged);
      _profile.removeListener(_onPlanOrProfileChanged);
      _event.removeListener(_onEventChanged);
    }
    super.dispose();
  }

  void _onPlanOrProfileChanged() {
    if (_event.loading || _event.sessions.isEmpty) return;
    unawaited(_seedBaseline());
  }

  void _onEventChanged() {
    if (_event.agendaRevision > _lastAgendaRevision) {
      _lastAgendaRevision = _event.agendaRevision;
      unawaited(_scanForChanges());
    }
  }

  Future<void> _seedBaseline() async {
    if (!mounted || _event.loading || _event.sessions.isEmpty) return;
    await _agendaAlerts.seedBaseline(
      sessions: _event.sessions,
      planSessionIds: _plan.sessionIds,
      followedSpeakerIds: _profile.profile.followedSpeakerIds.toSet(),
    );
  }

  Future<void> _scanForChanges() async {
    if (!mounted || _event.loading || _event.sessions.isEmpty) return;
    await _agendaAlerts.scanForChanges(
      sessions: _event.sessions,
      planSessionIds: _plan.sessionIds,
      followedSpeakerIds: _profile.profile.followedSpeakerIds.toSet(),
      now: _event.currentTime ?? DateTime.now(),
      alertsEnabled: _settings.agendaChangeAlertsEnabled,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Refreshes agenda data and scans for changes — used by the notification sheet.
Future<void> refreshAgendaAndScan(BuildContext context) async {
  final event = context.read<EventState>();
  final plan = context.read<PlanState>();
  final profile = context.read<ProfileState>();
  final settings = context.read<AppSettingsState>();
  final alerts = context.read<AgendaAlertsState>();

  await event.refreshAgenda();
  await alerts.scanForChanges(
    sessions: event.sessions,
    planSessionIds: plan.sessionIds,
    followedSpeakerIds: profile.profile.followedSpeakerIds.toSet(),
    now: event.currentTime ?? DateTime.now(),
    alertsEnabled: settings.agendaChangeAlertsEnabled,
  );
}
