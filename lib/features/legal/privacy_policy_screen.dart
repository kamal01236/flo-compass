import 'package:flutter/material.dart';


class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = <({String title, String body})>[
    (
      title: 'What we store locally',
      body:
          'Session bookmarks (My Plan), interest selections, theme and accessibility preferences, '
          'and optional engagement data (XP, achievements) stay in your browser via shared_preferences.',
    ),
    (
      title: 'Product analytics',
      body:
          'With your consent, Flo Compass records anonymized product events (screen views, '
          'bookmarks, companion usage) in a local ring buffer for diagnostics. Optional remote '
          'batching uses ANALYTICS_API_URL when configured — no names, emails, or attendee PII.',
    ),
    (
      title: 'What we do not do',
      body:
          'Flo Compass does not handle official event registration, ticketing, or badge printing. '
          'Those are managed by Accelevents.',
    ),
    (
      title: 'Optional sign-in',
      body:
          'When Azure AD login is enabled, account data may be linked to your identity for '
          'leaderboard credit and attributed feedback. Sign-in is optional for browsing and planning.',
    ),
    (
      title: 'Your rights',
      body:
          'You can clear local data from Profile settings. Web storage is not encrypted in this demo; '
          'production deployments should review encrypted storage options.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy policy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Flo Compass Privacy Policy',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Version 2026-07-11 · Flo 2026 demo',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          for (final section in _sections) ...[
            Text(section.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              section.body,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
