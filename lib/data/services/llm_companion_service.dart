import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../core/network/api_client.dart';
import '../local/local_user_store.dart';
import '../models/models.dart';
import 'companion_context_builder.dart';
import 'rule_based_companion_service.dart';

class LlmCompanionService {
  LlmCompanionService({
    ApiClient? apiClient,
    http.Client? client,
    RuleBasedCompanionService? fallback,
    CompanionContextBuilder? contextBuilder,
    LocalUserStore? store,
  }) : _apiClient = apiClient,
       _client = client ?? http.Client(),
       _fallback = fallback ?? RuleBasedCompanionService(),
       _contextBuilder = contextBuilder ?? CompanionContextBuilder(),
       _store = store ?? LocalUserStore();

  final ApiClient? _apiClient;
  final http.Client _client;
  final RuleBasedCompanionService _fallback;
  final CompanionContextBuilder _contextBuilder;
  final LocalUserStore _store;

  static const _maxQueries = 20;
  int _queryCount = 0;
  bool _queryCountLoaded = false;

  Future<CompanionMessage> answer({
    required CompanionContext context,
    required CompanionKnowledgePack pack,
  }) async {
    await _ensureQueryCountLoaded();
    if (!AppConfig.companionApiEnabled) {
      return _fallback.answer(context: context, pack: pack);
    }

    if (_queryCount >= _maxQueries) {
      return const CompanionMessage(
        text: 'Query limit reached for this session. Using local search.',
        usedLlm: false,
      );
    }

    if (_looksLikeInjection(context.query)) {
      return const CompanionMessage(
        text: 'I can only help with Flo 2026 sessions.',
        usedLlm: false,
      );
    }

    try {
      final contextText = _contextBuilder.build(pack, context);
      final uri = Uri.parse(AppConfig.companionApiUrl);
      final body = jsonEncode({
        'system': _systemPrompt(contextText),
        'query': context.query.substring(0, context.query.length.clamp(0, 500)),
      });

      final response = _apiClient != null
          ? await _apiClient.post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
          : await _client
                .post(
                  uri,
                  headers: {'Content-Type': 'application/json'},
                  body: body,
                )
                .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final validated = _validateLlmResponse(decoded, pack, context);
        if (validated != null) {
          await _incrementQueryCount();
          return validated;
        }
      }
    } catch (_) {
      // fall through to rule-based
    }

    return _fallback.answer(context: context, pack: pack);
  }

  Future<void> _ensureQueryCountLoaded() async {
    if (_queryCountLoaded) return;
    _queryCountLoaded = true;
    _queryCount = await _store.getCompanionQueryCount();
  }

  Future<void> _incrementQueryCount() async {
    _queryCount++;
    await _store.setCompanionQueryCount(_queryCount);
  }

  CompanionMessage? _validateLlmResponse(
    Map<String, dynamic> decoded,
    CompanionKnowledgePack pack,
    CompanionContext context,
  ) {
    final text = (decoded['answer'] as String?) ?? '';
    if (text.isEmpty || _containsPii(text)) return null;

    final citedSessions = (decoded['citedSessionIds'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .where(pack.sessionIds.contains)
        .toList();
    final citedVenues = (decoded['citedVenueIds'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .where(pack.venueIds.contains)
        .toList();
    final citedAmenities = (decoded['citedAmenityIds'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .where(pack.amenityIds.contains)
        .toList();

    if (citedSessions.isEmpty &&
        citedVenues.isEmpty &&
        citedAmenities.isEmpty) {
      return null;
    }

    final sources = <CompanionSource>[
      for (final id in citedSessions)
        CompanionSource(
          kind: 'session',
          id: id,
          label: context.sessions.firstWhere((s) => s.id == id).title,
        ),
      for (final id in citedVenues)
        CompanionSource(
          kind: 'venue',
          id: id,
          label: context.venues.firstWhere((v) => v.id == id).name,
        ),
      for (final id in citedAmenities)
        CompanionSource(
          kind: 'amenity',
          id: id,
          label: context.amenities.firstWhere((a) => a.id == id).label,
        ),
    ];

    final clipped = text.length > 800 ? '${text.substring(0, 797)}...' : text;
    return CompanionMessage(
      text: clipped,
      sessionIds: citedSessions,
      venueIds: citedVenues,
      amenityIds: citedAmenities,
      referencedSessionId: citedSessions.isEmpty ? null : citedSessions.first,
      referencedVenueId: citedVenues.isEmpty ? null : citedVenues.first,
      referencedAmenityId: citedAmenities.isEmpty ? null : citedAmenities.first,
      usedLlm: true,
      sources: sources,
    );
  }

  String _systemPrompt(String context) =>
      '''
You are Flo Compass Assistant. You answer questions ONLY about the Flo 2026 event at Nagarro Gurgaon Office.
Context:
$context
Rules:
- If the question is unrelated to Flo 2026, respond: "I can only help with Flo 2026 sessions."
- Never invent sessions, venues, or amenities not in the context.
- Respond as JSON: {"answer": "...", "citedSessionIds": [], "citedVenueIds": [], "citedAmenityIds": []}
- Only cite IDs that appear in the context blocks above.
- Keep answers under 150 words.
''';

  bool _looksLikeInjection(String q) {
    final lower = q.toLowerCase();
    return lower.contains('ignore prior') ||
        lower.contains('system prompt') ||
        lower.contains('disregard');
  }

  bool _containsPii(String text) {
    return RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+').hasMatch(text) ||
        RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b').hasMatch(text) ||
        RegExp(r'\b\d{12,19}\b').hasMatch(text);
  }
}
