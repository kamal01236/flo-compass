import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/organizer_dashboard_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/common/common_widgets.dart';
import '../../shared/widgets/shared_widgets.dart';

class OrganizerOperationsPanel extends StatefulWidget {
  const OrganizerOperationsPanel({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  State<OrganizerOperationsPanel> createState() =>
      _OrganizerOperationsPanelState();
}

class _OrganizerOperationsPanelState extends State<OrganizerOperationsPanel> {
  late final ScrollController _scrollController;

  ScrollController get _effectiveController =>
      widget.scrollController ?? _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _reload();
    });
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  Future<void> _reload() async {
    await Future.wait([
      context.read<OrganizerDashboardState>().load(),
      context.read<AnnouncementState>().load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<OrganizerDashboardState>();
    final announcements = context.watch<AnnouncementState>();
    final stats = dashboard.stats;
    final loadingStats = dashboard.loading && stats == null;

    return ResponsiveLayout(
      child: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          controller: _effectiveController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Flo Compass organizer tools',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'This area controls Flo overlays only. Official agenda records stay in Accelevents.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            if (dashboard.error != null) ...[
              const SizedBox(height: 16),
              ErrorView(
                technicalDetail: dashboard.error,
                onRetry: () => dashboard.load(),
              ),
            ],
            if (announcements.error != null) ...[
              const SizedBox(height: 16),
              ErrorView(
                technicalDetail: announcements.error,
                onRetry: () => announcements.load(),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatChip(
                  label: 'Pending Q&A',
                  value: loadingStats ? null : '${stats?.pendingCount ?? '—'}',
                ),
                _StatChip(
                  label: 'Hidden questions',
                  value: loadingStats ? null : '${stats?.hiddenCount ?? '—'}',
                ),
                _StatChip(
                  label: 'Published notices',
                  value:
                      announcements.loading &&
                          announcements.announcements.isEmpty
                      ? null
                      : '${announcements.recentPublishedCount}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _OpsTile(
              icon: Icons.forum_outlined,
              title: 'Q&A moderation',
              subtitle:
                  '${stats?.pendingCount ?? 0} unanswered · ${stats?.hiddenCount ?? 0} hidden',
              onTap: () => context.push(AppRoutes.organizerQa),
            ),
            _OpsTile(
              icon: Icons.campaign_outlined,
              title: 'Announcements',
              subtitle:
                  '${announcements.recentPublishedCount} published · compose and archive overlay notices',
              onTap: () => context.push(AppRoutes.organizerAnnouncements),
            ),
            _OpsTile(
              icon: Icons.meeting_room_outlined,
              title: 'Match rooms',
              subtitle: 'Compose and publish Flo Meets rooms for attendees',
              onTap: () => context.push(AppRoutes.organizerMeetRooms),
            ),
            _OpsTile(
              icon: Icons.psychology_alt_outlined,
              title: 'Prompt curation',
              subtitle: 'Edit guided Session Q&A prompts used by attendees',
              onTap: () => context.push(AppRoutes.organizerPrompts),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final loading = value == null;
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: AppColors.accentStart.withValues(alpha: 0.15),
        child: loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                value!,
                style: const TextStyle(
                  color: AppColors.accentStart,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
      ),
      label: Text(label),
    );
  }
}

class _OpsTile extends StatelessWidget {
  const _OpsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
