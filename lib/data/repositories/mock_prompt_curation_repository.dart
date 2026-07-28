import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/audit_actor.dart';
import '../../domain/entities/session_qa.dart';
import '../../domain/repositories/prompt_curation_repository.dart';

class MockPromptCurationRepository implements PromptCurationRepository {
  MockPromptCurationRepository({AssetBundle? bundle, SharedPreferences? prefs})
    : _bundle = bundle ?? rootBundle,
      _prefs = prefs;

  final AssetBundle _bundle;
  SharedPreferences? _prefs;
  Map<String, dynamic>? _seedCache;

  static const _seedPath = 'assets/data/flo2026_session_qa.json';
  static const _overridesKey = 'flo_qa_prompt_overrides';

  @override
  Future<Map<String, List<String>>> listAllPromptSets() async {
    final seed = await _loadSeedPrompts();
    final overrides = await _loadOverrides();
    final sessionIds = {...seed.keys, ...overrides.keys};
    final result = <String, List<String>>{};
    for (final sessionId in sessionIds) {
      result[sessionId] = await promptsForSession(sessionId);
    }
    return result;
  }

  @override
  Future<List<String>> promptsForSession(String sessionId) async {
    final overrides = await _loadOverrides();
    final override = overrides[sessionId];
    if (override != null) return List<String>.from(override.prompts);
    final seed = await _loadSeedPrompts();
    return List<String>.from(seed[sessionId] ?? const []);
  }

  @override
  Future<void> saveSessionPrompts(
    String sessionId,
    List<String> prompts, {
    required AuditActor actor,
  }) async {
    final cleaned = prompts
        .map((prompt) => prompt.trim())
        .where((prompt) => prompt.isNotEmpty)
        .toList();
    final overrides = await _loadOverrides();
    overrides[sessionId] = SessionQaPromptOverride(
      prompts: cleaned,
      updatedBy: actor,
      updatedAt: DateTime.now(),
    );
    await _persistOverrides(overrides);
  }

  @override
  Future<void> resetSessionPrompts(
    String sessionId, {
    required AuditActor actor,
  }) async {
    final overrides = await _loadOverrides();
    overrides.remove(sessionId);
    await _persistOverrides(overrides);
  }

  Future<Map<String, List<String>>> _loadSeedPrompts() async {
    final seed = await _loadSeed();
    final promptsMap = seed['prompts'] as Map<String, dynamic>? ?? {};
    return promptsMap.map(
      (key, value) => MapEntry(
        key,
        (value as List<dynamic>? ?? []).whereType<String>().toList(),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadSeed() async {
    if (_seedCache != null) return _seedCache!;
    _seedCache =
        jsonDecode(await _bundle.loadString(_seedPath)) as Map<String, dynamic>;
    return _seedCache!;
  }

  Future<Map<String, SessionQaPromptOverride>> _loadOverrides() async {
    final prefs = await _ensurePrefs();
    final raw = prefs.getString(_overridesKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    final result = <String, SessionQaPromptOverride>{};
    decoded.forEach((key, value) {
      result[key as String] = SessionQaPromptOverride.fromJson(value);
    });
    return result;
  }

  Future<void> _persistOverrides(
    Map<String, SessionQaPromptOverride> overrides,
  ) async {
    final prefs = await _ensurePrefs();
    final encoded = overrides.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await prefs.setString(_overridesKey, jsonEncode(encoded));
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }
}

/// Shared prefs key for prompt overrides (also read by [MockSessionQaRepository]).
const kSessionQaPromptOverridesKey = 'flo_qa_prompt_overrides';
