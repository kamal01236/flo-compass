import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/analytics/analytics_tracker.dart';
import '../../data/models/models.dart';
import '../../data/services/ics_export_service.dart';
import '../../data/services/session_detail_assembler.dart';
import '../../data/services/walking_time_estimator.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/engagement_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/profile_provider.dart';
import '../../shared/tour/tour_controller.dart';
import '../../shared/tour/tour_step.dart';
import '../../shared/tour/tour_targets.dart';
import '../../shared/utils/friendly_error_messages.dart';
import '../../shared/utils/page_meta.dart';
import '../../shared/utils/page_meta_builder.dart';
import '../../shared/utils/web_download.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'session_detail_layout.dart';
import 'widgets/session_detail_companion_fab.dart';
import 'widgets/session_detail_engagement_panel.dart';
import 'widgets/session_detail_hero.dart';
import 'widgets/session_detail_logistics_tab.dart';
import 'widgets/session_detail_overview_tab.dart';
import 'widgets/session_detail_sticky_actions.dart';
import 'widgets/session_detail_qa_tab.dart';
import 'widgets/session_notes_section.dart';

class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen>
    with SingleTickerProviderStateMixin {
  final _assembler = SessionDetailAssembler();
  final _icsExportService = IcsExportService();
  final _walkingTimeEstimator = WalkingTimeEstimator();
  bool _viewRecorded = false;
  TabController? _tabController;
  bool _showQaBadge = false;
  String? _lastAppliedFocus;
  bool _tourTabListenerAttached = false;

  @override
  void dispose() {
    if (_tabController != null && _tourTabListenerAttached) {
      _tabController!.removeListener(_onTourTabChanged);
      _tourTabListenerAttached = false;
    }
    _tabController?.dispose();
    super.dispose();
  }

  void _onTourTabChanged() {
    if (!mounted) return;
    final controller = _tabController;
    if (controller == null) return;
    if (controller.indexIsChanging) return;
    if (controller.index != 1) return;
    TourController? tour;
    try {
      tour = context.read<TourController>();
    } catch (_) {
      return;
    }
    if (!tour.active) return;
    if (tour.currentStep.id != TourStepId.logisticsTab) return;
    unawaited(tour.next());
  }

  int? _focusTabIndex(String? focus) {
    return switch (focus) {
      'overview' => 0,
      'logistics' => 1,
      'qa' => 2,
      _ => null,
    };
  }

  void _syncTabFromRoute() {
    final focus = GoRouter.maybeOf(context)?.state.uri.queryParameters['focus'];
    if (focus == _lastAppliedFocus) return;
    final index = _focusTabIndex(focus);
    if (index == null) return;
    final controller = _tabController;
    if (controller == null) return;
    _lastAppliedFocus = focus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _tabController == null) return;
      if (_tabController!.index != index) {
        _tabController!.animateTo(index);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final event = context.read<EventState>();
    final session = event.sessionById(widget.sessionId);
    if (session != null) {
      applyPageMeta(
        forSession(
          session: session,
          origin: resolvePageMetaOrigin(),
          venue: event.venueById(session.venueId),
        ),
      );
    }
    if (_viewRecorded) return;
    if (session == null) return;
    _viewRecorded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final plan = context.read<PlanState>();
      final profile = context.read<ProfileState>();
      final engagement = context.read<EngagementState>();
      await trackAnalytics(
        'session_view',
        sessionId: session.id,
        properties: {'session_id': session.id, 'track_id': session.trackId},
      );
      await event.recordSessionView(session);
      await engagement.onSessionOpened(
        session: session,
        event: event,
        plan: plan,
        profile: profile,
      );
    });
    _syncTabFromRoute();
  }

  @override
  Widget build(BuildContext context) {
    final event = context.watch<EventState>();
    final plan = context.watch<PlanState>();
    final profile = context.watch<ProfileState>();
    final engagement = context.watch<EngagementState>();
    final appSettings = context.watch<AppSettingsState>();
    final session = event.sessionById(widget.sessionId);

    if (event.loading) {
      return const Scaffold(body: SessionSkeletonCard());
    }

    if (session == null) {
      return _notFoundScaffold(context);
    }

    final viewModel = _assembler.assemble(
      session: session,
      event: event,
      profile: profile.profile,
      plan: plan,
      engagement: engagement,
    );
    final walkEstimate = _walkEstimate(event, plan, session, viewModel.venue);
    final width = MediaQuery.sizeOf(context).width;
    final isNarrow = width < SessionDetailLayout.narrowBreakpoint;
    final tabBottomPadding = isNarrow
        ? SessionDetailLayout.narrowTabBottomPadding
        : SessionDetailLayout.wideTabBottomPadding;
    final showReactions =
        viewModel.attended || event.minutesRemaining(session) < 0;
    final isLive = viewModel.liveState == SessionLiveState.live;
    _showQaBadge = isLive;
    final routeFocus = GoRouter.maybeOf(
      context,
    )?.state.uri.queryParameters['focus'];
    final initialTabIndex = (_focusTabIndex(routeFocus) ?? 0).clamp(0, 2);
    if (_tabController == null) {
      _tabController = TabController(
        length: 3,
        vsync: this,
        initialIndex: initialTabIndex,
      );
      if (routeFocus != null) {
        _lastAppliedFocus = routeFocus;
      }
    }
    if (!_tourTabListenerAttached) {
      _tabController!.addListener(_onTourTabChanged);
      _tourTabListenerAttached = true;
    }
    _syncTabFromRoute();
    final engagementPanel = SessionDetailEngagementPanel(
      session: session,
      showReactions: showReactions,
    );

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/discover'),
          ),
        ),
        title: Text(
          isNarrow ? 'Session' : session.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Semantics(
            label: viewModel.inPlan ? 'Remove from plan' : 'Add to plan',
            button: true,
            child: IconButton(
              tooltip: viewModel.inPlan ? 'Remove from plan' : 'Add to plan',
              onPressed: () => plan.toggle(session.id),
              icon: Icon(
                viewModel.inPlan ? Icons.bookmark : Icons.bookmark_outline,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Overview'),
            KeyedSubtree(
              key: tourLogisticsTabKey,
              child: const Tab(text: 'Logistics'),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Q&A'),
                  if (_showQaBadge) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: ResponsiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: SessionDetailHero(
                session: session,
                viewModel: viewModel,
                track: viewModel.track,
                attendanceMode: profile.profile.attendanceMode,
                onShare: () => _copyShareLink(context, session.id),
                desktopActions: isNarrow
                    ? null
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SessionDetailDesktopActions(
                            session: session,
                            viewModel: viewModel,
                            attendanceMode: profile.profile.attendanceMode,
                            onMarkAttended: () => _markAttended(
                              context,
                              session: session,
                              engagement: engagement,
                              event: event,
                              plan: plan,
                              profile: profile,
                            ),
                            onAddToCalendar: () => _exportIcs(
                              context,
                              session,
                              viewModel.venue,
                              event,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SessionNotesExpandable(sessionId: session.id),
                        ],
                      ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SessionDetailOverviewTab(
                    session: session,
                    viewModel: viewModel,
                    showPlainEnglish: appSettings.showPlainEnglishCards,
                    showPostSessionPulse: showReactions,
                    engagementPanel: engagementPanel,
                    isNarrow: isNarrow,
                    showNotesInOverview: isNarrow,
                    attendanceMode: profile.profile.attendanceMode,
                    walkEstimate: walkEstimate,
                    bottomScrollPadding: tabBottomPadding,
                    onOpenLogistics: () => _tabController?.animateTo(1),
                  ),
                  SessionDetailLogisticsTab(
                    session: session,
                    viewModel: viewModel,
                    event: event,
                    plan: plan,
                    profile: profile.profile,
                    attendanceMode: profile.profile.attendanceMode,
                    walkEstimate: walkEstimate,
                    bottomScrollPadding: tabBottomPadding,
                    onExportIcs: () =>
                        _exportIcs(context, session, viewModel.venue, event),
                  ),
                  SessionDetailQaTab(
                    sessionId: session.id,
                    sessionTitle: session.title,
                    sessionAbstract: session.abstract,
                    bottomScrollPadding: tabBottomPadding,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isNarrow
          ? null
          : SessionDetailCompanionFab(
              sessionId: session.id,
              sessionTitle: session.title,
            ),
      bottomNavigationBar: isNarrow
          ? SessionDetailStickyActions(
              session: session,
              viewModel: viewModel,
              attendanceMode: profile.profile.attendanceMode,
              onMarkAttended: () => _markAttended(
                context,
                session: session,
                engagement: engagement,
                event: event,
                plan: plan,
                profile: profile,
              ),
              onAddToCalendar: () =>
                  _exportIcs(context, session, viewModel.venue, event),
            )
          : null,
    );
  }

  WalkingTimeEstimate? _walkEstimate(
    EventState event,
    PlanState plan,
    Session session,
    Venue? venue,
  ) {
    final previous = _previousPlannedSession(
      plan.plannedSessions(event.sessions),
      session,
    );
    if (previous == null) return null;
    return _walkingTimeEstimator.estimate(
      from: event.venueById(previous.venueId),
      to: venue,
    );
  }

  Session? _previousPlannedSession(List<Session> planned, Session session) {
    final ordered = [...planned]
      ..sort((a, b) {
        final d = a.dayNumber.compareTo(b.dayNumber);
        if (d != 0) return d;
        return a.startTime.compareTo(b.startTime);
      });
    Session? previous;
    for (final item in ordered) {
      if (item.id == session.id) return previous;
      previous = item;
    }
    return null;
  }

  Scaffold _notFoundScaffold(BuildContext context) {
    final copy = FriendlyErrorCopy.random(FriendlyErrorKind.sessionNotFound);
    final debugId = kDebugMode ? 'ID: ${widget.sessionId}' : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Session')),
      body: EmptyState(
        title: copy.title,
        message: debugId == null ? copy.message : '${copy.message}\n\n$debugId',
        semanticsLabel: copy.semanticLabel,
        action: Wrap(
          spacing: 8,
          children: [
            FilledButton(
              onPressed: () => context.go('/discover'),
              child: const Text('Back to Discover'),
            ),
            OutlinedButton(
              onPressed: () => context.go('/companion?q=Find%20session'),
              child: const Text('Ask Flo instead'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyShareLink(BuildContext context, String sessionId) async {
    final url = Uri.base.replace(path: '/session/$sessionId').toString();
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Session link copied')));
    }
  }

  Future<void> _markAttended(
    BuildContext context, {
    required Session session,
    required EngagementState engagement,
    required EventState event,
    required PlanState plan,
    required ProfileState profile,
  }) async {
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

  void _exportIcs(
    BuildContext context,
    Session session,
    Venue? venue,
    EventState event,
  ) {
    final content = _icsExportService.buildForSession(
      session: session,
      meta: event.meta,
      location: venue?.name ?? session.venueId,
    );
    downloadText(content, '${session.id}.ics', mimeType: 'text/calendar');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Calendar file downloaded')));
  }
}
