import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/plan_provider.dart';
import '../../shared/utils/connectivity.dart';
import '../../shared/utils/event_day_mode.dart';
import '../../shared/utils/event_notifications.dart';
import '../../shared/utils/event_stage.dart';
import '../../shared/utils/now_next_resolver.dart';
import '../../shared/utils/discover_scroll_bridge.dart';
import '../../shared/tour/tour_targets.dart';
import '../../shared/widgets/now_next_bar.dart';
import '../../shared/widgets/offline_banner.dart';
import 'shell_navigation_controller.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool? _wasOnline;
  bool _isOnline = ConnectivityPlatform.isOnline;
  bool _announceOffline = false;
  StreamSubscription<bool>? _connectivitySub;
  VoidCallback? _shellScrollToTop;
  VoidCallback? _companionScrollToBottom;
  bool _nowBarCollapsed = false;
  DateTime? _forceExpandUntil;

  @override
  void initState() {
    super.initState();
    _wasOnline = _isOnline;
    ShellNavigationController.register(_onTabSelected);
    _connectivitySub = ConnectivityPlatform.onlineStream.listen(
      _onConnectivityChanged,
    );
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    ShellNavigationController.unregister();
    super.dispose();
  }

  void _onConnectivityChanged(bool online) {
    if (!mounted) return;
    setState(() {
      _announceOffline = _wasOnline == true && !online;
      _wasOnline = online;
      _isOnline = online;
    });
  }

  static const _destinations = <({String label, IconData icon})>[
    (label: 'Discover', icon: Icons.explore_outlined),
    (label: 'Ask Flo', icon: Icons.auto_awesome_outlined),
    (label: 'Meets', icon: Icons.people_outline),
    (label: 'My Plan', icon: Icons.bookmark_outline),
    (label: 'Profile', icon: Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final event = context.watch<EventState>();
    final plan = context.watch<PlanState>();
    final appSettings = context.watch<AppSettingsState>();

    return DiscoverScrollBridge(
      register: (callback) {
        _shellScrollToTop = callback;
      },
      registerScrollToBottom: (callback) {
        _companionScrollToBottom = callback;
      },
      onScrollOffset: _handleScrollOffset,
      child: Scaffold(
        body: ValueListenableBuilder<DateTime>(
          valueListenable: event.clockTicker,
          builder: (context, now, _) {
            final isEventDayMode = resolveEventDayModeForEvent(
              appSettings.settings,
              event.currentDay,
            );
            final notifications = resolveEventNotificationsFromContext(context);
            final nowNext = resolveNowNext(
              planned: plan.plannedSessions(event.sessions),
              minutesUntil: event.minutesUntil,
              minutesRemaining: event.minutesRemaining,
              liveFallback: event.happeningNow(),
            );
            final stage = resolveStage(current: event.currentTime ?? now);
            final showEventDayHeader =
                isEventDayMode && stage != EventStage.beforeEvent;

            return Column(
              children: [
                if (showEventDayHeader)
                  _buildEventDayHeader(
                    context,
                    event: event,
                    plan: plan,
                    nowNext: nowNext,
                    notificationCount: notifications.count,
                    onNotificationsTap: () => _showNotifications(
                      context,
                      notifications: notifications,
                    ),
                  ),
                if (!isEventDayMode && !_isOnline)
                  OfflineBanner(announce: _announceOffline),
                Expanded(child: widget.navigationShell),
              ],
            );
          },
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: _onTabSelected,
          destinations: [
            NavigationDestination(
              icon: Semantics(
                label: '${l10n.tabDiscover} tab',
                child: Icon(_destinations[0].icon),
              ),
              selectedIcon: Icon(_selectedIcon(_destinations[0].icon)),
              label: l10n.tabDiscover,
            ),
            NavigationDestination(
              icon: Semantics(
                label: '${l10n.tabCompanion} tab',
                child: Icon(_destinations[1].icon),
              ),
              selectedIcon: Icon(_selectedIcon(_destinations[1].icon)),
              label: l10n.tabCompanion,
            ),
            NavigationDestination(
              icon: Semantics(
                label: '${l10n.tabMeets} tab',
                child: Icon(_destinations[2].icon),
              ),
              selectedIcon: Icon(_selectedIcon(_destinations[2].icon)),
              label: l10n.tabMeets,
            ),
            NavigationDestination(
              icon: Semantics(
                label: '${l10n.tabMyPlan} tab',
                child: Icon(_destinations[3].icon),
              ),
              selectedIcon: Icon(_selectedIcon(_destinations[3].icon)),
              label: l10n.tabMyPlan,
            ),
            NavigationDestination(
              icon: Semantics(
                label: '${l10n.tabProfile} tab',
                child: Icon(_destinations[4].icon),
              ),
              selectedIcon: Icon(_selectedIcon(_destinations[4].icon)),
              label: l10n.tabProfile,
            ),
          ],
        ),
      ),
    );
  }

  void _handleScrollOffset(double offset, {required bool atTop}) {
    if (!mounted) return;
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    if (!isMobile) {
      if (_nowBarCollapsed) {
        setState(() => _nowBarCollapsed = false);
      }
      return;
    }
    final forceExpanded =
        _forceExpandUntil != null &&
        DateTime.now().isBefore(_forceExpandUntil!);
    if (atTop || forceExpanded) {
      if (_nowBarCollapsed) {
        setState(() => _nowBarCollapsed = false);
      }
      if (atTop) {
        _forceExpandUntil = null;
      }
    } else if (offset > 60 && !_nowBarCollapsed) {
      setState(() => _nowBarCollapsed = true);
    }
  }

  void _onNowBarExpand() {
    setState(() {
      _nowBarCollapsed = false;
      _forceExpandUntil = DateTime.now().add(const Duration(seconds: 3));
    });
  }

  void _onTabSelected(int index) {
    final shell = widget.navigationShell;
    if (index != shell.currentIndex) {
      unawaited(context.read<AppSettingsState>().recordShellTabVisit(index));
    }
    if (index == 0) {
      final path = GoRouterState.of(context).uri.path;
      final onDiscoverFeed =
          shell.currentIndex == 0 && path == AppRoutes.discover;

      if (!onDiscoverFeed) {
        shell.goBranch(0, initialLocation: true);
        return;
      }

      _scheduleShellScrollToTop();
      return;
    }

    if (index == 1) {
      shell.goBranch(1, initialLocation: true);
      _scheduleCompanionScrollToBottom();
      return;
    }
    if (index == 2 || index == 3) {
      shell.goBranch(index, initialLocation: true);
      _scheduleShellScrollToTop();
      return;
    }
    final alreadyOnProfile = shell.currentIndex == index;
    shell.goBranch(index);
    if (alreadyOnProfile) {
      _scheduleShellScrollToTop();
    }
  }

  void _scheduleShellScrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shellScrollToTop?.call();
    });
  }

  void _scheduleCompanionScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _companionScrollToBottom?.call();
    });
  }

  Widget _buildEventDayHeader(
    BuildContext context, {
    required EventState event,
    required PlanState plan,
    required NowNextResult nowNext,
    required int notificationCount,
    required VoidCallback onNotificationsTap,
  }) {
    final room = nowNext.displaySession?.venueId;
    final mapRoute = room == null ? '/map' : '/map?room=$room';
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final collapsed = isMobile && _nowBarCollapsed;

    return Material(
      elevation: 2,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            clipBehavior: Clip.hardEdge,
            child: NowNextBar(
              key: tourNowNextBarKey,
              nowSession: nowNext.now,
              nextSession: nowNext.next,
              event: event,
              plan: plan,
              collapsed: collapsed,
              onExpand: _onNowBarExpand,
              notificationCount: notificationCount,
              onNotificationsTap: onNotificationsTap,
              onMapTap: () => context.go(mapRoute),
              onDirectionsTap: nowNext.displaySession == null
                  ? null
                  : () => context.push(
                      '/directions?session=${nowNext.displaySession!.id}',
                    ),
            ),
          ),
          if (!_isOnline) OfflineBanner(announce: _announceOffline),
        ],
      ),
    );
  }

  Future<void> _showNotifications(
    BuildContext context, {
    required EventNotificationSnapshot notifications,
  }) {
    final event = context.read<EventState>();
    return showEventNotificationsSheetFromContext(
      context,
      notifications: notifications,
      minutesUntil: event.minutesUntil,
      venueNameFor: (id) => event.venueById(id)?.name,
    );
  }

  IconData _selectedIcon(IconData outlined) {
    return switch (outlined) {
      Icons.explore_outlined => Icons.explore,
      Icons.auto_awesome_outlined => Icons.auto_awesome,
      Icons.people_outline => Icons.people,
      Icons.bookmark_outline => Icons.bookmark,
      Icons.person_outline => Icons.person,
      _ => outlined,
    };
  }
}
