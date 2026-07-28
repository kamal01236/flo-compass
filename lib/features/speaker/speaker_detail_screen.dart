import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/models.dart';
import '../../data/services/conflict_detector.dart';
import '../../providers/event_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/profile_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/friendly_error_messages.dart';
import '../../shared/widgets/map_chip_button.dart';
import '../../shared/widgets/shared_widgets.dart';

class _BulkAddAnalysis {
  const _BulkAddAnalysis({
    required this.conflictFree,
    required this.conflicts,
    required this.alreadyInPlan,
  });

  final List<Session> conflictFree;
  final List<PlanConflict> conflicts;
  final int alreadyInPlan;
}

class SpeakerDetailScreen extends StatefulWidget {
  const SpeakerDetailScreen({super.key, required this.speakerId});

  final String speakerId;

  @override
  State<SpeakerDetailScreen> createState() => _SpeakerDetailScreenState();
}

class _SpeakerDetailScreenState extends State<SpeakerDetailScreen> {
  String? _dayFilter;
  final _conflictDetector = ConflictDetector();

  List<Session> _speakerSessions(EventState event, String speakerId) {
    var sessions = event.sessions
        .where((session) => session.speakerIds.contains(speakerId))
        .toList();
    if (_dayFilter != null) {
      sessions = sessions.where((s) => s.day == _dayFilter).toList();
    }
    sessions.sort((a, b) {
      final d = a.dayNumber.compareTo(b.dayNumber);
      if (d != 0) return d;
      return a.startTime.compareTo(b.startTime);
    });
    return sessions;
  }

  _BulkAddAnalysis _analyzeBulkAdd({
    required List<Session> candidates,
    required List<Session> currentPlan,
    required PlanState plan,
  }) {
    final conflictFree = <Session>[];
    final conflicts = <PlanConflict>[];
    var alreadyInPlan = 0;
    var working = [...currentPlan];

    for (final session in candidates) {
      if (plan.isInPlan(session.id)) {
        alreadyInPlan++;
        continue;
      }
      final test = [...working, session];
      final newConflicts = _conflictDetector.findConflicts(test);
      final involvesCandidate = newConflicts.any(
        (c) => c.sessionA.id == session.id || c.sessionB.id == session.id,
      );
      if (involvesCandidate) {
        for (final conflict in newConflicts) {
          if (conflict.sessionA.id == session.id ||
              conflict.sessionB.id == session.id) {
            final duplicate = conflicts.any(
              (c) =>
                  (c.sessionA.id == conflict.sessionA.id &&
                      c.sessionB.id == conflict.sessionB.id) ||
                  (c.sessionA.id == conflict.sessionB.id &&
                      c.sessionB.id == conflict.sessionA.id),
            );
            if (!duplicate) conflicts.add(conflict);
          }
        }
      } else {
        conflictFree.add(session);
        working.add(session);
      }
    }

    return _BulkAddAnalysis(
      conflictFree: conflictFree,
      conflicts: conflicts,
      alreadyInPlan: alreadyInPlan,
    );
  }

  Future<void> _addAllToPlan(
    BuildContext context,
    List<Session> sessions,
  ) async {
    final plan = context.read<PlanState>();
    final event = context.read<EventState>();
    final currentPlan = plan.plannedSessions(event.sessions);
    final analysis = _analyzeBulkAdd(
      candidates: sessions,
      currentPlan: currentPlan,
      plan: plan,
    );

    if (analysis.conflictFree.isEmpty && analysis.conflicts.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All sessions are already in your plan'),
          ),
        );
      }
      return;
    }

    if (analysis.conflicts.isEmpty) {
      await plan.mergeSessions(analysis.conflictFree.map((s) => s.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ${analysis.conflictFree.length} session'
              '${analysis.conflictFree.length == 1 ? '' : 's'} to your plan',
            ),
          ),
        );
      }
      return;
    }

    final addConflictFree = analysis.conflictFree.isNotEmpty;
    final choice = await showDialog<_BulkAddChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule conflicts'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${analysis.conflicts.length} overlap'
                '${analysis.conflicts.length == 1 ? '' : 's'} found when adding '
                '${sessions.length - analysis.alreadyInPlan} session'
                '${sessions.length - analysis.alreadyInPlan == 1 ? '' : 's'}.',
              ),
              if (analysis.alreadyInPlan > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '$analysis.alreadyInPlan already in your plan.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 12),
              for (final conflict in analysis.conflicts.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '• ${conflict.sessionA.title} overlaps ${conflict.sessionB.title}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              if (analysis.conflicts.length > 5)
                Text(
                  '…and ${analysis.conflicts.length - 5} more',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _BulkAddChoice.cancel),
            child: const Text('Cancel'),
          ),
          if (addConflictFree)
            FilledButton.tonal(
              onPressed: () =>
                  Navigator.pop(context, _BulkAddChoice.conflictFreeOnly),
              child: Text(
                'Add ${analysis.conflictFree.length} without conflicts',
              ),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _BulkAddChoice.addAll),
            child: const Text('Add all anyway'),
          ),
        ],
      ),
    );

    if (!context.mounted || choice == null || choice == _BulkAddChoice.cancel) {
      return;
    }

    final ids = switch (choice) {
      _BulkAddChoice.conflictFreeOnly => analysis.conflictFree.map((s) => s.id),
      _BulkAddChoice.addAll =>
        sessions.where((s) => !plan.isInPlan(s.id)).map((s) => s.id),
      _BulkAddChoice.cancel => const <String>[],
    };

    if (ids.isEmpty) return;
    await plan.mergeSessions(ids);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${ids.length} session${ids.length == 1 ? '' : 's'} to your plan',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = context.watch<EventState>();
    final profile = context.watch<ProfileState>();
    final plan = context.watch<PlanState>();
    final speaker = event.speakerById(widget.speakerId);
    if (speaker == null) {
      final copy = FriendlyErrorCopy.random(FriendlyErrorKind.speakerNotFound);
      return Scaffold(
        appBar: AppBar(title: const Text('Speaker')),
        body: EmptyState(
          title: copy.title,
          message: copy.message,
          semanticsLabel: copy.semanticLabel,
          action: FilledButton(
            onPressed: () => context.go('/discover'),
            child: const Text('Back to Discover'),
          ),
        ),
      );
    }
    final followed = profile.profile.followedSpeakerIds.contains(speaker.id);
    final sessions = _speakerSessions(event, speaker.id);
    final similar = event.speakers
        .where((s) => s.id != speaker.id && s.tier == speaker.tier)
        .take(5)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(speaker.name),
        actions: [
          const DiscoverHomeAction(),
          if (sessions.isNotEmpty)
            TextButton(
              onPressed: () => _addAllToPlan(context, sessions),
              child: const Text('Add all to plan'),
            ),
        ],
      ),
      body: ResponsiveLayout(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 28,
                backgroundImage: speaker.photoAsset == null
                    ? null
                    : AssetImage(speaker.photoAsset!),
                backgroundColor: AppTheme.colorForTrack('trk-06'),
                child: speaker.photoAsset == null
                    ? Text(speaker.name.substring(0, 1))
                    : null,
              ),
              title: Text(speaker.name),
              subtitle: Text(
                followed
                    ? 'Following · You\'ll see alerts when they present'
                    : speaker.title,
              ),
              trailing: FilledButton.tonalIcon(
                onPressed: () => profile.toggleFollowSpeaker(speaker.id),
                icon: Icon(followed ? Icons.favorite : Icons.favorite_border),
                label: Text(followed ? 'Following' : 'Follow'),
              ),
            ),
            const SizedBox(height: 8),
            Text(speaker.bio),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => context.go('/companion'),
              child: Text('Ask Flo about ${speaker.name}'),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All days'),
                  selected: _dayFilter == null,
                  onSelected: (_) => setState(() => _dayFilter = null),
                ),
                for (final day in const ['Day 1', 'Day 2', 'Day 3'])
                  FilterChip(
                    label: Text(day),
                    selected: _dayFilter == day,
                    onSelected: (_) => setState(() => _dayFilter = day),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Sessions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (sessions.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No sessions match this filter.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              )
            else
              _SpeakerSessionTimeline(
                sessions: sessions,
                event: event,
                plan: plan,
              ),
            const SizedBox(height: 16),
            Text(
              'Similar speakers',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final item in similar)
                  ActionChip(
                    label: Text(item.name),
                    onPressed: () => context.push('/speaker/${item.id}'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _BulkAddChoice { cancel, conflictFreeOnly, addAll }

class _SpeakerSessionTimeline extends StatelessWidget {
  const _SpeakerSessionTimeline({
    required this.sessions,
    required this.event,
    required this.plan,
  });

  final List<Session> sessions;
  final EventState event;
  final PlanState plan;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    String? currentDay;

    for (final session in sessions) {
      if (session.day != currentDay) {
        currentDay = session.day;
        rows.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              currentDay,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.accentStart,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
      rows.add(
        _SpeakerTimelineRow(
          session: session,
          event: event,
          plan: plan,
          isLastInDay: _isLastInDay(session, sessions),
        ),
      );
    }

    return Column(children: rows);
  }

  bool _isLastInDay(Session session, List<Session> all) {
    final index = all.indexOf(session);
    if (index == all.length - 1) return true;
    return all[index + 1].day != session.day;
  }
}

class _SpeakerTimelineRow extends StatelessWidget {
  const _SpeakerTimelineRow({
    required this.session,
    required this.event,
    required this.plan,
    required this.isLastInDay,
  });

  final Session session;
  final EventState event;
  final PlanState plan;
  final bool isLastInDay;

  @override
  Widget build(BuildContext context) {
    final venue = event.venueById(session.venueId);
    final trackColor = AppTheme.colorForTrack(session.trackId);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Column(
              children: [
                Text(
                  session.startTime,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: trackColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accentStart, width: 2),
                  ),
                ),
                if (!isLastInDay)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppChromeColors.of(context).skeleton.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SessionCard(
              title: session.title,
              subtitle:
                  '${session.startTime}–${session.endTime} · ${venue?.name ?? session.venueId}',
              inPlan: plan.isInPlan(session.id),
              featured: session.featured,
              trackColor: trackColor,
              trailing: MapChipButton(
                venueId: session.venueId,
                venueName: venue?.name ?? session.venueId,
              ),
              onTap: () => context.push('/session/${session.id}'),
              onTogglePlan: () => plan.toggle(session.id),
            ),
          ),
        ],
      ),
    );
  }
}
