import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'core/di/service_locator.dart';
import 'core/analytics/analytics_flush_worker.dart';
import 'core/analytics/analytics_service.dart';
import 'l10n/app_localizations.dart';
import 'providers/agenda_alerts_provider.dart';
import 'providers/announcement_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/companion_provider.dart';
import 'providers/consent_provider.dart';
import 'providers/event_provider.dart';
import 'providers/engagement_provider.dart';
import 'providers/ops_config_provider.dart';
import 'providers/organizer_dashboard_provider.dart';
import 'providers/plan_provider.dart';
import 'providers/flo_meets_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/prompt_curation_provider.dart';
import 'providers/app_settings_provider.dart';
import 'providers/session_qa_provider.dart';
import 'data/services/companion_service.dart';
import 'data/services/feedback_service.dart';
import 'data/services/navigation_history_service.dart';
import 'routing/app_router.dart';
import 'shared/a11y/keyboard_shortcuts.dart';
import 'shared/a11y/route_announcer.dart';
import 'shared/theme/app_theme.dart';
import 'shared/utils/app_theme_resolver.dart';
import 'shared/widgets/agenda_change_scope.dart';
import 'shared/widgets/leave_now_scope.dart';
import 'shared/widgets/page_meta_coordinator.dart';
import 'shared/tour/tour_controller.dart';
import 'shared/tour/tour_overlay.dart';
import 'shared/widgets/pwa_install_coordinator.dart';

class FloCompassApp extends StatelessWidget {
  const FloCompassApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsState>();
    final localeCode = settings.localeCode;
    final mode = settings.themeMode;
    final useDyslexiaFont = settings.useDyslexiaFont;

    if (mode == AppThemeMode.highContrast) {
      return MaterialApp.router(
        title: AppConfig.appTitle,
        debugShowCheckedModeBanner: false,
        locale: localeCode == null ? null : Locale(localeCode),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.themeFor(
          AppThemeMode.highContrast,
          useDyslexiaFont: useDyslexiaFont,
        ),
        routerConfig: router,
        builder: _appBuilder,
      );
    }

    return MaterialApp.router(
      title: AppConfig.appTitle,
      debugShowCheckedModeBanner: false,
      locale: localeCode == null ? null : Locale(localeCode),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.themeFor(
        AppThemeMode.light,
        useDyslexiaFont: useDyslexiaFont,
      ),
      darkTheme: AppTheme.themeFor(
        AppThemeMode.dark,
        useDyslexiaFont: useDyslexiaFont,
      ),
      themeMode: materialThemeModeFor(mode),
      routerConfig: router,
      builder: _appBuilder,
    );
  }

  Widget _appBuilder(BuildContext context, Widget? child) {
    return TourOverlay(
      router: router,
      child: PwaInstallCoordinator(
        router: router,
        child: KeyboardShortcuts(
          child: PageMetaCoordinator(
            router: router,
            child: RouteAnnouncer(
              router: router,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

Future<Widget> buildApp() async {
  await configureDependencies();
  sl<AnalyticsFlushWorker>();
  unawaited(FeedbackService().flushQueued());

  final profileState = ProfileState();
  final eventState = EventState();
  final planState = PlanState();
  final engagementState = EngagementState();
  final appSettings = AppSettingsState();
  final agendaAlertsState = AgendaAlertsState();
  final consentState = ConsentState();
  final authState = AuthState();
  final sessionQaState = SessionQaState();
  final announcementState = AnnouncementState();
  final promptCurationState = PromptCurationState();
  final organizerDashboardState = OrganizerDashboardState();
  final opsConfigState = OpsConfigState();
  final floMeetsState = FloMeetsState();
  profileState.onResetHook = engagementState.reset;

  await Future.wait([
    profileState.init(),
    floMeetsState.init(),
    consentState.init(),
    authState.init(),
    appSettings.init(),
    agendaAlertsState.init(),
    planState.init(),
    engagementState.init(),
    opsConfigState.init(),
  ]);
  Future<void> syncFloMeetsAuth() async {
    await floMeetsState.bindAuthSubject(authState.service.session?.subject);
  }

  await syncFloMeetsAuth();
  authState.addListener(() {
    unawaited(syncFloMeetsAuth());
  });
  await appSettings.loadLocaleFromStore();
  await eventState.load();
  await agendaAlertsState.seedBaseline(
    sessions: eventState.sessions,
    planSessionIds: planState.sessionIds,
    followedSpeakerIds: profileState.profile.followedSpeakerIds.toSet(),
  );
  await engagementState.syncQuestDay(eventState.currentDay);

  final router = createAppRouter(
    profileState,
    consentState: consentState,
    authState: authState,
    floMeetsState: floMeetsState,
    analytics: sl<AnalyticsService>(),
  );
  final historyService = NavigationHistoryService();

  void recordRouteIfNeeded() {
    final location = router.state.matchedLocation;
    if (location.startsWith('/session/')) {
      final id = router.state.pathParameters['id'];
      final session = id == null ? null : eventState.sessionById(id);
      if (session != null) {
        unawaited(
          historyService.record(
            route: location,
            label: session.title,
            subtitle: '${session.day} · ${session.startTime}',
          ),
        );
      }
    } else if (location.startsWith('/speaker/')) {
      final id = router.state.pathParameters['id'];
      final speaker = id == null ? null : eventState.speakerById(id);
      if (speaker != null) {
        unawaited(
          historyService.record(
            route: location,
            label: speaker.name,
            subtitle: speaker.title,
          ),
        );
      }
    }
  }

  router.routerDelegate.addListener(recordRouteIfNeeded);

  final companionState = CompanionState(service: sl<CompanionService>());
  final analyticsService = sl<AnalyticsService>();
  final tourController = TourController(
    router: router,
    appSettings: appSettings,
    planState: planState,
    companionState: companionState,
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => eventState),
      ChangeNotifierProvider.value(value: profileState),
      ChangeNotifierProvider.value(value: planState),
      ChangeNotifierProvider.value(value: engagementState),
      ChangeNotifierProvider.value(value: sessionQaState),
      ChangeNotifierProvider.value(value: announcementState),
      ChangeNotifierProvider.value(value: promptCurationState),
      ChangeNotifierProvider.value(value: organizerDashboardState),
      ChangeNotifierProvider.value(value: opsConfigState),
      ChangeNotifierProvider.value(value: agendaAlertsState),
      ChangeNotifierProvider.value(value: appSettings),
      ChangeNotifierProvider.value(value: consentState),
      ChangeNotifierProvider.value(value: authState),
      ChangeNotifierProvider.value(value: floMeetsState),
      ChangeNotifierProvider.value(value: companionState),
      ChangeNotifierProvider.value(value: tourController),
      Provider<AnalyticsService>.value(value: analyticsService),
    ],
    child: AgendaChangeScope(
      child: LeaveNowScope(child: FloCompassApp(router: router)),
    ),
  );
}
