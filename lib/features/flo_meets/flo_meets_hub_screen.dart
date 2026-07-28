import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../data/models/flo_meet_connection.dart';
import '../../data/models/flo_meet_room.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/flo_meets_provider.dart';
import '../../shared/utils/flo_meet_amenity_label.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'flo_meets_sign_in_gate.dart';

/// Flo Meets hub: Rooms | Waiting | Matches.
class FloMeetsHubScreen extends StatefulWidget {
  const FloMeetsHubScreen({super.key});

  @override
  State<FloMeetsHubScreen> createState() => _FloMeetsHubScreenState();
}

class _FloMeetsHubScreenState extends State<FloMeetsHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final floMeets = context.read<FloMeetsState>();
      floMeets.loadRooms();
      unawaited(floMeets.applyDemoSeedIfNeeded());
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthState>();
    final floMeets = context.watch<FloMeetsState>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.floMeetsTitle)),
        body: const FloMeetsSignInGate(),
      );
    }

    if (!floMeets.preferences.isSetupComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go(AppRoutes.floMeetsPreferences);
      });
      return Scaffold(
        appBar: AppBar(title: Text(l10n.floMeetsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.floMeetsTitle),
        actions: [
          IconButton(
            tooltip: l10n.floMeetsEditPreferences,
            icon: const Icon(Icons.tune_outlined),
            onPressed: () => context.go(AppRoutes.floMeetsPreferences),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.floMeetsHubRooms),
            Tab(text: l10n.floMeetsHubWaiting),
            Tab(text: l10n.floMeetsHubMatches),
          ],
        ),
      ),
      body: ResponsiveLayout(
        child: floMeets.roomsLoading && floMeets.rooms.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabs,
                children: [
                  _RoomsTab(floMeets: floMeets, l10n: l10n),
                  _WaitingTab(floMeets: floMeets, l10n: l10n),
                  _MatchesTab(floMeets: floMeets, l10n: l10n),
                ],
              ),
      ),
    );
  }
}

class _RoomsTab extends StatelessWidget {
  const _RoomsTab({required this.floMeets, required this.l10n});

  final FloMeetsState floMeets;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final event = context.watch<EventState>();
    final rooms = floMeets.rooms.where((r) => r.isPublished).toList();
    if (rooms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.floMeetsRoomsEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rooms.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final room = rooms[index];
        return _RoomCard(
          room: room,
          occupancy: floMeets.occupancyFor(room),
          joined: floMeets.isJoined(room.id),
          amenityLabel: _amenityLabel(event, room.amenityId),
          l10n: l10n,
          onTap: () => context.go(AppRoutes.floMeetRoom(room.id)),
        );
      },
    );
  }

  static String _amenityLabel(EventState event, String amenityId) {
    final amenity = event.amenityById(amenityId);
    if (amenity == null) return amenityId;
    return formatFloMeetAmenityLabel(amenity);
  }
}

class _WaitingTab extends StatelessWidget {
  const _WaitingTab({required this.floMeets, required this.l10n});

  final FloMeetsState floMeets;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final waiting = floMeets.waitingConnections;
    if (waiting.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.floMeetsWaitingEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: waiting.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final c = waiting[index];
        return _ConnectionCard(
          connection: c,
          subtitle: l10n.floMeetsWaitingForThem,
          onTap: () =>
              context.go(AppRoutes.floMeetWindow(c.roomId, c.partnerId)),
        );
      },
    );
  }
}

class _MatchesTab extends StatelessWidget {
  const _MatchesTab({required this.floMeets, required this.l10n});

  final FloMeetsState floMeets;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final matches = floMeets.matches;
    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.floMeetsMatchesEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final c = matches[index];
        return _ConnectionCard(
          connection: c,
          subtitle: l10n.floMeetsMatchedLabel,
          onTap: () {
            final meetId = c.meetId;
            if (meetId != null) {
              context.go(AppRoutes.floMeetDetail(meetId));
            } else {
              context.go(AppRoutes.floMeetWindow(c.roomId, c.partnerId));
            }
          },
        );
      },
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.occupancy,
    required this.joined,
    required this.amenityLabel,
    required this.l10n,
    required this.onTap,
  });

  final FloMeetRoom room;
  final int occupancy;
  final bool joined;
  final String amenityLabel;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time =
        '${_fmt(room.windowStart)} – ${_fmt(room.windowEnd)} · ${room.day}';
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (joined)
                    Chip(
                      label: Text(l10n.floMeetsJoinedBadge),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(time, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 16),
                  const SizedBox(width: 4),
                  Expanded(child: Text(amenityLabel)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.floMeetsOccupancy(occupancy, room.capacity),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.connection,
    required this.subtitle,
    required this.onTap,
  });

  final FloMeetConnection connection;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(connection.partnerNickname),
        subtitle: Text('$subtitle · ${connection.matchPercent}%'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
