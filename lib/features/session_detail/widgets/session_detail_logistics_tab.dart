import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/user_profile.dart';
import '../../../data/services/micro_agenda_service.dart';
import '../../../data/services/session_detail_assembler.dart';
import '../../../data/services/walking_time_estimator.dart';
import '../../../domain/entities/plan_conflict.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/entities/venue.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/plan_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/tour/tour_targets.dart';
import '../../../shared/utils/session_stream_launch.dart';
import 'session_detail_a11y_section.dart';
import 'session_detail_related_section.dart';

class SessionDetailLogisticsTab extends StatelessWidget {
  const SessionDetailLogisticsTab({
    super.key,
    required this.session,
    required this.viewModel,
    required this.event,
    required this.plan,
    required this.profile,
    required this.attendanceMode,
    required this.walkEstimate,
    required this.onExportIcs,
    this.bottomScrollPadding = 0,
    this.microAgendaService,
  });

  final Session session;
  final SessionDetailViewModel viewModel;
  final EventState event;
  final PlanState plan;
  final UserProfile profile;
  final AttendanceMode attendanceMode;
  final WalkingTimeEstimate? walkEstimate;
  final VoidCallback onExportIcs;
  final double bottomScrollPadding;
  final MicroAgendaService? microAgendaService;

  @override
  Widget build(BuildContext context) {
    final venue = viewModel.venue;
    final remote = attendanceMode == AttendanceMode.remote;
    final agenda =
        microAgendaService ??
        MicroAgendaService(clockService: event.clockService);
    final upcoming = agenda.nextTwoHours(
      event: event,
      plan: plan,
      profile: profile,
    );
    final showAgenda =
        upcoming.isNotEmpty &&
        (agenda.shouldShowForSession(session) ||
            plan
                .plannedSessions(event.sessions)
                .any(agenda.shouldShowForSession));

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomScrollPadding),
      children: [
        Text(
          '${session.day} · ${session.startTime}–${session.endTime}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          viewModel.timeDisplay,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.circle, size: 10, color: viewModel.capacityColor),
            const SizedBox(width: 6),
            Text(viewModel.capacityLabel),
            const SizedBox(width: 12),
            Text(
              '${viewModel.attendeeInterestCount} saved (demo)',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
        if (viewModel.streamNudge != null) ...[
          const SizedBox(height: 12),
          MaterialBanner(
            backgroundColor: Colors.orange.withValues(alpha: 0.12),
            content: Text(viewModel.streamNudge!.label),
            leading: const Icon(Icons.live_tv, color: Colors.orange),
            actions: [
              if (viewModel.streamAction.url != null)
                TextButton(
                  onPressed: () =>
                      launchDemoStream(context, viewModel.streamAction.url!),
                  child: const Text('Join stream'),
                ),
            ],
          ),
        ],
        if (viewModel.planConflicts.isNotEmpty) ...[
          const SizedBox(height: 16),
          _PlanConflictBanner(
            conflicts: viewModel.planConflicts,
            sessionId: session.id,
            sessionTitle: session.title,
          ),
        ],
        if (showAgenda) ...[
          const SizedBox(height: 20),
          Text(
            'Your next 2 hours',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: upcoming.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = upcoming[index];
                final isCurrent = item.id == session.id;
                return _MicroAgendaMiniCard(
                  session: item,
                  isCurrent: isCurrent,
                  onTap: () => context.replace('/session/${item.id}'),
                );
              },
            ),
          ),
        ],
        if (venue != null && !remote) ...[
          const SizedBox(height: 16),
          _VenueMiniCard(venue: venue),
        ],
        if (walkEstimate != null && !remote) ...[
          const SizedBox(height: 8),
          Text(
            'From previous plan item: ~${walkEstimate!.minutes} min walk (${walkEstimate!.reason})',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
        if (viewModel.streamAction.isStreamable) ...[
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.live_tv, color: AppColors.accentStart),
              title: Text(viewModel.streamAction.label),
              subtitle: viewModel.streamAction.isMock
                  ? const Text('Demo stream — not an official Flo broadcast')
                  : null,
              trailing: viewModel.streamAction.url != null
                  ? const Icon(Icons.open_in_new)
                  : null,
              onTap: viewModel.streamAction.url == null
                  ? null
                  : () =>
                        launchDemoStream(context, viewModel.streamAction.url!),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (!remote) ...[
              OutlinedButton.icon(
                onPressed: () =>
                    context.push('/directions?session=${session.id}'),
                icon: const Icon(Icons.directions_walk),
                label: const Text('Directions'),
              ),
              OutlinedButton.icon(
                key: tourVenueMapButtonKey,
                onPressed: () => context.push('/map?room=${session.venueId}'),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Map'),
              ),
            ],
            OutlinedButton.icon(
              onPressed: onExportIcs,
              icon: const Icon(Icons.calendar_month),
              label: const Text('Add to calendar'),
            ),
          ],
        ),
        if (session.featured) ...[
          const SizedBox(height: 20),
          SessionDetailA11ySection(sessionId: session.id, venue: venue),
        ],
        const SizedBox(height: 20),
        SessionDetailRelatedSection(
          related: viewModel.relatedSessions,
          missed: viewModel.missedAlternatives,
        ),
      ],
    );
  }
}

class _MicroAgendaMiniCard extends StatelessWidget {
  const _MicroAgendaMiniCard({
    required this.session,
    required this.isCurrent,
    required this.onTap,
  });

  final Session session;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        color: isCurrent ? AppColors.accentStart.withValues(alpha: 0.08) : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  session.startTime,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VenueMiniCard extends StatelessWidget {
  const _VenueMiniCard({required this.venue});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(venue.name, style: Theme.of(context).textTheme.titleSmall),
            Text(
              'Floor ${venue.floor} · ${venue.building} · Wing ${venue.wing}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            if (venue.zone.isNotEmpty) Text('Zone: ${venue.zone}'),
            if (venue.landmarks.isNotEmpty)
              Text('Landmarks: ${venue.landmarks.join(', ')}'),
            if (venue.stepFree)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.accessible,
                      size: 16,
                      color: AppColors.accentStart,
                    ),
                    SizedBox(width: 4),
                    Text('Step-free access'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanConflictBanner extends StatelessWidget {
  const _PlanConflictBanner({
    required this.conflicts,
    required this.sessionId,
    required this.sessionTitle,
  });

  final List<PlanConflict> conflicts;
  final String sessionId;
  final String sessionTitle;

  @override
  Widget build(BuildContext context) {
    final conflict = conflicts.first;
    final other = conflict.sessionA.id == sessionId
        ? conflict.sessionB
        : conflict.sessionA;
    return MaterialBanner(
      backgroundColor: Colors.amber.withValues(alpha: 0.12),
      content: Text('Overlaps with "${other.title}" in your plan'),
      leading: const Icon(Icons.warning_amber, color: Colors.amber),
      actions: [
        TextButton(
          onPressed: () => context.push(
            '/companion?q=${Uri.encodeComponent('Resolve plan conflict for $sessionTitle')}&sessionId=$sessionId',
          ),
          child: const Text('Ask Flo to resolve'),
        ),
      ],
    );
  }
}
