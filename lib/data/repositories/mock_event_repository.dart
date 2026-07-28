import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/logging/app_logger.dart';
import '../dtos/event_meta_dto.dart';
import '../dtos/learning_path_dto.dart';
import '../dtos/session_dto.dart';
import '../dtos/speaker_dto.dart';
import '../dtos/track_dto.dart';
import '../dtos/venue_dto.dart';
import '../mappers/event_meta_mapper.dart';
import '../mappers/learning_path_mapper.dart';
import '../mappers/session_mapper.dart';
import '../mappers/speaker_mapper.dart';
import '../mappers/track_mapper.dart';
import '../mappers/venue_mapper.dart';
import '../models/models.dart';
import 'data_integrity_exception.dart';
import '../../domain/repositories/event_repository.dart';
import '../../shared/utils/id_validator.dart';
import '../mappers/amenity_mapper.dart';
import '../mappers/campus_mapper.dart';
import '../mappers/navigation_hint_mapper.dart';

class MockEventRepository implements EventRepository {
  MockEventRepository({AssetBundle? bundle, this.strictIntegrity = true})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final bool strictIntegrity;

  List<Session>? _sessions;
  List<Speaker>? _speakers;
  List<Venue>? _venues;
  List<Track>? _tracks;
  List<LearningPath>? _learningPaths;
  EventMeta? _meta;
  List<Amenity>? _amenities;
  List<NavigationHint>? _navigationHints;
  CampusLayout? _campus;

  void invalidateSessionsCache() {
    _sessions = null;
  }

  @override
  Future<EventMeta> loadMeta() async {
    _meta ??= eventMetaFromDto(
      EventMetaDto.fromJson(
        jsonDecode(await _bundle.loadString('assets/data/flo2026_meta.json'))
            as Map<String, dynamic>,
      ),
    );
    return _meta!;
  }

  @override
  Future<List<Session>> loadSessions() async {
    if (_sessions != null) return _sessions!;
    final raw =
        jsonDecode(
              await _bundle.loadString('assets/data/flo2026_sessions.json'),
            )
            as List<dynamic>;
    var sessions = raw
        .map(
          (e) => sessionFromDto(SessionDto.fromJson(e as Map<String, dynamic>)),
        )
        .toList();
    sessions = await _applySessionOverrides(sessions);
    _sessions = sessions;
    _validateIntegrity();
    return _sessions!;
  }

  Future<List<Session>> _applySessionOverrides(List<Session> base) async {
    try {
      final raw = await _bundle.loadString(
        'assets/data/flo2026_session_overrides.json',
      );
      final overrides = jsonDecode(raw) as List<dynamic>;
      if (overrides.isEmpty) return base;

      final byId = {for (final s in base) s.id: s};
      for (final entry in overrides) {
        if (entry is! Map<String, dynamic>) continue;
        final id = entry['id'] as String?;
        if (id == null) continue;
        if (entry['cancelled'] == true) {
          byId.remove(id);
          continue;
        }
        final existing = byId[id];
        if (existing == null) continue;
        byId[id] = Session(
          id: existing.id,
          title: existing.title,
          abstract: existing.abstract,
          day: entry['day'] as String? ?? existing.day,
          startTime: entry['startTime'] as String? ?? existing.startTime,
          endTime: entry['endTime'] as String? ?? existing.endTime,
          venueId: entry['venueId'] as String? ?? existing.venueId,
          trackId: existing.trackId,
          speakerIds: existing.speakerIds,
          tags: existing.tags,
          format: existing.format,
          level: existing.level,
          featured: existing.featured,
          capacity: existing.capacity,
          building: existing.building,
          attendeeInterestCount: existing.attendeeInterestCount,
          occupancyPercent: existing.occupancyPercent,
        );
      }
      return byId.values.toList();
    } catch (_) {
      return base;
    }
  }

  @override
  Future<List<Speaker>> loadSpeakers() async {
    _speakers ??=
        (jsonDecode(
                  await _bundle.loadString('assets/data/flo2026_speakers.json'),
                )
                as List<dynamic>)
            .map(
              (e) => speakerFromDto(
                SpeakerDto.fromJson(e as Map<String, dynamic>),
              ),
            )
            .toList();
    return _speakers!;
  }

  @override
  Future<List<Venue>> loadVenues() async {
    _venues ??=
        (jsonDecode(await _bundle.loadString('assets/data/flo2026_venues.json'))
                as List<dynamic>)
            .map(
              (e) => venueFromDto(VenueDto.fromJson(e as Map<String, dynamic>)),
            )
            .toList();
    return _venues!;
  }

  @override
  Future<List<Track>> loadTracks() async {
    _tracks ??=
        (jsonDecode(await _bundle.loadString('assets/data/flo2026_tracks.json'))
                as List<dynamic>)
            .map(
              (e) => trackFromDto(TrackDto.fromJson(e as Map<String, dynamic>)),
            )
            .toList();
    return _tracks!;
  }

  @override
  Future<List<LearningPath>> loadLearningPaths() async {
    if (_learningPaths != null) return _learningPaths!;
    final raw =
        jsonDecode(await _bundle.loadString('assets/data/learning_paths.json'))
            as Map<String, dynamic>;
    _learningPaths = (raw['paths'] as List<dynamic>)
        .map(
          (e) => learningPathFromDto(
            LearningPathDto.fromJson(e as Map<String, dynamic>),
          ),
        )
        .toList();
    return _learningPaths!;
  }

  @override
  Future<List<Amenity>> loadAmenities() async {
    _amenities ??=
        (jsonDecode(
                  await _bundle.loadString(
                    'assets/data/flo2026_amenities.json',
                  ),
                )
                as List<dynamic>)
            .map((e) => amenityFromJson(e as Map<String, dynamic>))
            .toList();
    return _amenities!;
  }

  @override
  Future<List<NavigationHint>> loadNavigationHints() async {
    if (_navigationHints != null) return _navigationHints!;
    final raw =
        jsonDecode(
              await _bundle.loadString(
                'assets/data/flo2026_navigation_hints.json',
              ),
            )
            as Map<String, dynamic>;
    _navigationHints = navigationHintsFromBundle(raw);
    return _navigationHints!;
  }

  @override
  Future<CampusLayout> loadCampus() async {
    _campus ??= campusFromJson(
      jsonDecode(await _bundle.loadString('assets/data/flo2026_campus.json'))
          as Map<String, dynamic>,
    );
    return _campus!;
  }

  @override
  Future<Session?> getSessionById(String id) async {
    if (IdValidator.sanitizeSessionId(id) == null) return null;
    final sessions = await loadSessions();
    for (final session in sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  void _validateIntegrity() {
    final sessions = _sessions!;
    final speakerIds = (_speakers ?? []).map((s) => s.id).toSet();
    final venueIds = (_venues ?? []).map((v) => v.id).toSet();
    final venueCapacity = {for (final v in _venues ?? []) v.id: v.capacity};
    final venueById = {for (final v in _venues ?? []) v.id: v};
    final violations = <String>[];

    for (final session in sessions) {
      if (session.startTime == '12:00' && session.venueId != 'ven-C601') {
        violations.add('non-cafeteria 12:00 session ${session.id}');
      }
      if (session.startTime != '12:00' && session.venueId == 'ven-C601') {
        violations.add('cafeteria outside 12:00 ${session.id}');
      }
      for (final sid in session.speakerIds) {
        if (speakerIds.isNotEmpty && !speakerIds.contains(sid)) {
          violations.add('${session.id} unknown speaker $sid');
        }
      }
      if (venueIds.isNotEmpty && !venueIds.contains(session.venueId)) {
        violations.add('${session.id} unknown venue');
      }
      final venue = venueById[session.venueId];
      if (venue != null && venue.floor != 'G' && venue.id.startsWith('ven-')) {
        final wingFromId = RegExp(
          r'ven-(?:\d{1,2})(N|S)\d',
        ).firstMatch(venue.id);
        final parsedWing = wingFromId?.group(1);
        if (parsedWing != null && venue.wing != parsedWing) {
          violations.add('${session.id} venue wing mismatch');
        }
      }
      final cap = venueCapacity[session.venueId];
      if (cap != null && session.capacity > cap) {
        violations.add('${session.id} capacity exceeds venue');
      }
      if (session.occupancyPercent < 0 || session.occupancyPercent > 100) {
        violations.add('${session.id} occupancyPercent out of range');
      }
    }

    for (final message in violations) {
      if (strictIntegrity) {
        throw DataIntegrityException(message);
      }
      AppLog.w('Data integrity: $message');
    }
  }
}
