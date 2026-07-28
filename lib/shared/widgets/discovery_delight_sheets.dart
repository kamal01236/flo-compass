import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/models.dart';
import '../../data/services/conflict_detector.dart';
import '../../data/services/day_planner_service.dart';
import '../../providers/context_adapters.dart';
import '../../providers/event_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/profile_provider.dart';
import '../../data/services/walking_time_estimator.dart';
import '../a11y/motion_policy.dart';
import '../theme/app_theme.dart';

Future<void> showBuildAfternoonSheet(BuildContext context) async {
  final event = context.read<EventState>();
  final plan = context.read<PlanState>();
  final profile = context.read<ProfileState>();
  final day = event.currentDay ?? 'Day 1';
  final planner = DayPlannerService(eventClockService: event.clockService);
  final proposed = planner.buildAfternoon(
    buildDayPlannerContext(
      day: day,
      plan: plan,
      event: event,
      profile: profile,
    ),
  );

  if (!context.mounted) return;
  if (proposed.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No open afternoon slots to fill')),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Build my afternoon · $day',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${proposed.length} conflict-free sessions (13:00–17:00)',
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final session in proposed)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(session.title),
                        subtitle: Text(
                          '${session.startTime}–${session.endTime} · ${event.venueById(session.venueId)?.name ?? session.venueId}',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ctx.pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final added = await plan.addSessions(
                          proposed.map((s) => s.id).toList(),
                          event.sessions,
                        );
                        if (ctx.mounted) {
                          ctx.pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added $added sessions to plan'),
                            ),
                          );
                        }
                      },
                      child: const Text('Add all'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showSurpriseSessionModal(
  BuildContext context, {
  required Session session,
  required EventState event,
}) async {
  final disableAnimations = !shouldAnimate(context);
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Surprise session',
    pageBuilder: (ctx, _, _) {
      return _SurpriseSessionDialog(session: session, event: event);
    },
    transitionBuilder: (ctx, animation, _, child) {
      if (disableAnimations) return child;
      return ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: child,
      );
    },
  );
}

class _SurpriseSessionDialog extends StatelessWidget {
  const _SurpriseSessionDialog({required this.session, required this.event});

  final Session session;
  final EventState event;

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<PlanState>();
    final venue = event.venueById(session.venueId);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Material(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.casino_outlined, color: AppColors.accentStart),
                    const SizedBox(width: 8),
                    Text(
                      'Surprise pick',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  session.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  '${session.day} · ${session.startTime} · ${venue?.name ?? session.venueId}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  session.abstract,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          final router = GoRouter.of(context);
                          Navigator.of(context, rootNavigator: true).pop();
                          Future<void>.microtask(
                            () => router.push('/session/${session.id}'),
                          );
                        },
                        child: const Text('Show detail'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _addToPlan(context, plan),
                        child: Text(
                          plan.isInPlan(session.id) ? 'In plan' : 'Add to plan',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addToPlan(BuildContext context, PlanState plan) async {
    if (plan.isInPlan(session.id)) {
      context.pop();
      return;
    }
    final testPlan = [...plan.plannedSessions(event.sessions), session];
    final conflicts = ConflictDetector().findConflicts(testPlan);
    if (conflicts.isNotEmpty && context.mounted) {
      final conflict = conflicts.first;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Schedule conflict'),
          content: Text(
            'Adding "${session.title}" overlaps "${conflict.sessionA.id == session.id ? conflict.sessionB.title : conflict.sessionA.title}". Add anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => ctx.pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => ctx.pop(true),
              child: const Text('Add anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    await plan.toggle(session.id);
    if (context.mounted) context.pop();
  }
}

Future<void> showSwapSimulatorSheet(
  BuildContext context, {
  required PlanConflict conflict,
}) async {
  final event = context.read<EventState>();
  final plan = context.read<PlanState>();
  final profile = context.read<ProfileState>();
  final reco = event.recommendationService;
  final walking = WalkingTimeEstimator();
  final current = conflict.sessionB;
  final proposed = reco.pickSwapAlternative(
    conflictSession: current,
    allSessions: event.sessions,
    speakers: event.speakers,
    tracks: event.tracks,
    profile: profile.profile,
    plannedIds: plan.sessionIds,
    behaviorSnapshot: event.behaviorSnapshot,
  );

  if (proposed == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No swap alternative in this slot')),
    );
    return;
  }

  final currentScore = reco.scoreForSession(
    session: current,
    speakers: event.speakers,
    tracks: event.tracks,
    profile: profile.profile,
    now: event.currentTime,
    behaviorSnapshot: event.behaviorSnapshot,
  );
  final proposedScore = reco.scoreForSession(
    session: proposed,
    speakers: event.speakers,
    tracks: event.tracks,
    profile: profile.profile,
    now: event.currentTime,
    behaviorSnapshot: event.behaviorSnapshot,
  );
  final scoreDelta = proposedScore - currentScore;

  final fromVenue = event.venueById(conflict.sessionA.venueId);
  final toCurrent = event.venueById(current.venueId);
  final toProposed = event.venueById(proposed.venueId);
  final walkCurrent = walking.estimate(from: fromVenue, to: toCurrent).minutes;
  final walkProposed = walking
      .estimate(from: fromVenue, to: toProposed)
      .minutes;
  final walkDelta = walkProposed - walkCurrent;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Swap simulator',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _SwapColumn(
                      label: 'Current',
                      session: current,
                      score: currentScore,
                      walkMin: walkCurrent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SwapColumn(
                      label: 'Proposed',
                      session: proposed,
                      score: proposedScore,
                      walkMin: walkProposed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Interest score ${scoreDelta >= 0 ? '+' : ''}${scoreDelta.toStringAsFixed(1)} · Walk ${walkDelta >= 0 ? '+' : ''}$walkDelta min',
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ctx.pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        if (plan.isInPlan(current.id)) {
                          await plan.toggle(current.id);
                        }
                        if (!plan.isInPlan(proposed.id)) {
                          await plan.toggle(proposed.id);
                        }
                        if (ctx.mounted) ctx.pop();
                      },
                      child: const Text('Confirm swap'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SwapColumn extends StatelessWidget {
  const _SwapColumn({
    required this.label,
    required this.session,
    required this.score,
    required this.walkMin,
  });

  final String label;
  final Session session;
  final double score;
  final int walkMin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Text(session.title, maxLines: 3, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(
          '${session.startTime} · score ${score.toStringAsFixed(1)}',
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        Text(
          'Walk ~$walkMin min',
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
