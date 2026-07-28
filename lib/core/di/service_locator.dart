import 'package:get_it/get_it.dart';

import '../../core/config/data_source.dart';
import '../../core/config/runtime_config.dart';
import '../analytics/analytics_config.dart';
import '../analytics/analytics_flush_worker.dart';
import '../analytics/analytics_service.dart';
import '../auth/auth_service.dart';
import '../consent/consent_service.dart';
import '../network/api_client.dart';
import '../observability/crash_reporter.dart';
import '../../data/local/local_user_store.dart';
import '../../data/repositories/mock_announcement_repository.dart';
import '../../data/repositories/mock_event_repository.dart';
import '../../data/repositories/mock_prompt_curation_repository.dart';
import '../../data/repositories/mock_session_qa_repository.dart';
import '../../data/repositories/remote_event_repository.dart';
import '../../data/services/companion_service.dart';
import '../../data/services/event_clock_service.dart';
import '../../data/services/llm_companion_service.dart';
import '../../data/services/recommendation_service.dart';
import '../../data/services/rule_based_companion_service.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/repositories/prompt_curation_repository.dart';
import '../../domain/repositories/session_qa_repository.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  if (sl.isRegistered<EventRepository>()) return;

  await RuntimeConfig.load();

  sl.registerLazySingleton<ApiClient>(ApiClient.new);
  sl.registerLazySingleton<LocalUserStore>(LocalUserStore.new);
  sl.registerLazySingleton<AuthService>(AuthService.new);
  sl.registerLazySingleton<EventRepository>(() {
    if (RuntimeConfig.dataSource == DataSource.remote) {
      return RemoteEventRepository(
        apiClient: sl<ApiClient>(),
        fallback: MockEventRepository(strictIntegrity: false),
      );
    }
    return MockEventRepository(strictIntegrity: false);
  });
  sl.registerLazySingleton<SessionQaRepository>(MockSessionQaRepository.new);
  sl.registerLazySingleton<AnnouncementRepository>(
    MockAnnouncementRepository.new,
  );
  sl.registerLazySingleton<PromptCurationRepository>(
    MockPromptCurationRepository.new,
  );
  sl.registerLazySingleton(RecommendationService.new);
  sl.registerLazySingleton(EventClockService.new);
  sl.registerLazySingleton(RuleBasedCompanionService.new);
  sl.registerLazySingleton<LlmCompanionService>(
    () => LlmCompanionService(
      apiClient: sl<ApiClient>(),
      fallback: sl<RuleBasedCompanionService>(),
      store: sl<LocalUserStore>(),
    ),
  );
  sl.registerLazySingleton<CompanionService>(
    () => CompanionService(
      ruleBased: sl<RuleBasedCompanionService>(),
      llm: sl<LlmCompanionService>(),
    ),
  );
  sl.registerLazySingleton<AnalyticsService>(
    () => AnalyticsService.create(
      config: AnalyticsConfig.resolve(),
      consentService: ConsentService(store: sl<LocalUserStore>()),
      store: sl<LocalUserStore>(),
      platformRoleProvider: () => sl<AuthService>().platformRole,
    ),
  );
  sl.registerLazySingleton<AnalyticsFlushWorker>(() {
    final worker = AnalyticsFlushWorker(analytics: sl<AnalyticsService>());
    worker.start();
    return worker;
  });
  CrashReporter.instance.bindAnalytics(sl<AnalyticsService>());
}
