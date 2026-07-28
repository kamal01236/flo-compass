import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../providers/engagement_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../shared/utils/session_note_excerpt.dart';

class MyPlanNotesSection extends StatelessWidget {
  const MyPlanNotesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final engagement = context.watch<EngagementState>();
    final event = context.watch<EventState>();

    final entries = <({String sessionId, String title, String excerpt})>[];
    engagement.notesBySessionId.forEach((sessionId, note) {
      final excerpt = excerptSessionNote(note);
      if (excerpt.isEmpty) return;
      final session = event.sessionById(sessionId);
      if (session == null) return;
      entries.add((
        sessionId: sessionId,
        title: session.title,
        excerpt: excerpt,
      ));
    });
    entries.sort((a, b) => a.title.compareTo(b.title));

    if (entries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        child: ExpansionTile(
          initiallyExpanded: false,
          leading: const Icon(Icons.note_alt_outlined),
          title: const Text('My notes'),
          subtitle: Text('${entries.length} saved'),
          childrenPadding: EdgeInsets.zero,
          children: [
            for (final entry in entries)
              ListTile(
                contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                title: Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  entry.excerpt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/session/${entry.sessionId}'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
