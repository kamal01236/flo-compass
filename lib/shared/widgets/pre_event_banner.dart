import 'package:flutter/material.dart';

import '../../providers/event_provider.dart';
import '../utils/event_stage.dart';
import 'discovery_delight_sheets.dart';
import 'event_notification_icon_button.dart';

class PreEventBanner extends StatelessWidget {
  const PreEventBanner({
    super.key,
    required this.event,
    this.notificationCount = 0,
    this.onNotificationsTap,
  });

  final EventState event;
  final int notificationCount;
  final VoidCallback? onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final start =
        firstSessionStart(event.sessions) ?? DateTime(2026, 11, 4, 9, 0);
    final sessionCount = event.sessions.isEmpty ? 640 : event.sessions.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatEventStartTitle(start),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nagarro Gurgaon Office · 3 days · ~$sessionCount sessions',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (onNotificationsTap != null)
                EventNotificationIconButton(
                  count: notificationCount,
                  onTap: onNotificationsTap!,
                ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => showBuildAfternoonSheet(context),
            icon: const Icon(Icons.schedule),
            label: const Text('Build my Day 1 plan'),
          ),
        ],
      ),
    );
  }
}
