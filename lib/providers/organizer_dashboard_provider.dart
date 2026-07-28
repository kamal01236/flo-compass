import 'package:flutter/foundation.dart';

import '../core/di/service_locator.dart';
import '../data/repositories/mock_session_qa_repository.dart';
import '../domain/entities/session_qa_moderation_stats.dart';
import '../domain/repositories/session_qa_repository.dart';

SessionQaRepository _defaultSessionQaRepository() {
  if (sl.isRegistered<SessionQaRepository>()) {
    return sl<SessionQaRepository>();
  }
  return MockSessionQaRepository();
}

class OrganizerDashboardState extends ChangeNotifier {
  OrganizerDashboardState({SessionQaRepository? repository})
    : _repository = repository ?? _defaultSessionQaRepository();

  final SessionQaRepository _repository;

  bool loading = false;
  String? error;
  SessionQaModerationStats? stats;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      stats = await _repository.loadModerationStats();
    } catch (e) {
      error = kDebugMode ? '$e' : 'Failed to load organizer stats';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
