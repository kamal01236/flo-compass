import 'dart:async';
import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/analytics/analytics_tracker.dart';
import '../../data/models/models.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/daily_quest_service.dart';
import '../../data/services/micro_agenda_service.dart';
import '../../data/services/plain_english_service.dart';
import '../../providers/context_adapters.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/engagement_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/flo_meets_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/a11y/motion_policy.dart';
import '../../shared/utils/discover_scroll_bridge.dart';
import '../../shared/utils/session_format_filter.dart';
import '../../shared/utils/social_proof.dart';
import '../../shared/utils/event_day_mode.dart';
import '../../shared/utils/event_notifications.dart';
import '../../shared/utils/event_stage.dart';
import '../../shared/tour/tour_targets.dart';
import '../../shared/widgets/discovery_delight_sheets.dart';
import '../../shared/widgets/map_chip_button.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'discover_filters.dart';
import 'widgets/discover_session_list.dart';
import 'widgets/flo_meet_discover_chip.dart';
import 'widgets/discover_top_header.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    this.initialFilters = const DiscoverFilters(),
  });

  final DiscoverFilters initialFilters;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  static const _plainEnglish = PlainEnglishService();
  static const _searchHints = <String>[
    'Search sessions…',
    'Try "Kubernetes"',
    'Try "GenAI"',
    'Try a speaker name',
  ];
  String? _dayFilter;
  String? _trackFilter;
  String? _floorFilter;
  String? _wingFilter;
  String _search = '';
  DiscoverSortMode _sortMode = DiscoverSortMode.relevance;
  bool _showAllTracks = false;
  int _visibleCount = 30;
  int _rankedTotal = 0;
  bool _loadingMore = false;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  Timer? _uriSyncDebounce;
  bool _suppressUriSync = false;
  DiscoverScrollBridge? _scrollBridge;
  final ValueNotifier<int> _searchHintIndex = ValueNotifier<int>(0);
  Timer? _searchHintTimer;
  bool _searchHintsStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollBridge = DiscoverScrollBridge.maybeOf(context);
    if (!_searchHintsStarted) {
      _searchHintsStarted = true;
      if (shouldAnimate(context)) {
        _searchHintTimer = Timer.periodic(const Duration(seconds: 4), (_) {
          if (!mounted) return;
          _searchHintIndex.value =
              (_searchHintIndex.value + 1) % _searchHints.length;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _applyFilters(widget.initialFilters, syncUri: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerScrollBridge();
      final event = context.read<EventState>();
      final engagement = context.read<EngagementState>();
      unawaited(engagement.syncQuestDay(event.currentDay));
    });
  }

  @override
  void didUpdateWidget(covariant DiscoverScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilters != widget.initialFilters) {
      _applyFilters(widget.initialFilters, syncUri: false);
    }
  }

  @override
  void dispose() {
    _scrollBridge?.register(null);
    _debounce?.cancel();
    _uriSyncDebounce?.cancel();
    _searchHintTimer?.cancel();
    _searchHintIndex.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _registerScrollBridge() {
    if (!mounted) return;
    _scrollBridge ??= DiscoverScrollBridge.maybeOf(context);
    _scrollBridge?.register(_scrollToTop);
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

  void _applyFilters(DiscoverFilters filters, {required bool syncUri}) {
    _suppressUriSync = true;
    setState(() {
      _dayFilter = filters.day;
      _trackFilter = filters.track;
      _floorFilter = filters.floor;
      _wingFilter = filters.wing;
      _search = filters.query?.toLowerCase() ?? '';
      _sortMode = filters.sort;
      _searchController.text = filters.query ?? '';
      _visibleCount = 30;
      _loadingMore = false;
    });
    _suppressUriSync = false;
    if (syncUri) _scheduleUriSync();
  }

  DiscoverFilters _currentFilters() {
    return DiscoverFilters(
      day: _dayFilter,
      floor: _floorFilter,
      wing: _wingFilter,
      track: _trackFilter,
      query: _search.isEmpty ? null : _search,
      sort: _sortMode,
    );
  }

  void _scheduleUriSync() {
    if (_suppressUriSync) return;
    _uriSyncDebounce?.cancel();
    _uriSyncDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final router = GoRouter.maybeOf(context);
      if (router == null) return;
      final uri = _currentFilters().toUri();
      final current = router.state.uri;
      if (current.path == uri.path && current.query == uri.query) return;
      router.go(uri.toString());
    });
  }

  void _updateFilter(VoidCallback apply) {
    setState(apply);
    _scheduleUriSync();
  }

  Future<void> _copyDiscoverLink() async {
    final uri = _currentFilters().toUri();
    final url = Uri.base.replace(path: uri.path, query: uri.query).toString();
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Discover link copied')));
  }

  void _loadMoreIfNeeded() {
    if (_loadingMore || _visibleCount >= _rankedTotal) return;
    _loadingMore = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _visibleCount = min(_visibleCount + 30, _rankedTotal));
      _loadingMore = false;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final offset = position.pixels;
    _scrollBridge?.onScrollOffset?.call(offset, atTop: offset <= 0);
    if (!position.hasContentDimensions || position.maxScrollExtent <= 0) {
      return;
    }
    final threshold = position.maxScrollExtent - 220;
    if (offset < threshold) return;
    _loadMoreIfNeeded();
  }

  FloMeetsState? _maybeFloMeets(BuildContext context) {
    try {
      return context.watch<FloMeetsState>();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = context.watch<EventState>();
    final profile = context.watch<ProfileState>().profile;
    final plan = context.watch<PlanState>();
    final engagement = context.watch<EngagementState>();
    final floMeets = _maybeFloMeets(context);
    final lowBandwidth = context.watch<AppSettingsState>().isLowBandwidth;
    final showPlainEnglish = context
        .watch<AppSettingsState>()
        .showPlainEnglishCards;
    return ValueListenableBuilder<DateTime>(
      valueListenable: event.clockTicker,
      builder: (context, now, _) {
        final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
        final isEventDayMode = resolveEventDayModeForEvent(
          context.watch<AppSettingsState>().settings,
          event.currentDay,
        );
        final stage = resolveStage(current: event.currentTime ?? now);
        final notifications = resolveEventNotificationsFromContext(context);

        final l10n = AppLocalizations.of(context);
        return Scaffold(
          appBar: AppBar(
            title: GradientTitle(l10n.tabDiscover),
            actions: [
              if (!isEventDayMode) const EventNotificationAppBarAction(),
              if (MediaQuery.sizeOf(context).width < 520)
                PopupMenuButton<String>(
                  tooltip: 'Discover actions',
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'surprise':
                        _surpriseMe(context, event, profile, plan, engagement);
                      case 'copy':
                        unawaited(_copyDiscoverLink());
                      default:
                        if (value.startsWith('sort-')) {
                          final mode = DiscoverSortMode.values.firstWhere(
                            (m) => m.name == value.substring(5),
                            orElse: () => DiscoverSortMode.relevance,
                          );
                          _updateFilter(() => _sortMode = mode);
                        }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'surprise',
                      child: Text('Surprise me'),
                    ),
                    const PopupMenuItem(
                      value: 'copy',
                      child: Text('Copy link'),
                    ),
                    const PopupMenuDivider(),
                    for (final mode in discoverAppBarSortModes)
                      PopupMenuItem(
                        value: 'sort-${mode.name}',
                        child: _sortMenuRow(mode),
                      ),
                  ],
                )
              else ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: () =>
                      _surpriseMe(context, event, profile, plan, engagement),
                  child: const Text('Surprise me'),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Copy link',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.link),
                  onPressed: _copyDiscoverLink,
                ),
                _sortMenuButton(),
                const SizedBox(width: 8),
              ],
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Semantics(
                  label: 'Search sessions',
                  child: KeyedSubtree(
                    key: isCurrentRoute ? tourDiscoverSearchKey : null,
                    child: ValueListenableBuilder<int>(
                      valueListenable: _searchHintIndex,
                      builder: (context, hintIndex, _) => TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: _searchHints[hintIndex],
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _search = '');
                                    _scheduleUriSync();
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {});
                          _debounce?.cancel();
                          _debounce = Timer(
                            const Duration(milliseconds: 300),
                            () {
                              if (!mounted) return;
                              setState(
                                () => _search = value.trim().toLowerCase(),
                              );
                              _scheduleUriSync();
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: _buildBody(
            event,
            profile,
            plan,
            engagement,
            floMeets,
            lowBandwidth,
            isEventDayMode,
            showPlainEnglish,
            stage,
            notifications,
            now,
          ),
        );
      },
    );
  }

  Widget _sortMenuRow(DiscoverSortMode mode) {
    return Row(
      children: [
        Expanded(child: Text(mode.label)),
        if (mode == _sortMode) const Icon(Icons.check, size: 18),
      ],
    );
  }

  Widget _sortMenuButton() {
    return PopupMenuButton<DiscoverSortMode>(
      tooltip: _sortMode.label,
      icon: const Icon(Icons.sort),
      onSelected: (value) => _updateFilter(() => _sortMode = value),
      itemBuilder: (context) => [
        for (final mode in discoverAppBarSortModes)
          PopupMenuItem(value: mode, child: _sortMenuRow(mode)),
      ],
    );
  }

  Widget _buildBody(
    EventState event,
    UserProfile profile,
    PlanState plan,
    EngagementState engagement,
    FloMeetsState? floMeets,
    bool lowBandwidth,
    bool isEventDayMode,
    bool showPlainEnglish,
    EventStage stage,
    EventNotificationSnapshot notifications,
    DateTime now,
  ) {
    if (event.loading) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, _) => const SessionSkeletonCard(),
      );
    }
    if (event.error != null) {
      return ErrorView(technicalDetail: event.error, onRetry: event.load);
    }

    var ranked = event.rankedSessions(profile);
    if (_dayFilter != null) {
      ranked = ranked.where((s) => s.session.day == _dayFilter).toList();
    }
    if (_trackFilter != null) {
      ranked = ranked.where((s) => s.session.trackId == _trackFilter).toList();
    }
    if (_floorFilter != null || _wingFilter != null) {
      ranked = ranked.where((s) {
        final venue = event.venueById(s.session.venueId);
        return (_floorFilter == null || venue?.floor == _floorFilter) &&
            (_wingFilter == null || venue?.wing == _wingFilter);
      }).toList();
    }
    if (_search.isNotEmpty) {
      final index = event.searchIndex;
      ranked = ranked
          .where(
            (s) => index.isReady
                ? index.matchesSession(s.session, _search)
                : s.session.title.toLowerCase().contains(_search) ||
                      s.session.tags.any(
                        (t) => t.toLowerCase().contains(_search),
                      ),
          )
          .toList();
    }

    ranked = _sortRanked(ranked, event);
    ranked = applyEnergyFilter(ranked, profile.energyFilter);
    _rankedTotal = ranked.length;

    final happeningNow = event.happeningNow();
    final startingSoon = event.startingSoon();
    final visible = ranked.take(_visibleCount).toList();
    final canLoadMore = visible.length < ranked.length;

    final profileState = context.read<ProfileState>();
    final l10n = AppLocalizations.of(context);
    final recCtx = buildRecommendationContext(
      profile: profileState,
      plan: plan,
      event: event,
    );
    final heroSession = isEventDayMode
        ? event.recommendationService.pickFloPickHero(recCtx)
        : null;
    final heroReasons = heroSession == null
        ? const <String>[]
        : event.recommendationService
              .rankSessions(
                sessions: [heroSession],
                speakers: event.speakers,
                tracks: event.tracks,
                profile: profile,
                now: event.currentTime,
                behaviorSnapshot: event.behaviorSnapshot,
              )
              .first
              .matchReasons;

    const densityLeadCount = 3;
    final earlySessions = visible.take(densityLeadCount).toList();
    final lateSessions = visible.length > densityLeadCount
        ? visible.sublist(densityLeadCount)
        : <ScoredSession>[];

    final topHeader = <Widget>[
      DiscoverTopHeader(
        event: event,
        profile: profile,
        isEventDayMode: isEventDayMode,
        stage: stage,
        notifications: notifications,
        heroSession: heroSession,
        heroReasons: heroReasons,
        rankedCount: ranked.length,
        dayFilter: _dayFilter,
        trackFilter: _trackFilter,
        floorFilter: _floorFilter,
        wingFilter: _wingFilter,
        showAllTracks: _showAllTracks,
        onDayFilter: (day) => _updateFilter(() => _dayFilter = day),
        onTrackFilter: (track) => _updateFilter(() => _trackFilter = track),
        onFloorFilter: (floor) => _updateFilter(() => _floorFilter = floor),
        onWingFilter: (wing) => _updateFilter(() => _wingFilter = wing),
        onShowAllTracks: () => setState(() => _showAllTracks = true),
        onClearAllFilters: _clearAllFilters,
        hasActiveFilters: _hasNonSearchActiveFilters(),
      ),
      if (floMeets != null && floMeets.preferences.isSetupComplete)
        Builder(
          builder: (context) {
            final nextMeet = floMeets.nextMeetToday(event.currentDay, now);
            if (nextMeet == null) return const SizedBox.shrink();
            return FloMeetDiscoverChip(meet: nextMeet);
          },
        ),
    ];

    final belowFoldHeader = <Widget>[
      DiscoverLearningPathsRow(
        event: event,
        plan: plan,
        engagement: engagement,
      ),
      _MicroAgendaRow(
        sessions: MicroAgendaService(
          clockService: event.clockService,
        ).nextTwoHours(event: event, plan: plan, profile: profile),
        onSessionTap: _pushSession,
      ),
      if (happeningNow.isNotEmpty)
        DiscoverLiveStrip(
          event: event,
          sessions: happeningNow,
          title: l10n.discoverHappeningNow,
          pulse: !lowBandwidth && shouldAnimate(context),
          showRemaining: true,
          onSessionTap: _pushSession,
        ),
      if (startingSoon.isNotEmpty)
        DiscoverLiveStrip(
          event: event,
          sessions: startingSoon,
          title: l10n.discoverStartingSoon,
          onSessionTap: _pushSession,
        ),
      DiscoverDailyQuestCard(engagement: engagement, event: event),
    ];

    return ResponsiveLayout(
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverList(delegate: SliverChildListDelegate(topHeader)),
          if (ranked.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                title: l10n.discoverEmptyFiltered,
                message: l10n.discoverEmptyFilteredHint,
              ),
            )
          else
            SliverLayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(14);
                final grid =
                    constraints.crossAxisExtent >= 900 &&
                    !lowBandwidth &&
                    textScale <= 1.5;
                if (grid) {
                  return SliverMainAxisGroup(
                    slivers: [
                      SliverList(
                        delegate: SliverChildListDelegate(belowFoldHeader),
                      ),
                      SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: (1.35 / textScale).clamp(
                            0.75,
                            1.35,
                          ),
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _sessionTile(
                            event,
                            plan,
                            visible[index],
                            lowBandwidth: lowBandwidth,
                            showPlainEnglish: showPlainEnglish,
                          );
                        }, childCount: visible.length),
                      ),
                      if (canLoadMore)
                        SliverToBoxAdapter(
                          child: DiscoverLoadMoreButton(
                            onPressed: _loadMoreIfNeeded,
                          ),
                        ),
                    ],
                  );
                }
                return SliverMainAxisGroup(
                  slivers: [
                    if (earlySessions.isNotEmpty)
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _sessionTile(
                            event,
                            plan,
                            earlySessions[index],
                            lowBandwidth: lowBandwidth,
                            enableSwipe: true,
                            showPlainEnglish: showPlainEnglish,
                          );
                        }, childCount: earlySessions.length),
                      ),
                    SliverList(
                      delegate: SliverChildListDelegate(belowFoldHeader),
                    ),
                    if (lateSessions.isNotEmpty)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= lateSessions.length) {
                              return DiscoverLoadMoreButton(
                                onPressed: _loadMoreIfNeeded,
                              );
                            }
                            return _sessionTile(
                              event,
                              plan,
                              lateSessions[index],
                              lowBandwidth: lowBandwidth,
                              enableSwipe: true,
                              showPlainEnglish: showPlainEnglish,
                            );
                          },
                          childCount:
                              lateSessions.length + (canLoadMore ? 1 : 0),
                        ),
                      )
                    else if (canLoadMore)
                      SliverToBoxAdapter(
                        child: DiscoverLoadMoreButton(
                          onPressed: _loadMoreIfNeeded,
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  List<ScoredSession> _sortRanked(
    List<ScoredSession> ranked,
    EventState event,
  ) {
    final list = [...ranked];
    switch (_sortMode) {
      case DiscoverSortMode.relevance:
        return list;
      case DiscoverSortMode.soonest:
        list.sort((a, b) {
          final d = a.session.dayNumber.compareTo(b.session.dayNumber);
          if (d != 0) return d;
          return a.session.startTime.compareTo(b.session.startTime);
        });
        return list;
      case DiscoverSortMode.featuredFirst:
        list.sort((a, b) {
          if (a.session.featured != b.session.featured) {
            return a.session.featured ? -1 : 1;
          }
          return b.score.compareTo(a.score);
        });
        return list;
      case DiscoverSortMode.speakerTier:
        int tierOf(ScoredSession s) {
          final speakerId = s.session.speakerIds.isEmpty
              ? null
              : s.session.speakerIds.first;
          return event.speakerById(speakerId ?? '')?.tier ?? 5;
        }

        list.sort((a, b) {
          final tierCompare = tierOf(a).compareTo(tierOf(b));
          if (tierCompare != 0) return tierCompare;
          return b.score.compareTo(a.score);
        });
        return list;
      case DiscoverSortMode.happeningNow:
        final happeningIds = event.happeningNow().map((s) => s.id).toSet();
        list.sort((a, b) {
          final aLive = happeningIds.contains(a.session.id);
          final bLive = happeningIds.contains(b.session.id);
          if (aLive != bLive) return aLive ? -1 : 1;
          return b.score.compareTo(a.score);
        });
        return list;
    }
  }

  bool _hasNonSearchActiveFilters() {
    return _dayFilter != null ||
        _floorFilter != null ||
        _wingFilter != null ||
        _trackFilter != null;
  }

  bool _hasActiveFilters() {
    return _dayFilter != null ||
        _floorFilter != null ||
        _wingFilter != null ||
        _trackFilter != null ||
        _search.isNotEmpty;
  }

  void _clearAllFilters() {
    if (!_hasActiveFilters()) return;
    _updateFilter(() {
      _dayFilter = null;
      _trackFilter = null;
      _floorFilter = null;
      _wingFilter = null;
      _search = '';
      _searchController.clear();
    });
  }

  void _pushSession(String sessionId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.push('/session/$sessionId');
    });
  }

  Widget _sessionTile(
    EventState event,
    PlanState plan,
    ScoredSession scored, {
    required bool lowBandwidth,
    bool enableSwipe = false,
    bool showPlainEnglish = false,
  }) {
    final session = scored.session;
    final venue = event.venueById(session.venueId);
    final track = event.trackById(session.trackId);
    final speakerId = session.speakerIds.isEmpty
        ? null
        : session.speakerIds.first;
    final speaker = event.speakerById(speakerId ?? '');
    final subtitle =
        '${session.day} · ${session.startTime} · ${venue?.name ?? session.venueId}${track != null ? ' · ${track.name}' : ''}';

    final venueId = venue?.id ?? session.venueId;
    final venueName = venue?.name ?? session.venueId;
    final card = Semantics(
      label: 'Swipe to bookmark',
      child: SessionCard(
        title: session.title,
        subtitle: subtitle,
        matchReasons: scored.matchReasons,
        featured: session.featured,
        inPlan: plan.isInPlan(session.id),
        trackColor: AppTheme.colorForTrack(track?.id ?? '', track?.color),
        occupancyPercent: session.occupancyPercent,
        attendeeInterestCount: mockSavedCount(session.id),
        showSocialProof: true,
        speakerName: speaker?.name,
        speakerPhotoAsset: speaker?.photoAsset,
        hideSpeakerPhoto: lowBandwidth,
        plainEnglishSummary: showPlainEnglish
            ? _plainEnglish.summarize(session)
            : null,
        sessionAbstract: showPlainEnglish ? session.abstract : null,
        sessionFormat: session.format,
        trailing: MapChipButton(venueId: venueId, venueName: venueName),
        onTap: () => _pushSession(session.id),
        onTogglePlan: () => _togglePlan(context, plan, session.id),
      ),
    );

    if (!enableSwipe) return card;

    final inPlan = plan.isInPlan(session.id);
    return Dismissible(
      key: ValueKey('swipe-${session.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.accentStart,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              inPlan ? 'Remove from My Plan' : 'Added to My Plan',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(width: 8),
            Icon(
              inPlan ? Icons.bookmark_remove : Icons.bookmark,
              color: Colors.white,
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        final engagement = context.read<EngagementState>();
        final eventState = context.read<EventState>();
        final profileState = context.read<ProfileState>();
        final messenger = ScaffoldMessenger.of(context);
        final wasInPlan = inPlan;
        final questsBefore = engagement.dailyQuests(eventState.currentDay);
        await plan.toggle(session.id);
        if (!context.mounted) return false;
        if (!wasInPlan) {
          final first = plan.sessionIds.length == 1;
          await eventState.trackBookmark(session.trackId);
          final delta = await engagement.onBookmarkAdded(
            isFirstBookmark: first,
            session: session,
            event: eventState,
            plan: plan,
            profile: profileState,
          );
          _showQuestCompletionSnackbar(
            messenger,
            questsBefore,
            engagement.dailyQuests(eventState.currentDay),
          );
          if (!context.mounted) return false;
          messenger.showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 4),
              content: Semantics(
                liveRegion: true,
                child: Text('+$delta XP · Bookmark added'),
              ),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  unawaited(context.read<PlanState>().toggle(session.id));
                },
              ),
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 4),
              content: Semantics(
                liveRegion: true,
                child: const Text('Removed from My Plan'),
              ),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  unawaited(context.read<PlanState>().toggle(session.id));
                },
              ),
            ),
          );
        }
        return false;
      },
      child: card,
    );
  }

  Future<void> _togglePlan(
    BuildContext context,
    PlanState plan,
    String sessionId,
  ) async {
    final engagement = context.read<EngagementState>();
    final event = context.read<EventState>();
    final profileState = context.read<ProfileState>();
    final messenger = ScaffoldMessenger.of(context);
    final session = event.sessionById(sessionId);
    final adding = !plan.isInPlan(sessionId);
    final first = adding && plan.sessionIds.isEmpty;
    final questsBefore = engagement.dailyQuests(event.currentDay);
    await plan.toggle(sessionId);
    if (session != null) {
      await trackAnalytics(
        adding ? 'bookmark_add' : 'bookmark_remove',
        sessionId: sessionId,
        properties: {
          'session_id': sessionId,
          'track_id': session.trackId,
          'source': 'discover',
          'action': adding ? 'add' : 'remove',
        },
      );
    }
    if (!context.mounted || !adding) return;
    if (session != null) {
      await event.trackBookmark(session.trackId);
    }
    final delta = await engagement.onBookmarkAdded(
      isFirstBookmark: first,
      session: session,
      event: event,
      plan: plan,
      profile: profileState,
    );
    _showQuestCompletionSnackbar(
      messenger,
      questsBefore,
      engagement.dailyQuests(event.currentDay),
    );
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1500),
        content: Semantics(
          liveRegion: true,
          child: Text('+$delta XP · Bookmark added'),
        ),
      ),
    );
  }

  void _showQuestCompletionSnackbar(
    ScaffoldMessengerState messenger,
    List<DailyQuestProgress> before,
    List<DailyQuestProgress> after,
  ) {
    for (var i = 0; i < after.length; i++) {
      if (i >= before.length) continue;
      if (after[i].completed && !before[i].completed) {
        messenger.showSnackBar(
          SnackBar(
            content: Semantics(
              liveRegion: true,
              child: Text('+30 XP · Quest complete: ${after[i].title}'),
            ),
          ),
        );
      }
    }
  }

  void _surpriseMe(
    BuildContext context,
    EventState event,
    UserProfile profile,
    PlanState plan,
    EngagementState engagement,
  ) {
    final profileState = context.read<ProfileState>();
    final pick = event.recommendationService.pickSurprise(
      buildRecommendationContext(
        profile: profileState,
        plan: plan,
        event: event,
      ),
      attendedSessionIds: engagement.attendedSessionIds.toSet(),
    );
    if (pick == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No surprise sessions left — explore filters!'),
        ),
      );
      return;
    }
    unawaited(showSurpriseSessionModal(context, session: pick, event: event));
  }
}

class _MicroAgendaRow extends StatelessWidget {
  const _MicroAgendaRow({required this.sessions, required this.onSessionTap});

  final List<Session> sessions;
  final void Function(String sessionId) onSessionTap;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        child: ExpansionTile(
          initiallyExpanded: false,
          title: const Text('Your next 2 hours'),
          subtitle: Text('${sessions.length} sessions coming up'),
          children: [
            SizedBox(
              height: 88,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                scrollDirection: Axis.horizontal,
                itemCount: sessions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return SizedBox(
                    width: 180,
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      title: Text(
                        session.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        '${session.day} · ${session.startTime}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: () => onSessionTap(session.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
