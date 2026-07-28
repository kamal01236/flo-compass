import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../theme/app_theme.dart';

class PlanShareCard extends StatelessWidget {
  const PlanShareCard({super.key, required this.sessions});

  final List<Session> sessions;

  @override
  Widget build(BuildContext context) {
    final panel = AppChromeColors.of(context).elevatedPanel;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.accentStart.withValues(alpha: 0.18),
            panel,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Flo 2026 · Nagarro Gurgaon Office',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          for (final session in sessions.take(8))
            Text('• ${session.day} ${session.startTime}  ${session.title}'),
        ],
      ),
    );
  }
}
