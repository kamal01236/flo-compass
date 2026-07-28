import 'dart:convert';
import 'dart:io';

const String kBuilding = 'Nagarro Gurgaon Office';
const List<String> kDays = ['Day 1', 'Day 2', 'Day 3'];
const List<String> kFloors = ['G', '6', '7', '8', '9', '10', '11', '12', '13'];
const List<String> kWings = ['N', 'S', 'central'];

Future<List<dynamic>> _list(String path) async =>
    jsonDecode(await File(path).readAsString()) as List<dynamic>;

Future<Map<String, dynamic>> _map(String path) async =>
    jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;

Future<void> main() async {
  final violations = <String>[];

  final meta = await _map('assets/data/flo2026_meta.json');
  final venues = (await _list(
    'assets/data/flo2026_venues.json',
  )).cast<Map<String, dynamic>>();
  final tracks = (await _list(
    'assets/data/flo2026_tracks.json',
  )).cast<Map<String, dynamic>>();
  final speakers = (await _list(
    'assets/data/flo2026_speakers.json',
  )).cast<Map<String, dynamic>>();
  final sessions = (await _list(
    'assets/data/flo2026_sessions.json',
  )).cast<Map<String, dynamic>>();

  if (meta['venue'] != kBuilding) {
    violations.add('meta.venue must be $kBuilding');
  }

  final floorStories = (meta['floorStories'] as Map<String, dynamic>?) ?? {};
  for (final floor in kFloors) {
    final story = floorStories[floor] as String?;
    if (story == null || story.trim().isEmpty) {
      violations.add('meta.floorStories missing blurb for floor $floor');
    }
  }

  final venueIds = <String>{};
  final venueById = <String, Map<String, dynamic>>{};
  for (final venue in venues) {
    final id = venue['id'] as String? ?? '';
    if (!venueIds.add(id)) {
      violations.add('duplicate venue id $id');
    }
    venueById[id] = venue;
    if (venue['building'] != kBuilding) {
      violations.add('venue $id has invalid building');
    }
    if (!kFloors.contains(venue['floor'])) {
      violations.add('venue $id floor ${venue['floor']} invalid');
    }
    if (!kWings.contains(venue['wing'])) {
      violations.add('venue $id wing ${venue['wing']} invalid');
    }
  }
  if (venues.length != 90) {
    violations.add('venue count should be 90, got ${venues.length}');
  }

  final trackIds = tracks.map((t) => t['id'] as String).toSet();
  final speakerIds = speakers.map((s) => s['id'] as String).toSet();
  final sessionIds = <String>{};
  final speakerBooked = <String, Set<String>>{};

  var featuredCount = 0;
  var longAbstractCount = 0;
  var cafeteriaOutOfSlotCount = 0;

  for (final session in sessions) {
    final id = session['id'] as String? ?? '';
    if (!sessionIds.add(id)) {
      violations.add('duplicate session id $id');
    }
    if (session['building'] != kBuilding) {
      violations.add('session $id has invalid building');
    }
    if (!kDays.contains(session['day'])) {
      violations.add('session $id has invalid day');
    }

    final venueId = session['venueId'] as String? ?? '';
    final venue = venueById[venueId];
    if (venue == null) {
      violations.add('session $id references unknown venue $venueId');
      continue;
    }
    if (!trackIds.contains(session['trackId'])) {
      violations.add('session $id references unknown track');
    }
    final speakerList = (session['speakerIds'] as List<dynamic>? ?? [])
        .cast<String>();
    if (speakerList.isEmpty) {
      violations.add('session $id has empty speakers');
    }
    for (final speakerId in speakerList) {
      if (!speakerIds.contains(speakerId)) {
        violations.add('session $id references unknown speaker $speakerId');
      }
      final token = '${session['day']}|${session['startTime']}';
      final bucket = speakerBooked.putIfAbsent(speakerId, () => <String>{});
      if (bucket.contains(token)) {
        violations.add('speaker $speakerId double-booked at $token');
      }
      bucket.add(token);
    }

    final sessionCapacity = session['capacity'] as int? ?? 0;
    final venueCapacity = venue['capacity'] as int? ?? 0;
    if (sessionCapacity > venueCapacity) {
      violations.add('session $id exceeds venue capacity');
    }

    if ((session['featured'] as bool?) ?? false) {
      featuredCount++;
    }
    final abstract = (session['abstract'] as String? ?? '').trim();
    if (abstract.length >= 250) {
      longAbstractCount++;
    }

    if (venueId == 'ven-C601' && session['startTime'] != '12:00') {
      cafeteriaOutOfSlotCount++;
      violations.add('session $id uses cafeteria outside 12:00');
    }

    final wing = venue['wing'] as String? ?? '';
    if (venueId.startsWith('ven-') && venueId.length >= 7) {
      if (venueId.contains('N') && wing != 'N') {
        violations.add('session $id venue wing mismatch: expected N');
      }
      if (venueId.contains('S') && wing != 'S') {
        violations.add('session $id venue wing mismatch: expected S');
      }
    }
  }

  if (featuredCount != 10) {
    violations.add('expected 10 featured sessions, got $featuredCount');
  }
  if (sessions.length < 620 || sessions.length > 660) {
    violations.add('expected ~640 sessions, got ${sessions.length}');
  }
  if (longAbstractCount < (sessions.length * 0.9)) {
    violations.add(
      'at least 90% abstracts must be >=250 chars, got $longAbstractCount/${sessions.length}',
    );
  }
  if (cafeteriaOutOfSlotCount > 0) {
    violations.add(
      'cafeteria slot rule broken for $cafeteriaOutOfSlotCount sessions',
    );
  }

  const parkingFloors = ['B', 'G', '1', '2', '3', '4'];
  const wellnessFloors = ['B', '1', '2', '3', '4', '5'];
  for (final floor in wellnessFloors) {
    final story = floorStories[floor] as String?;
    if (story == null || story.trim().isEmpty) {
      violations.add('meta.floorStories missing blurb for floor $floor');
    }
  }

  final amenitiesFile = File('assets/data/flo2026_amenities.json');
  if (amenitiesFile.existsSync()) {
    final amenities =
        (jsonDecode(await amenitiesFile.readAsString()) as List<dynamic>)
            .cast<Map<String, dynamic>>();
    final parking = amenities
        .where((a) => a['type'] == 'parking_car' || a['type'] == 'parking_bike')
        .toList();
    if (parking.length != 12) {
      violations.add('expected 12 parking amenities, got ${parking.length}');
    }
    for (final floor in parkingFloors) {
      final car = parking.where(
        (a) => a['floor'] == floor && a['type'] == 'parking_car',
      );
      final bike = parking.where(
        (a) => a['floor'] == floor && a['type'] == 'parking_bike',
      );
      if (car.isEmpty || bike.isEmpty) {
        violations.add('parking floor $floor missing car or bike amenity');
      }
    }
    for (final spot in parking) {
      final type = spot['type'] as String? ?? '';
      final expectedTotal = type == 'parking_car' ? 40 : 100;
      if (spot['capacityTotal'] != expectedTotal) {
        violations.add('${spot['id']} capacityTotal should be $expectedTotal');
      }
    }
    stdout.writeln(
      '  amenities: ${amenities.length} (parking: ${parking.length})',
    );
  }

  final campusFile = File('assets/data/flo2026_campus.json');
  if (campusFile.existsSync()) {
    final campus =
        jsonDecode(await campusFile.readAsString()) as Map<String, dynamic>;
    final campusParking = (campus['parkingFloors'] as List<dynamic>? ?? [])
        .cast<String>();
    if (campusParking.length != parkingFloors.length) {
      violations.add('campus parkingFloors count mismatch');
    }
    for (final floor in parkingFloors) {
      if (!campusParking.contains(floor)) {
        violations.add('campus missing parking floor $floor');
      }
    }
  }

  final learningPathsFile = File('assets/data/learning_paths.json');
  if (learningPathsFile.existsSync()) {
    final learningPathsRaw =
        jsonDecode(await learningPathsFile.readAsString())
            as Map<String, dynamic>;
    final paths = (learningPathsRaw['paths'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    if (paths.length < 5 || paths.length > 8) {
      violations.add(
        'learning_paths.json should contain 5-8 paths, got ${paths.length}',
      );
    }
    for (final path in paths) {
      final pathId = path['id'] as String? ?? '';
      final sessionIdList = (path['sessionIds'] as List<dynamic>? ?? [])
          .cast<String>();
      if (sessionIdList.isEmpty) {
        violations.add('learning path $pathId has no sessionIds');
      }
      if (sessionIdList.length > 8) {
        violations.add(
          'learning path $pathId exceeds 8 sessions (${sessionIdList.length})',
        );
      }
      for (final sessionId in sessionIdList) {
        if (!sessionIds.contains(sessionId)) {
          violations.add(
            'learning path $pathId references unknown session $sessionId',
          );
        }
      }
    }
    stdout.writeln('  paths:    ${paths.length}');
  }

  stdout.writeln('Flo 2026 dataset validation');
  stdout.writeln('  venues:   ${venues.length}');
  stdout.writeln('  tracks:   ${tracks.length}');
  stdout.writeln('  speakers: ${speakers.length}');
  stdout.writeln('  sessions: ${sessions.length} (featured: $featuredCount)');

  if (violations.isEmpty) {
    stdout.writeln('OK: validation passed');
    exitCode = 0;
    return;
  }

  stderr.writeln('FAIL: ${violations.length} violation(s)');
  for (final violation in violations) {
    stderr.writeln('  - $violation');
  }
  exitCode = 1;
}
