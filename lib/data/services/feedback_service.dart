import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/config/build_info.dart';
import '../../data/local/local_user_store.dart';

class FeedbackPayload {
  const FeedbackPayload({
    required this.message,
    this.category,
    this.route,
    this.userId,
    this.sessionId,
    this.errorSummary,
  });

  final String message;
  final String? category;
  final String? route;
  final String? userId;
  final String? sessionId;
  final String? errorSummary;

  Map<String, dynamic> toJson() => {
    'message': message,
    if (category != null) 'category': category,
    if (route != null) 'route': route,
    if (userId != null) 'userId': userId,
    if (sessionId != null) 'sessionId': sessionId,
    if (errorSummary != null) 'errorSummary': errorSummary,
    'appVersion': BuildInfo.version,
    'buildSha': BuildInfo.buildSha,
    'submittedAt': DateTime.now().toIso8601String(),
  };
}

class FeedbackService {
  FeedbackService({LocalUserStore? store, http.Client? client})
    : _store = store ?? LocalUserStore(),
      _client = client ?? http.Client();

  final LocalUserStore _store;
  final http.Client _client;

  Future<bool> submit(FeedbackPayload payload) async {
    final url = AppConfig.feedbackApiUrl;
    if (url.isEmpty) {
      await _store.enqueueFeedback(jsonEncode(payload.toJson()));
      return false;
    }
    await flushQueued();
    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload.toJson()),
          )
          .timeout(const Duration(seconds: 8));
      return response.statusCode < 400;
    } catch (_) {
      await _store.enqueueFeedback(jsonEncode(payload.toJson()));
      return false;
    }
  }

  Future<int> flushQueued() async {
    final url = AppConfig.feedbackApiUrl;
    if (url.isEmpty) return 0;
    final queued = await _store.getFeedbackQueue();
    if (queued.isEmpty) return 0;

    final remaining = <String>[];
    var sent = 0;
    for (final payload in queued) {
      final ok = await _postRaw(url, payload);
      if (ok) {
        sent++;
      } else {
        remaining.add(payload);
      }
    }
    await _store.setFeedbackQueue(remaining);
    return sent;
  }

  Future<bool> _postRaw(String url, String body) async {
    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 8));
      return response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }
}
