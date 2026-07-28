import 'package:flutter/material.dart';

class AccessibilityStatementScreen extends StatelessWidget {
  const AccessibilityStatementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Accessibility statement',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Flo Compass targets WCAG 2.1 AA for core flows: keyboard navigation, visible focus rings, '
            'semantic labels on icon buttons, route announcements, and reduced-motion support.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 16),
          const Text(
            'Supported adjustments:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '• High-contrast theme in Profile settings',
            style: TextStyle(color: muted),
          ),
          Text(
            '• OpenDyslexic font option',
            style: TextStyle(color: muted),
          ),
          Text(
            '• Skip-to-content link on web shell',
            style: TextStyle(color: muted),
          ),
          Text(
            '• Modal focus trapping for sheets and dialogs',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 16),
          Text(
            'Report accessibility issues via Profile → Send feedback.',
            style: TextStyle(color: muted),
          ),
        ],
      ),
    );
  }
}
