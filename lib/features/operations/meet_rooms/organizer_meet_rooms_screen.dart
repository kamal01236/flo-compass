import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/app_capability.dart';
import '../../../core/routing/app_routes.dart';
import '../../../data/models/flo_meet_room.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/flo_meets_provider.dart';
import '../../../shared/auth/capability_guard.dart';
import '../../../shared/widgets/shared_widgets.dart';

class OrganizerMeetRoomsScreen extends StatefulWidget {
  const OrganizerMeetRoomsScreen({super.key});

  @override
  State<OrganizerMeetRoomsScreen> createState() =>
      _OrganizerMeetRoomsScreenState();
}

class _OrganizerMeetRoomsScreenState extends State<OrganizerMeetRoomsScreen> {
  List<FloMeetRoom> _rooms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final catalog = context.read<FloMeetsState>().roomCatalog;
    final seed = await catalog.loadSeedRooms();
    final overlay = await catalog.listOrganizerRooms();
    final byId = <String, FloMeetRoom>{for (final r in seed) r.id: r};
    for (final r in overlay) {
      byId[r.id] = r;
    }
    final rooms = byId.values.toList()
      ..sort((a, b) => b.windowStart.compareTo(a.windowStart));
    if (!mounted) return;
    setState(() {
      _rooms = rooms;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return CapabilityGuard(
      capability: AppCapability.publishAnnouncement,
      authState: auth,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Match rooms'),
          actions: [
            IconButton(
              tooltip: 'Compose match room',
              onPressed: () => context.push(AppRoutes.organizerMeetRoomCompose),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: ResponsiveLayout(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _rooms.isEmpty
              ? _EmptyState(
                  onCompose: () =>
                      context.push(AppRoutes.organizerMeetRoomCompose),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _rooms.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final room = _rooms[index];
                    return Card(
                      child: ListTile(
                        title: Text(room.title),
                        subtitle: Text(
                          '${room.day} · ${room.status.label} · ${room.source.name}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          AppRoutes.organizerMeetRoomDetail(room.id),
                        ),
                        onLongPress: room.status == FloMeetRoomStatus.draft
                            ? () async {
                                final floMeets = context.read<FloMeetsState>();
                                await floMeets.roomCatalog.publish(room.id);
                                await floMeets.loadRooms();
                                if (!mounted) return;
                                await _reload();
                              }
                            : room.status == FloMeetRoomStatus.published
                            ? () async {
                                final floMeets = context.read<FloMeetsState>();
                                await floMeets.roomCatalog.archive(room.id);
                                await floMeets.loadRooms();
                                if (!mounted) return;
                                await _reload();
                              }
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCompose});

  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.meeting_room_outlined, size: 48),
            const SizedBox(height: 12),
            const Text('No match rooms yet'),
            const SizedBox(height: 8),
            Text(
              'Compose Flo Meets rooms for attendees. Seeded rooms appear here too.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCompose,
              icon: const Icon(Icons.add),
              label: const Text('Compose room'),
            ),
          ],
        ),
      ),
    );
  }
}
