import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/models/user_profile.dart';
import '../../../data/services/plain_english_service.dart';
import '../../../data/services/session_detail_assembler.dart';
import '../../../data/services/walking_time_estimator.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/entities/venue.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/tour/tour_targets.dart';
import 'session_detail_engagement_panel.dart';
import 'session_detail_materials_section.dart';
import 'session_detail_speakers_tab.dart';
import 'session_notes_section.dart';

class SessionDetailOverviewTab extends StatelessWidget {
  const SessionDetailOverviewTab({
    super.key,
    required this.session,
    required this.viewModel,
    required this.showPlainEnglish,
    required this.showPostSessionPulse,
    required this.engagementPanel,
    this.isNarrow = false,
    this.showNotesInOverview = false,
    this.attendanceMode = AttendanceMode.onSite,
    this.walkEstimate,
    this.bottomScrollPadding = 0,
    this.onOpenLogistics,
  });

  final Session session;
  final SessionDetailViewModel viewModel;
  final bool showPlainEnglish;
  final bool showPostSessionPulse;
  final SessionDetailEngagementPanel engagementPanel;
  final bool isNarrow;
  final bool showNotesInOverview;
  final AttendanceMode attendanceMode;
  final WalkingTimeEstimate? walkEstimate;
  final double bottomScrollPadding;
  final VoidCallback? onOpenLogistics;

  bool get _showGettingThere {
    if (attendanceMode == AttendanceMode.remote) return false;
    if (viewModel.venue == null) return false;
    return switch (viewModel.liveState) {
      SessionLiveState.upcoming ||
      SessionLiveState.startingSoon ||
      SessionLiveState.live => true,
      SessionLiveState.ended => false,
    };
  }

  @override
  Widget build(BuildContext context) {
    const plainEnglish = PlainEnglishService();
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomScrollPadding),
      children: [
        if (viewModel.matchReasons.isNotEmpty) ...[
          KeyedSubtree(
            key: tourRecoReasonKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Why this matches you',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final reason in viewModel.matchReasons)
                      Chip(
                        label: Text(
                          reason,
                          style: const TextStyle(fontSize: 12),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_showGettingThere) ...[
          _GettingThereCard(
            venue: viewModel.venue!,
            walkEstimate: walkEstimate,
            onOpenLogistics: onOpenLogistics,
          ),
          const SizedBox(height: 16),
        ],
        if (showNotesInOverview) ...[
          SessionNotesExpandable(sessionId: session.id),
          const SizedBox(height: 16),
        ],
        if (showPlainEnglish) ...[
          Text(
            plainEnglish.summarize(session),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
        ],
        ExpansionTile(
          title: const Text('Full abstract'),
          initiallyExpanded: isNarrow ? false : !showPlainEnglish,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(session.abstract),
              ),
            ),
          ],
        ),
        if (viewModel.formatHints.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Format tips', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          for (final hint in viewModel.formatHints)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  Expanded(child: Text(hint)),
                ],
              ),
            ),
        ],
        if (viewModel.learningPathHits.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Learning path', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final hit in viewModel.learningPathHits)
            _LearningPathHitCard(hit: hit),
        ],
        if (viewModel.bingoHints.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (final hint in viewModel.bingoHints)
                Chip(
                  avatar: const Icon(Icons.grid_on, size: 16),
                  label: Text(hint),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
        if (showPostSessionPulse) ...[
          const SizedBox(height: 16),
          SessionDetailPulseSection(sessionId: session.id),
        ],
        const SizedBox(height: 16),
        SessionDetailMaterialsSection(session: session),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          children: [
            for (final tag in session.tags)
              Chip(label: Text(tag.replaceAll('_', ' '))),
          ],
        ),
        const SizedBox(height: 16),
        SessionDetailSpeakersTab(
          session: session,
          event: context.read(),
          track: viewModel.track,
        ),
        const SizedBox(height: 16),
        engagementPanel,
      ],
    );
  }
}

class _GettingThereCard extends StatelessWidget {
  const _GettingThereCard({
    required this.venue,
    this.walkEstimate,
    this.onOpenLogistics,
  });

  final Venue venue;
  final WalkingTimeEstimate? walkEstimate;
  final VoidCallback? onOpenLogistics;

  @override
  Widget build(BuildContext context) {
    final venueName = venue.name;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.place_outlined, color: AppColors.accentStart),
                const SizedBox(width: 8),
                Text(
                  'Getting there',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(venueName, style: Theme.of(context).textTheme.bodyLarge),
            Text(
              'Floor ${venue.floor} · Wing ${venue.wing}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            if (walkEstimate != null) ...[
              const SizedBox(height: 6),
              Text(
                '~${walkEstimate!.minutes} min walk from previous plan item',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
            if (onOpenLogistics != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onOpenLogistics,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Logistics & map'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LearningPathHitCard extends StatelessWidget {
  const _LearningPathHitCard({required this.hit});

  final LearningPathHit hit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.push('/learning-path/${hit.path.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hit.path.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  hit.path.description,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: hit.progress,
                  minHeight: 6,
                  color: AppColors.accentStart,
                ),
                const SizedBox(height: 4),
                Text(
                  '${hit.completedCount}/${hit.totalCount} sessions complete · '
                  'Bookmarked or attended',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
