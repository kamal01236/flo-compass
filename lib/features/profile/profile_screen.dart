import 'dart:async';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/app_capability.dart';
import '../../core/auth/platform_role.dart';
import '../../core/config/app_config.dart';
import '../../core/config/build_info.dart';
import '../../core/config/runtime_config.dart';
import '../../core/routing/app_routes.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/achievement_service.dart';
import '../../data/services/navigation_history_service.dart';
import '../../data/services/track_passport_service.dart';
import '../../data/models/networking_card.dart';
import '../../features/connect/business_card_preview.dart';
import '../../features/feedback/feedback_sheet.dart';
import '../../features/operations/admin_operations_panel.dart';
import '../../features/operations/organizer_operations_panel.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/engagement_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/plan_provider.dart';
import '../../shared/auth/mock_user_picker.dart';
import '../../providers/profile_provider.dart';
import '../../shared/auth/capability_guard.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/tour/tour_controller.dart';
import '../../shared/utils/discover_scroll_bridge.dart';
import '../../shared/utils/event_day_mode.dart';
import '../../shared/utils/track_display.dart';
import '../../shared/utils/pwa_install.dart';
import '../../shared/utils/web_download.dart';
import '../../shared/utils/web_push.dart';
import '../../shared/widgets/achievement_badge.dart';
import '../../shared/widgets/achievement_confetti.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'widgets/analytics_diagnostics_panel.dart';

enum _ProfileMenuAction { feedback, accessibility, install, replayTour }

Future<void> replayProductTour(BuildContext context) async {
  final settings = context.read<AppSettingsState>();
  final tour = context.read<TourController>();
  await settings.resetTour();
  await tour.start(force: true);
  if (context.mounted) context.go(AppRoutes.discover);
}

enum _SettingsGroup {
  appearance,
  eventExperience,
  notifications,
  community,
  accountRoles,
  about,
  advanced,
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final _achievementShareKey = GlobalKey();
  bool _pushPermissionDenied = false;
  bool _pushSupported = true;
  DiscoverScrollBridge? _scrollBridge;
  TabController? _tabController;
  int _tabControllerLength = 3;
  final _tabScrollHandlers = <int, VoidCallback>{};
  String? _lastDeniedReason;
  String? _lastAppliedTabParam;

  @override
  void initState() {
    super.initState();
    _refreshPushPermission();
  }

  int _profileTabCount(AuthState auth) {
    var count = 3;
    if (auth.hasCapability(AppCapability.moderateQa)) count++;
    if (auth.hasCapability(AppCapability.manageOpsConfig)) count++;
    return count;
  }

  void _ensureTabController(int length) {
    if (_tabController != null && _tabControllerLength == length) {
      _syncTabFromRoute();
      return;
    }
    final oldIndex = _tabController?.index ?? 0;
    final routeTab = GoRouterState.of(context).uri.queryParameters['tab'];
    final routeIndex = _profileTabIndexFromParam(routeTab);
    final initialIndex = routeIndex ?? oldIndex;
    _tabController?.dispose();
    _tabControllerLength = length;
    _tabController = TabController(
      length: length,
      vsync: this,
      initialIndex: initialIndex.clamp(0, length - 1),
    );
    if (routeTab != null) {
      _lastAppliedTabParam = routeTab;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollBridge ??= DiscoverScrollBridge.maybeOf(context);
    _scrollBridge?.register(_scrollProfileToTop);
    final denied = GoRouterState.of(context).uri.queryParameters['denied'];
    if (denied != null && denied != _lastDeniedReason) {
      _lastDeniedReason = denied;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_deniedMessage(denied))));
        context.go(AppRoutes.profile);
      });
    }
    _syncTabFromRoute();
  }

  String _deniedMessage(String reason) {
    return switch (reason) {
      'admin' => AppCapability.manageOpsConfig.denialMessage,
      'announcements' => AppCapability.publishAnnouncement.denialMessage,
      _ => AppCapability.moderateQa.denialMessage,
    };
  }

  @override
  void dispose() {
    _scrollBridge?.register(null);
    _tabController?.dispose();
    super.dispose();
  }

  void _scrollProfileToTop() {
    _tabScrollHandlers[_tabController?.index ?? 0]?.call();
  }

  void _registerTabScrollHandler(int tabIndex, VoidCallback? handler) {
    if (handler == null) {
      _tabScrollHandlers.remove(tabIndex);
    } else {
      _tabScrollHandlers[tabIndex] = handler;
    }
  }

  int? _profileTabIndexFromParam(String? tab) {
    return switch (tab) {
      'you' => 0,
      'progress' => 1,
      'settings' => 2,
      _ => null,
    };
  }

  void _syncTabFromRoute() {
    final tab = GoRouterState.of(context).uri.queryParameters['tab'];
    if (tab == _lastAppliedTabParam) return;
    final index = _profileTabIndexFromParam(tab);
    if (index == null) return;
    final controller = _tabController;
    if (controller == null) return;
    _lastAppliedTabParam = tab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _tabController == null) return;
      if (_tabController!.index != index) {
        _tabController!.animateTo(index);
      }
    });
  }

  Future<void> _refreshPushPermission() async {
    final supported = isNotificationSupported;
    final denied = supported && await getNotificationPermission() == 'denied';
    if (!mounted) return;
    setState(() {
      _pushSupported = supported;
      _pushPermissionDenied = denied;
    });
  }

  Future<void> _handleProfileMenuAction(
    BuildContext context,
    _ProfileMenuAction action,
    AppLocalizations l10n,
  ) async {
    switch (action) {
      case _ProfileMenuAction.feedback:
        await showFeedbackSheet(context);
      case _ProfileMenuAction.accessibility:
        if (context.mounted) context.push(AppRoutes.accessibility);
      case _ProfileMenuAction.install:
        if (isInstallPromptAvailable) {
          await triggerInstallPrompt();
          return;
        }
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.profileInstallFallback)));
      case _ProfileMenuAction.replayTour:
        await replayProductTour(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileState>();
    final appSettings = context.watch<AppSettingsState>();
    final event = context.watch<EventState>();
    final engagement = context.watch<EngagementState>();
    final plan = context.watch<PlanState>();
    final auth = context.watch<AuthState>();
    final profile = profileState.profile;
    final l10n = AppLocalizations.of(context);
    final isEventDayMode = resolveEventDayModeForEvent(
      appSettings.settings,
      event.currentDay,
    );
    _syncAchievements(context, engagement, plan, event);

    final showOrganizerTab = auth.hasCapability(AppCapability.moderateQa);
    final showAdminTab = auth.hasCapability(AppCapability.manageOpsConfig);
    final tabCount = _profileTabCount(auth);
    _ensureTabController(tabCount);
    final tabController = _tabController!;
    _syncTabFromRoute();

    final streakSet = engagement.snapshot.streakDays.toSet();
    final unlocked = AchievementService.unlockedFromIds(
      engagement.achievements,
    );

    final tabs = <Tab>[
      Tab(text: l10n.profileTabYou),
      Tab(text: l10n.profileTabProgress),
      Tab(text: l10n.profileTabSettings),
      if (showOrganizerTab)
        Tab(
          icon: const Icon(Icons.forum_outlined),
          text: l10n.profileTabOrganizer,
        ),
      if (showAdminTab)
        Tab(
          icon: const Icon(Icons.admin_panel_settings_outlined),
          text: l10n.profileTabAdmin,
        ),
    ];

    final tabViews = <Widget>[
      _ProfileOverviewTab(
        profile: profile,
        onSelectTab: tabController.animateTo,
        organizerTabIndex: showOrganizerTab ? 3 : null,
        adminTabIndex: showAdminTab ? (showOrganizerTab ? 4 : 3) : null,
      ),
      _ProfileEngagementTab(
        engagement: engagement,
        event: event,
        plan: plan,
        appSettings: appSettings,
        streakSet: streakSet,
        unlocked: unlocked,
        achievementShareKey: _achievementShareKey,
        onDownloadAchievementPng: _downloadAchievementPng,
      ),
      _ProfileSettingsTab(
        profileState: profileState,
        appSettings: appSettings,
        l10n: l10n,
        pushSupported: _pushSupported,
        pushPermissionDenied: _pushPermissionDenied,
        onRefreshPushPermission: _refreshPushPermission,
      ),
      if (showOrganizerTab) const _ProfileOrganizerTab(tabIndex: 3),
      if (showAdminTab) _ProfileAdminTab(tabIndex: showOrganizerTab ? 4 : 3),
    ];

    return _ProfileScrollCoordinator(
      registerTabScroll: _registerTabScrollHandler,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.profileScreenTitle),
          actions: [
            if (!isEventDayMode) const EventNotificationAppBarAction(),
            PopupMenuButton<_ProfileMenuAction>(
              tooltip: l10n.profileMoreOptions,
              onSelected: (action) =>
                  _handleProfileMenuAction(context, action, l10n),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _ProfileMenuAction.feedback,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.feedback_outlined),
                    title: Text(l10n.sendFeedback),
                  ),
                ),
                PopupMenuItem(
                  value: _ProfileMenuAction.accessibility,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.accessibility_new_outlined),
                    title: Text(l10n.accessibilityStatement),
                  ),
                ),
                PopupMenuItem(
                  value: _ProfileMenuAction.replayTour,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.explore_outlined),
                    title: Text(l10n.replayTour),
                  ),
                ),
                if (isInstallPromptAvailable)
                  PopupMenuItem(
                    value: _ProfileMenuAction.install,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.install_mobile_outlined),
                      title: Text(l10n.profileInstallApp),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: ResponsiveLayout(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                child: TabBar(
                  controller: tabController,
                  isScrollable: true,
                  tabs: tabs,
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: tabViews,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadAchievementPng() async {
    final context = _achievementShareKey.currentContext;
    if (context == null) return;
    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    downloadPng(bytes.buffer.asUint8List(), 'flo-compass-achievements.png');
  }

  void _syncAchievements(
    BuildContext context,
    EngagementState engagement,
    PlanState plan,
    EventState event,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final previous = engagement.achievements.toSet();
      final unlocked = AchievementService().evaluate(
        engagement: engagement.snapshot,
        plannedSessions: plan.plannedSessions(event.sessions),
        allSessions: event.sessions,
        tracks: event.tracks,
      );
      for (final achievement in unlocked) {
        if (previous.contains(achievement.id)) continue;
        await engagement.unlockAchievement(achievement.id);
        if (context.mounted) showAchievementConfetti(context);
      }
    });
  }
}

class _ProfileScrollCoordinator extends InheritedWidget {
  const _ProfileScrollCoordinator({
    required this.registerTabScroll,
    required super.child,
  });

  final void Function(int tabIndex, VoidCallback? callback) registerTabScroll;

  static _ProfileScrollCoordinator? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ProfileScrollCoordinator>();
  }

  @override
  bool updateShouldNotify(_ProfileScrollCoordinator oldWidget) => false;
}

mixin _ProfileScrollReporting<T extends StatefulWidget> on State<T> {
  int get profileTabIndex;

  late final ScrollController profileScrollController;
  _ProfileScrollCoordinator? _profileScrollCoordinator;

  @override
  void initState() {
    super.initState();
    profileScrollController = ScrollController()..addListener(_reportScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileScrollCoordinator ??= _ProfileScrollCoordinator.maybeOf(context);
    _profileScrollCoordinator?.registerTabScroll(profileTabIndex, _scrollToTop);
  }

  void _scrollToTop() {
    if (!profileScrollController.hasClients) return;
    unawaited(
      profileScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      ),
    );
  }

  void _reportScroll() {
    if (!profileScrollController.hasClients) return;
    final offset = profileScrollController.offset;
    DiscoverScrollBridge.maybeOf(
      context,
    )?.reportScrollOffset(offset, atTop: offset <= 0);
  }

  @override
  void dispose() {
    _profileScrollCoordinator?.registerTabScroll(profileTabIndex, null);
    profileScrollController.dispose();
    super.dispose();
  }
}

class _ProfileOrganizerTab extends StatefulWidget {
  const _ProfileOrganizerTab({required this.tabIndex});

  final int tabIndex;

  @override
  State<_ProfileOrganizerTab> createState() => _ProfileOrganizerTabState();
}

class _ProfileOrganizerTabState extends State<_ProfileOrganizerTab>
    with _ProfileScrollReporting {
  @override
  int get profileTabIndex => widget.tabIndex;

  @override
  Widget build(BuildContext context) {
    return OrganizerOperationsPanel(scrollController: profileScrollController);
  }
}

class _ProfileAdminTab extends StatefulWidget {
  const _ProfileAdminTab({required this.tabIndex});

  final int tabIndex;

  @override
  State<_ProfileAdminTab> createState() => _ProfileAdminTabState();
}

class _ProfileAdminTabState extends State<_ProfileAdminTab>
    with _ProfileScrollReporting {
  @override
  int get profileTabIndex => widget.tabIndex;

  @override
  Widget build(BuildContext context) {
    return AdminOperationsPanel(scrollController: profileScrollController);
  }
}

class _YouSectionCard extends StatelessWidget {
  const _YouSectionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.accentStart),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ProfileOverviewTab extends StatefulWidget {
  const _ProfileOverviewTab({
    required this.profile,
    required this.onSelectTab,
    this.organizerTabIndex,
    this.adminTabIndex,
  });

  final UserProfile profile;
  final ValueChanged<int> onSelectTab;
  final int? organizerTabIndex;
  final int? adminTabIndex;

  @override
  State<_ProfileOverviewTab> createState() => _ProfileOverviewTabState();
}

class _AttendanceModePill extends StatelessWidget {
  const _AttendanceModePill({required this.mode});

  final AttendanceMode mode;

  @override
  Widget build(BuildContext context) {
    final isOnSite = mode == AttendanceMode.onSite;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnSite ? Icons.location_on_outlined : Icons.live_tv_outlined,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(mode.label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _BusinessCardOffCard extends StatelessWidget {
  const _BusinessCardOffCard({required this.card});

  final NetworkingCard card;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppChromeColors.of(context).skeleton,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.badge_outlined, color: AppColors.accentStart),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Business card is off — turn it on to share your '
                      'details via QR at Flo.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: card.enabled,
                onChanged: (enabled) async {
                  if (!enabled) return;
                  await context.read<ProfileState>().saveNetworkingCard(
                    card.copyWith(enabled: true),
                  );
                },
                title: Text(l10n.profileEnableBusinessCard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YouDemoAccessCard extends StatelessWidget {
  const _YouDemoAccessCard({
    required this.authState,
    required this.onSelectTab,
    required this.onPickUser,
    required this.organizationLabel,
    this.organizerTabIndex,
    this.adminTabIndex,
  });

  final AuthState authState;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onPickUser;
  final String organizationLabel;
  final int? organizerTabIndex;
  final int? adminTabIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAuthenticated = authState.isAuthenticated;
    final canOpenOrganizer =
        organizerTabIndex != null &&
        authState.hasCapability(AppCapability.moderateQa);
    final canOpenAdmin =
        adminTabIndex != null &&
        authState.hasCapability(AppCapability.manageOpsConfig);

    return _YouSectionCard(
      icon: Icons.login_outlined,
      title: l10n.profileDemoAccessTitle,
      children: [
        Text(
          l10n.profileDemoAccessBody,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 12),
        if (isAuthenticated) ...[
          Text(
            l10n.profileSignedInAs(authState.displayName ?? ''),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (authState.email != null && authState.email!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              authState.email!,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            l10n.profileDemoPlatformAccess(
              authState.platformRole.label,
              organizationLabel,
            ),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          if (canOpenOrganizer || canOpenAdmin) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canOpenOrganizer)
                  OutlinedButton.icon(
                    onPressed: () => onSelectTab(organizerTabIndex!),
                    icon: const Icon(Icons.forum_outlined),
                    label: Text(l10n.profileOpenOrganizerTab),
                  ),
                if (canOpenAdmin)
                  OutlinedButton.icon(
                    onPressed: () => onSelectTab(adminTabIndex!),
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: Text(l10n.profileOpenAdminTab),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onPickUser,
            icon: const Icon(Icons.swap_horiz),
            label: Text(l10n.profileSwitchUser),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: authState.logout,
              icon: const Icon(Icons.logout),
              label: Text(l10n.profileLogout),
            ),
          ),
        ] else
          FilledButton.icon(
            onPressed: onPickUser,
            icon: const Icon(Icons.login),
            label: Text(l10n.profileLogin),
          ),
      ],
    );
  }
}

class _ProfileOverviewTabState extends State<_ProfileOverviewTab>
    with _ProfileScrollReporting {
  @override
  int get profileTabIndex => 0;

  Future<void> _showMockUserPicker(BuildContext context) =>
      showMockUserPicker(context);

  String _mockOrganizationLabel(AuthState authState) {
    final subject = authState.service.session?.subject;
    if (subject == null) return '';
    for (final user in RuntimeConfig.mockUsers) {
      if (user.id == subject && user.organization.isNotEmpty) {
        return ' · ${user.organization}';
      }
    }
    return '';
  }

  List<Widget> _networkingSectionChildren(
    BuildContext context,
    NetworkingCard networkingCard,
  ) {
    final canShareQr = networkingCard.enabled && networkingCard.isConfigured;

    return [
      if (!networkingCard.enabled)
        _BusinessCardOffCard(card: networkingCard)
      else ...[
        BusinessCardPreview.fromCard(card: networkingCard),
        if (!networkingCard.isConfigured) ...[
          const SizedBox(height: 8),
          Text(
            'Add a display name + one channel to finish setup',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ],
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.tonalIcon(
            onPressed: () {
              if (!canShareQr) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Finish your card in Edit card before sharing your QR.',
                    ),
                  ),
                );
                return;
              }
              context.push(AppRoutes.connectShare);
            },
            icon: const Icon(Icons.qr_code),
            label: const Text('My QR card'),
          ),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.connectEdit),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit card'),
          ),
        ],
      ),
    ];
  }

  Widget _personalizationSection(BuildContext context, UserProfile profile) {
    return _YouSectionCard(
      icon: Icons.person_outline,
      title: 'Personalization',
      subtitle: 'Shapes Discover rankings and session recommendations.',
      children: [
        Text('Your role at Flo', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(profile.onboardingComplete ? profile.role.label : 'Not set'),
        const SizedBox(height: 12),
        _AttendanceModePill(mode: profile.attendanceMode),
        const SizedBox(height: 12),
        Text('Interests', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (profile.interests.isEmpty)
          Text(
            'No interests selected',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final id in profile.interests)
                Chip(
                  label: Text(
                    InterestTagX.fromId(id)?.label ?? id.replaceAll('_', ' '),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => context.go('/onboarding?edit=1'),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit profile'),
        ),
      ],
    );
  }

  Widget _networkingSection(
    BuildContext context,
    NetworkingCard networkingCard,
  ) {
    return _YouSectionCard(
      icon: Icons.badge_outlined,
      title: 'Networking',
      subtitle: 'Share a digital business card via QR at Flo.',
      children: _networkingSectionChildren(context, networkingCard),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileState>().profile;
    final authState = context.watch<AuthState>();
    final showMockLogin =
        RuntimeConfig.mockLoginEnabled && profile.onboardingComplete;
    final networkingCard = profile.networkingCard ?? NetworkingCard.empty;

    return LayoutBuilder(
      builder: (context, constraints) {
        const wideBreakpoint = 900.0;
        final isNarrow = constraints.maxWidth < 520;
        final isWide = constraints.maxWidth >= wideBreakpoint;
        final maxWidth = isWide ? 1040.0 : 560.0;

        final personalization = _personalizationSection(context, profile);
        final networking = _networkingSection(context, networkingCard);
        final demoAccess = showMockLogin
            ? _YouDemoAccessCard(
                authState: authState,
                onSelectTab: widget.onSelectTab,
                organizerTabIndex: widget.organizerTabIndex,
                adminTabIndex: widget.adminTabIndex,
                onPickUser: () => _showMockUserPicker(context),
                organizationLabel: _mockOrganizationLabel(authState),
              )
            : null;

        final sectionBody = isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: personalization),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        networking,
                        ?demoAccess,
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  personalization,
                  const SizedBox(height: 16),
                  networking,
                  ?demoAccess,
                ],
              );

        return SingleChildScrollView(
          controller: profileScrollController,
          padding: EdgeInsets.fromLTRB(20, 20, 20, isNarrow ? 32 : 20),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const GradientTitle('You at Flo'),
                  const SizedBox(height: 8),
                  Text(
                    'Your interests personalize Discover. '
                    'Data stays on this device.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  sectionBody,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileEngagementTab extends StatefulWidget {
  const _ProfileEngagementTab({
    required this.engagement,
    required this.event,
    required this.plan,
    required this.appSettings,
    required this.streakSet,
    required this.unlocked,
    required this.achievementShareKey,
    required this.onDownloadAchievementPng,
  });

  final EngagementState engagement;
  final EventState event;
  final PlanState plan;
  final AppSettingsState appSettings;
  final Set<String> streakSet;
  final List<Achievement> unlocked;
  final GlobalKey achievementShareKey;
  final Future<void> Function() onDownloadAchievementPng;

  @override
  State<_ProfileEngagementTab> createState() => _ProfileEngagementTabState();
}

class _ProfileEngagementTabState extends State<_ProfileEngagementTab>
    with _ProfileScrollReporting {
  @override
  int get profileTabIndex => 1;

  @override
  Widget build(BuildContext context) {
    final engagement = context.watch<EngagementState>();
    final event = widget.event;
    final plan = widget.plan;
    final appSettings = widget.appSettings;
    final unlocked = AchievementService.unlockedFromIds(
      engagement.achievements,
    );
    final trackProgressList = TrackPassportService().compute(
      tracks: event.tracks,
      plannedSessions: plan.plannedSessions(event.sessions),
      allSessions: event.sessions,
      engagement: engagement.snapshot,
    );
    final xpProgress =
        (engagement.xp /
                (engagement.nextMilestone == 0 ? 1 : engagement.nextMilestone))
            .clamp(0.0, 1.0);

    return SingleChildScrollView(
      controller: profileScrollController,
      padding: const EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SettingsSection(
                icon: Icons.bolt_outlined,
                title: 'Engagement',
                children: [
                  Text(
                    '${engagement.levelLabel} · ${engagement.xp}/${engagement.nextMilestone} XP',
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: xpProgress,
                      minHeight: 8,
                      color: AppColors.accentStart,
                    ),
                  ),
                  if (appSettings.leaderboardOptIn) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/leaderboard'),
                      icon: const Icon(Icons.leaderboard_outlined),
                      label: const Text('View mock leaderboard'),
                    ),
                  ],
                ],
              ),
              _SettingsSection(
                icon: Icons.local_fire_department_outlined,
                title: 'Attendance streaks',
                children: [
                  Text(
                    'Tracked automatically when you open sessions each day',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final day in const ['Day 1', 'Day 2', 'Day 3'])
                        _StreakDayIndicator(
                          day: day,
                          attended: widget.streakSet.contains(day),
                        ),
                    ],
                  ),
                ],
              ),
              _SettingsSection(
                icon: Icons.badge_outlined,
                title: 'Track passport',
                children: [
                  Text(
                    'Bookmark or attend 3 sessions per track to fill a ring.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 520;
                      if (isNarrow) {
                        const spacing = 12.0;
                        final itemWidth =
                            (constraints.maxWidth - spacing * 2) / 3;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            for (final trackProgress in trackProgressList)
                              SizedBox(
                                width: itemWidth,
                                child: _TrackPassportRing(
                                  trackProgress: trackProgress,
                                ),
                              ),
                          ],
                        );
                      }

                      return SizedBox(
                        height: 108,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final trackProgress in trackProgressList)
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: _TrackPassportRing(
                                  trackProgress: trackProgress,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              _SettingsSection(
                icon: Icons.extension_outlined,
                title: 'Event tools',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => context.push('/bingo'),
                        icon: const Icon(Icons.grid_view),
                        label: Text(
                          'Session Bingo (${engagement.bingoMarks.length}/25)',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/qr'),
                        icon: const Icon(Icons.qr_code_2),
                        label: const Text('Demo QR posters'),
                      ),
                    ],
                  ),
                ],
              ),
              _SettingsSection(
                icon: Icons.military_tech_outlined,
                title: 'Achievements',
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 520;
                      final shareButton = OutlinedButton.icon(
                        onPressed: unlocked.isEmpty
                            ? null
                            : widget.onDownloadAchievementPng,
                        icon: const Icon(Icons.download),
                        label: const Text('Share PNG'),
                      );

                      if (unlocked.isEmpty) {
                        return Text(
                          'Complete sessions, quests, and event tools to unlock '
                          'achievements. They will appear here.',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        );
                      }

                      final badgeWidth = isNarrow
                          ? null
                          : ((constraints.maxWidth - 8) / 2).clamp(
                              160.0,
                              280.0,
                            );

                      final badges = RepaintBoundary(
                        key: widget.achievementShareKey,
                        child: isNarrow
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final achievement in unlocked) ...[
                                    AchievementBadge(
                                      id: achievement.id,
                                      name: achievement.name,
                                      description: achievement.description,
                                      unlockedAt: DateTime.now(),
                                      width: null,
                                    ),
                                    if (achievement != unlocked.last)
                                      const SizedBox(height: 8),
                                  ],
                                ],
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final achievement in unlocked)
                                    AchievementBadge(
                                      id: achievement.id,
                                      name: achievement.name,
                                      description: achievement.description,
                                      unlockedAt: DateTime.now(),
                                      width: badgeWidth,
                                    ),
                                ],
                              ),
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            shareButton,
                            const SizedBox(height: 12),
                            badges,
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: shareButton,
                          ),
                          const SizedBox(height: 8),
                          badges,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackPassportRing extends StatelessWidget {
  const _TrackPassportRing({required this.trackProgress});

  final TrackPassportProgress trackProgress;

  @override
  Widget build(BuildContext context) {
    final shortLabel = trackShortLabel(trackProgress.trackName);
    return Semantics(
      label:
          '${trackProgress.trackName}: '
          '${trackProgress.combinedCount} of ${trackProgress.target} sessions',
      child: Tooltip(
        message: trackProgress.trackName,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                value: trackProgress.progress,
                strokeWidth: 5,
                color: AppTheme.colorForTrack(trackProgress.trackId),
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 88,
              child: Text(
                shortLabel,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              ),
            ),
            Text(
              '${trackProgress.combinedCount}/${trackProgress.target}',
              style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSettingsTab extends StatefulWidget {
  const _ProfileSettingsTab({
    required this.profileState,
    required this.appSettings,
    required this.l10n,
    required this.pushSupported,
    required this.pushPermissionDenied,
    required this.onRefreshPushPermission,
  });

  final ProfileState profileState;
  final AppSettingsState appSettings;
  final AppLocalizations l10n;
  final bool pushSupported;
  final bool pushPermissionDenied;
  final Future<void> Function() onRefreshPushPermission;

  @override
  State<_ProfileSettingsTab> createState() => _ProfileSettingsTabState();
}

class _ProfileSettingsTabState extends State<_ProfileSettingsTab>
    with _ProfileScrollReporting {
  @override
  int get profileTabIndex => 2;

  _SettingsGroup _selectedGroup = _SettingsGroup.appearance;

  static const _themeInfoBody =
      'System follows your device light or dark setting. '
      'High contrast overrides with black background, white text, '
      'and yellow focus rings.';

  static const _attendanceInfoBody =
      'Remote mode emphasizes stream CTAs and hides walk directions on session detail.';

  static const _eventDayInfoBody =
      'Auto activates during Flo 2026 event days (Nov 4–6). '
      'On keeps the Now/Next bar always visible for demos.';

  static const _keyboardShortcutsBody =
      'Cmd/Ctrl+K — command palette\n'
      'Press 1–4 to switch tabs (when not typing)\n'
      '1 Discover · 2 Companion · 3 My Plan · 4 Profile\n'
      'Discover filter chips — Tab to focus, Left/Right arrow keys to move, Enter/Space toggle\n'
      'Clear all is first in chip tab order';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 240, child: _buildSectionList(isWide: true)),
              const VerticalDivider(width: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: profileScrollController,
                  padding: const EdgeInsets.all(20),
                  child: _buildDetailPane(
                    _buildGroupContent(_selectedGroup, isWide: true),
                  ),
                ),
              ),
            ],
          );
        }

        return SingleChildScrollView(
          controller: profileScrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final group in _SettingsGroup.values)
                if (group == _SettingsGroup.advanced)
                  _buildAdvancedExpansion()
                else
                  _buildGroupContent(group, isWide: false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailPane(Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: child,
      ),
    );
  }

  Widget _buildSectionList({required bool isWide}) {
    return Material(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final group in _SettingsGroup.values)
            ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              selected: _selectedGroup == group,
              selectedTileColor: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.35),
              leading: Icon(_groupIcon(group)),
              title: Text(_groupTitle(group)),
              onTap: () => setState(() => _selectedGroup = group),
            ),
        ],
      ),
    );
  }

  IconData _groupIcon(_SettingsGroup group) {
    return switch (group) {
      _SettingsGroup.appearance => Icons.palette_outlined,
      _SettingsGroup.eventExperience => Icons.event_outlined,
      _SettingsGroup.notifications => Icons.notifications_outlined,
      _SettingsGroup.community => Icons.groups_outlined,
      _SettingsGroup.accountRoles => Icons.person_outline,
      _SettingsGroup.about => Icons.info_outline,
      _SettingsGroup.advanced => Icons.tune_outlined,
    };
  }

  String _groupTitle(_SettingsGroup group) {
    final l10n = widget.l10n;
    return switch (group) {
      _SettingsGroup.appearance => l10n.profileAppearanceSection,
      _SettingsGroup.eventExperience => l10n.profileEventExperienceSection,
      _SettingsGroup.notifications => l10n.profileNotificationsSection,
      _SettingsGroup.community => 'Community',
      _SettingsGroup.accountRoles => 'Account and roles',
      _SettingsGroup.about => 'About',
      _SettingsGroup.advanced => 'Advanced',
    };
  }

  Widget _buildGroupContent(_SettingsGroup group, {required bool isWide}) {
    return switch (group) {
      _SettingsGroup.appearance => _buildAppearanceSection(),
      _SettingsGroup.eventExperience => _buildEventExperienceSection(),
      _SettingsGroup.notifications => _buildNotificationsSection(),
      _SettingsGroup.community => _buildCommunitySection(),
      _SettingsGroup.accountRoles => _buildAccountRolesSection(),
      _SettingsGroup.about => _buildAboutSection(),
      _SettingsGroup.advanced =>
        isWide ? _buildAdvancedSection() : const SizedBox.shrink(),
    };
  }

  Widget _buildAppearanceSection() {
    final appSettings = widget.appSettings;
    final l10n = widget.l10n;

    return _SettingsSection(
      icon: Icons.palette_outlined,
      title: l10n.profileAppearanceSection,
      children: [
        Semantics(
          label: 'Theme appearance',
          child: _SettingChoice<AppThemeMode>(
            title: l10n.profileTheme,
            subtitle: l10n.profileThemeSubtitle,
            infoTitle: l10n.profileTheme,
            infoBody: _themeInfoBody,
            segments: [
              ButtonSegment(
                value: AppThemeMode.system,
                label: Text(l10n.profileThemeSystem),
              ),
              ButtonSegment(
                value: AppThemeMode.light,
                label: Text(l10n.profileThemeLight),
              ),
              ButtonSegment(
                value: AppThemeMode.dark,
                label: Text(l10n.profileThemeDark),
              ),
              ButtonSegment(
                value: AppThemeMode.highContrast,
                label: Text(l10n.profileThemeHighContrast),
              ),
            ],
            selected: appSettings.themeMode,
            onChanged: appSettings.setThemeMode,
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: appSettings.useDyslexiaFont,
          onChanged: appSettings.setUseDyslexiaFont,
          title: Text(l10n.profileDyslexiaFont),
          subtitle: Text(l10n.profileDyslexiaFontSubtitle),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: appSettings.showPlainEnglishCards,
          onChanged: appSettings.setShowPlainEnglishCards,
          title: Text(l10n.profilePlainEnglish),
          subtitle: Text(l10n.profilePlainEnglishSubtitle),
        ),
        _SettingChoice<String>(
          title: l10n.localeLabel,
          segments: [
            ButtonSegment(value: 'en', label: Text(l10n.localeEn)),
            ButtonSegment(value: 'de', label: Text(l10n.localeDe)),
            ButtonSegment(value: 'es', label: Text(l10n.localeEs)),
          ],
          selected: appSettings.localeCode ?? 'en',
          onChanged: appSettings.setLocaleCode,
        ),
      ],
    );
  }

  Widget _buildEventExperienceSection() {
    final appSettings = widget.appSettings;
    final profileState = widget.profileState;
    final l10n = widget.l10n;

    return _SettingsSection(
      icon: Icons.event_outlined,
      title: l10n.profileEventExperienceSection,
      children: [
        _SettingChoice<AttendanceMode>(
          title: l10n.profileAttendanceMode,
          subtitle: l10n.profileAttendanceModeSubtitle,
          infoTitle: l10n.profileAttendanceMode,
          infoBody: _attendanceInfoBody,
          segments: [
            ButtonSegment(
              value: AttendanceMode.onSite,
              label: Text(l10n.profileAttendanceOnSite),
              icon: const Icon(Icons.location_on_outlined),
            ),
            ButtonSegment(
              value: AttendanceMode.remote,
              label: Text(l10n.profileAttendanceRemote),
              icon: const Icon(Icons.live_tv_outlined),
            ),
          ],
          selected: profileState.profile.attendanceMode,
          onChanged: profileState.setAttendanceMode,
        ),
        _SettingChoice<EventDayMode>(
          title: l10n.profileEventDayMode,
          subtitle: l10n.profileEventDayModeSubtitle,
          infoTitle: l10n.profileEventDayMode,
          infoBody: _eventDayInfoBody,
          segments: [
            ButtonSegment(
              value: EventDayMode.auto,
              label: Text(l10n.profileEventDayAuto),
            ),
            ButtonSegment(
              value: EventDayMode.on,
              label: Text(l10n.profileEventDayOn),
            ),
            ButtonSegment(
              value: EventDayMode.off,
              label: Text(l10n.profileEventDayOff),
            ),
          ],
          selected: appSettings.eventDayMode,
          onChanged: appSettings.setEventDayMode,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: appSettings.isLowBandwidth,
          onChanged: appSettings.setLowBandwidth,
          title: Text(l10n.profileLowBandwidth),
          subtitle: Text(l10n.profileLowBandwidthSubtitle),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    final appSettings = widget.appSettings;
    final l10n = widget.l10n;

    return _SettingsSection(
      icon: Icons.notifications_outlined,
      title: l10n.profileNotificationsSection,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: appSettings.agendaChangeAlertsEnabled,
          onChanged: (value) async {
            await appSettings.setAgendaChangeAlertsEnabled(value);
            if (!mounted) return;
            if (!value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.profileAgendaChangeAlertsDisabledSnack),
                ),
              );
            }
          },
          title: Text(l10n.profileAgendaChangeAlerts),
          subtitle: Text(l10n.profileAgendaChangeAlertsSubtitle),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: appSettings.agendaChangePushEnabled,
          onChanged: null,
          title: Text(l10n.profileAgendaChangePush),
          subtitle: Text(l10n.profileAgendaChangePushSubtitle),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: appSettings.leaveNowPushEnabled,
          onChanged: !widget.pushSupported || widget.pushPermissionDenied
              ? null
              : (value) async {
                  final enabled = await appSettings.setLeaveNowPushEnabled(
                    value,
                  );
                  if (!mounted) return;
                  if (value && !enabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.profileNotificationPermissionDeniedSnack,
                        ),
                      ),
                    );
                  }
                  await widget.onRefreshPushPermission();
                },
          title: Text(l10n.profileLeaveNowReminders),
          subtitle: Text(
            !widget.pushSupported
                ? l10n.profileLeaveNowReminderUnsupported
                : widget.pushPermissionDenied
                ? l10n.profileLeaveNowReminderDenied
                : l10n.profileLeaveNowReminderEnabled,
          ),
        ),
      ],
    );
  }

  Widget _buildCommunitySection() {
    final appSettings = widget.appSettings;

    return _SettingsSection(
      icon: Icons.groups_outlined,
      title: 'Community',
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: appSettings.leaderboardOptIn,
          onChanged: (value) async {
            if (value && !requireAuth(context, AppCapability.earnXp)) {
              return;
            }
            await appSettings.setLeaderboardOptIn(value);
            if (!mounted) return;
            if (value) context.push('/leaderboard');
          },
          title: const Text('Show mock leaderboard'),
          subtitle: const Text(
            'Demo rankings with fictional names — not real attendees.',
          ),
        ),
      ],
    );
  }

  Widget _buildAccountRolesSection() {
    final l10n = widget.l10n;
    final authState = context.watch<AuthState>();
    final canOpenOrganizer = authState.hasCapability(AppCapability.moderateQa);
    final canOpenAdmin = authState.hasCapability(AppCapability.manageOpsConfig);

    return _SettingsSection(
      icon: Icons.person_outline,
      title: 'Account and roles',
      children: [
        if (authState.isEnabled && !RuntimeConfig.mockLoginEnabled) ...[
          if (authState.isAuthenticated)
            Text(l10n.profileSignedInAs(authState.displayName ?? ''))
          else
            Text(
              'Sign in to earn XP and join the mock leaderboard.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          const SizedBox(height: 8),
          if (authState.isAuthenticated)
            OutlinedButton(
              onPressed: authState.logout,
              child: Text(l10n.profileLogout),
            )
          else
            FilledButton(
              onPressed: authState.beginLogin,
              child: Text(l10n.profileLogin),
            ),
          const SizedBox(height: 8),
          Text(
            'Account data is linked to your identity when signed in.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
        if (AppConfig.configProfile == 'dev') ...[
          Text(
            'Platform role: ${authState.platformRole.label}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 8),
        ],
        if (canOpenOrganizer || canOpenAdmin) ...[
          Text(
            'Organizer and admin tools are available in dedicated Profile tabs when your role allows.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ] else ...[
          Text(
            'Operations tools appear here when your platform role is organizer or admin.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _buildAboutSection() {
    final l10n = widget.l10n;

    return _SettingsSection(
      icon: Icons.info_outline,
      title: 'About',
      children: [
        Text(
          l10n.aboutVersion('1.0.0', BuildInfo.buildSha),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        if (AppConfig.configProfile == 'dev') ...[
          const SizedBox(height: 8),
          Text(
            'Config profile: ${AppConfig.configProfile}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedSection() {
    return Semantics(
      container: true,
      label: 'Advanced settings',
      child: _SettingsSection(
        icon: Icons.tune_outlined,
        title: 'Advanced',
        children: [_buildAdvancedContent()],
      ),
    );
  }

  Widget _buildAdvancedExpansion() {
    return Semantics(
      container: true,
      label: 'Advanced settings',
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: ExpansionTile(
          leading: const Icon(Icons.tune_outlined),
          title: const Text('Advanced'),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildAdvancedContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedContent() {
    final profileState = widget.profileState;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingRow(
          title: 'Keyboard shortcuts',
          subtitle: 'Cmd/Ctrl+K opens the command palette.',
          trailing: _SettingInfoButton(
            title: 'Keyboard shortcuts',
            body: _keyboardShortcutsBody,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => replayProductTour(context),
          child: Text(widget.l10n.replayTour),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => context.push('/recap'),
          child: const Text('Open recap'),
        ),
        const SizedBox(height: 12),
        const Divider(),
        const AnalyticsDiagnosticsPanel(),
        const SizedBox(height: 12),
        const Divider(),
        Text('Danger zone', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        _DestructiveButton(
          label: 'Reset progress',
          onPressed: () => _confirmResetProgress(context),
        ),
        const SizedBox(height: 12),
        _DestructiveButton(
          label: 'Clear navigation history',
          onPressed: () => _confirmClearNavigationHistory(context),
        ),
        const SizedBox(height: 12),
        _DestructiveButton(
          label: 'Reset onboarding',
          semanticsLabel: 'Reset onboarding',
          onPressed: () => _confirmResetOnboarding(context, profileState),
        ),
      ],
    );
  }

  Future<void> _confirmResetProgress(BuildContext context) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Reset progress?',
      message:
          'Clears XP, achievements, streaks, and bingo progress. Cannot be undone.',
    );
    if (confirmed && context.mounted) {
      await context.read<EngagementState>().reset();
    }
  }

  Future<void> _confirmResetOnboarding(
    BuildContext context,
    ProfileState profileState,
  ) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Reset onboarding?',
      message: 'Clears your profile and progress, then returns to onboarding.',
    );
    if (!confirmed || !context.mounted) return;
    await profileState.resetOnboarding();
    if (context.mounted) context.go('/onboarding');
  }

  Future<void> _confirmClearNavigationHistory(BuildContext context) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Clear navigation history?',
      message: 'Clears recent routes used by the command palette.',
      confirmLabel: 'Clear',
    );
    if (!confirmed || !context.mounted) return;
    await NavigationHistoryService().clear();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Navigation history cleared')));
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.accentStart),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
    );
  }
}

class _DestructiveButton extends StatelessWidget {
  const _DestructiveButton({
    required this.label,
    required this.onPressed,
    this.semanticsLabel,
  });

  final String label;
  final VoidCallback onPressed;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final button = FilledButton.tonal(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.errorContainer,
        foregroundColor: colorScheme.onErrorContainer,
      ),
      onPressed: onPressed,
      child: Text(label),
    );

    if (semanticsLabel == null) return button;
    return Semantics(label: semanticsLabel, button: true, child: button);
  }
}

void _showSettingInfoSheet(
  BuildContext context, {
  required String title,
  required String body,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Text(body, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    ),
  );
}

class _SettingInfoButton extends StatelessWidget {
  const _SettingInfoButton({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info_outline, size: 20),
      tooltip: 'More info about $title',
      onPressed: () => _showSettingInfoSheet(context, title: title, body: body),
    );
  }
}

class _SettingChoice<T> extends StatelessWidget {
  const _SettingChoice({
    required this.title,
    this.subtitle,
    this.infoTitle,
    this.infoBody,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.forceDropdownWhenSegments = 4,
  });

  final String title;
  final String? subtitle;
  final String? infoTitle;
  final String? infoBody;
  final List<ButtonSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final int forceDropdownWhenSegments;

  String _segmentLabel(ButtonSegment<T> segment) {
    final label = segment.label;
    if (label is Text) {
      return label.data ?? segment.value.toString();
    }
    return segment.value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useDropdown =
            constraints.maxWidth < 420 ||
            segments.length >= forceDropdownWhenSegments;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (infoBody != null)
                  _SettingInfoButton(
                    title: infoTitle ?? title,
                    body: infoBody!,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (useDropdown)
              DropdownMenu<T>(
                initialSelection: selected,
                expandedInsets: EdgeInsets.zero,
                onSelected: (value) {
                  if (value != null) onChanged(value);
                },
                dropdownMenuEntries: [
                  for (final segment in segments)
                    DropdownMenuEntry<T>(
                      value: segment.value,
                      label: _segmentLabel(segment),
                    ),
                ],
              )
            else
              SegmentedButton<T>(
                segments: segments,
                selected: {selected},
                onSelectionChanged: (selection) => onChanged(selection.first),
              ),
          ],
        );
      },
    );
  }
}

class _StreakDayIndicator extends StatelessWidget {
  const _StreakDayIndicator({required this.day, required this.attended});

  final String day;
  final bool attended;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: attended ? '$day attended' : '$day not yet',
      child: InputChip(
        label: Text(day),
        avatar: attended ? const Icon(Icons.check, size: 18) : null,
        onPressed: null,
        backgroundColor: attended
            ? AppColors.accentStart.withValues(alpha: 0.2)
            : null,
      ),
    );
  }
}
