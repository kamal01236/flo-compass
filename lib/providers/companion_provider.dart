import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../data/models/models.dart';
import '../data/models/user_profile.dart';
import '../data/services/companion_service.dart';
import 'event_provider.dart';
import 'plan_provider.dart';

class ChatTurn {
  const ChatTurn({
    required this.turnIndex,
    required this.query,
    required this.response,
  });

  final int turnIndex;
  final String query;
  final CompanionMessage response;
}

class CompanionState extends ChangeNotifier {
  CompanionState({CompanionService? service})
    : _service = service ?? CompanionService();

  final CompanionService _service;
  final List<ChatTurn> _history = [];
  bool busy = false;
  bool lastUsedLlm = false;
  bool showFallbackBanner = false;
  String? lastReferencedSessionId;
  String? lastReferencedTrack;

  List<ChatTurn> get history => List.unmodifiable(_history);

  Future<void> ask({
    required String query,
    required EventState event,
    required PlanState plan,
    required UserProfile profile,
    String? initialSessionId,
  }) async {
    if (query.trim().isEmpty) return;
    busy = true;
    notifyListeners();
    try {
      final priorQueries = _history.length <= 4
          ? _history.map((turn) => turn.query).toList()
          : _history
                .sublist(_history.length - 4)
                .map((turn) => turn.query)
                .toList();
      final context = CompanionContext(
        query: query,
        sessions: event.sessions,
        speakers: event.speakers,
        venues: event.venues,
        tracks: event.tracks,
        amenities: event.amenities,
        navigationHints: event.navigationHints,
        meta: event.meta,
        campus: event.campus,
        profile: profile,
        plannedSessions: plan.plannedSessions(event.sessions),
        now: event.currentTime,
        currentDay: event.currentDay,
        priorQueries: priorQueries,
        lastReferencedSessionId: initialSessionId ?? lastReferencedSessionId,
        minutesUntil: event.minutesUntil,
        conflicts: plan.conflicts(event.sessions),
      );

      final response = await _service.answer(context: context);

      lastUsedLlm = response.usedLlm;
      showFallbackBanner = AppConfig.companionApiEnabled && !response.usedLlm;
      _history.add(
        ChatTurn(
          turnIndex: _history.length + 1,
          query: query,
          response: response,
        ),
      );
      lastReferencedSessionId =
          response.referencedSessionId ?? lastReferencedSessionId;
      lastReferencedTrack = response.referencedTrack ?? lastReferencedTrack;
    } catch (_) {
      lastUsedLlm = false;
      showFallbackBanner = false;
      _history.add(
        ChatTurn(
          turnIndex: _history.length + 1,
          query: query,
          response: const CompanionMessage(
            text: 'Something went wrong. Please try again.',
          ),
        ),
      );
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void clear() {
    _history.clear();
    showFallbackBanner = false;
    lastReferencedSessionId = null;
    lastReferencedTrack = null;
    notifyListeners();
  }

  void dismissFallbackBanner() {
    showFallbackBanner = false;
    notifyListeners();
  }
}
