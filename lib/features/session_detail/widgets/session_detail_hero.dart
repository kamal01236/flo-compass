import 'package:flutter/material.dart';

import '../../../data/models/user_profile.dart';
import '../../../data/services/session_detail_assembler.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/entities/track.dart';
import '../../../shared/a11y/motion_policy.dart';
import '../../../shared/theme/app_theme.dart';

class SessionDetailHero extends StatelessWidget {
  const SessionDetailHero({
    super.key,
    required this.session,
    required this.viewModel,
    this.track,
    this.attendanceMode = AttendanceMode.onSite,
    this.onShare,
    this.desktopActions,
  });

  final Session session;
  final SessionDetailViewModel viewModel;
  final Track? track;
  final AttendanceMode attendanceMode;
  final VoidCallback? onShare;
  final Widget? desktopActions;

  @override
  Widget build(BuildContext context) {
    final trackColor = AppTheme.colorForTrack(track?.id ?? session.trackId);
    final remote = attendanceMode == AttendanceMode.remote;
    final showCoWatch =
        remote &&
        viewModel.liveState == SessionLiveState.live &&
        viewModel.streamAction.isStreamable &&
        viewModel.coWatchCount != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _LiveStateBadge(state: viewModel.liveState),
            Chip(
              label: Text(session.format),
              visualDensity: VisualDensity.compact,
            ),
            if (session.featured)
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: AppColors.accentStart, size: 18),
                  SizedBox(width: 4),
                  Text('Featured'),
                ],
              ),
            if (onShare != null)
              Semantics(
                label: 'Copy session link',
                button: true,
                child: IconButton(
                  tooltip: 'Copy link',
                  onPressed: onShare,
                  icon: const Icon(Icons.link),
                ),
              ),
          ],
        ),
        if (showCoWatch) ...[
          const SizedBox(height: 6),
          Text(
            '~${viewModel.coWatchCount} watching (demo)',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
        const SizedBox(height: 8),
        Text(session.title, style: Theme.of(context).textTheme.headlineSmall),
        if (viewModel.dayTheme != null) ...[
          const SizedBox(height: 6),
          Text(
            viewModel.dayTheme!,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
        if (desktopActions != null) ...[
          const SizedBox(height: 12),
          desktopActions!,
        ],
      ],
    );
  }
}

class _LiveStateBadge extends StatefulWidget {
  const _LiveStateBadge({required this.state});

  final SessionLiveState state;

  @override
  State<_LiveStateBadge> createState() => _LiveStateBadgeState();
}

class _LiveStateBadgeState extends State<_LiveStateBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _LiveStateBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _syncPulse();
    }
  }

  void _syncPulse() {
    final isLive = widget.state == SessionLiveState.live;
    if (isLive) {
      _pulse ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat(reverse: true);
    } else {
      _pulse?.dispose();
      _pulse = null;
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (widget.state) {
      SessionLiveState.live => ('LIVE', Colors.redAccent, Icons.sensors),
      SessionLiveState.startingSoon => (
        'Starting soon',
        AppColors.accentStart,
        Icons.schedule,
      ),
      SessionLiveState.ended => (
        'Ended',
        Theme.of(context).colorScheme.onSurfaceVariant,
        Icons.check_circle,
      ),
      SessionLiveState.upcoming => (
        'Upcoming',
        Theme.of(context).colorScheme.onSurfaceVariant,
        Icons.event,
      ),
    };

    final animate =
        widget.state == SessionLiveState.live &&
        shouldAnimate(context) &&
        _pulse != null;

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: animate ? 0.12 + (_pulse!.value * 0.12) : 0.15,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(
            alpha: animate ? 0.5 + (_pulse!.value * 0.3) : 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );

    if (animate) {
      badge = AnimatedBuilder(
        animation: _pulse!,
        builder: (context, child) => child!,
        child: badge,
      );
    }

    return badge;
  }
}
