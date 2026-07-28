import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/app_capability.dart';
import '../core/auth/auth_service.dart';
import '../core/config/runtime_config.dart';
import '../core/di/service_locator.dart';
import '../data/models/engagement_snapshot.dart';
import '../data/models/models.dart';
import '../data/models/user_profile.dart';
import '../data/services/bingo_service.dart';
import '../data/services/daily_quest_service.dart';
import '../providers/event_provider.dart';
import '../providers/plan_provider.dart';
import '../providers/profile_provider.dart';

export '../data/models/engagement_snapshot.dart';

class EngagementState extends ChangeNotifier {
  EngagementState({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _key = 'flo_compass_engagement';
  EngagementSnapshot snapshot = EngagementSnapshot.empty;

  final BingoService _bingoService = BingoService();
  final DailyQuestService _questService = DailyQuestService();

  int get xp => snapshot.xp;
  List<String> get achievements => snapshot.achievements;
  List<String> get attendedSessionIds => snapshot.attendedSessionIds;
  Map<String, int> get ratings => snapshot.ratings;
  Map<String, String> get reactions => snapshot.reactions;
  Map<String, String> get pulseBySessionId => snapshot.pulseBySessionId;
  Map<String, String> get notesBySessionId => snapshot.notesBySessionId;
  List<int> get bingoMarks => snapshot.bingoMarks;

  String get levelLabel {
    final level = switch (xp) {
      >= 1000 => 5,
      >= 500 => 4,
      >= 250 => 3,
      >= 100 => 2,
      _ => 1,
    };
    return 'Explorer · Lvl $level';
  }

  int get nextMilestone {
    if (xp < 100) return 100;
    if (xp < 250) return 250;
    if (xp < 500) return 500;
    if (xp < 1000) return 1000;
    return xp;
  }

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw != null) {
      try {
        snapshot = EngagementSnapshot.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to decode engagement snapshot: $e');
        }
      }
    }
    notifyListeners();
  }

  Future<void> syncQuestDay(String? currentDay) async {
    await _prefsReady();
    final beforeDay = snapshot.lastQuestDay;
    final next = _questService.resetIfNewDay(snapshot, currentDay);
    if (next.lastQuestDay != beforeDay) await _save(next);
  }

  List<DailyQuestProgress> dailyQuests(String? currentDay) =>
      _questService.progressFor(snapshot: snapshot, currentDay: currentDay);

  bool isBingoMarked(int index) => snapshot.bingoMarks.contains(index);

  Future<int> markBingoCell(int index, {bool fromAuto = false}) async {
    if (!_canEarnXp()) return 0;
    if (index < 0 || index >= BingoService.gridSize) return 0;
    if (snapshot.bingoMarks.contains(index)) return 0;
    await _prefsReady();

    var totalXp = 20;
    final marks = [...snapshot.bingoMarks, index]..sort();
    var rowBonuses = [...snapshot.bingoRowBonuses];

    final rowIndex = index ~/ 5;
    if (_bingoService.isRowComplete(rowIndex, marks) &&
        !rowBonuses.contains(rowIndex)) {
      rowBonuses.add(rowIndex);
      totalXp += 50;
    }

    final next = snapshot.copyWith(
      bingoMarks: marks,
      bingoRowBonuses: rowBonuses,
      xp: snapshot.xp + totalXp,
    );
    await _save(next);
    return totalXp;
  }

  Future<void> recordFloorVisit(String floor) async {
    if (snapshot.visitedFloors.contains(floor)) return;
    await _prefsReady();
    final next = snapshot.copyWith(
      visitedFloors: [...snapshot.visitedFloors, floor],
    );
    await _save(next);
  }

  Future<int> addXp(int delta) async {
    if (!_canEarnXp()) return 0;
    await _prefsReady();
    final next = snapshot.copyWith(xp: snapshot.xp + delta);
    await _save(next);
    return delta;
  }

  Future<String?> _applyQuestSnapshot(EngagementSnapshot next) async {
    final before = snapshot;
    var updated = next;
    final questId = _questService.newlyCompletedQuestId(
      before: before,
      after: updated,
      currentDay: next.lastQuestDay,
    );
    if (questId != null && !before.completedQuestIds.contains(questId)) {
      updated = updated.copyWith(
        completedQuestIds: [...updated.completedQuestIds, questId],
        xp: updated.xp + 30,
      );
    }
    await _save(updated);
    return questId;
  }

  Future<int> onBookmarkAdded({
    required bool isFirstBookmark,
    Session? session,
    EventState? event,
    PlanState? plan,
    ProfileState? profile,
  }) async {
    await _prefsReady();
    var next = snapshot.copyWith(xp: snapshot.xp + (isFirstBookmark ? 25 : 10));
    if (session != null && event != null) {
      next = _questService.resetIfNewDay(next, event.currentDay);
      next = _questService.bumpBookmark(
        snapshot: next,
        session: session,
        clock: event.clockService,
      );
      if (next.lastQuestDay == null && event.currentDay != null) {
        next = next.copyWith(lastQuestDay: event.currentDay);
      }
    }
    await _applyQuestSnapshot(next);
    if (plan != null && event != null && profile != null) {
      await refreshBingoAutoMarks(
        plan: plan,
        event: event,
        profile: profile.profile,
      );
    }
    return isFirstBookmark ? 25 : 10;
  }

  Future<int> onOnboardingCompleted() => addXp(50);

  Future<int> onSessionOpened({
    Session? session,
    EventState? event,
    PlanState? plan,
    ProfileState? profile,
  }) async {
    await _prefsReady();
    var next = snapshot.copyWith(detailViews: snapshot.detailViews + 1);
    if (session != null && event != null) {
      next = _questService.resetIfNewDay(next, event.currentDay);
      next = _questService.bumpTrackView(
        snapshot: next,
        trackId: session.trackId,
      );
      if (next.lastQuestDay == null && event.currentDay != null) {
        next = next.copyWith(lastQuestDay: event.currentDay);
      }
    }
    next = next.copyWith(xp: next.xp + 5);
    await _applyQuestSnapshot(next);
    if (plan != null && event != null && profile != null) {
      await refreshBingoAutoMarks(
        plan: plan,
        event: event,
        profile: profile.profile,
      );
    }
    return 5;
  }

  Future<int> onCompanionQuestion({
    EventState? event,
    PlanState? plan,
    ProfileState? profile,
  }) async {
    await _prefsReady();
    var next = snapshot.copyWith(
      companionQuestions: snapshot.companionQuestions + 1,
    );
    if (event != null) {
      next = _questService.resetIfNewDay(next, event.currentDay);
      next = _questService.bumpCompanion(next);
      if (next.lastQuestDay == null && event.currentDay != null) {
        next = next.copyWith(lastQuestDay: event.currentDay);
      }
    }
    next = next.copyWith(xp: next.xp + 15);
    await _applyQuestSnapshot(next);
    if (plan != null && event != null && profile != null) {
      await refreshBingoAutoMarks(
        plan: plan,
        event: event,
        profile: profile.profile,
      );
    }
    return 15;
  }

  Future<int> onSessionQuestionAsked() async {
    return addXp(15);
  }

  Future<int> onSessionQuestionUpvoted() async {
    return addXp(5);
  }

  Future<int> markAttended(
    String sessionId,
    String day, {
    EventState? event,
    PlanState? plan,
    ProfileState? profile,
  }) async {
    await _prefsReady();
    final attended = [...snapshot.attendedSessionIds];
    if (!attended.contains(sessionId)) attended.add(sessionId);
    final streakDays = [...snapshot.streakDays];
    if (!streakDays.contains(day)) streakDays.add(day);
    final next = snapshot.copyWith(
      attendedSessionIds: attended.take(100).toList(),
      streakDays: streakDays,
      xp: snapshot.xp + 30,
    );
    await _save(next);
    if (plan != null && event != null && profile != null) {
      await refreshBingoAutoMarks(
        plan: plan,
        event: event,
        profile: profile.profile,
      );
    }
    return 30;
  }

  Future<int> rateSession(
    String sessionId,
    int stars, {
    EventState? event,
    PlanState? plan,
    ProfileState? profile,
  }) async {
    await _prefsReady();
    final updated = {...snapshot.ratings, sessionId: stars};
    final next = snapshot.copyWith(ratings: updated, xp: snapshot.xp + 10);
    await _save(next);
    if (stars >= 4 && event != null) {
      final session = event.sessionById(sessionId);
      if (session != null) {
        await event.recordPositiveFeedback(
          tags: session.tags,
          trackId: session.trackId,
        );
      }
    }
    if (plan != null && event != null && profile != null) {
      await refreshBingoAutoMarks(
        plan: plan,
        event: event,
        profile: profile.profile,
      );
    }
    return 10;
  }

  Future<int> setReaction(String sessionId, String emojiKey) async {
    await _prefsReady();
    final hadReaction = snapshot.reactions.containsKey(sessionId);
    final next = snapshot.copyWith(
      reactions: {...snapshot.reactions, sessionId: emojiKey},
      xp: snapshot.xp + (hadReaction ? 0 : 5),
    );
    await _save(next);
    return hadReaction ? 0 : 5;
  }

  Future<int> setPulse(
    String sessionId,
    String pulse, {
    EventState? event,
  }) async {
    await _prefsReady();
    final hadPulse = snapshot.pulseBySessionId.containsKey(sessionId);
    final next = snapshot.copyWith(
      pulseBySessionId: {...snapshot.pulseBySessionId, sessionId: pulse},
      xp: snapshot.xp + (hadPulse ? 0 : 5),
    );
    await _save(next);
    if (pulse == 'worth_it' && event != null) {
      final session = event.sessionById(sessionId);
      if (session != null) {
        await event.recordPositiveFeedback(
          tags: session.tags,
          trackId: session.trackId,
        );
      }
    }
    return hadPulse ? 0 : 5;
  }

  Future<void> setSessionNote(String sessionId, String note) async {
    await _prefsReady();
    final trimmed = note.length > 500 ? note.substring(0, 500) : note;
    var notes = {...snapshot.notesBySessionId, sessionId: trimmed};
    if (notes.length > 50) {
      final keys = notes.keys.toList()..sort();
      notes = {for (final k in keys.skip(keys.length - 50)) k: notes[k]!};
    }
    final next = snapshot.copyWith(notesBySessionId: notes);
    await _save(next);
  }

  /// Deterministic mock distribution for demo reaction wall.
  Map<String, int> aggregateReactionsForSession(String sessionId) {
    final hash = sessionId.codeUnits.fold<int>(0, (a, b) => a + b);
    return {
      'fire': 8 + hash % 12,
      'lightbulb': 5 + (hash ~/ 3) % 10,
      'clap': 10 + (hash ~/ 7) % 15,
      'thinking': 3 + (hash ~/ 11) % 8,
      'heart': 6 + (hash ~/ 13) % 9,
    };
  }

  String? pulseForSession(String sessionId) =>
      snapshot.pulseBySessionId[sessionId];

  String? noteForSession(String sessionId) =>
      snapshot.notesBySessionId[sessionId];

  Future<List<int>> refreshBingoAutoMarks({
    required PlanState plan,
    required EventState event,
    required UserProfile profile,
  }) async {
    final planned = plan.plannedSessions(event.sessions);
    final newMarks = _bingoService.evaluateAutoMarks(
      engagement: snapshot,
      plannedSessions: planned,
      allSessions: event.sessions,
      profile: profile,
    );
    final awarded = <int>[];
    for (final index in newMarks) {
      final xp = await markBingoCell(index, fromAuto: true);
      if (xp > 0) awarded.add(index);
    }
    return awarded;
  }

  Future<void> unlockAchievement(String id) async {
    if (snapshot.achievements.contains(id)) return;
    await _prefsReady();
    final next = snapshot.copyWith(
      achievements: [...snapshot.achievements, id],
    );
    await _save(next);
  }

  Future<void> reset() async {
    await _prefsReady();
    snapshot = EngagementSnapshot.empty;
    await _prefs!.remove(_key);
    notifyListeners();
  }

  Future<void> _prefsReady() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _save(EngagementSnapshot next) async {
    await _prefsReady();
    try {
      await _prefs!.setString(_key, jsonEncode(next.toJson()));
      snapshot = next;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to save engagement snapshot: $e');
      }
    }
  }

  bool _canEarnXp() {
    if (!RuntimeConfig.authEnabled) return true;
    if (!sl.isRegistered<AuthService>()) return false;
    return sl<AuthService>().hasCapability(AppCapability.earnXp);
  }
}
