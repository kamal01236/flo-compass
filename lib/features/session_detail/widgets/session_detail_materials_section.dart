import 'package:flutter/material.dart';

import '../../../data/services/session_format_hints.dart';
import '../../../data/services/session_stream_resolver.dart';
import '../../../domain/entities/session.dart';

class SessionDetailMaterialsSection extends StatelessWidget {
  const SessionDetailMaterialsSection({
    super.key,
    required this.session,
    this.streamResolver = const SessionStreamResolver(),
    this.formatHints = const SessionFormatHints(),
  });

  final Session session;
  final SessionStreamResolver streamResolver;
  final SessionFormatHints formatHints;

  @override
  Widget build(BuildContext context) {
    final bullets = _extractLeaveWithBullets(session.abstract);
    final resources = formatHints.resourceHintsFor(session.format);
    final stream = streamResolver.resolve(session);

    if (bullets.isEmpty && resources.isEmpty && !stream.isStreamable) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Materials', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (bullets.isNotEmpty)
          for (final line in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(line)),
                ],
              ),
            )
        else
          for (final resource in resources)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text(resource),
                ],
              ),
            ),
        if (stream.isStreamable)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.video_library_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
                SizedBox(width: 6),
                Text(
                  'Recording coming soon (demo)',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<String> _extractLeaveWithBullets(String abstract) {
    final lower = abstract.toLowerCase();
    final marker = "you'll leave with";
    final idx = lower.indexOf(marker);
    if (idx < 0) return const [];

    final tail = abstract.substring(idx + marker.length).trim();
    return tail
        .split(RegExp(r'[\n•\-]'))
        .map((s) => s.trim())
        .where((s) => s.length > 3)
        .take(4)
        .toList();
  }
}
