import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../../domain/inputs/navigation_search_context.dart';
import '../../shared/utils/now_next_resolver.dart';

enum NavigationResultKind { session, speaker, venue, track, action }

class NavigationResult {
  const NavigationResult({
    required this.kind,
    required this.label,
    this.subtitle,
    required this.icon,
    this.route,
    this.onExecute,
    this.score = 0,
  });

  final NavigationResultKind kind;
  final String label;
  final String? subtitle;
  final IconData icon;
  final String? route;
  final void Function(BuildContext context, GoRouter router)? onExecute;
  final int score;

  void execute(BuildContext context, GoRouter router) {
    if (onExecute != null) {
      onExecute!(context, router);
    } else if (route != null) {
      if (kind == NavigationResultKind.session ||
          kind == NavigationResultKind.speaker) {
        router.push(route!);
      } else {
        router.go(route!);
      }
    }
  }
}

class NavigationSearchGroups {
  const NavigationSearchGroups({
    this.actions = const [],
    this.sessions = const [],
    this.speakers = const [],
    this.venues = const [],
    this.tracks = const [],
  });

  final List<NavigationResult> actions;
  final List<NavigationResult> sessions;
  final List<NavigationResult> speakers;
  final List<NavigationResult> venues;
  final List<NavigationResult> tracks;

  List<NavigationResult> get all => [
    ...actions,
    ...sessions,
    ...speakers,
    ...venues,
    ...tracks,
  ];

  bool get isEmpty =>
      actions.isEmpty &&
      sessions.isEmpty &&
      speakers.isEmpty &&
      venues.isEmpty &&
      tracks.isEmpty;
}

class NavigationSearchService {
  static const _maxPerGroup = 8;

  static List<NavigationResult> defaultActions({
    required void Function(BuildContext, GoRouter) onConflicts,
  }) {
    return [
      NavigationResult(
        kind: NavigationResultKind.action,
        label: 'Go to Discover',
        icon: Icons.explore_outlined,
        route: '/discover',
      ),
      NavigationResult(
        kind: NavigationResultKind.action,
        label: 'Go to Companion',
        icon: Icons.chat_bubble_outline,
        route: '/companion',
      ),
      NavigationResult(
        kind: NavigationResultKind.action,
        label: 'Go to My Plan',
        icon: Icons.bookmark_outline,
        route: '/my-plan',
      ),
      NavigationResult(
        kind: NavigationResultKind.action,
        label: 'Go to Profile',
        icon: Icons.person_outline,
        route: '/profile',
      ),
      NavigationResult(
        kind: NavigationResultKind.action,
        label: 'Open venue map',
        icon: Icons.map_outlined,
        route: '/map',
      ),
      NavigationResult(
        kind: NavigationResultKind.action,
        label: 'Open recap',
        icon: Icons.auto_awesome,
        route: '/recap',
      ),
      NavigationResult(
        kind: NavigationResultKind.action,
        label: 'View plan conflicts',
        icon: Icons.warning_amber_outlined,
        onExecute: onConflicts,
      ),
    ];
  }

  static NavigationSearchGroups search(
    String query, {
    required NavigationSearchContext catalog,
    List<Session>? plannedSessions,
    NowNextResult? nowNext,
    required void Function(BuildContext, GoRouter) onConflicts,
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return NavigationSearchGroups(
        actions: defaultActions(onConflicts: onConflicts),
      );
    }

    final lower = trimmed.toLowerCase();
    final magic = _magicKeyword(
      lower,
      catalog: catalog,
      plannedSessions: plannedSessions,
      nowNext: nowNext,
      onConflicts: onConflicts,
    );
    if (magic != null) {
      return NavigationSearchGroups(actions: [magic]);
    }

    return NavigationSearchGroups(
      actions: _filterActions(lower, onConflicts: onConflicts),
      sessions: _searchSessions(lower, catalog),
      speakers: _searchSpeakers(lower, catalog),
      venues: _searchVenues(lower, catalog),
      tracks: _searchTracks(lower, catalog),
    );
  }

  static NavigationResult? _magicKeyword(
    String lower, {
    required NavigationSearchContext catalog,
    List<Session>? plannedSessions,
    NowNextResult? nowNext,
    required void Function(BuildContext, GoRouter) onConflicts,
  }) {
    final resolved =
        nowNext ??
        (plannedSessions != null
            ? resolveNowNext(
                planned: plannedSessions,
                minutesUntil: (_) => 0,
                minutesRemaining: (_) => 0,
              )
            : null);

    switch (lower) {
      case 'now':
        final session = resolved?.now ?? resolved?.displaySession;
        if (session == null) return null;
        return NavigationResult(
          kind: NavigationResultKind.action,
          label: 'Now: ${session.title}',
          subtitle: '${session.day} · ${session.startTime}',
          icon: Icons.play_circle_outline,
          onExecute: (context, router) {
            router.push('/session/${session.id}');
          },
        );
      case 'next':
        final session = resolved?.next ?? resolved?.displaySession;
        if (session == null) return null;
        return NavigationResult(
          kind: NavigationResultKind.action,
          label: 'Next: ${session.title}',
          subtitle: '${session.day} · ${session.startTime}',
          icon: Icons.skip_next_outlined,
          onExecute: (context, router) {
            router.push('/session/${session.id}');
          },
        );
      case 'conflicts':
        return NavigationResult(
          kind: NavigationResultKind.action,
          label: 'View plan conflicts',
          icon: Icons.warning_amber_outlined,
          onExecute: onConflicts,
        );
      case 'map':
        return NavigationResult(
          kind: NavigationResultKind.action,
          label: 'Open venue map',
          icon: Icons.map_outlined,
          route: '/map',
        );
      case 'day1':
        return NavigationResult(
          kind: NavigationResultKind.action,
          label: 'Discover · Day 1',
          icon: Icons.filter_alt_outlined,
          route: '/discover?day=Day%201',
        );
      case 'day2':
        return NavigationResult(
          kind: NavigationResultKind.action,
          label: 'Discover · Day 2',
          icon: Icons.filter_alt_outlined,
          route: '/discover?day=Day%202',
        );
      case 'day3':
        return NavigationResult(
          kind: NavigationResultKind.action,
          label: 'Discover · Day 3',
          icon: Icons.filter_alt_outlined,
          route: '/discover?day=Day%203',
        );
      case 'recap':
        return NavigationResult(
          kind: NavigationResultKind.action,
          label: 'Open recap',
          icon: Icons.auto_awesome,
          route: '/recap',
        );
      default:
        return null;
    }
  }

  static List<NavigationResult> _filterActions(
    String lower, {
    required void Function(BuildContext, GoRouter) onConflicts,
  }) {
    return defaultActions(
      onConflicts: onConflicts,
    ).where((a) => a.label.toLowerCase().contains(lower)).toList();
  }

  static List<NavigationResult> _searchSessions(
    String lower,
    NavigationSearchContext catalog,
  ) {
    final scored = <({Session session, int score})>[];
    for (final session in catalog.sessions) {
      final score = _sessionScore(lower, session, catalog);
      if (score > 0) {
        scored.add((session: session, score: score));
      }
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(_maxPerGroup).map((entry) {
      final session = entry.session;
      return NavigationResult(
        kind: NavigationResultKind.session,
        label: session.title,
        subtitle: '${session.day} · ${session.startTime}',
        icon: Icons.event,
        route: '/session/${session.id}',
        score: entry.score,
      );
    }).toList();
  }

  static int _sessionScore(
    String lower,
    Session session,
    NavigationSearchContext catalog,
  ) {
    if (session.id.toLowerCase() == lower) return 1000;
    final title = session.title.toLowerCase();
    if (title.startsWith(lower)) return 800;
    if (title.contains(lower)) return 600;
    for (final tag in session.tags) {
      if (tag.toLowerCase().contains(lower)) return 400;
    }
    for (final speakerId in session.speakerIds) {
      final speaker = catalog.speakerById(speakerId);
      if (speaker != null && speaker.name.toLowerCase().contains(lower)) {
        return 500;
      }
    }
    final track = catalog.trackById(session.trackId);
    if (track != null && track.name.toLowerCase().contains(lower)) return 300;
    final venue = catalog.venueById(session.venueId);
    if (venue != null && venue.name.toLowerCase().contains(lower)) return 200;
    return 0;
  }

  static List<NavigationResult> _searchSpeakers(
    String lower,
    NavigationSearchContext catalog,
  ) {
    final scored = <({Speaker speaker, int score})>[];
    for (final speaker in catalog.speakers) {
      final score = _entityScore(
        lower,
        id: speaker.id,
        primary: speaker.name,
        secondary: speaker.title,
      );
      if (score > 0) scored.add((speaker: speaker, score: score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(_maxPerGroup).map((entry) {
      final speaker = entry.speaker;
      return NavigationResult(
        kind: NavigationResultKind.speaker,
        label: speaker.name,
        subtitle: speaker.title,
        icon: Icons.person,
        route: '/speaker/${speaker.id}',
        score: entry.score,
      );
    }).toList();
  }

  static List<NavigationResult> _searchVenues(
    String lower,
    NavigationSearchContext catalog,
  ) {
    final scored = <({Venue venue, int score})>[];
    for (final venue in catalog.venues) {
      final score = _entityScore(
        lower,
        id: venue.id,
        primary: venue.name,
        secondary: 'Floor ${venue.floor} · Wing ${venue.wing}',
      );
      if (score > 0) scored.add((venue: venue, score: score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(_maxPerGroup).map((entry) {
      final venue = entry.venue;
      return NavigationResult(
        kind: NavigationResultKind.venue,
        label: venue.name,
        subtitle: 'Floor ${venue.floor} · Wing ${venue.wing}',
        icon: Icons.meeting_room_outlined,
        route: '/map?room=${venue.id}',
        score: entry.score,
      );
    }).toList();
  }

  static List<NavigationResult> _searchTracks(
    String lower,
    NavigationSearchContext catalog,
  ) {
    final scored = <({Track track, int score})>[];
    for (final track in catalog.tracks) {
      final score = _entityScore(
        lower,
        id: track.id,
        primary: track.name,
        secondary: track.tags.join(', '),
      );
      if (score > 0) scored.add((track: track, score: score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(_maxPerGroup).map((entry) {
      final track = entry.track;
      return NavigationResult(
        kind: NavigationResultKind.track,
        label: track.name,
        subtitle: track.tags.isEmpty ? null : track.tags.first,
        icon: Icons.label_outline,
        route: '/discover?track=${Uri.encodeComponent(track.id)}',
        score: entry.score,
      );
    }).toList();
  }

  static int _entityScore(
    String lower, {
    required String id,
    required String primary,
    String? secondary,
  }) {
    if (id.toLowerCase() == lower) return 1000;
    final p = primary.toLowerCase();
    if (p.startsWith(lower)) return 800;
    if (p.contains(lower)) return 600;
    if (secondary != null && secondary.toLowerCase().contains(lower)) {
      return 300;
    }
    return 0;
  }
}
