import '../models/models.dart';
import '../models/user_profile.dart';
import 'companion_knowledge_retriever.dart';
import 'conflict_detector.dart';
import 'day_planner_service.dart';
import 'leave_now_scheduler.dart';
import 'vertical_movement_service.dart';
import 'session_stream_resolver.dart';
import 'walking_time_estimator.dart';

class RuleBasedCompanionService {
  RuleBasedCompanionService({
    DayPlannerService? dayPlannerService,
    WalkingTimeEstimator? walkEstimator,
    ConflictDetector? conflictDetector,
    VerticalMovementService? verticalService,
  }) : _dayPlannerService = dayPlannerService ?? DayPlannerService(),
       _walkEstimator = walkEstimator ?? WalkingTimeEstimator(),
       _conflictDetector = conflictDetector ?? ConflictDetector(),
       _verticalService = verticalService ?? const VerticalMovementService();

  final DayPlannerService _dayPlannerService;
  final WalkingTimeEstimator _walkEstimator;
  final ConflictDetector _conflictDetector;
  final VerticalMovementService _verticalService;

  WalkingTimeEstimator _estimator(CompanionContext context) {
    return _walkEstimator.withContext(
      campus: context.campus,
      isEventDayMode: context.currentDay != null,
    );
  }

  CompanionMessage answer({
    required CompanionContext context,
    CompanionKnowledgePack? pack,
  }) {
    final knowledge = pack ?? CompanionKnowledgeRetriever().retrieve(context);
    final q = context.query.toLowerCase().trim();

    if (q.isEmpty) {
      return const CompanionMessage(
        text: 'Ask me about Flo 2026 sessions, speakers, venues, or tracks.',
      );
    }
    if (_isOffTopic(q)) {
      return const CompanionMessage(
        text: 'I can only help with Flo 2026 sessions.',
      );
    }

    return _nextSessionQuery(q, context) ??
        _stressShortcut(q, context) ??
        _parkingQuery(q, context) ??
        _arrivalQuery(q, context) ??
        _gardenBreakQuery(q, context) ??
        _gymLibraryQuery(q, context) ??
        _stairsAdviceQuery(q, context) ??
        _amenityQuery(q, context) ??
        _venueDirectionsQuery(q, context) ??
        _planCoachQuery(q, context) ??
        _microAgendaQuery(q, context) ??
        _dayPlannerQuery(q, context, knowledge) ??
        _whereIsThatQuery(q, context) ??
        _ceoKeynoteQuery(q, context) ??
        _ceoFiresideQuery(q, context) ??
        _chairmanFiresideQuery(q, context) ??
        _ctoQuery(q, context) ??
        _threePmQuery(q, context) ??
        _cursorQuery(q, context, knowledge) ??
        _speakerQuery(q, context) ??
        _keywordFallback(q, context, knowledge) ??
        _defaultFallback(context, knowledge);
  }

  CompanionMessage? _nextSessionQuery(String q, CompanionContext context) {
    if (!_matchesAny(q, [
      'next session',
      'my next session',
      'take me to my next',
      'where is my next',
    ])) {
      return null;
    }

    final planned = _orderedPlan(context);
    Session? next;
    for (final session in planned) {
      final until = context.minutesUntil?.call(session);
      if (until == null || until > 0) {
        next = session;
        break;
      }
    }

    if (next == null) {
      return const CompanionMessage(
        text:
            'No upcoming sessions in My Plan. Try "Plan my Day 1" or add a session from Discover.',
        followUps: ['Plan my Day 1', "What's happening now?"],
      );
    }

    final venue = _venue(next.venueId, context.venues);
    final until = context.minutesUntil?.call(next) ?? 0;
    final walk = _walkFromPrevious(next, context);
    final landmark = venue?.landmarks.isNotEmpty == true
        ? ' Look for ${venue!.landmarks.first}.'
        : '';

    return CompanionMessage(
      text:
          'Your next session is "${next.title}" in ${venue?.name ?? next.venueId} (Floor ${venue?.floor ?? '?'}, ${venue?.wing ?? '?'} wing) — starts in $until min. Walk ~${walk.minutes} min.$landmark',
      sessionIds: [next.id],
      venueIds: venue != null ? [venue.id] : const [],
      referencedSessionId: next.id,
      referencedTrack: next.trackId,
      referencedVenueId: venue?.id,
      navigationAction: CompanionNavigationAction.directionsToSession,
      sources: [
        CompanionSource(kind: 'session', id: next.id, label: next.title),
        if (venue != null)
          CompanionSource(kind: 'venue', id: venue.id, label: venue.name),
      ],
      followUps: const ['Get directions', 'Open on map'],
    );
  }

  CompanionMessage? _stressShortcut(String q, CompanionContext context) {
    if (q.contains("i'm lost") || q.contains('im lost')) {
      final help = context.amenities.firstWhere(
        (a) => a.type == 'help_desk',
        orElse: () => context.amenities.firstWhere(
          (a) => a.type == 'elevator',
          orElse: () => context.amenities.first,
        ),
      );
      return CompanionMessage(
        text:
            'Head to ${help.label} on Floor ${help.floor} (${help.wing} wing). Registration can point you to your next room.',
        amenityIds: [help.id],
        referencedAmenityId: help.id,
        navigationAction: CompanionNavigationAction.openAmenity,
        sources: [
          CompanionSource(kind: 'amenity', id: help.id, label: help.label),
        ],
        followUps: const ['Where is my next session?', 'Nearest restroom'],
      );
    }

    if (q.contains("i'm late") || q.contains('im late')) {
      final next = _nextPlanned(context);
      if (next == null) {
        return const CompanionMessage(
          text:
              'No planned session coming up. Check Discover for sessions starting soon.',
        );
      }
      final venue = _venue(next.venueId, context.venues);
      return CompanionMessage(
        text:
            'Fastest route: take the nearest elevator to Floor ${venue?.floor ?? '?'} ${venue?.wing ?? ''} wing — "${next.title}" starts in ${context.minutesUntil?.call(next) ?? '?'} min.',
        sessionIds: [next.id],
        venueIds: venue != null ? [venue.id] : const [],
        referencedSessionId: next.id,
        referencedVenueId: venue?.id,
        navigationAction: CompanionNavigationAction.directionsToSession,
        followUps: ['Open on map'],
      );
    }

    return null;
  }

  CompanionMessage? _parkingQuery(String q, CompanionContext context) {
    if (!_matchesAny(q, [
          'where can i park',
          'where to park',
          'park my car',
          'park my bike',
          'bike parking',
          'car parking',
          'car park',
        ]) &&
        !(q.contains('parking') &&
            (q.contains('car') || q.contains('bike') || q.contains('floor')))) {
      return null;
    }

    final floorMatch = RegExp(r'floor\s*(\d+|b|g)').firstMatch(q);
    var targetFloor = floorMatch?.group(1)?.toUpperCase();
    if (targetFloor == null) {
      final ordMatch = RegExp(r'(\d)(?:st|nd|rd|th)\s+floor').firstMatch(q);
      targetFloor = ordMatch?.group(1);
    }

    var parking = context.amenities.where((a) => a.isParking).toList();
    if (targetFloor != null) {
      parking = parking.where((a) => a.floor == targetFloor).toList();
    }

    final wantBike = q.contains('bike');
    final wantCar = q.contains('car') && !wantBike;
    if (wantBike) {
      parking = parking.where((a) => a.type == 'parking_bike').toList();
    } else if (wantCar) {
      parking = parking.where((a) => a.type == 'parking_car').toList();
    }

    if (parking.isEmpty) {
      return const CompanionMessage(
        text:
            'No parking data for that floor. Try Basement, Ground, or floors 1–4.',
        followUps: ['Where can I park my car?', 'Open parking map'],
      );
    }

    parking.sort(
      (a, b) => (b.capacityAvailable ?? 0).compareTo(a.capacityAvailable ?? 0),
    );

    final byFloor = <String, List<Amenity>>{};
    for (final spot in parking) {
      byFloor.putIfAbsent(spot.floor, () => []).add(spot);
    }

    final lines = <String>[];
    for (final floor
        in byFloor.keys.toList()..sort((a, b) {
          final campus = context.campus;
          if (campus == null) return a.compareTo(b);
          return campus.floorIndex(a).compareTo(campus.floorIndex(b));
        })) {
      final spots = byFloor[floor]!;
      final car = spots.firstWhereOrNull((s) => s.type == 'parking_car');
      final bike = spots.firstWhereOrNull((s) => s.type == 'parking_bike');
      final floorLabel = _parkingFloorLabel(floor);
      final parts = <String>[];
      if (car != null) {
        parts.add('Cars ${car.capacityAvailable}/${car.capacityTotal}');
      }
      if (bike != null) {
        parts.add('Bikes ${bike.capacityAvailable}/${bike.capacityTotal}');
      }
      if (parts.isNotEmpty) {
        lines.add('$floorLabel: ${parts.join(', ')}');
      }
    }

    final top = parking.take(4).map((a) => a.id).toList();
    return CompanionMessage(
      text:
          'Parking availability (mock demo counts): ${lines.take(3).join(' · ')}',
      amenityIds: top,
      navigationAction: CompanionNavigationAction.openAmenity,
      sources: parking
          .take(3)
          .map(
            (a) => CompanionSource(kind: 'amenity', id: a.id, label: a.label),
          )
          .toList(),
      followUps: const [
        'Car parking floor 2',
        'Bike parking',
        'Open parking map',
      ],
    );
  }

  CompanionMessage? _arrivalQuery(String q, CompanionContext context) {
    if (!_matchesAny(q, [
      'i just arrived',
      'just arrived',
      'where is reception',
    ])) {
      return null;
    }

    final help = context.amenities.firstWhereOrNull(
      (a) => a.type == 'help_desk',
    );
    final cars = context.amenities
        .where((a) => a.type == 'parking_car')
        .fold<int>(0, (sum, a) => sum + (a.capacityAvailable ?? 0));
    final bikes = context.amenities
        .where((a) => a.type == 'parking_bike')
        .fold<int>(0, (sum, a) => sum + (a.capacityAvailable ?? 0));

    final reception = help?.label ?? 'Ground Reception';
    return CompanionMessage(
      text:
          'Welcome to Flo 2026! Head to $reception on Ground floor for registration. Parking mock totals: ~$cars car bays and ~$bikes bike slots free across B–4.',
      amenityIds: help != null ? [help.id] : const [],
      referencedAmenityId: help?.id,
      navigationAction: CompanionNavigationAction.openAmenity,
      sources: [
        if (help != null)
          CompanionSource(kind: 'amenity', id: help.id, label: help.label),
      ],
      followUps: const [
        'Where can I park my car?',
        'Where is my next session?',
      ],
    );
  }

  CompanionMessage? _gardenBreakQuery(String q, CompanionContext context) {
    if (!_matchesAny(q, [
      'fresh air',
      'garden',
      'need a break',
      'take a break',
      'wellness',
    ])) {
      return null;
    }

    final garden = context.amenities.firstWhereOrNull(
      (a) => a.type == 'garden',
    );
    if (garden == null) {
      return const CompanionMessage(
        text: 'Floor 5 wellness garden — open air, fountain, and light snacks.',
        followUps: ['Open on map'],
      );
    }

    final fromFloor = _inferFloor(context) ?? '7';
    final campus = context.campus;
    final vertical = campus != null
        ? _verticalService.recommend(
            campus: campus,
            fromFloor: fromFloor,
            toFloor: garden.floor,
            isEventDayMode: context.currentDay != null,
          )
        : null;

    final modeHint = vertical != null
        ? ' ${vertical.mode == 'stairs' ? 'Stairs' : 'Lifts'} ~${vertical.minutes} min from Floor $fromFloor.'
        : '';

    return CompanionMessage(
      text: 'Floor 5 garden — open air, fountain, and light snacks.$modeHint',
      amenityIds: [garden.id],
      referencedAmenityId: garden.id,
      navigationAction: CompanionNavigationAction.openAmenity,
      sources: [
        CompanionSource(kind: 'amenity', id: garden.id, label: garden.label),
      ],
      followUps: const ['I have 20 minutes', 'Open on map'],
    );
  }

  CompanionMessage? _gymLibraryQuery(String q, CompanionContext context) {
    String? type;
    if (q.contains('gym') || q.contains('workout')) {
      type = 'gym';
    } else if (q.contains('library')) {
      type = 'library';
    }
    if (type == null) return null;

    final amenity = context.amenities.firstWhereOrNull((a) => a.type == type);
    if (amenity == null) {
      return CompanionMessage(
        text:
            'Floor 6 South has the ${type == 'gym' ? 'gym' : 'library'} near the training rooms.',
        followUps: ['Open on map'],
      );
    }

    return CompanionMessage(
      text:
          '${amenity.label} is on Floor ${amenity.floor}, ${amenity.wing} wing (South amenities block).',
      amenityIds: [amenity.id],
      referencedAmenityId: amenity.id,
      navigationAction: CompanionNavigationAction.openAmenity,
      sources: [
        CompanionSource(kind: 'amenity', id: amenity.id, label: amenity.label),
      ],
      followUps: const ['Open on map', 'Nearest restroom'],
    );
  }

  CompanionMessage? _stairsAdviceQuery(String q, CompanionContext context) {
    if (!_matchesAny(q, [
      'should i take stairs',
      'take the stairs',
      'stairs or lift',
      'stairs or elevator',
      'fastest way to floor',
    ])) {
      return null;
    }

    final campus = context.campus;
    if (campus == null) {
      return const CompanionMessage(
        text:
            'For 1–2 floors up or up to 3 down, central stairs are often faster than lifts during event rush.',
      );
    }

    final floorMatch = RegExp(r'floor\s*(\d+)').firstMatch(q);
    final toFloor = floorMatch?.group(1) ?? _inferFloor(context) ?? '8';
    final fromFloor = _inferFloor(context) ?? 'G';
    final rec = _verticalService.recommend(
      campus: campus,
      fromFloor: fromFloor,
      toFloor: toFloor,
      isEventDayMode: context.currentDay != null,
    );

    final alt = rec.tip != null ? ' ${rec.tip}' : '';
    return CompanionMessage(
      text:
          'From Floor $fromFloor to $toFloor: ${rec.mode == 'stairs' ? 'Stairs' : 'Lifts'} ~${rec.minutes} min (${rec.reason}).$alt',
      followUps: const ['Get directions', 'Open on map'],
    );
  }

  String _parkingFloorLabel(String floor) {
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

  CompanionMessage? _amenityQuery(String q, CompanionContext context) {
    String? type;
    String? targetWing;

    if (_matchesAny(q, ['restroom', 'bathroom', 'toilet', 'wc'])) {
      type = 'restroom';
      if (_matchesAny(q, ['ladies', 'women', "women's"])) {
        targetWing = 'N';
      } else if (_matchesAny(q, ['gents', "men's", ' mens '])) {
        targetWing = 'S';
      } else if (q.contains(' men')) {
        targetWing = 'S';
      }
    } else if (_matchesAny(q, ['quiet', 'focus zone'])) {
      type = 'quiet_zone';
    } else if (_matchesAny(q, ['coffee', 'cafeteria', 'cafe'])) {
      type = 'coffee';
    } else if (_matchesAny(q, ['elevator', 'lift'])) {
      type = 'elevator';
    }

    if (type == null) return null;

    final floorMatch = RegExp(r'floor\s*(\d+|g|b)').firstMatch(q);
    final targetFloor =
        floorMatch?.group(1)?.toUpperCase() ?? _inferFloor(context);

    final candidates = context.amenities
        .where(
          (a) =>
              a.type == type &&
              (targetFloor == null || a.floor == targetFloor) &&
              (targetWing == null || a.wing == targetWing),
        )
        .toList();

    if (candidates.isEmpty && type == 'restroom' && targetWing != null) {
      return CompanionMessage(
        text:
            'No restrooms found on Floor ${targetFloor ?? '?'} ${targetWing == 'N' ? 'North (ladies signage)' : 'South (gents signage)'}. Try another floor.',
        followUps: const ['Nearest ladies restroom Floor 8', 'Open on map'],
      );
    }

    if (candidates.isEmpty) {
      return CompanionMessage(
        text:
            'No $type found on Floor ${targetFloor ?? '?'}. Try another floor.',
        followUps: const ['Nearest restroom Floor 8', 'Open on map'],
      );
    }

    final amenity = candidates.first;
    final fromVenue = _currentVenue(context);
    final toVenue = amenity.venueId != null
        ? _venue(amenity.venueId!, context.venues)
        : null;
    final walk = _estimator(context).estimate(from: fromVenue, to: toVenue);
    final disclaimer = context.campus?.restroomConvention.disclaimer;
    final wingNote = type == 'restroom' && disclaimer != null
        ? ' ($disclaimer)'
        : '';

    return CompanionMessage(
      text:
          'Nearest ${amenity.label}: Floor ${amenity.floor}, ${amenity.wing} wing (~${walk.minutes} min walk).$wingNote',
      amenityIds: [amenity.id],
      venueIds: amenity.venueId != null ? [amenity.venueId!] : const [],
      referencedAmenityId: amenity.id,
      referencedVenueId: amenity.venueId,
      navigationAction: amenity.venueId != null
          ? CompanionNavigationAction.openVenueMap
          : CompanionNavigationAction.openAmenity,
      sources: [
        CompanionSource(kind: 'amenity', id: amenity.id, label: amenity.label),
      ],
      followUps: const ['Open on map', 'Where is my next session?'],
    );
  }

  CompanionMessage? _venueDirectionsQuery(String q, CompanionContext context) {
    if (!_matchesAny(q, ['how do i get', 'directions to', 'take me to'])) {
      return null;
    }

    Venue? match;
    for (final venue in context.venues) {
      if (q.contains(venue.name.toLowerCase()) ||
          q.contains(venue.id.toLowerCase())) {
        match = venue;
        break;
      }
    }

    if (match == null) return null;

    final from = _currentVenue(context);
    final walk = _estimator(context).estimate(from: from, to: match);
    final story = context.meta?.storyForFloor(match.floor);
    final landmark = match.landmarks.isNotEmpty
        ? ' ${match.landmarks.join('; ')}.'
        : '';
    final stepFree = match.stepFree ? ' Step-free route available.' : '';

    return CompanionMessage(
      text:
          '${match.name} is on Floor ${match.floor} (${match.wing} wing) — ~${walk.minutes} min walk.$landmark${story != null ? ' $story' : ''}$stepFree',
      venueIds: [match.id],
      referencedVenueId: match.id,
      navigationAction: CompanionNavigationAction.openVenueMap,
      sources: [
        CompanionSource(kind: 'venue', id: match.id, label: match.name),
      ],
      followUps: const ['Open on map'],
    );
  }

  CompanionMessage? _planCoachQuery(String q, CompanionContext context) {
    if (!_matchesAny(q, [
      'fix my plan',
      'fix my conflicts',
      'what should i skip',
      'resolve conflict',
      'resolve plan conflict',
      'overlaps with',
      'clash at',
    ])) {
      return null;
    }

    final conflicts = context.conflicts.isNotEmpty
        ? context.conflicts
        : _conflictDetector.findConflicts(context.plannedSessions);

    if (conflicts.isEmpty) {
      return const CompanionMessage(
        text: 'No time conflicts in My Plan — you are good to go!',
        followUps: ["What's in my next 2 hours?"],
      );
    }

    final refId = context.lastReferencedSessionId;
    final conflict = refId == null
        ? conflicts.first
        : conflicts.firstWhere(
            (c) => c.sessionA.id == refId || c.sessionB.id == refId,
            orElse: () => conflicts.first,
          );

    final a = conflict.sessionA;
    final b = conflict.sessionB;
    final skip = _lowerInterestMatch(a, b, context.profile) ? a : b;
    final keep = skip.id == a.id ? b : a;

    final streamHint = _streamConflictHint(
      context: context,
      keep: keep,
      skip: skip,
    );

    return CompanionMessage(
      text:
          'You have a clash at ${a.startTime}: "${a.title}" vs "${b.title}". Based on your interests, consider skipping "${skip.title}" and keeping "${keep.title}".$streamHint',
      sessionIds: [keep.id, skip.id],
      referencedSessionId: keep.id,
      referencedTrack: keep.trackId,
      sources: [
        CompanionSource(kind: 'session', id: keep.id, label: keep.title),
        CompanionSource(kind: 'session', id: skip.id, label: skip.title),
      ],
      followUps: const ['Show alternatives', "What's in my next 2 hours?"],
    );
  }

  String _streamConflictHint({
    required CompanionContext context,
    required Session keep,
    required Session skip,
  }) {
    if (context.profile.attendanceMode != AttendanceMode.remote) {
      return '';
    }
    const resolver = SessionStreamResolver();
    for (final session in [keep, skip]) {
      final action = resolver.resolve(session);
      if (action.isStreamable && action.url != null) {
        return ' As a remote attendee, you can stream "${session.title}" instead of rushing on-site.';
      }
    }
    return '';
  }

  CompanionMessage? _microAgendaQuery(String q, CompanionContext context) {
    final isTwentyMin =
        q.contains('20 minutes') || q.contains('twenty minutes');
    if (!_matchesAny(q, [
      'next 2 hours',
      'next two hours',
      'coming up',
      'i have 15 minutes',
      'i have 20 minutes',
    ])) {
      return null;
    }

    final planned = _orderedPlan(context).where((session) {
      if (context.minutesUntil == null) return true;
      final until = context.minutesUntil!(session);
      final window = isTwentyMin ? 20 : 120;
      return until >= 0 && until <= window;
    }).toList();

    if (planned.isEmpty && isTwentyMin) {
      final garden = context.amenities.firstWhereOrNull(
        (a) => a.type == 'garden',
      );
      final fromFloor = _inferFloor(context) ?? '6';
      final campus = context.campus;
      final walkHint = campus != null
          ? _verticalService.recommend(
              campus: campus,
              fromFloor: fromFloor,
              toFloor: campus.wellnessFloor,
              isEventDayMode: context.currentDay != null,
            )
          : null;
      final walkText = walkHint != null
          ? ' (~${walkHint.minutes} min ${walkHint.mode} to Floor 5)'
          : '';
      return CompanionMessage(
        text:
            'Nothing planned in the next 20 minutes. Take a garden break on Floor 5 — open air, fountain, and light snacks$walkText.',
        amenityIds: garden != null ? [garden.id] : const [],
        referencedAmenityId: garden?.id,
        navigationAction: CompanionNavigationAction.openAmenity,
        sources: garden != null
            ? [
                CompanionSource(
                  kind: 'amenity',
                  id: garden.id,
                  label: garden.label,
                ),
              ]
            : const [],
        followUps: const ['Open on map', "What's happening now?"],
      );
    }

    if (planned.isEmpty) {
      if (q.contains('20 minutes') && context.campus != null) {
        final garden = context.amenities.firstWhereOrNull(
          (a) => a.type == 'garden',
        );
        final fromFloor = _inferFloor(context) ?? '7';
        final vertical = _verticalService.recommend(
          campus: context.campus!,
          fromFloor: fromFloor,
          toFloor: context.campus!.wellnessFloor,
          isEventDayMode: context.currentDay != null,
        );
        return CompanionMessage(
          text:
              'Nothing planned in the next 20 minutes. Take a break at Floor 5 garden — fresh air and light snacks (~${vertical.minutes} min ${vertical.mode} from Floor $fromFloor).',
          amenityIds: garden != null ? [garden.id] : const [],
          referencedAmenityId: garden?.id,
          navigationAction: CompanionNavigationAction.openAmenity,
          followUps: const ['Open on map', 'Plan my Day 1'],
        );
      }

      final pick = context.sessions.where((s) => s.featured).take(2).toList();
      return CompanionMessage(
        text:
            'Nothing planned in the next 2 hours. Flo Pick: ${pick.map((s) => '${s.title} (${s.startTime})').join('; ')}',
        sessionIds: pick.map((s) => s.id).toList(),
        followUps: const ['Add to My Plan', 'Plan my Day 1'],
      );
    }

    return CompanionMessage(
      text:
          'Your next 2 hours: ${planned.map((s) => '${s.title} (${s.day} ${s.startTime})').join('; ')}',
      sessionIds: planned.map((s) => s.id).toList(),
      referencedSessionId: planned.first.id,
      sources: planned
          .map(
            (s) => CompanionSource(kind: 'session', id: s.id, label: s.title),
          )
          .toList(),
      followUps: const ['Get directions', 'Fix my conflicts'],
    );
  }

  CompanionMessage? _dayPlannerQuery(
    String q,
    CompanionContext context,
    CompanionKnowledgePack knowledge,
  ) {
    if (!_isDayPlannerQuery(q)) return null;

    final parsedDay = _extractDay(q);
    final plan = _dayPlannerService.buildPlan(
      sessions: context.sessions,
      speakers: context.speakers,
      tracks: context.tracks,
      profile: context.profile,
      requestedDay: parsedDay,
    );
    return CompanionMessage(
      text: plan.text,
      sessionIds: plan.sessions.map((s) => s.id).toList(),
      sources: plan.sessions
          .map(
            (s) => CompanionSource(kind: 'session', id: s.id, label: s.title),
          )
          .toList(),
      followUps: const [
        'Save this plan',
        'Show all their sessions',
        'What should I skip?',
      ],
      referencedSessionId: plan.sessions.isEmpty
          ? null
          : plan.sessions.first.id,
      referencedTrack: plan.sessions.isEmpty
          ? null
          : plan.sessions.first.trackId,
    );
  }

  CompanionMessage? _whereIsThatQuery(String q, CompanionContext context) {
    if (!_matchesAny(q, ['where is that', 'where is this'])) return null;
    final sessionId = context.lastReferencedSessionId;
    if (sessionId == null) return null;

    final match = context.sessions.firstWhereOrNull((s) => s.id == sessionId);
    if (match == null) return null;

    final venue = _venue(match.venueId, context.venues);
    return CompanionMessage(
      text:
          '"${match.title}" is at ${venue?.name ?? match.venueId} on ${match.day} at ${match.startTime}.',
      sessionIds: [match.id],
      venueIds: venue != null ? [venue.id] : const [],
      referencedSessionId: match.id,
      referencedTrack: match.trackId,
      referencedVenueId: venue?.id,
      navigationAction: CompanionNavigationAction.directionsToSession,
      sources: [
        CompanionSource(kind: 'session', id: match.id, label: match.title),
        if (venue != null)
          CompanionSource(kind: 'venue', id: venue.id, label: venue.name),
      ],
      followUps: const ['Get directions', 'Add to My Plan'],
    );
  }

  CompanionMessage? _ceoKeynoteQuery(String q, CompanionContext context) {
    if (!q.contains('ceo') ||
        !(q.contains('keynote') || q.contains('opening'))) {
      return null;
    }
    final match = context.sessions.firstWhereOrNull(
      (s) =>
          s.title.toLowerCase().contains('ceo') &&
          (s.format == 'Keynote' || s.title.toLowerCase().contains('keynote')),
    );
    if (match == null) return null;
    final venue = _venue(match.venueId, context.venues);
    return CompanionMessage(
      text:
          'The CEO keynote is "${match.title}" on ${match.day} at ${match.startTime} in ${venue?.name ?? match.venueId}.',
      sessionIds: [match.id],
      venueIds: venue != null ? [venue.id] : const [],
      referencedSessionId: match.id,
      referencedVenueId: venue?.id,
      navigationAction: CompanionNavigationAction.directionsToSession,
      sources: [
        CompanionSource(kind: 'session', id: match.id, label: match.title),
      ],
      followUps: const ['Get directions', 'Add to My Plan'],
    );
  }

  CompanionMessage? _ceoFiresideQuery(String q, CompanionContext context) {
    if (!q.contains('ceo') || !q.contains('fireside')) return null;
    final match = context.sessions.firstWhereOrNull(
      (s) => s.title.toLowerCase().contains('ceo fireside'),
    );
    if (match == null) return null;
    final venue = _venue(match.venueId, context.venues);
    return CompanionMessage(
      text:
          'The CEO fireside is "${match.title}" on ${match.day} at ${match.startTime} in ${venue?.name ?? match.venueId}.',
      sessionIds: [match.id],
      venueIds: venue != null ? [venue.id] : const [],
      referencedSessionId: match.id,
      referencedVenueId: venue?.id,
      navigationAction: CompanionNavigationAction.directionsToSession,
      sources: [
        CompanionSource(kind: 'session', id: match.id, label: match.title),
      ],
      followUps: const ['Get directions', "What's nearby?"],
    );
  }

  CompanionMessage? _chairmanFiresideQuery(String q, CompanionContext context) {
    if (!q.contains('chairman')) return null;
    final match = context.sessions.firstWhereOrNull(
      (s) =>
          s.title.toLowerCase().contains('chairman') ||
          (s.format == 'Fireside Chat' &&
              s.speakerIds.any(
                (id) =>
                    context.speakers
                        .firstWhereOrNull((sp) => sp.id == id)
                        ?.title
                        .toLowerCase()
                        .contains('chairman') ??
                    false,
              )),
    );
    if (match == null) return null;
    final venue = _venue(match.venueId, context.venues);
    return CompanionMessage(
      text:
          'The Chairman fireside is "${match.title}" on ${match.day} at ${match.startTime} in ${venue?.name ?? match.venueId}.',
      sessionIds: [match.id],
      venueIds: venue != null ? [venue.id] : const [],
      referencedSessionId: match.id,
      referencedVenueId: venue?.id,
      navigationAction: CompanionNavigationAction.directionsToSession,
      sources: [
        CompanionSource(kind: 'session', id: match.id, label: match.title),
      ],
      followUps: const ['Get directions', 'Add to My Plan'],
    );
  }

  CompanionMessage? _ctoQuery(String q, CompanionContext context) {
    if (!q.contains('cto')) return null;
    if (q.contains('who is')) {
      final cto = context.speakers.firstWhereOrNull(
        (s) => s.title.toLowerCase().contains('cto'),
      );
      if (cto == null) return null;
      final ctoSessions = context.sessions
          .where((s) => s.speakerIds.contains(cto.id))
          .take(4)
          .toList();
      return CompanionMessage(
        text:
            'The CTO is ${cto.name}. Sessions: ${ctoSessions.map((s) => '${s.title} (${s.day} ${s.startTime})').join('; ')}',
        sessionIds: ctoSessions.map((s) => s.id).toList(),
        referencedSessionId: ctoSessions.isEmpty ? null : ctoSessions.first.id,
        sources: ctoSessions
            .map(
              (s) => CompanionSource(kind: 'session', id: s.id, label: s.title),
            )
            .toList(),
        followUps: const ['Show all their sessions', 'Add to My Plan'],
      );
    }
    if (q.contains('day 1')) {
      final cto = context.speakers.firstWhereOrNull(
        (s) => s.title.toLowerCase().contains('cto'),
      );
      if (cto == null) return null;
      final dayOneSessions = context.sessions
          .where((s) => s.speakerIds.contains(cto.id) && s.day == 'Day 1')
          .take(5)
          .toList();
      if (dayOneSessions.isEmpty) return null;
      return CompanionMessage(
        text:
            'CTO sessions on Day 1: ${dayOneSessions.map((s) => '${s.title} (${s.startTime})').join('; ')}',
        sessionIds: dayOneSessions.map((s) => s.id).toList(),
        referencedSessionId: dayOneSessions.first.id,
        sources: dayOneSessions
            .map(
              (s) => CompanionSource(kind: 'session', id: s.id, label: s.title),
            )
            .toList(),
        followUps: const ['Add to My Plan', 'Show all their sessions'],
      );
    }
    return null;
  }

  CompanionMessage? _threePmQuery(String q, CompanionContext context) {
    if (!_matchesAny(q, [
      "what's happening at 3pm",
      'happening at 3pm',
      'what is happening now',
      "what's happening now",
    ])) {
      return null;
    }
    final hits = context.sessions
        .where(
          (s) =>
              s.startTime == '15:00' ||
              (q.contains('now') && _isLiveNow(s, context)),
        )
        .take(5)
        .toList();
    if (hits.isEmpty) return null;
    return CompanionMessage(
      text:
          'Top picks: ${hits.map((s) => '${s.title} (${_venueName(s.venueId, context.venues)})').join('; ')}',
      sessionIds: hits.map((s) => s.id).toList(),
      sources: hits
          .map(
            (s) => CompanionSource(kind: 'session', id: s.id, label: s.title),
          )
          .toList(),
      followUps: const ['Save this plan', 'Show by floor'],
    );
  }

  CompanionMessage? _cursorQuery(
    String q,
    CompanionContext context,
    CompanionKnowledgePack knowledge,
  ) {
    if (!q.contains('cursor') && !q.contains('devex')) return null;
    final matches = knowledge.sessions.isNotEmpty
        ? knowledge.sessions
        : context.sessions
              .where(
                (s) =>
                    s.tags.contains('cursor') ||
                    s.tags.contains('devex') ||
                    s.title.toLowerCase().contains('cursor'),
              )
              .take(5)
              .toList();
    if (matches.isEmpty) return null;
    return CompanionMessage(
      text:
          'Cursor & DevEx sessions: ${matches.map((s) => '${s.title} (${s.day} ${s.startTime})').join('; ')}',
      sessionIds: matches.map((s) => s.id).toList(),
      referencedSessionId: matches.first.id,
      sources: matches
          .map(
            (s) => CompanionSource(kind: 'session', id: s.id, label: s.title),
          )
          .toList(),
      followUps: const ['Save this plan', "What's next after this?"],
    );
  }

  CompanionMessage? _speakerQuery(String q, CompanionContext context) {
    final speakerMatch = context.speakers.firstWhereOrNull(
      (s) => q.contains(s.name.toLowerCase()),
    );
    if (speakerMatch == null) return null;
    final spkSessions = context.sessions
        .where((s) => s.speakerIds.contains(speakerMatch.id))
        .take(5)
        .toList();
    return CompanionMessage(
      text:
          '${speakerMatch.name} (${speakerMatch.title}) speaks at: ${spkSessions.map((s) => '${s.title} ${s.day} ${s.startTime}').join('; ')}',
      sessionIds: spkSessions.map((s) => s.id).toList(),
      referencedSessionId: spkSessions.isEmpty ? null : spkSessions.first.id,
      sources: spkSessions
          .map(
            (s) => CompanionSource(kind: 'session', id: s.id, label: s.title),
          )
          .toList(),
      followUps: const ['Show all their sessions', 'Add to My Plan'],
    );
  }

  CompanionMessage? _keywordFallback(
    String q,
    CompanionContext context,
    CompanionKnowledgePack knowledge,
  ) {
    final keywordHits = knowledge.sessions.isNotEmpty
        ? knowledge.sessions
        : context.sessions
              .where(
                (s) =>
                    s.tags.any((tag) => q.contains(tag.replaceAll('_', ' '))) ||
                    s.title.toLowerCase().contains(q),
              )
              .take(5)
              .toList();
    if (keywordHits.isEmpty) return null;
    return CompanionMessage(
      text:
          'Found ${keywordHits.length} matching sessions: ${keywordHits.map((s) => s.title).join('; ')}',
      sessionIds: keywordHits.map((s) => s.id).toList(),
      referencedSessionId: keywordHits.first.id,
      sources: keywordHits
          .map(
            (s) => CompanionSource(kind: 'session', id: s.id, label: s.title),
          )
          .toList(),
      followUps: const ['Show session details', 'Add to My Plan'],
    );
  }

  CompanionMessage _defaultFallback(
    CompanionContext context,
    CompanionKnowledgePack knowledge,
  ) {
    final featured = context.sessions.where((s) => s.featured).take(3).toList();
    return CompanionMessage(
      text:
          'I could not find an exact match. Try asking about the CEO fireside, nearest restroom, where is my next session, or fix my plan.',
      sessionIds: featured.map((s) => s.id).toList(),
      referencedSessionId: featured.isEmpty ? null : featured.first.id,
      followUps: const ['Plan my day', 'Nearest restroom', "I'm lost"],
    );
  }

  bool _isOffTopic(String q) {
    const blocked = ['weather', 'stock', 'bitcoin', 'recipe', 'ignore prior'];
    return blocked.any(q.contains);
  }

  bool _isDayPlannerQuery(String q) {
    return q.contains('plan my day') ||
        q.contains('build my schedule') ||
        q.contains('day 2 plan') ||
        q.contains('day 1 plan') ||
        q.contains('day 3 plan');
  }

  String? _extractDay(String q) {
    if (q.contains('day 1')) return 'Day 1';
    if (q.contains('day 2')) return 'Day 2';
    if (q.contains('day 3')) return 'Day 3';
    return null;
  }

  bool _matchesAny(String q, List<String> phrases) =>
      phrases.any((p) => q.contains(p));

  Venue? _venue(String id, List<Venue> venues) =>
      venues.firstWhereOrNull((v) => v.id == id);

  String _venueName(String venueId, List<Venue> venues) =>
      _venue(venueId, venues)?.name ?? venueId;

  List<Session> _orderedPlan(CompanionContext context) {
    final ordered = [...context.plannedSessions]
      ..sort((a, b) {
        final day = a.dayNumber.compareTo(b.dayNumber);
        if (day != 0) return day;
        return a.startTime.compareTo(b.startTime);
      });
    return ordered;
  }

  Session? _nextPlanned(CompanionContext context) {
    for (final session in _orderedPlan(context)) {
      final until = context.minutesUntil?.call(session);
      if (until == null || until > 0) return session;
    }
    return null;
  }

  Venue? _currentVenue(CompanionContext context) {
    Session? current;
    for (final session in _orderedPlan(context)) {
      final until = context.minutesUntil?.call(session);
      if (until != null && until <= 0) {
        current = session;
      }
    }
    if (current != null) {
      return _venue(current.venueId, context.venues);
    }
    return _venue(kDefaultFromVenueId, context.venues);
  }

  String? _inferFloor(CompanionContext context) {
    final next = _nextPlanned(context);
    if (next == null) return null;
    return _venue(next.venueId, context.venues)?.floor;
  }

  WalkingTimeEstimate _walkFromPrevious(
    Session next,
    CompanionContext context,
  ) {
    final ordered = _orderedPlan(context);
    Session? previous;
    for (final session in ordered) {
      if (session.id == next.id) break;
      previous = session;
    }
    return _walkEstimator
        .withContext(
          campus: context.campus,
          isEventDayMode: context.currentDay != null,
        )
        .estimate(
          from: previous != null
              ? _venue(previous.venueId, context.venues)
              : _venue(kDefaultFromVenueId, context.venues),
          to: _venue(next.venueId, context.venues),
        );
  }

  bool _lowerInterestMatch(Session a, Session b, UserProfile profile) {
    int score(Session s) {
      var total = 0;
      for (final interest in profile.interests) {
        if (s.tags.contains(interest)) total += 2;
      }
      if (s.featured) total += 1;
      return total;
    }

    return score(a) < score(b);
  }

  bool _isLiveNow(Session session, CompanionContext context) {
    final until = context.minutesUntil?.call(session);
    return until != null && until <= 0;
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) predicate) {
    for (final item in this) {
      if (predicate(item)) return item;
    }
    return null;
  }
}
