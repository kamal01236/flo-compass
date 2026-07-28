import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/di/service_locator.dart';
import '../data/models/models.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/mock_event_repository.dart';
import '../data/services/recommendation_service.dart';
import '../data/services/event_clock_service.dart';
import '../data/services/behavior_signal_service.dart';
import '../data/services/session_search_index.dart';
import '../domain/repositories/event_repository.dart';

EventRepository _defaultEventRepository() {
  if (sl.isRegistered<EventRepository>()) {
    return sl<EventRepository>();
  }
  return MockEventRepository();
}

RecommendationService _defaultRecommendationService() {
  if (sl.isRegistered<RecommendationService>()) {
    return sl<RecommendationService>();
  }
  return RecommendationService();
}

EventClockService _defaultEventClockService() {
  if (sl.isRegistered<EventClockService>()) {
    return sl<EventClockService>();
  }
  return EventClockService();
}

class EventState extends ChangeNotifier {
  EventState({
    EventRepository? repository,
    RecommendationService? recommendationService,
    EventClockService? eventClockService,
  }) : _repository = repository ?? _defaultEventRepository(),
       _recommendationService =
           recommendationService ?? _defaultRecommendationService(),
       _clockService = eventClockService ?? _defaultEventClockService() {
    clockTicker = ValueNotifier<DateTime>(_clockService.now());
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      clockTicker.value = _clockService.now();
    });
  }

  final EventRepository _repository;
  final RecommendationService _recommendationService;
  final EventClockService _clockService;
  final BehaviorSignalService _behaviorSignalService = BehaviorSignalService();
  late final ValueNotifier<DateTime> clockTicker;
  late final Timer _ticker;
  BehaviorSnapshot? _behaviorSnapshot;
  final Map<String, Session> _sessionsById = {};
  final Map<String, Speaker> _speakersById = {};
  final Map<String, Venue> _venuesById = {};
  final Map<String, Track> _tracksById = {};
  final Map<String, Amenity> _amenitiesById = {};

  bool loading = true;
  String? error;
  EventMeta? meta;
  List<Session> sessions = [];
  List<Speaker> speakers = [];
  List<Venue> venues = [];
  List<Track> tracks = [];
  List<LearningPath> learningPaths = [];
  List<Amenity> amenities = [];
  List<NavigationHint> navigationHints = [];
  CampusLayout? campus;
  SessionSearchIndex searchIndex = SessionSearchIndex.empty;
  DateTime? get currentTime => clockTicker.value;
  bool get isDemoMode => _clockService.isInDemoMode;
  String? get currentDay => _clockService.currentDay();

  @override
  void dispose() {
    _ticker.cancel();
    clockTicker.dispose();
    super.dispose();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      meta = await _repository.loadMeta();
      sessions = await _repository.loadSessions();
      speakers = await _repository.loadSpeakers();
      venues = await _repository.loadVenues();
      tracks = await _repository.loadTracks();
      learningPaths = await _repository.loadLearningPaths();
      amenities = await _repository.loadAmenities();
      navigationHints = await _repository.loadNavigationHints();
      campus = await _repository.loadCampus();
      _behaviorSnapshot = await _behaviorSignalService.load();
      _rebuildLookups();
      scheduleMicrotask(() {
        searchIndex = SessionSearchIndex.build(
          sessions: sessions,
          speakers: speakers,
          tracks: tracks,
        );
        notifyListeners();
      });
    } catch (e) {
      error = 'Failed to load event data.';
      if (kDebugMode) error = '$error $e';
      meta = null;
      sessions = [];
      speakers = [];
      venues = [];
      tracks = [];
      learningPaths = [];
      amenities = [];
      navigationHints = [];
      campus = null;
      _behaviorSnapshot = null;
      searchIndex = SessionSearchIndex.empty;
      _clearLookups();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  List<ScoredSession> rankedSessions(UserProfile profile) {
    return _recommendationService.rankSessions(
      sessions: sessions,
      speakers: speakers,
      tracks: tracks,
      profile: profile,
      now: _clockService.now(),
      preferenceMode: profile.recommendationMode,
      behaviorSnapshot: _behaviorSnapshot,
    );
  }

  RecommendationService get recommendationService => _recommendationService;
  BehaviorSnapshot? get behaviorSnapshot => _behaviorSnapshot;

  Future<void> recordSessionView(Session session) async {
    await _behaviorSignalService.bumpTrack(session.trackId, session.tags);
    _behaviorSnapshot = await _behaviorSignalService.load();
    notifyListeners();
  }

  Future<void> trackBookmark(String trackId) async {
    await _behaviorSignalService.trackBookmark(trackId: trackId);
    _behaviorSnapshot = await _behaviorSignalService.load();
    notifyListeners();
  }

  Future<void> recordPositiveFeedback({
    required List<String> tags,
    required String trackId,
  }) async {
    await _behaviorSignalService.recordPositiveFeedback(
      tags: tags,
      trackId: trackId,
    );
    _behaviorSnapshot = await _behaviorSignalService.load();
    notifyListeners();
  }

  List<Session> happeningNow() {
    return sessions.where(_clockService.isHappeningNow).toList();
  }

  List<Session> startingSoon({int withinMinutes = 15}) {
    return sessions
        .where(
          (s) => _clockService.isStartingSoon(s, withinMinutes: withinMinutes),
        )
        .toList();
  }

  int minutesUntil(Session session) => _clockService.minutesUntil(session);
  int minutesRemaining(Session session) =>
      _clockService.minutesRemaining(session);
  DateTime sessionStart(Session session) => _clockService.sessionStart(session);

  EventClockService get clockService => _clockService;

  void setDemoTime(DateTime? value) {
    _clockService.setOverride(value);
    clockTicker.value = _clockService.now();
  }

  Session? sessionById(String id) {
    final cached = _sessionsById[id];
    if (cached != null) return cached;
    for (final s in sessions) {
      if (s.id == id) {
        _sessionsById[id] = s;
        return s;
      }
    }
    return null;
  }

  int _agendaRevision = 0;
  int get agendaRevision => _agendaRevision;

  Future<void> refreshAgenda() async {
    final repo = _repository;
    if (repo is MockEventRepository) {
      repo.invalidateSessionsCache();
    }
    try {
      sessions = await _repository.loadSessions();
      _agendaRevision++;
      _rebuildLookups();
      searchIndex = SessionSearchIndex.build(
        sessions: sessions,
        speakers: speakers,
        tracks: tracks,
      );
      notifyListeners();
    } catch (e) {
      error = 'Failed to refresh agenda.';
      if (kDebugMode) error = '$error $e';
      notifyListeners();
    }
  }

  Speaker? speakerById(String id) {
    final cached = _speakersById[id];
    if (cached != null) return cached;
    for (final s in speakers) {
      if (s.id == id) {
        _speakersById[id] = s;
        return s;
      }
    }
    return null;
  }

  Venue? venueById(String id) {
    final cached = _venuesById[id];
    if (cached != null) return cached;
    for (final v in venues) {
      if (v.id == id) {
        _venuesById[id] = v;
        return v;
      }
    }
    return null;
  }

  Amenity? amenityById(String id) {
    final cached = _amenitiesById[id];
    if (cached != null) return cached;
    for (final a in amenities) {
      if (a.id == id) {
        _amenitiesById[id] = a;
        return a;
      }
    }
    return null;
  }

  Track? trackById(String id) {
    final cached = _tracksById[id];
    if (cached != null) return cached;
    for (final t in tracks) {
      if (t.id == id) {
        _tracksById[id] = t;
        return t;
      }
    }
    return null;
  }

  void _rebuildLookups() {
    _sessionsById
      ..clear()
      ..addEntries(sessions.map((s) => MapEntry(s.id, s)));
    _speakersById
      ..clear()
      ..addEntries(speakers.map((s) => MapEntry(s.id, s)));
    _venuesById
      ..clear()
      ..addEntries(venues.map((v) => MapEntry(v.id, v)));
    _tracksById
      ..clear()
      ..addEntries(tracks.map((t) => MapEntry(t.id, t)));
    _amenitiesById
      ..clear()
      ..addEntries(amenities.map((a) => MapEntry(a.id, a)));
  }

  void _clearLookups() {
    _sessionsById.clear();
    _speakersById.clear();
    _venuesById.clear();
    _tracksById.clear();
    _amenitiesById.clear();
  }
}
