import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/app_capability.dart';
import '../../../core/routing/app_routes.dart';
import '../../../data/models/flo_meet_room.dart';
import '../../../data/services/flo_meets_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/flo_meets_provider.dart';
import '../../../shared/auth/capability_guard.dart';
import '../../../shared/utils/flo_meet_amenity_label.dart';
import '../../../shared/widgets/shared_widgets.dart';

class OrganizerMeetRoomComposeScreen extends StatefulWidget {
  const OrganizerMeetRoomComposeScreen({super.key, this.roomId});

  final String? roomId;

  @override
  State<OrganizerMeetRoomComposeScreen> createState() =>
      _OrganizerMeetRoomComposeScreenState();
}

class _OrganizerMeetRoomComposeScreenState
    extends State<OrganizerMeetRoomComposeScreen> {
  final _titleController = TextEditingController();
  final _purposeController = TextEditingController();
  final _capacityController = TextEditingController(text: '10');
  String _day = 'Day 1';
  String? _amenityId;
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);
  bool _loading = true;
  FloMeetRoom? _existing;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final id = widget.roomId;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    final existing = await context.read<FloMeetsState>().roomCatalog.getById(
      id,
    );
    if (!mounted) return;
    _existing = existing;
    if (existing != null) {
      _titleController.text = existing.title;
      _purposeController.text = existing.purposeTags.join(', ');
      _capacityController.text = '${existing.capacity}';
      _day = existing.day;
      _amenityId = existing.amenityId;
      _start = TimeOfDay(
        hour: existing.windowStart.hour,
        minute: existing.windowStart.minute,
      );
      _end = TimeOfDay(
        hour: existing.windowEnd.hour,
        minute: existing.windowEnd.minute,
      );
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _purposeController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  DateTime _dayDate(String day) => switch (day) {
    'Day 2' => DateTime(2026, 11, 5),
    'Day 3' => DateTime(2026, 11, 6),
    _ => DateTime(2026, 11, 4),
  };

  DateTime _combine(String day, TimeOfDay time) {
    final d = _dayDate(day);
    return DateTime(d.year, d.month, d.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final event = context.watch<EventState>();
    final amenities = event.amenities
        .where((a) => floMeetAmenityTypes.contains(a.type))
        .toList();

    return CapabilityGuard(
      capability: AppCapability.publishAnnouncement,
      authState: auth,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.roomId == null ? 'Compose match room' : 'Edit match room',
          ),
          actions: [
            TextButton(
              onPressed: _loading ? null : () => _save(context, publish: false),
              child: const Text('Save draft'),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ResponsiveLayout(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _purposeController,
                      decoration: const InputDecoration(
                        labelText: 'Purpose tags (comma-separated)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _day,
                      decoration: const InputDecoration(
                        labelText: 'Day',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Day 1', child: Text('Day 1')),
                        DropdownMenuItem(value: 'Day 2', child: Text('Day 2')),
                        DropdownMenuItem(value: 'Day 3', child: Text('Day 3')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _day = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _amenityId,
                      decoration: const InputDecoration(
                        labelText: 'Amenity',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final a in amenities)
                          DropdownMenuItem(
                            value: a.id,
                            child: Text(formatFloMeetAmenityLabel(a)),
                          ),
                      ],
                      onChanged: (v) => setState(() => _amenityId = v),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _start,
                              );
                              if (picked != null) {
                                setState(() => _start = picked);
                              }
                            },
                            child: Text('Start ${_start.format(context)}'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _end,
                              );
                              if (picked != null) {
                                setState(() => _end = picked);
                              }
                            },
                            child: Text('End ${_end.format(context)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _capacityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Capacity',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _save(context, publish: true),
                      icon: const Icon(Icons.publish_outlined),
                      label: const Text('Publish now'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _save(BuildContext context, {required bool publish}) async {
    final title = _titleController.text.trim();
    final amenityId = _amenityId;
    final capacity = int.tryParse(_capacityController.text.trim()) ?? 0;
    if (title.isEmpty || amenityId == null || amenityId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and amenity are required')),
      );
      return;
    }
    if (capacity < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capacity must be at least 2')),
      );
      return;
    }

    final purposeTags = _purposeController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final now = DateTime.now();
    final room = FloMeetRoom(
      id: _existing?.id ?? 'org-room-${now.millisecondsSinceEpoch}',
      title: title,
      purposeTags: purposeTags,
      amenityId: amenityId,
      day: _day,
      windowStart: _combine(_day, _start),
      windowEnd: _combine(_day, _end),
      capacity: capacity,
      seedPartnerIds: _existing?.seedPartnerIds ?? const [],
      status: publish ? FloMeetRoomStatus.published : FloMeetRoomStatus.draft,
      source: FloMeetRoomSource.organizer,
    );

    final floMeets = context.read<FloMeetsState>();
    await floMeets.roomCatalog.save(room);
    await floMeets.loadRooms();
    if (!context.mounted) return;
    context.go(AppRoutes.organizerMeetRooms);
  }
}
