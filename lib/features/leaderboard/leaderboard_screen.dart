import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/app_settings_provider.dart';
import '../../providers/engagement_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'leaderboard_entries.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  static const disclaimer =
      'Demo leaderboard with simulated names. Not connected to real attendees.';

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettingsState>();
    final engagement = context.watch<EngagementState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mock leaderboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile'),
        ),
      ),
      body: ResponsiveLayout(
        child: appSettings.leaderboardOptIn
            ? _LeaderboardList(userXp: engagement.xp)
            : _OptInGate(onOptIn: () => appSettings.setLeaderboardOptIn(true)),
      ),
    );
  }
}

class _OptInGate extends StatelessWidget {
  const _OptInGate({required this.onOptIn});

  final VoidCallback onOptIn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GradientTitle('Mock leaderboard'),
          const SizedBox(height: 12),
          const Icon(Icons.info_outline, color: AppColors.accentStart),
          const SizedBox(height: 12),
          Text(
            LeaderboardScreen.disclaimer,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Rankings use fictional names plus your local XP from Flo Compass. '
            'You can turn this off anytime in Profile.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const Spacer(),
          Semantics(
            label: 'Show mock leaderboard',
            button: true,
            child: FilledButton.icon(
              onPressed: onOptIn,
              icon: const Icon(Icons.leaderboard_outlined),
              label: const Text('Show mock leaderboard'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.pop(),
            child: const Text('Not now'),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  const _LeaderboardList({required this.userXp});

  final int userXp;

  @override
  Widget build(BuildContext context) {
    final entries = buildLeaderboard(userXp: userXp);
    final userRank = userLeaderboardRank(entries);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const GradientTitle('Mock leaderboard'),
        const SizedBox(height: 8),
        Text(
          'Your rank: #$userRank · ${entries.firstWhere((e) => e.isCurrentUser).xp} XP',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          LeaderboardScreen.disclaimer,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < entries.length; i++)
          _LeaderboardTile(rank: i + 1, entry: entries[i]),
      ],
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.rank, required this.entry});

  final int rank;
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final highlight = entry.isCurrentUser;
    return Card(
      color: highlight ? AppColors.accentStart.withValues(alpha: 0.12) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: highlight
              ? AppColors.accentStart
              : AppChromeColors.of(context).skeleton,
          child: Text(
            '#$rank',
            style: TextStyle(
              fontSize: 12,
              color: highlight
                  ? Theme.of(context).colorScheme.onPrimary
                  : null,
            ),
          ),
        ),
        title: Text(
          entry.isCurrentUser ? '${entry.name} (you)' : entry.name,
          style: TextStyle(
            fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: Text('${entry.xp} XP'),
      ),
    );
  }
}
