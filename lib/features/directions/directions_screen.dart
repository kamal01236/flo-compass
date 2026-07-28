import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/models.dart';
import '../../data/services/walking_time_estimator.dart';
import '../../providers/event_provider.dart';
import '../../providers/plan_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/friendly_error_messages.dart';
import '../../shared/widgets/shared_widgets.dart';

class DirectionsScreen extends StatelessWidget {
  const DirectionsScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final event = context.watch<EventState>();
    final plan = context.watch<PlanState>();
    return ValueListenableBuilder<DateTime>(
      valueListenable: event.clockTicker,
      builder: (context, now, child) {
        final isEventDay = event.currentDay != null;
        final session = event.sessionById(sessionId);

        if (event.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (session == null) {
          final copy = FriendlyErrorCopy.random(
            FriendlyErrorKind.sessionNotFound,
          );
          final debugId = kDebugMode ? 'ID: $sessionId' : null;
          return Scaffold(
            appBar: AppBar(title: const Text('Directions')),
            body: EmptyState(
              title: copy.title,
              message: debugId == null
                  ? copy.message
                  : '${copy.message}\n\n$debugId',
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

        final venue = event.venueById(session.venueId);
        final inPlan = plan.isInPlan(session.id);
        final previousPlanned = _previousPlannedSession(
          plan.plannedSessions(event.sessions),
          session,
        );
        final walkEstimate =
            WalkingTimeEstimator(
              campus: event.campus,
              isEventDayMode: isEventDay,
            ).estimate(
              from: previousPlanned == null
                  ? null
                  : event.venueById(previousPlanned.venueId),
              to: venue,
            );
        final countdown = _countdownLabel(event, session);

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
            title: const Text('Directions'),
            actions: const [DiscoverHomeAction()],
          ),
          body: ResponsiveLayout(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      venue?.name ?? session.venueId,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _venueSubhead(venue, session),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${session.day} · ${session.startTime}–${session.endTime}',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            countdown,
                            style: const TextStyle(
                              color: AppColors.accentStart,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (previousPlanned != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  walkEstimate.recommendedMode == 'stairs'
                                      ? Icons.stairs
                                      : Icons.directions_walk,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(_walkPrimaryLabel(walkEstimate)),
                                ),
                              ],
                            ),
                            if (walkEstimate.verticalTip != null ||
                                walkEstimate.alternateMode != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _walkSecondaryLabel(walkEstimate, isEventDay),
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () =>
                          context.push('/map?room=${session.venueId}'),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Open floor map'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/session/${session.id}'),
                      icon: const Icon(Icons.event_note_outlined),
                      label: const Text('Session details'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => plan.toggle(session.id),
                      icon: Icon(
                        inPlan ? Icons.bookmark : Icons.bookmark_outline,
                      ),
                      label: Text(
                        inPlan ? 'Remove from plan' : 'Add to My Plan',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _walkPrimaryLabel(WalkingTimeEstimate estimate) {
    final mode = estimate.recommendedMode;
    if (mode == 'stairs') {
      return 'Stairs ~${estimate.minutes} min (${estimate.reason})';
    }
    if (mode == 'lift') {
      return 'Lifts ~${estimate.minutes} min (${estimate.reason})';
    }
    return '~${estimate.minutes} min walk (${estimate.reason})';
  }

  String _walkSecondaryLabel(WalkingTimeEstimate estimate, bool isEventDay) {
    if (estimate.verticalTip != null) return estimate.verticalTip!;
    if (estimate.alternateMode == 'lift' && isEventDay) {
      return 'Lifts ~5 min in rush';
    }
    if (estimate.alternateMode == 'stairs') {
      return 'Stairs may be faster for short climbs';
    }
    return '';
  }

  String _venueSubhead(Venue? venue, Session session) {
    if (venue == null) {
      return session.building;
    }
    final wing = switch (venue.wing.toLowerCase()) {
      'n' => 'North wing',
      's' => 'South wing',
      _ => '${venue.wing} wing',
    };
    final floorLabel = venue.floor == 'G' ? 'Ground' : 'Floor ${venue.floor}';
    return '$floorLabel · $wing · ${venue.building}';
  }

  String _countdownLabel(EventState event, Session session) {
    if (event.happeningNow().any((s) => s.id == session.id)) {
      final remaining = event.minutesRemaining(session);
      if (remaining <= 0) return 'Ending soon';
      return 'Ends in $remaining minutes';
    }
    final until = event.minutesUntil(session);
    if (until <= 0) return 'Starting soon';
    return 'Starts in $until minutes';
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
}
