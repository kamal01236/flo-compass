import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../core/analytics/analytics_tracker.dart';
import '../../data/models/models.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/companion_provider.dart';
import '../../providers/engagement_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/profile_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/tour/tour_controller.dart';
import '../../shared/tour/tour_targets.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/connectivity.dart';
import '../../shared/utils/countdown_format.dart';
import '../../shared/utils/discover_scroll_bridge.dart';
import '../../shared/utils/event_day_mode.dart';
import '../../shared/utils/now_next_resolver.dart';
import '../../shared/utils/voice_input.dart';
import '../../shared/utils/web_download.dart';
import '../../shared/widgets/map_chip_button.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../../shared/widgets/streaming_text.dart';

class CompanionScreen extends StatefulWidget {
  const CompanionScreen({super.key, this.initialQuery, this.initialSessionId});

  final String? initialQuery;
  final String? initialSessionId;

  @override
  State<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends State<CompanionScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _voiceSupported = false;
  bool _initialQuerySent = false;
  bool _isListening = false;
  bool _companionWasBusy = false;
  int _lastHistoryLength = 0;
  final _scrollController = ScrollController();
  DiscoverScrollBridge? _scrollBridge;
  CompanionState? _companionState;

  @override
  void initState() {
    super.initState();
    _checkVoiceSupport();
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _controller.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendInitialQuery());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animated: false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollBridge ??= DiscoverScrollBridge.maybeOf(context);
    _scrollBridge?.registerScrollToBottom?.call(_scrollToBottom);
    final companion = context.read<CompanionState>();
    if (_companionState != companion) {
      _companionState?.removeListener(_onCompanionChanged);
      _companionState = companion;
      _lastHistoryLength = companion.history.length;
      _companionWasBusy = companion.busy;
      companion.addListener(_onCompanionChanged);
    }
    _maybeApplyTourPrefill();
  }

  void _maybeApplyTourPrefill() {
    final tour = context.read<TourController>();
    if (!tour.shouldPrefillCompanion) return;
    if (_controller.text.trim().isEmpty) {
      _controller.text = tour.companionSampleQuery;
    }
    tour.markCompanionPrefillApplied();
  }

  void _onCompanionChanged() {
    if (!mounted || _companionState == null) return;
    final companion = _companionState!;
    if (companion.history.length > _lastHistoryLength) {
      _lastHistoryLength = companion.history.length;
      _scrollToBottom();
    }
    if (_companionWasBusy && !companion.busy) {
      _scrollToBottom();
      _scheduleFollowUpScrolls();
    }
    _companionWasBusy = companion.busy;
  }

  void _scheduleFollowUpScrolls() {
    for (final delay in const [
      Duration(milliseconds: 120),
      Duration(milliseconds: 320),
      Duration(milliseconds: 640),
    ]) {
      Future<void>.delayed(delay, () {
        if (mounted) _scrollToBottom(animated: false);
      });
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (animated) {
        unawaited(
          _scrollController.animateTo(
            maxExtent,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          ),
        );
      } else {
        _scrollController.jumpTo(maxExtent);
      }
    });
  }

  Future<void> _sendInitialQuery() async {
    if (_initialQuerySent || !mounted) return;
    _initialQuerySent = true;
    final event = context.read<EventState>();
    if (event.loading) return;
    final companion = context.read<CompanionState>();
    await _send(companion, event, widget.initialQuery!);
  }

  Future<void> _checkVoiceSupport() async {
    final supported = await isVoiceInputSupported();
    if (!mounted) return;
    setState(() => _voiceSupported = supported);
  }

  @override
  void dispose() {
    _scrollBridge?.registerScrollToBottom?.call(null);
    _companionState?.removeListener(_onCompanionChanged);
    _scrollController.dispose();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companion = context.watch<CompanionState>();
    final event = context.watch<EventState>();
    final plan = context.watch<PlanState>();
    final appSettings = context.watch<AppSettingsState>();
    final lowBandwidth = appSettings.isLowBandwidth;
    return ValueListenableBuilder<DateTime>(
      valueListenable: event.clockTicker,
      builder: (context, now, child) {
        final l10n = AppLocalizations.of(context);
        final isEventDay = resolveEventDayModeForEvent(
          appSettings.settings,
          event.currentDay,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Flo, your event guide'),
            actions: [
              if (!isEventDay) const EventNotificationAppBarAction(),
              if (companion.history.isNotEmpty)
                Semantics(
                  label: 'Clear chat',
                  button: true,
                  child: IconButton(
                    tooltip: 'Clear',
                    onPressed: companion.clear,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
            ],
          ),
          body: ResponsiveLayout(
            child: Column(
              children: [
                StreamBuilder<bool>(
                  stream: ConnectivityPlatform.onlineStream,
                  initialData: ConnectivityPlatform.isOnline,
                  builder: (context, snapshot) {
                    final isOnline = snapshot.data ?? true;
                    if (isOnline) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          avatar: Icon(
                            Icons.mic_off,
                            size: 16,
                            color: Colors.amber.shade200,
                          ),
                          label: const Text('Voice may be unavailable offline'),
                          backgroundColor: Colors.amber.withValues(alpha: 0.12),
                          side: BorderSide(
                            color: Colors.amber.withValues(alpha: 0.35),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    );
                  },
                ),
                if (companion.showFallbackBanner)
                  MaterialBanner(
                    content: const Text(
                      'AI enhanced mode unavailable — using local search',
                    ),
                    leading: const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                    ),
                    backgroundColor: Colors.orange.withValues(alpha: 0.1),
                    actions: [
                      TextButton(
                        onPressed: companion.dismissFallbackBanner,
                        child: Text(l10n.commonDismiss),
                      ),
                    ],
                  ),
                if (AppConfig.companionApiEnabled)
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'LLM path enabled via COMPANION_API_URL (demo only)',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Expanded(
                  child: companion.history.isEmpty
                      ? _emptyState(
                          companion,
                          event,
                          plan,
                          isEventDay: isEventDay,
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: companion.history.length,
                          itemBuilder: (context, index) {
                            final item = companion.history[index];
                            return _messageBubble(
                              context,
                              item.query,
                              item.response,
                              lowBandwidth: lowBandwidth,
                            );
                          },
                        ),
                ),
                if (companion.busy)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Flo is thinking...',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          label: _isListening
                              ? 'Listening for your question'
                              : 'Companion question',
                          child: TextField(
                            key: tourCompanionInputKey,
                            controller: _controller,
                            focusNode: _focus,
                            readOnly: _isListening,
                            decoration: InputDecoration(
                              hintText: _isListening
                                  ? 'Listening…'
                                  : 'Ask about sessions, speakers, venues…',
                              hintStyle: _isListening
                                  ? const TextStyle(
                                      color: AppColors.accentStart,
                                    )
                                  : null,
                              border: const OutlineInputBorder(),
                              enabledBorder: _isListening
                                  ? const OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppColors.accentStart,
                                        width: 1.5,
                                      ),
                                    )
                                  : null,
                              focusedBorder: _isListening
                                  ? const OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppColors.accentStart,
                                        width: 2,
                                      ),
                                    )
                                  : null,
                              suffixIcon: _buildVoiceSuffixIcon(
                                companion,
                                event,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _send(companion, event),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        label: 'Send question',
                        button: true,
                        child: IconButton.filled(
                          key: tourCompanionSendKey,
                          onPressed: companion.busy
                              ? null
                              : () => _send(companion, event),
                          icon: companion.busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoiceSuffixIcon(CompanionState companion, EventState event) {
    final tooltip = _voiceSupported
        ? (_isListening ? 'Listening…' : 'Voice input')
        : 'Voice input not supported';

    void onVoicePressed() {
      if (!_voiceSupported) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice input is not supported on this browser'),
          ),
        );
        return;
      }
      if (!_isListening) {
        _startVoiceCapture(companion, event);
      }
    }

    if (_isListening) {
      return Semantics(
        label: 'Listening for your question',
        button: true,
        selected: true,
        child: IconButton.filled(
          tooltip: tooltip,
          onPressed: null,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.accentStart,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.accentStart,
            disabledForegroundColor: Colors.white,
          ),
          icon: const Icon(Icons.mic, size: 20),
        ),
      );
    }

    return Semantics(
      label: _voiceSupported ? 'Voice input' : 'Voice input not supported',
      button: true,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onVoicePressed,
        icon: Icon(_voiceSupported ? Icons.mic : Icons.mic_off, size: 20),
      ),
    );
  }

  Future<void> _startVoiceCapture(
    CompanionState companion,
    EventState event,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isListening = true;
      _controller.clear();
    });
    try {
      final text = await captureVoiceInput();
      if (!mounted) return;
      final transcript = text?.trim() ?? '';
      if (transcript.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No speech detected.')),
        );
        return;
      }
      setState(() => _controller.text = transcript);
      await _send(companion, event);
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  Future<void> _send(
    CompanionState companion,
    EventState event, [
    String? overrideQuery,
  ]) async {
    final profile = context.read<ProfileState>().profile;
    final plan = context.read<PlanState>();
    final engagement = context.read<EngagementState>();
    final messenger = ScaffoldMessenger.of(context);
    final q = overrideQuery ?? _controller.text;
    if (overrideQuery == null) _controller.clear();
    if (q.trim().isEmpty) return;

    await trackAnalytics(
      'companion_question',
      properties: {
        'question_length_bucket': questionLengthBucketForAnalytics(
          q.trim().length,
        ),
        if (companion.lastReferencedSessionId != null ||
            widget.initialSessionId != null)
          'session_id':
              companion.lastReferencedSessionId ?? widget.initialSessionId,
      },
    );

    if (widget.initialSessionId != null &&
        companion.lastReferencedSessionId == null) {
      companion.lastReferencedSessionId = widget.initialSessionId;
    }

    await companion.ask(
      query: q,
      event: event,
      plan: plan,
      profile: profile,
      initialSessionId: widget.initialSessionId,
    );
    if (!mounted) return;
    _scrollToBottom();
    final delta = await engagement.onCompanionQuestion(
      event: event,
      plan: plan,
      profile: context.read<ProfileState>(),
    );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1500),
        content: Text('+$delta XP · Companion question'),
      ),
    );
  }

  Widget _messageBubble(
    BuildContext context,
    String query,
    CompanionMessage response, {
    required bool lowBandwidth,
  }) {
    final event = context.read<EventState>();
    final plan = context.read<PlanState>();
    final linkedSessions = response.sessionIds
        .map(event.sessionById)
        .whereType<Session>()
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppChromeColors.of(context).elevatedPanel,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(query),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.accentStart.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AiBadge(enhanced: response.usedLlm),
              const SizedBox(height: 8),
              StreamingText(
                text: response.text,
                enabled: !response.usedLlm,
                lowBandwidth: lowBandwidth,
              ),
              const SizedBox(height: 8),
              _actionRow(context, response, plan),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: response.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Answer copied')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 14),
                    label: const Text('Copy'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      final markdown =
                          '## Query\n$query\n\n## Answer\n${response.text}\n';
                      downloadText(
                        markdown,
                        'flo-companion-chat.md',
                        mimeType: 'text/markdown',
                      );
                    },
                    icon: const Icon(Icons.download, size: 14),
                    label: const Text('Export .md'),
                  ),
                ],
              ),
              if (response.sources.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Sources',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final source in response.sources.take(6))
                      ActionChip(
                        label: Text(source.label),
                        onPressed: () => _openSource(context, source),
                      ),
                  ],
                ),
              ] else if (response.sessionIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Sources',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final id in response.sessionIds.take(5))
                      ActionChip(
                        label: Text(event.sessionById(id)?.title ?? id),
                        onPressed: () => context.push('/session/$id'),
                      ),
                  ],
                ),
              ],
              if (linkedSessions.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final session in linkedSessions.take(2))
                  Card(
                    child: ListTile(
                      title: Text(session.title),
                      subtitle: Text('${session.day} · ${session.startTime}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MapChipButton(
                            venueId: session.venueId,
                            venueName:
                                event.venueById(session.venueId)?.name ??
                                session.venueId,
                          ),
                          const Icon(Icons.open_in_new),
                        ],
                      ),
                      onTap: () => context.push('/session/${session.id}'),
                    ),
                  ),
              ],
              if (response.followUps.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final followUp in response.followUps.take(4))
                      ActionChip(
                        label: Text(followUp),
                        onPressed: () {
                          if (followUp == 'Get directions' &&
                              response.referencedSessionId != null) {
                            context.push(
                              '/directions?session=${response.referencedSessionId}',
                            );
                            return;
                          }
                          if (followUp == 'Open on map') {
                            final room = response.venueIds.isNotEmpty
                                ? response.venueIds.first
                                : linkedSessions.firstOrNull?.venueId;
                            if (room != null) {
                              context.go('/map?room=$room');
                            }
                            return;
                          }
                          if (followUp == 'Add to My Plan' &&
                              response.referencedSessionId != null) {
                            plan.toggle(response.referencedSessionId!);
                            return;
                          }
                          _controller.text = followUp == 'Save this plan'
                              ? 'Plan my Day 1'
                              : followUp;
                          _focus.requestFocus();
                        },
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionRow(
    BuildContext context,
    CompanionMessage response,
    PlanState plan,
  ) {
    final actions = <Widget>[];

    if (response.navigationAction ==
            CompanionNavigationAction.directionsToSession &&
        response.referencedSessionId != null) {
      actions.add(
        FilledButton.tonalIcon(
          onPressed: () => context.push(
            '/directions?session=${response.referencedSessionId}',
          ),
          icon: const Icon(Icons.directions_walk, size: 16),
          label: const Text('Get directions'),
        ),
      );
    }

    if (response.venueIds.isNotEmpty ||
        response.navigationAction == CompanionNavigationAction.openVenueMap) {
      final room = response.venueIds.isNotEmpty
          ? response.venueIds.first
          : response.referencedSessionId != null
          ? context
                .read<EventState>()
                .sessionById(response.referencedSessionId!)
                ?.venueId
          : null;
      if (room != null) {
        actions.add(
          OutlinedButton.icon(
            onPressed: () => context.go('/map?room=$room'),
            icon: const Icon(Icons.map_outlined, size: 16),
            label: const Text('Open on map'),
          ),
        );
      }
    }

    if (response.referencedSessionId != null &&
        !plan.isInPlan(response.referencedSessionId!)) {
      actions.add(
        OutlinedButton.icon(
          onPressed: () => plan.toggle(response.referencedSessionId!),
          icon: const Icon(Icons.bookmark_add_outlined, size: 16),
          label: const Text('Add to My Plan'),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 6, children: actions);
  }

  void _openSource(BuildContext context, CompanionSource source) {
    switch (source.kind) {
      case 'session':
        context.push('/session/${source.id}');
      case 'venue':
        context.go('/map?room=${source.id}');
      case 'amenity':
        final amenity = context.read<EventState>().amenityById(source.id);
        final room = amenity?.venueId ?? 'ven-G01';
        context.go('/map?room=$room');
      default:
        break;
    }
  }

  Widget _emptyState(
    CompanionState companion,
    EventState event,
    PlanState plan, {
    required bool isEventDay,
  }) {
    if (isEventDay) {
      return _eventDayEmptyState(companion, event, plan);
    }
    return _genericEmptyState(companion, event);
  }

  Widget _eventDayEmptyState(
    CompanionState companion,
    EventState event,
    PlanState plan,
  ) {
    final planned = plan.plannedSessions(event.sessions);
    final nowNext = resolveNowNext(
      planned: planned,
      minutesUntil: event.minutesUntil,
      minutesRemaining: event.minutesRemaining,
      liveFallback: event.happeningNow(),
    );
    final next = nowNext.next ?? nowNext.now;
    final featured = event.sessions.where((s) => s.featured).firstOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: AppColors.accentStart.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Right now at Flo 2026',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (next != null) ...[
                    Text(
                      next.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event.venueById(next.venueId)?.name ?? next.venueId} · '
                      '${CountdownFormat.formatUntil(event.minutesUntil(next), now: event.currentTime, target: event.sessionStart(next))}',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () =>
                          context.push('/directions?session=${next.id}'),
                      icon: const Icon(Icons.directions_walk),
                      label: const Text('Get directions'),
                    ),
                  ] else if (featured != null) ...[
                    Text(
                      'Flo Pick: ${featured.title}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        _controller.text = 'Where is ${featured.title}?';
                        _send(companion, event);
                      },
                      child: const Text('Where is this session?'),
                    ),
                  ] else
                    Text(
                      'Ask me anything about sessions, rooms, or your plan.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.help_outline, size: 16),
                label: const Text("I'm lost"),
                onPressed: () => _send(companion, event, "I'm lost"),
              ),
              ActionChip(
                avatar: const Icon(Icons.schedule, size: 16),
                label: const Text("I'm late"),
                onPressed: () => _send(companion, event, "I'm late"),
              ),
              ActionChip(
                avatar: const Icon(Icons.merge_type, size: 16),
                label: const Text('Fix my conflicts'),
                onPressed: () => _send(companion, event, 'Fix my plan'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Try asking', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final prompt in _dynamicPrompts(event, planned))
                ActionChip(
                  label: Text(prompt),
                  onPressed: () => _send(companion, event, prompt),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _dynamicPrompts(EventState event, List<Session> planned) {
    final hour = event.currentTime?.hour ?? 10;
    if (hour < 11) {
      return const ['Plan my Day 1', "What's happening now?", 'CEO fireside'];
    }
    if (hour >= 11 && hour < 13) {
      return const [
        "Where's my next room?",
        'I have 15 minutes',
        'Nearest restroom on Floor 8',
      ];
    }
    if (hour >= 12 && hour < 14) {
      return const [
        'Cafeteria talks now',
        'Nearest quiet zone',
        'What\'s in my next 2 hours',
      ];
    }
    return const ["Where's my next room?", 'Fix my plan', 'Nearest restroom'];
  }

  Widget _genericEmptyState(CompanionState companion, EventState event) {
    final profile = context.read<ProfileState>().profile;
    final interestLabels = profile.interests.take(3).toList();
    final featured = event.sessions.where((s) => s.featured).take(2).toList();
    final prompts = <String>[
      if (interestLabels.isNotEmpty)
        'Plan my Day 1 for ${interestLabels.first}',
      if (interestLabels.length > 1)
        'What is the best ${interestLabels[1]} session today?',
      if (featured.isNotEmpty) 'Where is ${featured.first.title}?',
      "What's happening at 3PM?",
    ];
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const EmptyState(
            title: 'Ask Flo about Flo 2026',
            message: 'Try one of these sample prompts.',
            icon: Icons.chat_bubble_outline,
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final prompt in prompts)
                ActionChip(
                  label: Text(prompt),
                  onPressed: () => _send(companion, event, prompt),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
