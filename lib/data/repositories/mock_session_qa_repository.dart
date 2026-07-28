import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/runtime_config.dart';
import '../../core/di/service_locator.dart';
import '../../domain/entities/audit_actor.dart';
import '../../domain/entities/session_qa.dart';
import '../../domain/entities/session_qa_moderation_stats.dart';
import '../../domain/repositories/session_qa_repository.dart';
import '../local/local_user_store.dart';
import '../models/models.dart';
import 'mock_prompt_curation_repository.dart';

class MockSessionQaRepository implements SessionQaRepository {
  MockSessionQaRepository({
    AssetBundle? bundle,
    SharedPreferences? prefs,
    LocalUserStore? userStore,
  }) : _bundle = bundle ?? rootBundle,
       _prefs = prefs,
       _userStore = userStore;

  final AssetBundle _bundle;
  SharedPreferences? _prefs;
  LocalUserStore? _userStore;
  Map<String, dynamic>? _seedCache;

  static const _seedPath = 'assets/data/flo2026_session_qa.json';
  static const _customQuestionsKey = 'flo_qa_custom_questions';
  static const _customRepliesKey = 'flo_qa_custom_replies';
  static const _voteDeltasKey = 'flo_qa_vote_deltas';
  static const _moderationOverridesKey = 'flo_qa_moderation_overrides';
  static const _deviceIdKey = 'flo_qa_device_id';
  static const _votesPrefix = 'flo_qa_votes_';

  @override
  Future<SessionQaModerationStats> loadModerationStats() async {
    final seed = await _loadSeed();
    final seedQuestions = (seed['questions'] as List<dynamic>? ?? [])
        .map((e) => SessionQuestion.fromJson(e as Map<String, dynamic>))
        .toList();
    final customQuestions = await _loadAllCustomQuestions();
    final moderationOverrides = await _loadModerationOverrides();
    final replyOverrides = await _loadReplyOverrides();

    final merged = <SessionQuestion>[
      for (final question in seedQuestions)
        _applyModerationOverride(
          _withReplyOverrides(question, replyOverrides[question.id]),
          moderationOverrides[question.id],
        ),
      for (final question in customQuestions)
        _applyModerationOverride(question, moderationOverrides[question.id]),
    ];

    var pendingCount = 0;
    var hiddenCount = 0;
    final pendingBySession = <String, int>{};
    for (final question in merged) {
      if (question.hidden) {
        hiddenCount++;
        continue;
      }
      if (!question.answered) {
        pendingCount++;
        pendingBySession.update(
          question.sessionId,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    return SessionQaModerationStats(
      pendingCount: pendingCount,
      hiddenCount: hiddenCount,
      totalCount: merged.length,
      pendingBySession: pendingBySession,
    );
  }

  @override
  Future<SessionQaBundle> loadQuestions(String sessionId) async {
    final seed = await _loadSeed();
    final prompts = await _promptsForSession(sessionId, seed);
    final seedQuestions = (seed['questions'] as List<dynamic>? ?? [])
        .map((e) => SessionQuestion.fromJson(e as Map<String, dynamic>))
        .where((q) => q.sessionId == sessionId)
        .toList();
    final customQuestions = await _loadCustomQuestions(sessionId);
    final voteDeltas = await _loadVoteDeltas();
    final votes = await _loadVoterVotes();
    final replyOverrides = await _loadReplyOverrides();
    final moderationOverrides = await _loadModerationOverrides();

    final merged =
        [
          ...seedQuestions.map((q) {
            final replies = <SessionReply>[
              ...q.replies,
              ...?replyOverrides[q.id],
            ];
            final answered = q.answered || replies.isNotEmpty;
            return _applyModerationOverride(
              q.copyWith(replies: replies, answered: answered),
              moderationOverrides[q.id],
            );
          }),
          ...customQuestions.map(
            (q) => _applyModerationOverride(q, moderationOverrides[q.id]),
          ),
        ].map((q) {
          final delta = voteDeltas[q.id] ?? 0;
          final upvotes = max(0, q.upvotes + delta);
          return q.copyWith(
            upvotes: upvotes,
            viewerHasUpvoted: votes.contains(q.id),
          );
        }).toList();

    return SessionQaBundle(prompts: prompts, questions: merged);
  }

  @override
  Future<SessionQuestion> addQuestion(
    String sessionId,
    String question, {
    required AuditActor actor,
    String? authorName,
  }) async {
    final now = DateTime.now();
    final entry = SessionQuestion(
      id: 'qa-${now.millisecondsSinceEpoch}',
      sessionId: sessionId,
      authorName: authorName ?? actor.displayName,
      authorId: actor.id,
      question: question,
      createdAt: now,
      upvotes: 0,
      replies: const [],
      answered: false,
    );
    final prefs = await _ensurePrefs();
    final existing = _decodeList(prefs.getString(_customQuestionsKey));
    existing.add(entry.toJson());
    await prefs.setString(_customQuestionsKey, jsonEncode(existing));
    return entry;
  }

  @override
  Future<SessionReply> addReply(
    String questionId,
    String message, {
    required AuditActor actor,
    String? authorName,
  }) async {
    final reply = SessionReply(
      id: 'reply-${DateTime.now().millisecondsSinceEpoch}',
      questionId: questionId,
      authorName: authorName ?? actor.displayName,
      authorId: actor.id,
      message: message,
      createdAt: DateTime.now(),
    );
    final prefs = await _ensurePrefs();
    final customQuestions = _decodeList(prefs.getString(_customQuestionsKey));
    final index = customQuestions.indexWhere((q) => q['id'] == questionId);
    if (index != -1) {
      final question = Map<String, dynamic>.from(customQuestions[index]);
      final replies = (question['replies'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      replies.add(reply.toJson());
      question['replies'] = replies;
      question['answered'] = true;
      customQuestions[index] = question;
      await prefs.setString(_customQuestionsKey, jsonEncode(customQuestions));
      return reply;
    }

    final overrides = Map<String, dynamic>.from(
      _decodeMap(prefs.getString(_customRepliesKey)),
    );
    final replies = (overrides[questionId] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    replies.add(reply.toJson());
    overrides[questionId] = replies;
    await prefs.setString(_customRepliesKey, jsonEncode(overrides));
    return reply;
  }

  @override
  Future<bool> toggleVote(
    String questionId, {
    required AuditActor actor,
  }) async {
    final prefs = await _ensurePrefs();
    final votes = await _loadVoterVotes();
    final voteKey = await _votesKey();
    final voteDeltas = Map<String, dynamic>.from(
      _decodeMap(prefs.getString(_voteDeltasKey)),
    );
    final existing = (voteDeltas[questionId] as num?)?.toInt() ?? 0;

    bool nowUpvoted;
    if (votes.contains(questionId)) {
      votes.remove(questionId);
      voteDeltas[questionId] = existing - 1;
      nowUpvoted = false;
    } else {
      votes.add(questionId);
      voteDeltas[questionId] = existing + 1;
      nowUpvoted = true;
    }

    await prefs.setStringList(voteKey, votes.toList());
    await prefs.setString(_voteDeltasKey, jsonEncode(voteDeltas));
    return nowUpvoted;
  }

  @override
  Future<void> setQuestionAnswered(
    String questionId,
    bool answered, {
    required AuditActor actor,
  }) async {
    await _setQuestionFlag(
      questionId,
      'answered',
      answered,
      actor: actor,
      moderationAction: answered ? 'qa.mark_answered' : 'qa.mark_unanswered',
    );
  }

  @override
  Future<void> setQuestionPinned(
    String questionId,
    bool pinned, {
    required AuditActor actor,
  }) async {
    await _setQuestionFlag(
      questionId,
      'pinned',
      pinned,
      actor: actor,
      moderationAction: pinned ? 'qa.pin' : 'qa.unpin',
    );
  }

  @override
  Future<void> setQuestionHidden(
    String questionId,
    bool hidden, {
    required AuditActor actor,
  }) async {
    await _setQuestionFlag(
      questionId,
      'hidden',
      hidden,
      actor: actor,
      moderationAction: hidden ? 'qa.hide' : 'qa.unhide',
    );
  }

  Future<Map<String, dynamic>> _loadSeed() async {
    if (_seedCache != null) return _seedCache!;
    _seedCache =
        jsonDecode(await _bundle.loadString(_seedPath)) as Map<String, dynamic>;
    return _seedCache!;
  }

  Future<List<SessionQuestion>> _loadCustomQuestions(String sessionId) async {
    final prefs = await _ensurePrefs();
    return _decodeList(prefs.getString(_customQuestionsKey))
        .map((e) => SessionQuestion.fromJson(e))
        .where((q) => q.sessionId == sessionId)
        .toList();
  }

  Future<List<SessionQuestion>> _loadAllCustomQuestions() async {
    final prefs = await _ensurePrefs();
    return _decodeList(
      prefs.getString(_customQuestionsKey),
    ).map((e) => SessionQuestion.fromJson(e)).toList();
  }

  Future<List<String>> _promptsForSession(
    String sessionId,
    Map<String, dynamic> seed,
  ) async {
    final prefs = await _ensurePrefs();
    final raw = prefs.getString(kSessionQaPromptOverridesKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final override = decoded[sessionId];
        if (override != null) {
          return _promptsFromOverride(override);
        }
      }
    }
    final promptsMap = seed['prompts'] as Map<String, dynamic>? ?? {};
    return (promptsMap[sessionId] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();
  }

  List<String> _promptsFromOverride(dynamic override) {
    if (override is List) {
      return override.whereType<String>().toList();
    }
    if (override is Map) {
      return SessionQaPromptOverride.fromJson(
        Map<String, dynamic>.from(override),
      ).prompts;
    }
    return const [];
  }

  SessionQuestion _withReplyOverrides(
    SessionQuestion question,
    List<SessionReply>? replies,
  ) {
    if (replies == null || replies.isEmpty) return question;
    final mergedReplies = [...question.replies, ...replies];
    return question.copyWith(
      replies: mergedReplies,
      answered: question.answered || mergedReplies.isNotEmpty,
    );
  }

  Future<Map<String, List<SessionReply>>> _loadReplyOverrides() async {
    final prefs = await _ensurePrefs();
    final raw = _decodeMap(prefs.getString(_customRepliesKey));
    final result = <String, List<SessionReply>>{};
    raw.forEach((key, value) {
      final replies = (value as List<dynamic>? ?? [])
          .map(
            (e) => SessionReply.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      result[key] = replies;
    });
    return result;
  }

  Future<Map<String, int>> _loadVoteDeltas() async {
    final prefs = await _ensurePrefs();
    final raw = _decodeMap(prefs.getString(_voteDeltasKey));
    return raw.map((key, value) {
      final intValue = (value as num?)?.toInt() ?? 0;
      return MapEntry(key, intValue);
    });
  }

  Future<Map<String, Map<String, dynamic>>> _loadModerationOverrides() async {
    final prefs = await _ensurePrefs();
    final raw = _decodeMap(prefs.getString(_moderationOverridesKey));
    final result = <String, Map<String, dynamic>>{};
    raw.forEach((key, value) {
      if (value is Map) {
        result[key] = Map<String, dynamic>.from(value);
      }
    });
    return result;
  }

  Future<void> _setQuestionFlag(
    String questionId,
    String field,
    bool value, {
    required AuditActor actor,
    required String moderationAction,
  }) async {
    final prefs = await _ensurePrefs();
    final now = DateTime.now();
    final moderationMeta = {
      'moderatedBy': actor.toJson(),
      'moderatedAt': now.toIso8601String(),
      'moderationAction': moderationAction,
    };

    final customQuestions = _decodeList(prefs.getString(_customQuestionsKey));
    final customIndex = customQuestions.indexWhere(
      (q) => q['id'] == questionId,
    );
    if (customIndex >= 0) {
      final updated = Map<String, dynamic>.from(customQuestions[customIndex]);
      updated[field] = value;
      updated.addAll(moderationMeta);
      customQuestions[customIndex] = updated;
      await prefs.setString(_customQuestionsKey, jsonEncode(customQuestions));
      return;
    }

    final overrides = _decodeMap(prefs.getString(_moderationOverridesKey));
    final existing = Map<String, dynamic>.from(
      overrides[questionId] as Map? ?? const {},
    );
    existing[field] = value;
    existing.addAll(moderationMeta);
    overrides[questionId] = existing;
    await prefs.setString(_moderationOverridesKey, jsonEncode(overrides));
  }

  SessionQuestion _applyModerationOverride(
    SessionQuestion question,
    Map<String, dynamic>? override,
  ) {
    if (override == null) return question;
    final answered = override['answered'];
    final pinned = override['pinned'];
    final hidden = override['hidden'];
    final moderatedByRaw = override['moderatedBy'];
    final moderatedAtRaw = override['moderatedAt'];
    return question.copyWith(
      answered: answered is bool ? answered : question.answered,
      pinned: pinned is bool ? pinned : question.pinned,
      hidden: hidden is bool ? hidden : question.hidden,
      moderatedBy: moderatedByRaw is Map
          ? AuditActor.fromJson(Map<String, dynamic>.from(moderatedByRaw))
          : question.moderatedBy,
      moderatedAt: moderatedAtRaw is String
          ? DateTime.tryParse(moderatedAtRaw)
          : question.moderatedAt,
      moderationAction:
          override['moderationAction'] as String? ?? question.moderationAction,
    );
  }

  Future<Set<String>> _loadVoterVotes() async {
    final prefs = await _ensurePrefs();
    final key = await _votesKey();
    return (prefs.getStringList(key) ?? []).toSet();
  }

  Future<String> _votesKey() async => '$_votesPrefix${await _voterKey()}';

  Future<String> _voterKey() async {
    final authSubject = await _authenticatedSubject();
    if (authSubject != null) return 'user-$authSubject';
    final prefs = await _ensurePrefs();
    var deviceId = prefs.getString(_deviceIdKey);
    if (deviceId == null) {
      deviceId =
          'device-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
      await prefs.setString(_deviceIdKey, deviceId);
    }
    return deviceId;
  }

  Future<String?> _authenticatedSubject() async {
    if (!RuntimeConfig.authEnabled) return null;
    final store = _ensureUserStore();
    final auth = await store.readAuthMetadata();
    if (auth == null) return null;
    if (auth.expiresAt.isBefore(DateTime.now())) return null;
    return auth.subject;
  }

  LocalUserStore _ensureUserStore() {
    if (_userStore != null) return _userStore!;
    if (sl.isRegistered<LocalUserStore>()) {
      _userStore = sl<LocalUserStore>();
    } else {
      _userStore = LocalUserStore();
    }
    return _userStore!;
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Map<String, dynamic> _decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    return Map<String, dynamic>.from(decoded);
  }
}
