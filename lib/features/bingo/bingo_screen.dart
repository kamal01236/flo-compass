import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/services/bingo_service.dart';
import '../../providers/engagement_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/profile_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/shared_widgets.dart';

class BingoScreen extends StatelessWidget {
  const BingoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final engagement = context.watch<EngagementState>();
    final plan = context.watch<PlanState>();
    final event = context.watch<EventState>();
    final profile = context.watch<ProfileState>();
    final marks = engagement.bingoMarks;
    final markedCount = marks.length;

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/profile'),
          ),
        ),
        title: const Text('Session Bingo'),
      ),
      body: ResponsiveLayout(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GradientTitle('Session Bingo'),
              const SizedBox(height: 8),
              Text(
                '$markedCount / ${BingoService.gridSize} cells · +20 XP each · +50 XP per row',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: BingoService.gridSize,
                itemBuilder: (context, index) {
                  final cell = BingoService.cells[index];
                  final marked = marks.contains(index);
                  return Semantics(
                    label: cell.label,
                    checked: marked,
                    button: !marked,
                    child: InkWell(
                      onTap: marked
                          ? null
                          : () async {
                              final xp = await engagement.markBingoCell(index);
                              if (!context.mounted || xp == 0) return;
                              await engagement.refreshBingoAutoMarks(
                                plan: plan,
                                event: event,
                                profile: profile.profile,
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Semantics(
                                    liveRegion: true,
                                    child: Text('+$xp XP · ${cell.shortLabel}'),
                                  ),
                                ),
                              );
                            },
                      borderRadius: BorderRadius.circular(8),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: marked
                              ? AppColors.accentStart.withValues(alpha: 0.2)
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: marked
                                ? AppColors.accentStart
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Center(
                          child: marked
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.accentStart,
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Text(
                                    cell.shortLabel,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
