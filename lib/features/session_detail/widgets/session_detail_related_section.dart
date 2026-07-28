import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/session.dart';
import '../../../shared/widgets/shared_widgets.dart';

class SessionDetailRelatedSection extends StatelessWidget {
  const SessionDetailRelatedSection({
    super.key,
    required this.related,
    required this.missed,
  });

  final List<Session> related;
  final List<Session> missed;

  @override
  Widget build(BuildContext context) {
    if (related.isEmpty && missed.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (related.isNotEmpty) ...[
          Text(
            'Related sessions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _SessionCarousel(sessions: related),
        ],
        if (missed.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'If you miss this',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'Same track or topic — same day when possible',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          _SessionCarousel(sessions: missed),
        ],
      ],
    );
  }
}

class _SessionCarousel extends StatelessWidget {
  const _SessionCarousel({required this.sessions});

  final List<Session> sessions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sessions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final rel = sessions[index];
          return SizedBox(
            width: 280,
            child: SessionCard(
              title: rel.title,
              subtitle: '${rel.day} · ${rel.startTime}',
              onTap: () => context.replace('/session/${rel.id}'),
            ),
          );
        },
      ),
    );
  }
}
