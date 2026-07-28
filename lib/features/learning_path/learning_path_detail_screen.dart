import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/models.dart';
import '../../providers/engagement_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/plan_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/friendly_error_messages.dart';
import '../../shared/widgets/map_chip_button.dart';
import '../../shared/widgets/recap_wrapped_panel.dart';
import '../../shared/widgets/shared_widgets.dart';

class LearningPathDetailScreen extends StatelessWidget {
  const LearningPathDetailScreen({super.key, required this.pathId});

  final String pathId;

  @override
  Widget build(BuildContext context) {
    final event = context.watch<EventState>();
    final plan = context.watch<PlanState>();
    final engagement = context.watch<EngagementState>();

    final path = event.learningPaths.where((p) => p.id == pathId).firstOrNull;
    if (path == null) {
      final copy = FriendlyErrorCopy.random(FriendlyErrorKind.pathNotFound);
      return Scaffold(
        appBar: AppBar(title: const Text('Learning path')),
        body: EmptyState(
          title: copy.title,
          message: copy.message,
          semanticsLabel: copy.semanticLabel,
          action: FilledButton(
            onPressed: () => context.go('/discover'),
            child: const Text('Back to Discover'),
          ),
        ),
      );
    }

    final sessions = path.sessionIds
        .map(event.sessionById)
        .whereType<Session>()
        .toList();
    final completed = sessions.where((s) {
      return plan.isInPlan(s.id) ||
          engagement.attendedSessionIds.contains(s.id);
    }).length;
    final progress = sessions.isEmpty ? 0.0 : completed / sessions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(path.title),
        actions: const [DiscoverHomeAction()],
      ),
      body: ResponsiveLayout(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              path.description,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Center(
              child: RingGauge(
                progress: progress,
                label: '$completed/${sessions.length}\ncomplete',
              ),
            ),
            const SizedBox(height: 16),
            Text('Sessions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final session in sessions) ...[
              _PathSessionTile(
                session: session,
                event: event,
                plan: plan,
                engagement: engagement,
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _PathSessionTile extends StatelessWidget {
  const _PathSessionTile({
    required this.session,
    required this.event,
    required this.plan,
    required this.engagement,
  });

  final Session session;
  final EventState event;
  final PlanState plan;
  final EngagementState engagement;

  @override
  Widget build(BuildContext context) {
    final done =
        plan.isInPlan(session.id) ||
        engagement.attendedSessionIds.contains(session.id);
    final venue = event.venueById(session.venueId);

    return Card(
      child: ListTile(
        leading: Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? AppColors.accentStart : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(session.title),
        subtitle: Text(
          '${session.day} · ${session.startTime} · ${venue?.name ?? session.venueId}',
        ),
        trailing: MapChipButton(
          venueId: session.venueId,
          venueName: venue?.name ?? session.venueId,
        ),
        onTap: () => context.push('/session/${session.id}'),
      ),
    );
  }
}
