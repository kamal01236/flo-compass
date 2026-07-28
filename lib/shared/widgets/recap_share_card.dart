import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fixed-layout share card for PNG export (~380px wide).
class RecapShareCard extends StatelessWidget {
  const RecapShareCard({
    super.key,
    required this.xp,
    required this.levelLabel,
    required this.bookmarked,
    required this.attended,
    required this.tracksExplored,
    this.topRatedTrack,
    this.plannedSessionTitles = const [],
  });

  static const double cardWidth = 380;

  final int xp;
  final String levelLabel;
  final int bookmarked;
  final int attended;
  final int tracksExplored;
  final String? topRatedTrack;
  final List<String> plannedSessionTitles;

  @override
  Widget build(BuildContext context) {
    final sessions = plannedSessionTitles.take(3).toList();

    return SizedBox(
      width: cardWidth,
      child: Material(
        color: AppColors.scaffoldBackground,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accentStart.withValues(alpha: 0.35),
            ),
            gradient: const LinearGradient(
              colors: [Color(0xFF14151C), AppColors.scaffoldBackground],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 6,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    colors: [AppColors.accentStart, AppColors.accentEnd],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Flo Compass',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.accentStart,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'My Flo 2026',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            icon: Icons.bolt,
                            label: levelLabel,
                            value: '$xp XP',
                            color: AppColors.accentStart,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatTile(
                            icon: Icons.bookmark,
                            label: 'Bookmarked',
                            value: '$bookmarked',
                            color: AppColors.accentStart,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            icon: Icons.verified,
                            label: 'Attended',
                            value: '$attended',
                            color: Colors.cyan,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatTile(
                            icon: Icons.explore,
                            label: 'Tracks',
                            value: '$tracksExplored',
                            color: AppColors.accentEnd,
                          ),
                        ),
                      ],
                    ),
                    if (topRatedTrack != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Top rated track',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        topRatedTrack!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(color: Colors.white),
                      ),
                    ],
                    if (sessions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'On my plan',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final title in sessions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: AppColors.accentStart,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.secondaryText,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}
