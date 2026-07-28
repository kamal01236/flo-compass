import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/models.dart';
import '../../providers/plan_provider.dart';
import '../a11y/motion_policy.dart';
import '../widgets/discovery_delight_sheets.dart';
import '../theme/app_theme.dart';

/// Hero card for Flo's top event-day pick — zero height when [session] is null.
class FloPicksHero extends StatelessWidget {
  const FloPicksHero({
    super.key,
    required this.session,
    this.matchReasons = const [],
    this.showBuildAfternoon = false,
  });

  final Session? session;
  final List<String> matchReasons;
  final bool showBuildAfternoon;

  @override
  Widget build(BuildContext context) {
    if (session == null) return const SizedBox.shrink();

    final plan = context.read<PlanState>();
    final inPlan = plan.isInPlan(session!.id);

    return _MotionSafeAppear(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accentStart.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: AppColors.accentStart,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Flo Picks',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.accentStart,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  session!.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (matchReasons.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    matchReasons.first,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                _FloPicksActions(
                  session: session!,
                  inPlan: inPlan,
                  showBuildAfternoon: showBuildAfternoon,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _FloPicksMoreAction { askAbout, buildAfternoon }

class _FloPicksActions extends StatelessWidget {
  const _FloPicksActions({
    required this.session,
    required this.inPlan,
    required this.showBuildAfternoon,
  });

  final Session session;
  final bool inPlan;
  final bool showBuildAfternoon;

  @override
  Widget build(BuildContext context) {
    final encodedTitle = Uri.encodeComponent(session.title);
    final isNarrow = MediaQuery.sizeOf(context).width < 600;

    if (isNarrow) {
      return Row(
        children: [
          Flexible(
            child: FilledButton(
              onPressed: () => context.read<PlanState>().toggle(session.id),
              child: Text(inPlan ? 'In plan' : 'Add'),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: OutlinedButton(
              onPressed: () => context.push('/session/${session.id}'),
              child: const Text('Open'),
            ),
          ),
          PopupMenuButton<_FloPicksMoreAction>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More actions',
            onSelected: (action) =>
                _handleMoreAction(context, action, encodedTitle),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _FloPicksMoreAction.askAbout,
                child: Text('Ask about this'),
              ),
              if (showBuildAfternoon)
                const PopupMenuItem(
                  value: _FloPicksMoreAction.buildAfternoon,
                  child: Text('Build my afternoon'),
                ),
            ],
          ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        FilledButton(
          onPressed: () => context.read<PlanState>().toggle(session.id),
          child: Text(inPlan ? 'In plan' : 'Add'),
        ),
        OutlinedButton(
          onPressed: () => context.push('/session/${session.id}'),
          child: const Text('Open'),
        ),
        OutlinedButton(
          onPressed: () =>
              context.go('/companion?q=Tell%20me%20about%20$encodedTitle'),
          child: const Text('Ask about this'),
        ),
        if (showBuildAfternoon)
          OutlinedButton.icon(
            onPressed: () => showBuildAfternoonSheet(context),
            icon: const Icon(Icons.schedule),
            label: const Text('Build my afternoon'),
          ),
      ],
    );
  }

  void _handleMoreAction(
    BuildContext context,
    _FloPicksMoreAction action,
    String encodedTitle,
  ) {
    switch (action) {
      case _FloPicksMoreAction.askAbout:
        context.go('/companion?q=Tell%20me%20about%20$encodedTitle');
      case _FloPicksMoreAction.buildAfternoon:
        showBuildAfternoonSheet(context);
    }
  }
}

class _MotionSafeAppear extends StatefulWidget {
  const _MotionSafeAppear({required this.child});

  final Widget child;

  @override
  State<_MotionSafeAppear> createState() => _MotionSafeAppearState();
}

class _MotionSafeAppearState extends State<_MotionSafeAppear>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (shouldAnimate(context)) {
      _controller.forward(from: 0);
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _fade, child: widget.child);
  }
}
