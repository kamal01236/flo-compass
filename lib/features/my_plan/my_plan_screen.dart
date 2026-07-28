import 'dart:async';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/models.dart';
import '../../data/services/ics_export_service.dart';
import '../../data/services/plan_share_service.dart';
import '../../data/services/walking_time_estimator.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/discovery_delight_sheets.dart';
import '../../providers/agenda_alerts_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/engagement_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/plan_provider.dart';
import '../../shared/tour/tour_targets.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/discover_scroll_bridge.dart';
import '../../shared/utils/event_day_mode.dart';
import '../../shared/utils/web_download.dart';
import '../../shared/widgets/map_chip_button.dart';
import '../../shared/widgets/plan_share_card.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'widgets/my_plan_notes_section.dart';

class MyPlanScreen extends StatefulWidget {
  const MyPlanScreen({super.key});

  @override
  State<MyPlanScreen> createState() => _MyPlanScreenState();
}

class _MyPlanScreenState extends State<MyPlanScreen> {
  final _shareKey = GlobalKey();
  final _planShareService = PlanShareService();
  final _icsExport = IcsExportService();
  final _walking = WalkingTimeEstimator();
  final _scrollController = ScrollController();
  DiscoverScrollBridge? _scrollBridge;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_reportScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollBridge ??= DiscoverScrollBridge.maybeOf(context);
    _scrollBridge?.register(_scrollToTop);
  }

  void _reportScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    _scrollBridge?.reportScrollOffset(offset, atTop: offset <= 0);
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    unawaited(
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _scrollBridge?.register(null);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = context.watch<EventState>();
    final plan = context.watch<PlanState>();
    final agendaAlerts = context.watch<AgendaAlertsState>();
    final engagement = context.watch<EngagementState>();
    final appSettings = context.watch<AppSettingsState>();
    final isEventDayMode = resolveEventDayModeForEvent(
      appSettings.settings,
      event.currentDay,
    );
    final planned = plan.plannedSessions(event.sessions);
    final conflicts = plan.conflicts(event.sessions);
    final grouped = _groupByDay(planned);

    final shareToken = _planShareService.encodeSessionIds(plan.sessionIds);
    final shareUrl = '/plan/import?d=$shareToken';
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabMyPlan),
        actions: [if (!isEventDayMode) const EventNotificationAppBarAction()],
      ),
      body: ResponsiveLayout(
        child: event.loading
            ? const Center(child: CircularProgressIndicator())
            : planned.isEmpty
            ? EmptyState(
                title: l10n.myPlanEmptyTitle,
                message: l10n.myPlanEmptyMessage,
                icon: Icons.bookmark_outline,
                action: Wrap(
                  spacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () => context.go('/discover'),
                      child: Text(l10n.myPlanBrowseSessions),
                    ),
                    OutlinedButton(
                      onPressed: () =>
                          context.go('/companion?q=Plan%20my%20Day%201'),
                      child: Text(l10n.myPlanAskFloDay1),
                    ),
                  ],
                ),
              )
            : ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  RepaintBoundary(
                    key: _shareKey,
                    child: Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: PlanShareCard(sessions: planned),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _downloadPng(),
                          icon: const Icon(Icons.download),
                          label: const Text('Download PNG'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => showBuildAfternoonSheet(context),
                          icon: const Icon(Icons.schedule),
                          label: const Text('Build my afternoon'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: shareUrl),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Share link copied'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.link),
                          label: const Text('Copy shareable link'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            final content = _icsExport.buildForSessions(
                              sessions: planned,
                              meta: event.meta,
                              resolveVenueName: (id) =>
                                  event.venueById(id)?.name ?? id,
                            );
                            downloadText(
                              content,
                              'flo-compass-plan.ics',
                              mimeType: 'text/calendar',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Calendar file downloaded'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('Export plan to calendar'),
                        ),
                      ],
                    ),
                  ),
                  const MyPlanNotesSection(),
                  const SizedBox(height: 8),
                  Card(
                    key: tourMyPlanSummaryKey,
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '${planned.length} sessions · ${planned.where((s) => s.featured).length} keynotes · ${planned.map((s) => s.trackId).toSet().length} tracks · ${engagement.xp} XP',
                      ),
                    ),
                  ),
                  if (conflicts.isNotEmpty)
                    Builder(
                      builder: (context) {
                        final conflictTheme = AppTheme.conflictTheme(context);
                        return Card(
                          color: conflictTheme.background,
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: conflictTheme.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      conflictTheme.icon,
                                      color: conflictTheme.border,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(conflictTheme.label),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                for (final conflict in conflicts) ...[
                                  InkWell(
                                    onTap: () => showSwapSimulatorSheet(
                                      context,
                                      conflict: conflict,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.event_busy,
                                            size: 18,
                                            color: conflictTheme.border,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${conflict.sessionA.title} overlaps ${conflict.sessionB.title}',
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.swap_horiz,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => context.push(
                                        '/companion?q=${Uri.encodeComponent('Fix my plan conflicts')}',
                                      ),
                                      child: const Text('Resolve with Flo'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  for (final entry in grouped.entries) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    ..._buildTimelineForDay(
                      context,
                      event,
                      plan,
                      entry.value,
                      agendaAlerts,
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Map<String, List<Session>> _groupByDay(List<Session> planned) {
    final grouped = <String, List<Session>>{};
    for (final session in planned) {
      grouped.putIfAbsent(session.day, () => []).add(session);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    return grouped;
  }

  List<Widget> _buildTimelineForDay(
    BuildContext context,
    EventState event,
    PlanState plan,
    List<Session> sessions,
    AgendaAlertsState agendaAlerts,
  ) {
    final tiles = <Widget>[];
    Session? previous;
    for (final session in sessions) {
      if (previous != null) {
        final previousEnd = previous.endTime;
        if (previousEnd != session.startTime) {
          tiles.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Free block · $previousEnd to ${session.startTime}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          );
        }
        final estimate = _walking.estimate(
          from: event.venueById(previous.venueId),
          to: event.venueById(session.venueId),
        );
        tiles.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(label: Text('Walk ~${estimate.minutes} min')),
                TextButton(
                  onPressed: () =>
                      context.push('/directions?session=${session.id}'),
                  child: const Text('Directions'),
                ),
              ],
            ),
          ),
        );
      }

      if (agendaAlerts.hasUnreadForSession(session.id)) {
        tiles.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: const Icon(
                  Icons.notifications_active,
                  size: 18,
                  color: Colors.orangeAccent,
                ),
                label: Text(
                  _agendaAlertChipLabel(
                    agendaAlerts.latestUnreadForSession(session.id),
                  ),
                ),
                backgroundColor: Colors.orangeAccent.withValues(alpha: 0.12),
              ),
            ),
          ),
        );
      }

      tiles.add(
        SessionCard(
          title: session.title,
          subtitle:
              '${session.startTime}–${session.endTime} · ${event.venueById(session.venueId)?.name ?? session.venueId}',
          inPlan: true,
          featured: session.featured,
          trailing: MapChipButton(
            venueId: session.venueId,
            venueName:
                event.venueById(session.venueId)?.name ?? session.venueId,
          ),
          onTap: () => context.push('/session/${session.id}'),
          onTogglePlan: () => plan.toggle(session.id),
        ),
      );
      previous = session;
    }
    return tiles;
  }

  String _agendaAlertChipLabel(AgendaChangeAlert? alert) {
    if (alert == null) return 'Schedule updated';
    return switch (alert.type) {
      AgendaChangeType.roomChanged => 'Room updated',
      AgendaChangeType.timeChanged => 'Time updated',
      AgendaChangeType.cancelled => 'Session cancelled',
    };
  }

  Future<void> _downloadPng() async {
    final context = _shareKey.currentContext;
    if (context == null) return;
    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    downloadPng(bytes.buffer.asUint8List(), 'flo-compass-plan.png');
  }
}
