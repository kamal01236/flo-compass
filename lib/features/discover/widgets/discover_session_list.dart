import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/models.dart';
import '../../../providers/engagement_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/plan_provider.dart';
import '../../../shared/a11y/motion_policy.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/countdown_format.dart';

class DiscoverLoadMoreButton extends StatelessWidget {
  const DiscoverLoadMoreButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: OutlinedButton(
          onPressed: onPressed,
          child: const Text('Load more'),
        ),
      ),
    );
  }
}

class DiscoverDailyQuestCard extends StatelessWidget {
  const DiscoverDailyQuestCard({
    super.key,
    required this.engagement,
    required this.event,
  });

  final EngagementState engagement;
  final EventState event;

  @override
  Widget build(BuildContext context) {
    final quests = engagement.dailyQuests(event.currentDay);
    final completed = quests.where((q) => q.completed).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          'Daily quests ($completed/${quests.length} done)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: quests.isEmpty
            ? null
            : Text(
                quests.first.title,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
        children: [
          for (final quest in quests) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quest.title, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: quest.target == 0
                        ? 0
                        : (quest.current / quest.target).clamp(0, 1),
                    color: quest.completed ? AppColors.accentStart : null,
                  ),
                  Text(
                    quest.completed
                        ? 'Complete · +30 XP'
                        : '${quest.current}/${quest.target}',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DiscoverLiveStrip extends StatelessWidget {
  const DiscoverLiveStrip({
    super.key,
    required this.event,
    required this.sessions,
    required this.title,
    this.pulse = false,
    this.showRemaining = false,
    required this.onSessionTap,
  });

  final EventState event;
  final List<Session> sessions;
  final String title;
  final bool pulse;
  final bool showRemaining;
  final ValueChanged<String> onSessionTap;

  @override
  Widget build(BuildContext context) {
    final visibleSessions = showRemaining
        ? sessions
              .where((session) => event.minutesRemaining(session) > 0)
              .toList()
        : sessions;
    if (visibleSessions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (pulse) ...[
                  const SizedBox(width: 8),
                  const DiscoverLivePulseDot(),
                ],
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final session in visibleSessions.take(8))
                  GestureDetector(
                    onTap: () => onSessionTap(session.id),
                    child: Container(
                      width: 260,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: pulse
                              ? AppColors.accentStart.withValues(alpha: 0.7)
                              : AppColors.accentStart.withValues(alpha: 0.4),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accentStart.withValues(alpha: 0.14),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            session.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            showRemaining
                                ? CountdownFormat.formatRemaining(
                                    event.minutesRemaining(session),
                                  )
                                : CountdownFormat.formatUntil(
                                    event.minutesUntil(session),
                                    now: event.currentTime,
                                    target: event.sessionStart(session),
                                  ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DiscoverLearningPathsRow extends StatelessWidget {
  const DiscoverLearningPathsRow({
    super.key,
    required this.event,
    required this.plan,
    required this.engagement,
  });

  final EventState event;
  final PlanState plan;
  final EngagementState engagement;

  @override
  Widget build(BuildContext context) {
    if (event.learningPaths.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'Learning paths',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final path in event.learningPaths)
                _LearningPathCard(
                  path: path,
                  event: event,
                  plan: plan,
                  engagement: engagement,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LearningPathCard extends StatelessWidget {
  const _LearningPathCard({
    required this.path,
    required this.event,
    required this.plan,
    required this.engagement,
  });

  final LearningPath path;
  final EventState event;
  final PlanState plan;
  final EngagementState engagement;

  @override
  Widget build(BuildContext context) {
    final total = path.sessionIds.length;
    final done = path.sessionIds.where((id) {
      return plan.isInPlan(id) || engagement.attendedSessionIds.contains(id);
    }).length;

    return GestureDetector(
      onTap: () => context.push('/learning-path/${path.id}'),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accentStart.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(path.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text(
              '$done/$total complete',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class DiscoverLivePulseDot extends StatefulWidget {
  const DiscoverLivePulseDot({super.key});

  @override
  State<DiscoverLivePulseDot> createState() => _DiscoverLivePulseDotState();
}

class _DiscoverLivePulseDotState extends State<DiscoverLivePulseDot> {
  @override
  Widget build(BuildContext context) {
    if (!shouldAnimate(context)) {
      return const Icon(
        Icons.fiber_manual_record,
        size: 10,
        color: Colors.redAccent,
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1),
      duration: const Duration(milliseconds: 900),
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: const Icon(
          Icons.fiber_manual_record,
          size: 10,
          color: Colors.redAccent,
        ),
      ),
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }
}
