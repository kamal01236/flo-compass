import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/session.dart';
import '../../../domain/entities/speaker.dart';
import '../../../domain/entities/track.dart';
import '../../../providers/event_provider.dart';
import '../../../shared/theme/app_theme.dart';

class SessionDetailSpeakersTab extends StatelessWidget {
  const SessionDetailSpeakersTab({
    super.key,
    required this.session,
    required this.event,
    this.track,
  });

  final Session session;
  final EventState event;
  final Track? track;

  @override
  Widget build(BuildContext context) {
    final speakers = session.speakerIds
        .map(event.speakerById)
        .whereType<Speaker>()
        .toList();
    if (speakers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Speakers', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final speaker in speakers)
          _SpeakerCard(
            speaker: speaker,
            track: track,
            sessionCount: event.sessions
                .where((s) => s.speakerIds.contains(speaker.id))
                .length,
          ),
      ],
    );
  }
}

class _SpeakerCard extends StatelessWidget {
  const _SpeakerCard({
    required this.speaker,
    required this.track,
    required this.sessionCount,
  });

  final Speaker speaker;
  final Track? track;
  final int sessionCount;

  @override
  Widget build(BuildContext context) {
    final trackColor = AppTheme.colorForTrack(track?.id ?? '');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.push('/speaker/${speaker.id}'),
        leading: CircleAvatar(
          backgroundImage: speaker.photoAsset == null
              ? null
              : AssetImage(speaker.photoAsset!),
          backgroundColor: trackColor,
          child: speaker.photoAsset == null
              ? Text(_initials(speaker.name))
              : null,
        ),
        title: Text(speaker.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(speaker.title),
            if (speaker.bio.isNotEmpty)
              Text(
                speaker.bio,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            Text(
              '$sessionCount Flo sessions',
              style: const TextStyle(
                color: AppColors.accentStart,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).take(2).toList();
    return parts.map((e) => e[0]).join();
  }
}
