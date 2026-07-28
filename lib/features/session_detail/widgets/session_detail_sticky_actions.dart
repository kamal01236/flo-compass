import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/models/user_profile.dart';
import '../../../data/services/session_detail_assembler.dart';
import '../../../domain/entities/session.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/plan_provider.dart';
import '../../../shared/tour/tour_targets.dart';
import '../../../shared/utils/session_stream_launch.dart';

class SessionDetailStickyActions extends StatelessWidget {
  const SessionDetailStickyActions({
    super.key,
    required this.session,
    required this.viewModel,
    required this.attendanceMode,
    required this.onMarkAttended,
    required this.onAddToCalendar,
  });

  final Session session;
  final SessionDetailViewModel viewModel;
  final AttendanceMode attendanceMode;
  final VoidCallback onMarkAttended;
  final VoidCallback onAddToCalendar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showLeaveNow =
        viewModel.liveState == SessionLiveState.startingSoon &&
        viewModel.inPlan;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            if (showLeaveNow) ...[
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      context.push('/directions?session=${session.id}'),
                  icon: const Icon(Icons.directions_walk),
                  label: Text(l10n.sessionLeaveNow),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              flex: showLeaveNow ? 1 : 2,
              child: _primaryButton(context, l10n),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: l10n.sessionAddToCalendarTooltip,
              button: true,
              child: IconButton.filledTonal(
                tooltip: l10n.sessionAddToCalendarTooltip,
                onPressed: onAddToCalendar,
                icon: const Icon(Icons.calendar_month),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton(BuildContext context, AppLocalizations l10n) {
    final plan = context.read<PlanState>();
    final stream = viewModel.streamAction;

    if (!viewModel.inPlan) {
      return FilledButton(
        key: tourSessionAddToPlanKey,
        onPressed: () => plan.toggle(session.id),
        child: Text(l10n.sessionAddToMyPlan),
      );
    }

    if (viewModel.showStreamPriority && stream.url != null) {
      return FilledButton.icon(
        onPressed: () => launchDemoStream(context, stream.url!),
        icon: const Icon(Icons.live_tv),
        label: Text(l10n.sessionJoinStream),
      );
    }

    final remote = attendanceMode == AttendanceMode.remote;
    if (remote && stream.isStreamable && stream.url != null) {
      return FilledButton.icon(
        onPressed: () => launchDemoStream(context, stream.url!),
        icon: const Icon(Icons.live_tv),
        label: Text(stream.label),
      );
    }

    if (!viewModel.attended) {
      return FilledButton.icon(
        onPressed: onMarkAttended,
        icon: const Icon(Icons.verified),
        label: Text(l10n.sessionMarkAsAttended),
      );
    }

    return FilledButton.icon(
      onPressed: null,
      icon: const Icon(Icons.check),
      label: Text(l10n.sessionAdded),
    );
  }
}

class SessionDetailDesktopActions extends StatelessWidget {
  const SessionDetailDesktopActions({
    super.key,
    required this.session,
    required this.viewModel,
    required this.attendanceMode,
    required this.onMarkAttended,
    required this.onAddToCalendar,
  });

  final Session session;
  final SessionDetailViewModel viewModel;
  final AttendanceMode attendanceMode;
  final VoidCallback onMarkAttended;
  final VoidCallback onAddToCalendar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final plan = context.read<PlanState>();
    final showLeaveNow =
        viewModel.liveState == SessionLiveState.startingSoon &&
        viewModel.inPlan;
    final stream = viewModel.streamAction;

    final buttons = <Widget>[];

    if (showLeaveNow) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => context.push('/directions?session=${session.id}'),
          icon: const Icon(Icons.directions_walk),
          label: Text(l10n.sessionLeaveNow),
        ),
      );
    }

    if (viewModel.showStreamPriority && stream.url != null) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => launchDemoStream(context, stream.url!),
          icon: const Icon(Icons.live_tv),
          label: Text(l10n.sessionJoinStream),
        ),
      );
    } else if (attendanceMode == AttendanceMode.remote &&
        stream.isStreamable &&
        stream.url != null) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => launchDemoStream(context, stream.url!),
          icon: const Icon(Icons.live_tv),
          label: Text(stream.label),
        ),
      );
    }

    if (!viewModel.inPlan) {
      buttons.add(
        FilledButton.icon(
          key: tourSessionAddToPlanKey,
          onPressed: () => plan.toggle(session.id),
          icon: const Icon(Icons.bookmark_outline),
          label: Text(l10n.sessionAddToPlan),
        ),
      );
    } else if (!viewModel.attended &&
        viewModel.liveState != SessionLiveState.live) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: onMarkAttended,
          icon: const Icon(Icons.verified),
          label: Text(l10n.sessionMarkAttended),
        ),
      );
    } else if (viewModel.inPlan && viewModel.attended) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check),
          label: Text(l10n.sessionInPlan),
        ),
      );
    } else if (viewModel.inPlan) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => plan.toggle(session.id),
          icon: const Icon(Icons.bookmark),
          label: Text(l10n.sessionInPlan),
        ),
      );
    }

    buttons.add(
      OutlinedButton.icon(
        onPressed: onAddToCalendar,
        icon: const Icon(Icons.calendar_month),
        label: Text(l10n.sessionAddToCalendar),
      ),
    );

    if (stream.isStreamable &&
        stream.url != null &&
        !viewModel.showStreamPriority &&
        attendanceMode != AttendanceMode.remote) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => launchDemoStream(context, stream.url!),
          icon: const Icon(Icons.live_tv),
          label: Text(stream.label),
        ),
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: buttons);
  }
}
