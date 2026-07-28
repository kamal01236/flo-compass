import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../data/services/flo_meets_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/event_provider.dart';
import '../../providers/flo_meets_provider.dart';
import '../../providers/profile_provider.dart';
import '../../shared/utils/flo_meet_amenity_label.dart';
import '../../shared/widgets/shared_widgets.dart';

class FloMeetRoomDetailScreen extends StatefulWidget {
  const FloMeetRoomDetailScreen({super.key, required this.roomId});

  final String roomId;

  @override
  State<FloMeetRoomDetailScreen> createState() =>
      _FloMeetRoomDetailScreenState();
}

class _FloMeetRoomDetailScreenState extends State<FloMeetRoomDetailScreen> {
  List<RankedRoomMember> _members = [];
  bool _loadingMembers = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final floMeets = context.read<FloMeetsState>();
    final profile = context.read<ProfileState>();
    if (floMeets.rooms.isEmpty) {
      await floMeets.loadRooms();
    }
    final members = await floMeets.membersForRoom(
      roomId: widget.roomId,
      userRole: profile.profile.role,
      professionalInterests: profile.profile.interests,
    );
    if (!mounted) return;
    setState(() {
      _members = members;
      _loadingMembers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final floMeets = context.watch<FloMeetsState>();
    final event = context.watch<EventState>();
    final room = floMeets.roomById(widget.roomId);

    if (room == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.floMeetsTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.floMeetsRoomNotFound),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go(AppRoutes.floMeetsRoot),
                child: Text(l10n.floMeetsBackToHub),
              ),
            ],
          ),
        ),
      );
    }

    final amenity = event.amenityById(room.amenityId);
    final amenityLabel = amenity != null
        ? formatFloMeetAmenityLabel(amenity)
        : room.amenityId;
    final joined = floMeets.isJoined(room.id);
    final occupancy = floMeets.occupancyFor(room);
    final full = occupancy >= room.capacity && !joined;

    return Scaffold(
      appBar: AppBar(title: Text(room.title)),
      body: ResponsiveLayout(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${_fmt(room.windowStart)} – ${_fmt(room.windowEnd)} · ${room.day}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(amenityLabel)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.floMeetsOccupancy(occupancy, room.capacity),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            if (room.purposeTags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in room.purposeTags) Chip(label: Text(tag)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (joined)
              OutlinedButton.icon(
                onPressed: () async {
                  await floMeets.leaveRoom(room.id);
                },
                icon: const Icon(Icons.logout),
                label: Text(l10n.floMeetsLeaveRoom),
              )
            else
              FilledButton.icon(
                onPressed: full
                    ? null
                    : () async {
                        final ok = await floMeets.joinRoom(room.id);
                        if (!context.mounted) return;
                        if (!ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.floMeetsRoomFull)),
                          );
                        }
                      },
                icon: const Icon(Icons.login),
                label: Text(
                  full ? l10n.floMeetsRoomFull : l10n.floMeetsJoinRoom,
                ),
              ),
            const SizedBox(height: 24),
            Text(
              l10n.floMeetsPeopleInRoom,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_loadingMembers)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_members.isEmpty)
              Text(
                l10n.floMeetsNoPeopleInRoom,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            else
              ..._members.map((member) {
                final connection = floMeets.connectionFor(
                  room.id,
                  member.partner.id,
                );
                final status = connection == null
                    ? null
                    : connection.isMatch
                    ? l10n.floMeetsMatchedLabel
                    : connection.isWaiting
                    ? l10n.floMeetsWaitingForThem
                    : null;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(member.partner.nickname),
                    subtitle: Text(
                      status == null
                          ? l10n.floMeetsMatchPercent(member.matchPercent)
                          : '${l10n.floMeetsMatchPercent(member.matchPercent)} · $status',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(
                      AppRoutes.floMeetWindow(room.id, member.partner.id),
                    ),
                  ),
                );
              }),
          ],
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
