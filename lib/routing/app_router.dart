import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/app_capability.dart';
import '../core/analytics/analytics_route_observer.dart';
import '../core/analytics/analytics_service.dart';
import '../core/config/runtime_config.dart';
import '../core/routing/app_routes.dart';
import '../features/operations/admin_operations_screen.dart';
import '../features/operations/announcements/organizer_announcement_compose_screen.dart';
import '../features/operations/announcements/organizer_announcements_screen.dart';
import '../features/operations/organizer_operations_screen.dart';
import '../features/operations/organizer_qa_moderation_screen.dart';
import '../features/operations/prompts/organizer_prompt_curation_screen.dart';
import '../features/auth/auth_callback_screen.dart';
import '../features/bingo/bingo_screen.dart';
import '../features/companion/companion_screen.dart';
import '../features/connect/connect_card_screen.dart';
import '../features/connect/networking_card_editor_screen.dart';
import '../features/connect/networking_card_share_screen.dart';
import '../features/consent/privacy_consent_screen.dart';
import '../features/directions/directions_screen.dart';
import '../features/discover/discover_filters.dart';
import '../features/discover/discover_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';
import '../features/learning_path/learning_path_detail_screen.dart';
import '../features/legal/accessibility_statement_screen.dart';
import '../features/legal/privacy_policy_screen.dart';
import '../features/my_plan/my_plan_screen.dart';
import '../features/my_plan/plan_import_screen.dart';
import '../features/flo_meets/flo_meet_detail_screen.dart';
import '../features/flo_meets/flo_meet_match_window.dart';
import '../features/flo_meets/flo_meet_room_detail_screen.dart';
import '../features/flo_meets/flo_meets_hub_screen.dart';
import '../features/flo_meets/flo_meets_preferences_screen.dart';
import '../features/operations/meet_rooms/organizer_meet_room_compose_screen.dart';
import '../features/operations/meet_rooms/organizer_meet_rooms_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/qr/qr_generator_screen.dart';
import '../features/recap/recap_screen.dart';
import '../features/session_detail/session_detail_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/speaker/speaker_detail_screen.dart';
import '../features/venue_map/venue_map_screen.dart';
import '../providers/consent_provider.dart';
import '../providers/flo_meets_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../shared/widgets/flo_meets_round_coordinator.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

GoRouter createAppRouter(
  ProfileState profileState, {
  ConsentState? consentState,
  AuthState? authState,
  FloMeetsState? floMeetsState,
  AnalyticsService? analytics,
}) {
  final routeObserver = analytics == null
      ? null
      : AnalyticsRouteObserver(analytics);
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.resolveInitialLocation(),
    refreshListenable: Listenable.merge([
      profileState,
      ?consentState,
      ?authState,
      ?floMeetsState,
    ]),
    redirect: (context, state) {
      final isPublic = AppRoutes.isVisitorRoute(state);
      final location = state.matchedLocation;
      final deniedOrganizerRoute =
          location.startsWith(AppRoutes.organizer) &&
          !(authState?.hasCapability(AppCapability.moderateQa) ?? false);
      final deniedAnnouncementRoute =
          (location.startsWith(AppRoutes.organizerAnnouncements) ||
              location.startsWith(AppRoutes.organizerMeetRooms)) &&
          !(authState?.hasCapability(AppCapability.publishAnnouncement) ??
              false);
      final deniedAdminRoute =
          (location == AppRoutes.admin ||
              location.startsWith('${AppRoutes.admin}/')) &&
          !(authState?.hasCapability(AppCapability.manageOpsConfig) ?? false);

      if (consentState != null &&
          consentState.isReady &&
          !consentState.hasAcceptedPrivacy &&
          state.matchedLocation != AppRoutes.privacy &&
          state.matchedLocation != AppRoutes.consent &&
          !isPublic) {
        final returnTo = Uri.encodeComponent(
          AppRoutes.currentPathForReturn(state),
        );
        return '${AppRoutes.consent}?returnTo=$returnTo';
      }

      final complete = profileState.profile.onboardingComplete;
      final onOnboarding = state.matchedLocation == AppRoutes.onboarding;
      final isEditMode = state.uri.queryParameters['edit'] == '1';
      final isLegacyFloMeetsEdit =
          isEditMode && state.uri.queryParameters['step'] == 'flo-meets';

      if (isLegacyFloMeetsEdit) {
        return AppRoutes.floMeetsPreferences;
      }

      final onMeetsPrefs =
          state.matchedLocation == AppRoutes.floMeetsPreferences;
      final onMeetsBranch = state.matchedLocation.startsWith(
        AppRoutes.floMeetsRoot,
      );
      if (floMeetsState != null &&
          onMeetsBranch &&
          !onMeetsPrefs &&
          authState != null &&
          authState.isAuthenticated &&
          !floMeetsState.preferences.isSetupComplete) {
        return AppRoutes.floMeetsPreferences;
      }

      if (!complete && !onOnboarding && !isPublic) {
        return AppRoutes.onboarding;
      }
      if (complete && onOnboarding && !isEditMode) {
        return AppRoutes.discover;
      }
      if (!RuntimeConfig.flags.leaderboard &&
          state.matchedLocation == AppRoutes.leaderboard) {
        return AppRoutes.discover;
      }
      if (deniedOrganizerRoute || deniedAdminRoute || deniedAnnouncementRoute) {
        final reason = deniedAdminRoute
            ? 'admin'
            : deniedAnnouncementRoute
            ? 'announcements'
            : 'organizer';
        return Uri(
          path: AppRoutes.profile,
          queryParameters: {'denied': reason},
        ).toString();
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.consent,
        name: 'consent',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PrivacyConsentScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        name: 'privacy',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: AppRoutes.accessibility,
        name: 'accessibility',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AccessibilityStatementScreen(),
      ),
      GoRoute(
        path: AppRoutes.authCallback,
        name: 'authCallback',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AuthCallbackScreen(
          code: state.uri.queryParameters['code'],
          state: state.uri.queryParameters['state'],
          error: state.uri.queryParameters['error'],
        ),
      ),
      GoRoute(
        path: AppRoutes.planImport,
        name: 'planImport',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final payload = state.uri.queryParameters['d'] ?? '';
          return PlanImportScreen(payload: payload);
        },
      ),
      GoRoute(
        path: AppRoutes.leaderboard,
        name: 'leaderboard',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.recap,
        name: 'recap',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RecapScreen(),
      ),
      GoRoute(
        path: AppRoutes.bingo,
        name: 'bingo',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BingoScreen(),
      ),
      GoRoute(
        path: AppRoutes.qr,
        name: 'qr',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QrGeneratorScreen(),
      ),
      GoRoute(
        path: AppRoutes.connectEdit,
        name: 'connectEdit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NetworkingCardEditorScreen(),
      ),
      GoRoute(
        path: AppRoutes.connectShare,
        name: 'connectShare',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NetworkingCardShareScreen(),
      ),
      GoRoute(
        path: AppRoutes.organizer,
        name: 'organizerOperations',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OrganizerOperationsScreen(),
        routes: [
          GoRoute(
            path: 'announcements',
            name: 'organizerAnnouncements',
            builder: (context, state) => const OrganizerAnnouncementsScreen(),
            routes: [
              GoRoute(
                path: 'compose',
                name: 'organizerAnnouncementCompose',
                builder: (context, state) =>
                    const OrganizerAnnouncementComposeScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'organizerAnnouncementDetail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return OrganizerAnnouncementComposeScreen(announcementId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'meet-rooms',
            name: 'organizerMeetRooms',
            builder: (context, state) => const OrganizerMeetRoomsScreen(),
            routes: [
              GoRoute(
                path: 'compose',
                name: 'organizerMeetRoomCompose',
                builder: (context, state) =>
                    const OrganizerMeetRoomComposeScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'organizerMeetRoomDetail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return OrganizerMeetRoomComposeScreen(roomId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'prompts',
            name: 'organizerPrompts',
            builder: (context, state) => const OrganizerPromptCurationScreen(),
          ),
          GoRoute(
            path: 'qa',
            name: 'organizerQa',
            builder: (context, state) => const OrganizerQaModerationScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.admin,
        name: 'adminOperations',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminOperationsScreen(),
      ),
      GoRoute(
        path: '/connect/:token',
        name: 'connectPublic',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final token = state.pathParameters['token']!;
          return ConnectCardScreen(token: token);
        },
      ),
      ShellRoute(
        builder: (context, state, child) =>
            FloMeetsRoundCoordinator(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.onboarding,
            name: 'onboarding',
            builder: (context, state) => const OnboardingScreen(),
          ),
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return MainShell(navigationShell: navigationShell);
            },
            branches: [
              StatefulShellBranch(
                navigatorKey: _shellNavigatorKey,
                routes: [
                  GoRoute(
                    path: AppRoutes.discover,
                    name: 'discover',
                    builder: (context, state) => DiscoverScreen(
                      initialFilters: DiscoverFilters.fromUri(state.uri),
                    ),
                  ),
                  GoRoute(
                    path: '/session/:id',
                    name: 'sessionDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return SessionDetailScreen(sessionId: id);
                    },
                  ),
                  GoRoute(
                    path: '/speaker/:id',
                    name: 'speakerDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return SpeakerDetailScreen(speakerId: id);
                    },
                  ),
                  GoRoute(
                    path: AppRoutes.map,
                    name: 'map',
                    builder: (context, state) {
                      final room = state.uri.queryParameters['room'];
                      return VenueMapScreen(highlightRoom: room);
                    },
                  ),
                  GoRoute(
                    path: AppRoutes.directions,
                    name: 'directions',
                    redirect: (context, state) {
                      final session = state.uri.queryParameters['session'];
                      if (session == null || session.isEmpty) {
                        return AppRoutes.discover;
                      }
                      return null;
                    },
                    builder: (context, state) {
                      final sessionId = state.uri.queryParameters['session']!;
                      return DirectionsScreen(sessionId: sessionId);
                    },
                  ),
                  GoRoute(
                    path: '/learning-path/:id',
                    name: 'learningPath',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return LearningPathDetailScreen(pathId: id);
                    },
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.companion,
                    name: 'companion',
                    builder: (context, state) => CompanionScreen(
                      initialQuery: state.uri.queryParameters['q'],
                      initialSessionId: state.uri.queryParameters['sessionId'],
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.floMeetsRoot,
                    name: 'floMeets',
                    builder: (context, state) => const FloMeetsHubScreen(),
                    routes: [
                      GoRoute(
                        path: 'preferences',
                        name: 'floMeetsPreferences',
                        builder: (context, state) =>
                            const FloMeetsPreferencesScreen(),
                      ),
                      GoRoute(
                        path: 'room/:roomId',
                        name: 'floMeetRoom',
                        builder: (context, state) {
                          final roomId = state.pathParameters['roomId']!;
                          return FloMeetRoomDetailScreen(roomId: roomId);
                        },
                      ),
                      GoRoute(
                        path: 'window/:roomId/:partnerId',
                        name: 'floMeetWindow',
                        builder: (context, state) {
                          final roomId = state.pathParameters['roomId']!;
                          final partnerId = state.pathParameters['partnerId']!;
                          return FloMeetMatchWindowScreen(
                            roomId: roomId,
                            partnerId: partnerId,
                          );
                        },
                      ),
                      GoRoute(
                        path: 'match/:id',
                        name: 'floMeetDetail',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return FloMeetDetailScreen(meetId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.myPlan,
                    name: 'myPlan',
                    builder: (context, state) => const MyPlanScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.profile,
                    name: 'profile',
                    builder: (context, state) => const ProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  if (analytics != null && routeObserver != null) {
    void onRouteChange() {
      try {
        routeObserver.didChangeRoute(router.state.matchedLocation);
      } catch (_) {
        // Router may not have a resolved match during initial construction.
      }
    }

    router.routerDelegate.addListener(onRouteChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => onRouteChange());
  }
  return router;
}
