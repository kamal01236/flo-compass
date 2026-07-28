import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/models.dart';
import '../../data/services/recap_summary_builder.dart';
import '../../providers/engagement_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/profile_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/now_next_resolver.dart';
import '../../shared/utils/web_download.dart';
import '../../shared/widgets/recap_share_card.dart';
import '../../shared/widgets/recap_wrapped_panel.dart';
import '../../shared/widgets/shared_widgets.dart';

class RecapScreen extends StatefulWidget {
  const RecapScreen({super.key});

  @override
  State<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends State<RecapScreen> {
  final _shareKey = GlobalKey();
  final _summaryBuilder = RecapSummaryBuilder();

  @override
  Widget build(BuildContext context) {
    final event = context.watch<EventState>();
    final plan = context.watch<PlanState>();
    final engagement = context.watch<EngagementState>();
    final planned = plan.plannedSessions(event.sessions);
    final bookmarked = planned.length;
    final attended = engagement.attendedSessionIds.length;
    final nowNext = resolveNowNext(
      planned: planned,
      minutesUntil: event.minutesUntil,
      minutesRemaining: event.minutesRemaining,
      liveFallback: event.happeningNow(),
    );
    final currentSession = nowNext.displaySession;
    final ratedTrack = _topRatedTrack(event, engagement.ratings);
    final exploredTracks = planned.map((s) => s.trackId).toSet().length;
    final perDay = <String, int>{'Day 1': 0, 'Day 2': 0, 'Day 3': 0};
    for (final session in planned) {
      perDay.update(session.day, (v) => v + 1, ifAbsent: () => 1);
    }

    final summary = _summaryBuilder.build(
      engagement: engagement,
      event: event,
      plan: plan,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event recap'),
        actions: [
          IconButton(
            tooltip: 'Download summary',
            icon: const Icon(Icons.description_outlined),
            onPressed: () => _downloadSummary(summary, event),
          ),
          IconButton(
            tooltip: 'Download share card',
            icon: const Icon(Icons.download),
            onPressed: _downloadPng,
          ),
        ],
      ),
      body: ResponsiveLayout(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            RecapAutoAdvancePageView(
              children: [
                RecapWrappedPanel(
                  title: 'XP and Level',
                  child: Center(
                    child: RingGauge(
                      progress:
                          (engagement.xp /
                                  (engagement.nextMilestone == 0
                                      ? 1
                                      : engagement.nextMilestone))
                              .clamp(0, 1),
                      label: '${engagement.levelLabel}\n${engagement.xp} XP',
                    ),
                  ),
                ),
                RecapWrappedPanel(
                  title: 'So far',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mid-event progress',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _SoFarStatCard(
                              icon: Icons.bookmark,
                              label: 'Bookmarked',
                              value: '$bookmarked',
                              color: AppColors.accentStart,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SoFarStatCard(
                              icon: Icons.verified,
                              label: 'Attended',
                              value: '$attended',
                              color: Colors.cyan,
                            ),
                          ),
                        ],
                      ),
                      if (currentSession != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          nowNext.now != null
                              ? 'Happening now: ${currentSession.title}'
                              : 'Up next: ${currentSession.title}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed:
                              engagement.attendedSessionIds.contains(
                                currentSession.id,
                              )
                              ? null
                              : () => _markCurrentAttended(
                                  context,
                                  currentSession,
                                ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(
                            engagement.attendedSessionIds.contains(
                                  currentSession.id,
                                )
                                ? 'Current session marked attended'
                                : 'Mark current session attended',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (summary.noteExcerpts.isNotEmpty)
                  RecapWrappedPanel(
                    title: 'Your session notes',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final note in summary.noteExcerpts)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(note.title),
                            subtitle: Text(note.excerpt),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () =>
                                context.push('/session/${note.sessionId}'),
                          ),
                      ],
                    ),
                  ),
                if (summary.worthItSessions.isNotEmpty)
                  RecapWrappedPanel(
                    title: 'Worth it',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final title in summary.worthItSessions)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.thumb_up,
                              color: AppColors.accentStart,
                            ),
                            title: Text(title),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () =>
                                _openSessionByTitle(context, event, title),
                          ),
                      ],
                    ),
                  ),
                RecapWrappedPanel(
                  title: 'Tracks Explored',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You explored $exploredTracks of ${event.tracks.length} tracks',
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: [
                          for (final trackId
                              in planned.map((s) => s.trackId).toSet())
                            Chip(
                              label: Text(
                                event.trackById(trackId)?.name ?? trackId,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                RecapWrappedPanel(
                  title: 'Sessions by Day',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar('Day 1', perDay['Day 1']!, Colors.teal),
                      _bar('Day 2', perDay['Day 2']!, Colors.cyan),
                      _bar('Day 3', perDay['Day 3']!, Colors.green),
                    ],
                  ),
                ),
                RecapWrappedPanel(
                  title: 'Highlights',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('You bookmarked ${planned.length} sessions'),
                      Text('You attended $attended sessions'),
                      Text(
                        'You reacted to ${engagement.reactions.length} sessions',
                      ),
                      Text('Top rated track: ${ratedTrack ?? 'N/A'}'),
                      Text('Most active day: ${_maxDay(perDay)}'),
                      Text(
                        'Estimated walking distance: ${planned.length * 120}m',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: -RecapShareCard.cardWidth - 32,
              top: 0,
              child: RepaintBoundary(
                key: _shareKey,
                child: RecapShareCard(
                  xp: engagement.xp,
                  levelLabel: engagement.levelLabel,
                  bookmarked: bookmarked,
                  attended: attended,
                  tracksExplored: exploredTracks,
                  topRatedTrack: ratedTrack,
                  plannedSessionTitles: summary.plannedSessionTitles,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadSummary(RecapSummary summary, EventState event) {
    final eventName = event.meta?.eventName ?? 'Flo Compass';
    downloadText(summary.toText(eventName: eventName), 'flo-compass-recap.txt');
  }

  Widget _bar(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 64, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: (value / 10).clamp(0, 1),
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text('$value'),
        ],
      ),
    );
  }

  String _maxDay(Map<String, int> perDay) {
    final sorted = perDay.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  String? _topRatedTrack(EventState event, Map<String, int> ratings) {
    if (ratings.isEmpty) return null;
    final byTrack = <String, List<int>>{};
    ratings.forEach((sessionId, stars) {
      final session = event.sessionById(sessionId);
      if (session == null) return;
      byTrack.putIfAbsent(session.trackId, () => []).add(stars);
    });
    String? bestTrack;
    double bestAvg = -1;
    byTrack.forEach((trackId, values) {
      final avg = values.reduce((a, b) => a + b) / values.length;
      if (avg > bestAvg) {
        bestAvg = avg;
        bestTrack = event.trackById(trackId)?.name ?? trackId;
      }
    });
    return bestTrack;
  }

  Future<void> _markCurrentAttended(
    BuildContext context,
    Session session,
  ) async {
    final engagement = context.read<EngagementState>();
    final event = context.read<EventState>();
    final plan = context.read<PlanState>();
    final profile = context.read<ProfileState>();
    final delta = await engagement.markAttended(
      session.id,
      session.day,
      event: event,
      plan: plan,
      profile: profile,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            liveRegion: true,
            child: Text('+$delta XP · Marked attended'),
          ),
        ),
      );
    }
  }

  void _openSessionByTitle(
    BuildContext context,
    EventState event,
    String title,
  ) {
    final session = event.sessions.firstWhere(
      (s) => s.title == title,
      orElse: () => event.sessions.first,
    );
    context.push('/session/${session.id}');
  }

  Future<void> _downloadPng() async {
    final shareContext = _shareKey.currentContext;
    if (shareContext == null) return;
    final boundary = shareContext.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    downloadPng(bytes.buffer.asUint8List(), 'flo-compass-recap.png');
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Share card downloaded')));
  }
}

class _SoFarStatCard extends StatelessWidget {
  const _SoFarStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
