import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/session.dart';
import '../../../providers/engagement_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/plan_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../shared/theme/app_theme.dart';

class SessionDetailEngagementPanel extends StatelessWidget {
  const SessionDetailEngagementPanel({
    super.key,
    required this.session,
    required this.showReactions,
  });

  final Session session;
  final bool showReactions;

  static const reactionOptions = <({String key, IconData icon, String label})>[
    (key: 'fire', icon: Icons.local_fire_department, label: 'Fire'),
    (key: 'lightbulb', icon: Icons.lightbulb_outline, label: 'Insight'),
    (key: 'clap', icon: Icons.thumb_up_alt_outlined, label: 'Applause'),
    (key: 'thinking', icon: Icons.psychology_outlined, label: 'Thoughtful'),
    (key: 'heart', icon: Icons.favorite_border, label: 'Love'),
  ];

  @override
  Widget build(BuildContext context) {
    final engagement = context.watch<EngagementState>();
    final event = context.read<EventState>();
    final plan = context.read<PlanState>();
    final profile = context.read<ProfileState>();
    final selectedReaction = engagement.reactions[session.id];
    final aggregates = engagement.aggregateReactionsForSession(session.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showReactions) ...[
          Text('How was it?', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final option in SessionDetailEngagementPanel.reactionOptions)
                Semantics(
                  label: '${option.label} reaction',
                  button: true,
                  selected: selectedReaction == option.key,
                  child: IconButton(
                    tooltip: option.label,
                    onPressed: () async {
                      final delta = await engagement.setReaction(
                        session.id,
                        option.key,
                      );
                      if (!context.mounted) return;
                      if (delta > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Semantics(
                              liveRegion: true,
                              child: Text('+$delta XP · Reaction saved'),
                            ),
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      option.icon,
                      color: selectedReaction == option.key
                          ? AppColors.accentStart
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Room pulse (demo)',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            children: [
              for (final entry in aggregates.entries)
                Text('${entry.key}: ${entry.value}'),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Rate:'),
            const SizedBox(width: 8),
            for (var star = 1; star <= 5; star++)
              IconButton(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                iconSize: 28,
                onPressed: () async {
                  final delta = await engagement.rateSession(
                    session.id,
                    star,
                    event: event,
                    plan: plan,
                    profile: profile,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Semantics(
                          liveRegion: true,
                          child: Text('+$delta XP · Rated $star stars'),
                        ),
                      ),
                    );
                  }
                },
                icon: Icon(
                  Icons.star,
                  color: (engagement.ratings[session.id] ?? 0) >= star
                      ? Colors.amber
                      : AppColors.disabledStar,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class SessionDetailPulseSection extends StatelessWidget {
  const SessionDetailPulseSection({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final engagement = context.watch<EngagementState>();
    final selected = engagement.pulseForSession(sessionId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Worth it?', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final (value, label) in [
              ('worth_it', 'Worth it'),
              ('meh', 'Meh'),
              ('skip', 'Skip'),
            ])
              Semantics(
                label: label,
                button: true,
                selected: selected == value,
                child: ChoiceChip(
                  label: Text(label),
                  selected: selected == value,
                  onSelected: (_) async {
                    final delta = await engagement.setPulse(
                      sessionId,
                      value,
                      event: context.read<EventState>(),
                    );
                    if (!context.mounted) return;
                    if (delta > 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Semantics(
                            liveRegion: true,
                            child: Text('+$delta XP · Pulse saved'),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }
}
