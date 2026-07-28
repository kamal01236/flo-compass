import 'dart:async';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../data/models/models.dart';

import '../../providers/engagement_provider.dart';

import '../../providers/event_provider.dart';

import '../../providers/plan_provider.dart';

import '../../providers/profile_provider.dart';

import '../../shared/widgets/shared_widgets.dart';

import '../../shared/widgets/venue_floor_plan.dart';

import 'floor_story_panel.dart';

enum _VenueViewMode { map, list }

enum _CampusZone { parking, refresh, event }

class VenueMapScreen extends StatefulWidget {
  const VenueMapScreen({super.key, this.highlightRoom});

  final String? highlightRoom;

  @override
  State<VenueMapScreen> createState() => _VenueMapScreenState();
}

class _VenueMapScreenState extends State<VenueMapScreen>
    with SingleTickerProviderStateMixin {
  static const eventFloors = ['G', '6', '7', '8', '9', '10', '11', '12', '13'];
  static const parkingFloors = ['B', 'G', '1', '2', '3', '4'];

  _CampusZone _zone = _CampusZone.event;

  List<String> get _activeFloors => switch (_zone) {
    _CampusZone.parking => parkingFloors,
    _CampusZone.refresh => const ['5'],
    _CampusZone.event => eventFloors,
  };

  late final TabController _tabController = TabController(
    length: eventFloors.length,

    vsync: this,
  );

  final _searchController = TextEditingController();

  _VenueViewMode _viewMode = _VenueViewMode.map;

  String? _highlightRoom;

  String _storyFloor = 'G';

  void _onZoneChanged(_CampusZone zone) {
    setState(() {
      _zone = zone;
      if (zone != _CampusZone.event) {
        _viewMode = _VenueViewMode.list;
      }
      _storyFloor = switch (zone) {
        _CampusZone.parking => 'B',
        _CampusZone.refresh => '5',
        _CampusZone.event => eventFloors[_tabController.index],
      };
    });
  }

  @override
  void initState() {
    super.initState();

    _highlightRoom = widget.highlightRoom;

    if (widget.highlightRoom != null) {
      final floor = _inferFloor(widget.highlightRoom!);

      final index = eventFloors.indexOf(floor);

      if (index >= 0) _tabController.index = index;

      WidgetsBinding.instance.addPostFrameCallback((_) => _recordFloor(floor));
    }

    _storyFloor = eventFloors[_tabController.index];

    _tabController.addListener(_onTabChanged);
  }

  @override
  void didUpdateWidget(covariant VenueMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.highlightRoom != oldWidget.highlightRoom &&
        widget.highlightRoom != null) {
      _highlightRoom = widget.highlightRoom;

      final floor = _inferFloor(widget.highlightRoom!);

      final index = eventFloors.indexOf(floor);

      if (index >= 0) _tabController.index = index;
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    final floor = eventFloors[_tabController.index];

    setState(() => _storyFloor = floor);

    _recordFloor(floor);
  }

  void _recordFloor(String floor) {
    if (!mounted) return;

    if (!const {'7', '8', '9', '10', '11', '12', '13'}.contains(floor)) {
      return;
    }

    final engagement = context.read<EngagementState>();

    final event = context.read<EventState>();

    final plan = context.read<PlanState>();

    final profile = context.read<ProfileState>();

    unawaited(() async {
      await engagement.recordFloorVisit(floor);

      await engagement.refreshBingoAutoMarks(
        plan: plan,

        event: event,

        profile: profile.profile,
      );
    }());
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);

    _searchController.dispose();

    _tabController.dispose();

    super.dispose();
  }

  List<Venue> _filteredVenues(EventState event) {
    final query = _searchController.text.trim().toLowerCase();

    return event.venues.where((venue) {
      if (query.isEmpty) return true;

      return venue.id.toLowerCase().contains(query) ||
          venue.name.toLowerCase().contains(query);
    }).toList();
  }

  Map<String, Map<String, List<Venue>>> _groupVenues(List<Venue> venues) {
    final grouped = <String, Map<String, List<Venue>>>{};

    for (final venue in venues) {
      grouped
          .putIfAbsent(venue.floor, () => {})
          .putIfAbsent(venue.wing, () => [])
          .add(venue);
    }

    for (final wingMap in grouped.values) {
      for (final list in wingMap.values) {
        list.sort((a, b) => a.name.compareTo(b.name));
      }
    }

    return grouped;
  }

  void _selectRoomFromList(Venue venue) {
    final floorIndex = eventFloors.indexOf(venue.floor);

    setState(() {
      _zone = _CampusZone.event;
      _highlightRoom = venue.id;

      _viewMode = _VenueViewMode.map;

      if (floorIndex >= 0) _tabController.index = floorIndex;
    });

    _recordFloor(venue.floor);
  }

  String _wingLabel(String wing) {
    return switch (wing.toUpperCase()) {
      'N' => 'North',

      'S' => 'South',

      'CENTRAL' => 'Central',

      _ => wing,
    };
  }

  String _semanticsLabel(Venue venue, Session? liveSession) {
    final floorLabel = venue.floor == 'G' ? 'Ground' : 'Floor ${venue.floor}';

    final wing = _wingLabel(venue.wing);

    final base = '$floorLabel $wing, ${venue.name}, capacity ${venue.capacity}';

    if (liveSession == null) return base;

    return '$base, session: ${liveSession.title}';
  }

  @override
  Widget build(BuildContext context) {
    final event = context.watch<EventState>();

    final query = _searchController.text.trim().toLowerCase();

    final filteredVenues = _filteredVenues(event);

    final venuesByFloor = <String, List<String>>{};

    for (final venue in filteredVenues) {
      venuesByFloor.putIfAbsent(venue.floor, () => []).add(venue.id);
    }

    final liveByVenue = {
      for (final session in event.happeningNow()) session.venueId: session,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Venue map'),
        actions: const [DiscoverHomeAction()],

        bottom: _zone == _CampusZone.event && _viewMode == _VenueViewMode.map
            ? TabBar(
                controller: _tabController,

                isScrollable: true,

                tabs: const [
                  Tab(text: 'Ground'),

                  Tab(text: '6'),

                  Tab(text: '7'),

                  Tab(text: '8'),

                  Tab(text: '9'),

                  Tab(text: '10'),

                  Tab(text: '11'),

                  Tab(text: '12'),

                  Tab(text: '13'),
                ],
              )
            : null,
      ),

      body: ResponsiveLayout(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: SegmentedButton<_CampusZone>(
                segments: const [
                  ButtonSegment(
                    value: _CampusZone.parking,
                    label: Text('Parking'),
                    icon: Icon(Icons.local_parking_outlined),
                  ),
                  ButtonSegment(
                    value: _CampusZone.refresh,
                    label: Text('Refresh'),
                    icon: Icon(Icons.park_outlined),
                  ),
                  ButtonSegment(
                    value: _CampusZone.event,
                    label: Text('Event'),
                    icon: Icon(Icons.meeting_room_outlined),
                  ),
                ],
                selected: {_zone},
                onSelectionChanged: (selected) =>
                    _onZoneChanged(selected.first),
              ),
            ),
            if (_zone == _CampusZone.event)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: SegmentedButton<_VenueViewMode>(
                  segments: const [
                    ButtonSegment(
                      value: _VenueViewMode.map,

                      label: Text('Map'),

                      icon: Icon(Icons.map_outlined),
                    ),

                    ButtonSegment(
                      value: _VenueViewMode.list,

                      label: Text('List'),

                      icon: Icon(Icons.list_alt),
                    ),
                  ],

                  selected: {_viewMode},

                  onSelectionChanged: (selected) {
                    setState(() => _viewMode = selected.first);
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(12),

              child: TextField(
                controller: _searchController,

                decoration: const InputDecoration(
                  hintText: 'Search room or amenity',

                  prefixIcon: Icon(Icons.search),
                ),

                onChanged: (_) => setState(() {}),
              ),
            ),

            if (event.meta != null)
              FloorStoryPanel(
                floor: _storyFloor,

                blurb:
                    event.meta!.storyForFloor(_storyFloor) ??
                    'Explore sessions and rooms on this floor.',

                floors: _activeFloors,

                showFloorPicker:
                    _zone != _CampusZone.event ||
                    _viewMode == _VenueViewMode.list,

                onFloorChanged: (floor) {
                  setState(() {
                    _storyFloor = floor;

                    final index = eventFloors.indexOf(floor);

                    if (index >= 0) _tabController.index = index;
                  });
                },
              ),

            if (_zone == _CampusZone.event && _viewMode == _VenueViewMode.map)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),

                child: Align(
                  alignment: Alignment.centerLeft,

                  child: ActionChip(
                    label: const Text('Nearest coffee'),

                    onPressed: () {
                      _searchController.text = 'cafeteria';

                      _tabController.index = eventFloors.indexOf('6');

                      setState(() {});
                    },
                  ),
                ),
              ),

            Expanded(
              child: switch (_zone) {
                _CampusZone.parking => _buildParkingList(event),
                _CampusZone.refresh => _buildRefreshList(event, query),
                _CampusZone.event =>
                  _viewMode == _VenueViewMode.map
                      ? TabBarView(
                          controller: _tabController,
                          children: [
                            for (final floor in eventFloors)
                              ListView(
                                padding: const EdgeInsets.all(12),
                                children: [
                                  VenueFloorPlan(
                                    floor: floor,
                                    rooms: venuesByFloor[floor] ?? const [],
                                    highlightRoomId: _highlightRoom,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Amenities',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  for (final amenity in event.amenities.where(
                                    (a) =>
                                        a.floor == floor &&
                                        (query.isEmpty ||
                                            a.label.toLowerCase().contains(
                                              query,
                                            ) ||
                                            a.wing.toLowerCase().contains(
                                              query,
                                            )),
                                  ))
                                    ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.place_outlined),
                                      title: Text(amenity.label),
                                      subtitle: Text(amenity.wing),
                                    ),
                                ],
                              ),
                          ],
                        )
                      : _buildVenueList(filteredVenues, liveByVenue),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenueList(List<Venue> venues, Map<String, Session> liveByVenue) {
    if (venues.isEmpty) {
      return const EmptyState(
        title: 'No rooms match your search',

        message: 'Try a different room name or clear the search field.',
      );
    }

    final grouped = _groupVenues(venues);

    final orderedFloors = eventFloors.where(grouped.containsKey).toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),

      itemCount: orderedFloors.length,

      itemBuilder: (context, floorIndex) {
        final floor = orderedFloors[floorIndex];

        final wingMap = grouped[floor]!;

        final wingKeys = wingMap.keys.toList()
          ..sort((a, b) => _wingLabel(a).compareTo(_wingLabel(b)));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),

              child: Text(
                floor == 'G' ? 'Ground floor' : 'Floor $floor',

                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            for (final wing in wingKeys) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),

                child: Text(
                  '${_wingLabel(wing)} wing',

                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),

              for (final venue in wingMap[wing]!)
                _VenueListTile(
                  venue: venue,

                  liveSession: liveByVenue[venue.id],

                  semanticsLabel: _semanticsLabel(venue, liveByVenue[venue.id]),

                  onTap: () => _selectRoomFromList(venue),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildParkingList(EventState event) {
    final parking = event.amenities.where((a) => a.isParking).toList();
    final byFloor = <String, List<Amenity>>{};
    for (final floor in parkingFloors) {
      final spots = parking.where((a) => a.floor == floor).toList();
      if (spots.isNotEmpty) byFloor[floor] = spots;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      children: [
        for (final floor in parkingFloors)
          if (byFloor.containsKey(floor)) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Text(
                _parkingFloorTitle(floor),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            _ParkingFloorTile(amenities: byFloor[floor]!),
          ],
      ],
    );
  }

  Widget _buildRefreshList(EventState event, String query) {
    final amenities = event.amenities
        .where(
          (a) =>
              a.floor == '5' &&
              (query.isEmpty ||
                  a.label.toLowerCase().contains(query) ||
                  a.type.contains(query)),
        )
        .toList();

    if (amenities.isEmpty) {
      return const EmptyState(
        title: 'No wellness amenities match',
        message: 'Floor 5 has the garden and snack kiosk.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      children: [
        for (final amenity in amenities)
          ListTile(
            leading: Icon(
              amenity.type == 'garden'
                  ? Icons.park_outlined
                  : Icons.coffee_outlined,
            ),
            title: Text(amenity.label),
            subtitle: Text('Floor ${amenity.floor} · ${amenity.wing} wing'),
          ),
      ],
    );
  }

  String _parkingFloorTitle(String floor) {
    return switch (floor) {
      'B' => 'Basement',
      'G' => 'Ground',
      '1' => '1st floor',
      '2' => '2nd floor',
      '3' => '3rd floor',
      '4' => '4th floor',
      _ => 'Floor $floor',
    };
  }

  String _inferFloor(String venueId) {
    if (venueId == 'ven-G01') return 'G';

    if (venueId.startsWith('ven-T60') || venueId == 'ven-C601') return '6';

    final match = RegExp(r'^ven-(\d{1,2})[NS]\d$').firstMatch(venueId);

    return match?.group(1) ?? 'G';
  }
}

class _ParkingFloorTile extends StatelessWidget {
  const _ParkingFloorTile({required this.amenities});

  final List<Amenity> amenities;

  @override
  Widget build(BuildContext context) {
    Amenity? car;
    Amenity? bike;
    for (final amenity in amenities) {
      if (amenity.type == 'parking_car') car = amenity;
      if (amenity.type == 'parking_bike') bike = amenity;
    }

    final chips = <Widget>[];
    if (car != null) {
      chips.add(
        _AvailabilityChip(
          label: 'Cars',
          available: car.capacityAvailable ?? 0,
          total: car.capacityTotal ?? 0,
        ),
      );
    }
    if (bike != null) {
      chips.add(
        _AvailabilityChip(
          label: 'Bikes',
          available: bike.capacityAvailable ?? 0,
          total: bike.capacityTotal ?? 0,
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(spacing: 8, runSpacing: 8, children: chips),
      ),
    );
  }
}

class _AvailabilityChip extends StatelessWidget {
  const _AvailabilityChip({
    required this.label,
    required this.available,
    required this.total,
  });

  final String label;
  final int available;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : available / total;
    final color = ratio > 0.5
        ? Colors.green
        : ratio > 0.25
        ? Colors.orange
        : Colors.red;

    return Chip(
      avatar: Icon(Icons.circle, size: 10, color: color),
      label: Text('$label $available/$total'),
    );
  }
}

class _VenueListTile extends StatelessWidget {
  const _VenueListTile({
    required this.venue,

    required this.liveSession,

    required this.semanticsLabel,

    required this.onTap,
  });

  final Venue venue;

  final Session? liveSession;

  final String semanticsLabel;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,

      button: true,

      child: ListTile(
        onTap: onTap,

        title: Text(venue.name, maxLines: 2, overflow: TextOverflow.ellipsis),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text('Capacity ${venue.capacity}'),

            if (liveSession != null)
              Text(
                'Now: ${liveSession!.title}',

                maxLines: 2,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
          ],
        ),

        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
