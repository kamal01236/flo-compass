import 'dart:convert';

import '../../core/config/runtime_config.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/amenity.dart';
import '../../domain/entities/campus_layout.dart';
import '../../domain/entities/event_meta.dart';
import '../../domain/entities/learning_path.dart';
import '../../domain/entities/navigation_hint.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/speaker.dart';
import '../../domain/entities/track.dart';
import '../../domain/entities/venue.dart';
import '../../domain/repositories/event_repository.dart';
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

/// Remote HTTP repository; delegates to [fallback] when API is unavailable.
class RemoteEventRepository implements EventRepository {
  RemoteEventRepository({
    required ApiClient apiClient,
    required EventRepository fallback,
  }) : _api = apiClient,
       _fallback = fallback;

  final ApiClient _api;
  final EventRepository _fallback;

  bool get _useRemote => RuntimeConfig.apiBaseUrl.isNotEmpty;

  Future<T> _withFallback<T>(
    Future<T> Function() remote,
    Future<T> Function() fb,
  ) async {
    if (!_useRemote) return fb();
    try {
      return await remote();
    } catch (e) {
      // Expected when API is down — mock fallback is intentional, not a fault.
      AppLog.d('RemoteEventRepository fallback to local data: $e');
      return fb();
    }
  }

  @override
  Future<EventMeta> loadMeta() => _withFallback(() async {
    final res = await _api.get(_api.baseUri('/meta'));
    return eventMetaFromDto(
      EventMetaDto.fromJson(jsonDecode(res.body) as Map<String, dynamic>),
    );
  }, () => _fallback.loadMeta());

  @override
  Future<List<Session>> loadSessions() => _withFallback(() async {
    final res = await _api.get(_api.baseUri('/sessions'));
    final raw = jsonDecode(res.body) as List<dynamic>;
    return raw
        .map(
          (e) => sessionFromDto(SessionDto.fromJson(e as Map<String, dynamic>)),
        )
        .toList();
  }, () => _fallback.loadSessions());

  @override
  Future<List<Speaker>> loadSpeakers() => _withFallback(() async {
    final res = await _api.get(_api.baseUri('/speakers'));
    final raw = jsonDecode(res.body) as List<dynamic>;
    return raw
        .map(
          (e) => speakerFromDto(SpeakerDto.fromJson(e as Map<String, dynamic>)),
        )
        .toList();
  }, () => _fallback.loadSpeakers());

  @override
  Future<List<Venue>> loadVenues() => _withFallback(() async {
    final res = await _api.get(_api.baseUri('/venues'));
    final raw = jsonDecode(res.body) as List<dynamic>;
    return raw
        .map((e) => venueFromDto(VenueDto.fromJson(e as Map<String, dynamic>)))
        .toList();
  }, () => _fallback.loadVenues());

  @override
  Future<List<Track>> loadTracks() => _withFallback(() async {
    final res = await _api.get(_api.baseUri('/tracks'));
    final raw = jsonDecode(res.body) as List<dynamic>;
    return raw
        .map((e) => trackFromDto(TrackDto.fromJson(e as Map<String, dynamic>)))
        .toList();
  }, () => _fallback.loadTracks());

  @override
  Future<List<LearningPath>> loadLearningPaths() => _withFallback(() async {
    final res = await _api.get(_api.baseUri('/learning-paths'));
    final raw = jsonDecode(res.body) as Map<String, dynamic>;
    return (raw['paths'] as List<dynamic>)
        .map(
          (e) => learningPathFromDto(
            LearningPathDto.fromJson(e as Map<String, dynamic>),
          ),
        )
        .toList();
  }, () => _fallback.loadLearningPaths());

  @override
  Future<List<Amenity>> loadAmenities() => _fallback.loadAmenities();

  @override
  Future<List<NavigationHint>> loadNavigationHints() =>
      _fallback.loadNavigationHints();

  @override
  Future<CampusLayout> loadCampus() => _fallback.loadCampus();

  @override
  Future<Session?> getSessionById(String id) => _withFallback(() async {
    final res = await _api.get(_api.baseUri('/sessions/$id'));
    return sessionFromDto(
      SessionDto.fromJson(jsonDecode(res.body) as Map<String, dynamic>),
    );
  }, () => _fallback.getSessionById(id));
}
