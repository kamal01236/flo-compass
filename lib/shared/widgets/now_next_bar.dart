import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../../data/services/walking_time_estimator.dart';
import '../../providers/event_provider.dart';
import '../../providers/plan_provider.dart';
import '../theme/app_theme.dart';
import '../a11y/motion_policy.dart';
import '../utils/countdown_format.dart';
import 'event_notification_icon_button.dart';

const _iconTapConstraints = BoxConstraints(minWidth: 44, minHeight: 44);

class NowNextBar extends StatelessWidget {
  NowNextBar({
    super.key,
    this.nowSession,
    this.nextSession,
    required this.event,
    required this.plan,
    this.collapsed = false,
    this.onExpand,
    this.onDirectionsTap,
    this.onSessionTap,
    this.notificationCount,
    this.onNotificationsTap,
    this.onMapTap,
    this.onAskFloTap,
    WalkingTimeEstimator? walkingTimeEstimator,
  }) : _walkingTimeEstimator = walkingTimeEstimator ?? WalkingTimeEstimator();

  final Session? nowSession;
  final Session? nextSession;
  final EventState event;
  final PlanState plan;
  final bool collapsed;
  final VoidCallback? onExpand;
  final VoidCallback? onDirectionsTap;
  final VoidCallback? onSessionTap;
  final int? notificationCount;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onMapTap;
  final VoidCallback? onAskFloTap;
  final WalkingTimeEstimator _walkingTimeEstimator;

  Session? get _displaySession => nowSession ?? nextSession;

  bool get _isNow => nowSession != null;

  bool get _hasTrailingActions =>
      onMapTap != null ||
      onAskFloTap != null ||
      (onNotificationsTap != null && notificationCount != null);

  @override
  Widget build(BuildContext context) {
    final display = _displaySession;
    if (display == null) {
      if (!_hasTrailingActions) {
        return const SizedBox.shrink();
      }
      return _buildActionsOnlyBar(context);
    }

    if (collapsed) {
      return _buildCollapsedBar(context, display);
    }

    final venue = event.venueById(display.venueId);
    final walkMinutes = _walkMinutes(display);
    final countdownLabel = _countdownLabel(display);
    final disableAnimations = !shouldAnimate(context);

    return Semantics(
      button: true,
      label: 'Directions to ${display.title}',
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: InkWell(
          onTap: onDirectionsTap ?? onSessionTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NowNextPill(
                  isNow: _isNow,
                  pulse: _isNow && !disableAnimations,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _sessionInfoColumn(
                    context,
                    display,
                    countdownLabel,
                    venue,
                    walkMinutes,
                  ),
                ),
                if (_hasTrailingActions) ...[
                  const SizedBox(width: 4),
                  _trailingActionsColumn(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sessionInfoColumn(
    BuildContext context,
    Session display,
    String countdownLabel,
    Venue? venue,
    int? walkMinutes,
  ) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          display.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 2),
        Semantics(
          liveRegion: true,
          label: '$countdownLabel · ${display.title}',
          child: Text(
            countdownLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _isNow ? AppColors.accentStart : muted,
              fontSize: 13,
            ),
          ),
        ),
        if (venue != null || walkMinutes != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              if (venue != null)
                Flexible(
                  child: Text(
                    'Floor ${venue.floor} · ${CountdownFormat.wingLabel(venue.wing)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: muted,
                      fontSize: 13,
                    ),
                  ),
                ),
              if (venue != null && walkMinutes != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '·',
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                ),
              if (walkMinutes != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_walk, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '~${walkMinutes}m',
                      maxLines: 1,
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (_walkModeHint(display) != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '· ${_walkModeHint(display)}',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 13,
                          color: muted,
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _trailingActionsColumn(BuildContext context) {
    final actions = _trailingActions(context);
    if (actions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [Row(mainAxisSize: MainAxisSize.min, children: actions)],
    );
  }

  Widget _buildCollapsedBar(BuildContext context, Session display) {
    final countdownLabel = _countdownLabel(display);
    final disableAnimations = !shouldAnimate(context);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      label: '${_isNow ? 'Now' : 'Next'}: ${display.title}',
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: InkWell(
          onTap: onExpand ?? onDirectionsTap ?? onSessionTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NowNextPill(
                  isNow: _isNow,
                  pulse: _isNow && !disableAnimations,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    display.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  liveRegion: true,
                  label: countdownLabel,
                  child: Text(
                    countdownLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _isNow
                          ? AppColors.accentStart
                          : muted,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (_hasTrailingActions) _trailingActionsColumn(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionsOnlyBar(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [_trailingActionsColumn(context)],
          ),
        ),
      ),
    );
  }

  List<Widget> _trailingActions(BuildContext context) {
    final actions = <Widget>[];
    if (onNotificationsTap != null && notificationCount != null) {
      actions.add(
        ConstrainedBox(
          constraints: _iconTapConstraints,
          child: EventNotificationIconButton(
            count: notificationCount!,
            onTap: onNotificationsTap!,
          ),
        ),
      );
    }
    if (onMapTap != null) {
      actions.add(_mapButton(onMapTap!));
    }
    if (onAskFloTap != null) {
      actions.add(_askFloButton(onAskFloTap!));
    }
    return actions;
  }

  Widget _askFloButton(VoidCallback onTap) {
    return Semantics(
      button: true,
      label: 'Ask Flo',
      child: Tooltip(
        message: 'Ask Flo',
        child: IconButton(
          constraints: _iconTapConstraints,
          onPressed: onTap,
          icon: const Icon(Icons.auto_awesome_outlined),
        ),
      ),
    );
  }

  Widget _mapButton(VoidCallback onTap) {
    return Semantics(
      button: true,
      label: 'Map',
      child: Tooltip(
        message: 'Map',
        child: IconButton(
          constraints: _iconTapConstraints,
          onPressed: onTap,
          icon: const Icon(Icons.map_outlined),
        ),
      ),
    );
  }

  String _countdownLabel(Session session) {
    if (_isNow) {
      return CountdownFormat.formatRemaining(event.minutesRemaining(session));
    }
    final until = event.minutesUntil(session);
    return CountdownFormat.formatUntil(
      until,
      now: event.currentTime,
      target: event.sessionStart(session),
    );
  }

  int? _walkMinutes(Session display) {
    final previous = _previousPlannedWithin30Min(display);
    if (previous == null) return null;
    final estimate = _walkingTimeEstimator
        .withContext(
          campus: event.campus,
          isEventDayMode: event.currentDay != null,
        )
        .estimate(
          from: event.venueById(previous.venueId),
          to: event.venueById(display.venueId),
        );
    return estimate.minutes;
  }

  String? _walkModeHint(Session display) {
    final previous = _previousPlannedWithin30Min(display);
    if (previous == null) return null;
    final estimate = _walkingTimeEstimator
        .withContext(
          campus: event.campus,
          isEventDayMode: event.currentDay != null,
        )
        .estimate(
          from: event.venueById(previous.venueId),
          to: event.venueById(display.venueId),
        );
    final mode = estimate.recommendedMode;
    if (mode == null || mode == 'walk') return null;
    return mode == 'stairs' ? 'stairs' : 'lifts';
  }

  Session? _previousPlannedWithin30Min(Session display) {
    final planned = plan.plannedSessions(event.sessions);
    final ordered = [...planned]
      ..sort((a, b) {
        final d = a.dayNumber.compareTo(b.dayNumber);
        if (d != 0) return d;
        return a.startTime.compareTo(b.startTime);
      });

    Session? previous;
    for (final item in ordered) {
      if (item.id == display.id) {
        if (previous == null || previous.day != display.day) return null;
        final gapMinutes = _minutesBetweenEndAndStart(previous, display);
        return gapMinutes <= 30 ? previous : null;
      }
      previous = item;
    }
    return null;
  }

  int _minutesBetweenEndAndStart(Session previous, Session next) {
    final endParts = previous.endTime.split(':');
    final startParts = next.startTime.split(':');
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    final startMinutes =
        int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    return startMinutes - endMinutes;
  }
}

class _NowNextPill extends StatefulWidget {
  const _NowNextPill({required this.isNow, required this.pulse});

  final bool isNow;
  final bool pulse;

  @override
  State<_NowNextPill> createState() => _NowNextPillState();
}

class _NowNextPillState extends State<_NowNextPill>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _startPulseIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _NowNextPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && _controller == null) {
      _startPulseIfNeeded();
    } else if (!widget.pulse) {
      _controller?.dispose();
      _controller = null;
    }
  }

  void _startPulseIfNeeded() {
    if (!widget.pulse) return;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final borderColor = widget.isNow
        ? AppColors.accentStart
        : muted;
    final textColor = widget.isNow
        ? AppColors.accentStart
        : muted;

    return AnimatedBuilder(
      animation: _controller ?? const AlwaysStoppedAnimation(1),
      builder: (context, child) {
        final alpha = widget.pulse
            ? 0.55 + ((_controller?.value ?? 1) * 0.45)
            : 1.0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor.withValues(alpha: alpha),
              width: widget.pulse ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(999),
            color: widget.isNow
                ? AppColors.accentStart.withValues(alpha: 0.15)
                : null,
          ),
          child: child,
        );
      },
      child: Text(
        widget.isNow ? 'NOW' : 'NEXT',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
