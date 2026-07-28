import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/models.dart';
import '../../../data/models/user_profile.dart';
import '../../../providers/event_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/event_stage.dart';
import '../../../shared/utils/session_format_filter.dart';
import '../../../shared/utils/event_notifications.dart';
import '../../../shared/widgets/flo_picks_hero.dart';
import '../../../shared/widgets/pre_event_banner.dart';
import '../../../shared/widgets/published_announcement_banner.dart';
import '../personalize_sheet.dart';

bool isDefaultPersonalize(UserProfile profile) {
  return profile.recommendationMode == RecommendationMode.balanced &&
      profile.energyFilter == EnergyFilter.all;
}

/// Top-of-feed header: banner, Flo pick, personalize, filters, active chips.
class DiscoverTopHeader extends StatelessWidget {
  const DiscoverTopHeader({
    super.key,
    required this.event,
    required this.profile,
    required this.isEventDayMode,
    required this.stage,
    required this.notifications,
    required this.heroSession,
    required this.heroReasons,
    required this.rankedCount,
    required this.dayFilter,
    required this.trackFilter,
    required this.floorFilter,
    required this.wingFilter,
    required this.showAllTracks,
    required this.onDayFilter,
    required this.onTrackFilter,
    required this.onFloorFilter,
    required this.onWingFilter,
    required this.onShowAllTracks,
    required this.onClearAllFilters,
    required this.hasActiveFilters,
  });

  final EventState event;
  final UserProfile profile;
  final bool isEventDayMode;
  final EventStage stage;
  final EventNotificationSnapshot notifications;
  final Session? heroSession;
  final List<String> heroReasons;
  final int rankedCount;
  final String? dayFilter;
  final String? trackFilter;
  final String? floorFilter;
  final String? wingFilter;
  final bool showAllTracks;
  final ValueChanged<String?> onDayFilter;
  final ValueChanged<String?> onTrackFilter;
  final ValueChanged<String?> onFloorFilter;
  final ValueChanged<String?> onWingFilter;
  final VoidCallback onShowAllTracks;
  final VoidCallback onClearAllFilters;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PublishedAnnouncementBanner(),
        if (profile.attendanceMode == AttendanceMode.remote)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: MaterialBanner(
              content: const Text(
                'Remote mode — stream-friendly sessions highlighted',
              ),
              leading: const Icon(
                Icons.live_tv_outlined,
                color: AppColors.accentStart,
              ),
              backgroundColor: AppColors.accentStart.withValues(alpha: 0.08),
              actions: const [SizedBox.shrink()],
            ),
          ),
        if (isEventDayMode && stage == EventStage.beforeEvent)
          PreEventBanner(
            event: event,
            notificationCount: notifications.count,
            onNotificationsTap: () => showEventNotificationsSheetFromContext(
              context,
              notifications: notifications,
              minutesUntil: event.minutesUntil,
              venueNameFor: (id) => event.venueById(id)?.name,
            ),
          ),
        FloPicksHero(
          session: heroSession,
          matchReasons: heroReasons,
          showBuildAfternoon: isEventDayMode && stage == EventStage.duringEvent,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => showPersonalizeSheet(context),
              icon: const Icon(Icons.tune),
              label: Text('Personalize · ${personalizeSummary(profile)}'),
            ),
          ),
        ),
        DiscoverFilterBar(
          event: event,
          dayFilter: dayFilter,
          trackFilter: trackFilter,
          floorFilter: floorFilter,
          wingFilter: wingFilter,
          showAllTracks: showAllTracks,
          onDayFilter: onDayFilter,
          onTrackFilter: onTrackFilter,
          onFloorFilter: onFloorFilter,
          onWingFilter: onWingFilter,
          onShowAllTracks: onShowAllTracks,
        ),
        DiscoverActiveFilters(
          profile: profile,
          dayFilter: dayFilter,
          floorFilter: floorFilter,
          wingFilter: wingFilter,
          trackFilter: trackFilter,
        ),
        if (hasActiveFilters)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.filter_alt_off, size: 18),
                label: const Text('Clear all'),
                onPressed: onClearAllFilters,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              energyFilterCountLabel(rankedCount, profile.energyFilter),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

class DiscoverFilterBar extends StatelessWidget {
  const DiscoverFilterBar({
    super.key,
    required this.event,
    required this.dayFilter,
    required this.trackFilter,
    required this.floorFilter,
    required this.wingFilter,
    required this.showAllTracks,
    required this.onDayFilter,
    required this.onTrackFilter,
    required this.onFloorFilter,
    required this.onWingFilter,
    required this.onShowAllTracks,
  });

  final EventState event;
  final String? dayFilter;
  final String? trackFilter;
  final String? floorFilter;
  final String? wingFilter;
  final bool showAllTracks;
  final ValueChanged<String?> onDayFilter;
  final ValueChanged<String?> onTrackFilter;
  final ValueChanged<String?> onFloorFilter;
  final ValueChanged<String?> onWingFilter;
  final VoidCallback onShowAllTracks;

  @override
  Widget build(BuildContext context) {
    final floors = const ['G', '6', '7', '8', '9', '10', '11', '12', '13'];
    final tracks = showAllTracks ? event.tracks : event.tracks.take(6).toList();

    var order = 0.0;
    final chips = <Widget>[
      _chip('All days', dayFilter == null, order++, () => onDayFilter(null)),
      for (final day in const ['Day 1', 'Day 2', 'Day 3'])
        _chip(day, dayFilter == day, order++, () => onDayFilter(day)),
      _chip(
        'All floors',
        floorFilter == null,
        order++,
        () => onFloorFilter(null),
      ),
      for (final floor in floors)
        _chip(
          'Floor $floor',
          floorFilter == floor,
          order++,
          () => onFloorFilter(floor),
        ),
      _chip('Wing N', wingFilter == 'N', order++, () => onWingFilter('N')),
      _chip('Wing S', wingFilter == 'S', order++, () => onWingFilter('S')),
      _chip('Any wing', wingFilter == null, order++, () => onWingFilter(null)),
      _chip(
        'All tracks',
        trackFilter == null,
        order++,
        () => onTrackFilter(null),
      ),
      for (final track in tracks)
        _chip(
          track.name.split(' ').first,
          trackFilter == track.id,
          order++,
          () => onTrackFilter(track.id),
        ),
      if (!showAllTracks && event.tracks.length > 6)
        _chip(
          '+${event.tracks.length - 6} more',
          false,
          order++,
          onShowAllTracks,
        ),
    ];

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: chips),
      ),
    );
  }

  Widget _chip(String label, bool selected, double order, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FocusTraversalOrder(
        order: NumericFocusOrder(order),
        child: DiscoverKeyboardFilterChip(
          label: label,
          selected: selected,
          onToggle: onTap,
        ),
      ),
    );
  }
}

class DiscoverActiveFilters extends StatelessWidget {
  const DiscoverActiveFilters({
    super.key,
    required this.profile,
    required this.dayFilter,
    required this.floorFilter,
    required this.wingFilter,
    required this.trackFilter,
  });

  final UserProfile profile;
  final String? dayFilter;
  final String? floorFilter;
  final String? wingFilter;
  final String? trackFilter;

  @override
  Widget build(BuildContext context) {
    final items = <String>[
      if (!isDefaultPersonalize(profile)) personalizeSummary(profile),
      ?dayFilter,
      if (floorFilter != null) 'Floor $floorFilter',
      if (wingFilter != null) 'Wing $wingFilter',
      if (trackFilter != null) 'Track',
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 6,
        children: [
          for (final item in items)
            Chip(label: Text(item), visualDensity: VisualDensity.compact),
        ],
      ),
    );
  }
}

class DiscoverKeyboardFilterChip extends StatelessWidget {
  const DiscoverKeyboardFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onToggle,
  });

  final String label;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Focus(
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          node.previousFocus();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          node.nextFocus();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space) {
          onToggle();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Semantics(
        label: 'Filter $label',
        selected: selected,
        button: true,
        child: FilterChip(
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          selected: selected,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          materialTapTargetSize: MaterialTapTargetSize.padded,
          side: selected
              ? const BorderSide(color: AppColors.accentStart)
              : null,
          onSelected: (_) => onToggle(),
        ),
      ),
    );
  }
}
