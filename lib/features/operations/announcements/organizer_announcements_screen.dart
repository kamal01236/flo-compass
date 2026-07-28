import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/app_capability.dart';
import '../../../core/routing/app_routes.dart';
import '../../../domain/entities/organizer_announcement.dart';
import '../../../providers/announcement_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/auth/capability_guard.dart';
import '../../../shared/widgets/shared_widgets.dart';

class OrganizerAnnouncementsScreen extends StatefulWidget {
  const OrganizerAnnouncementsScreen({super.key});

  @override
  State<OrganizerAnnouncementsScreen> createState() =>
      _OrganizerAnnouncementsScreenState();
}

class _OrganizerAnnouncementsScreenState
    extends State<OrganizerAnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AnnouncementState>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final announcements = context.watch<AnnouncementState>();

    return CapabilityGuard(
      capability: AppCapability.publishAnnouncement,
      authState: auth,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Announcements'),
          actions: [
            IconButton(
              tooltip: 'Compose announcement',
              onPressed: () =>
                  context.push(AppRoutes.organizerAnnouncementCompose),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: ResponsiveLayout(
          child: announcements.loading && announcements.announcements.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : announcements.announcements.isEmpty
              ? _EmptyState(
                  onCompose: () =>
                      context.push(AppRoutes.organizerAnnouncementCompose),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: announcements.announcements.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = announcements.announcements[index];
                    return _AnnouncementCard(
                      announcement: item,
                      onTap: () => context.push(
                        AppRoutes.organizerAnnouncementDetail(item.id),
                      ),
                      onPublish: item.status == AnnouncementStatus.draft
                          ? () => _publish(context, item.id)
                          : null,
                      onArchive: item.status == AnnouncementStatus.published
                          ? () => _archive(context, item.id)
                          : null,
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _publish(BuildContext context, String id) async {
    await context.read<AnnouncementState>().publish(id);
  }

  Future<void> _archive(BuildContext context, String id) async {
    await context.read<AnnouncementState>().archive(id);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCompose});

  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.campaign_outlined, size: 48),
            const SizedBox(height: 12),
            const Text('No announcements yet'),
            const SizedBox(height: 8),
            Text(
              'Compose overlay notices for attendees. Official agenda stays in Accelevents.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCompose,
              icon: const Icon(Icons.add),
              label: const Text('Compose'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
    required this.onTap,
    this.onPublish,
    this.onArchive,
  });

  final OrganizerAnnouncement announcement;
  final VoidCallback onTap;
  final VoidCallback? onPublish;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(announcement.title),
        subtitle: Text(
          '${announcement.status.label} · ${announcement.body}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onPublish != null)
              TextButton(onPressed: onPublish, child: const Text('Publish')),
            if (onArchive != null)
              TextButton(onPressed: onArchive, child: const Text('Archive')),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
