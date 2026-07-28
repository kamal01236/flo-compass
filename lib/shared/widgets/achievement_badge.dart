import 'package:flutter/material.dart';

class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.id,
    required this.name,
    required this.description,
    required this.unlockedAt,
    this.width,
  });

  final String id;
  final String name;
  final String description;
  final DateTime? unlockedAt;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final rarity = _rarityFor(id);
    final icon = _iconFor(id);
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rarity.color.withValues(alpha: 0.5)),
        gradient: LinearGradient(
          colors: [rarity.color.withValues(alpha: 0.18), Colors.transparent],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: rarity.color),
              const SizedBox(width: 8),
              Expanded(child: Text(name)),
            ],
          ),
          const SizedBox(height: 6),
          Text(description, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            '${rarity.label}${unlockedAt == null ? '' : ' · ${unlockedAt!.toIso8601String().split('T').first}'}',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: rarity.color),
          ),
        ],
      ),
    );
  }

  ({String label, Color color}) _rarityFor(String achievementId) {
    if (achievementId == 'renaissance' || achievementId == 'marathon') {
      return (label: 'epic', color: const Color(0xFF8B5CF6));
    }
    if (achievementId == 'cursor_ninja' || achievementId == 'flo_explorer') {
      return (label: 'rare', color: const Color(0xFF06B6D4));
    }
    return (label: 'common', color: const Color(0xFF10B981));
  }

  IconData _iconFor(String achievementId) {
    return switch (achievementId) {
      'keynote_hunter' => Icons.mic,
      'cursor_ninja' => Icons.code,
      'marathon' => Icons.directions_run,
      'companion_curious' => Icons.chat_bubble,
      'renaissance' => Icons.auto_awesome,
      'early_bird' => Icons.wb_sunny,
      'flo_explorer' => Icons.explore,
      _ => Icons.emoji_events,
    };
  }
}
