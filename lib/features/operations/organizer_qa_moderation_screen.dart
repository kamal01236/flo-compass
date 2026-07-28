import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/app_capability.dart';
import '../../../core/routing/app_routes.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/organizer_dashboard_provider.dart';
import '../../../shared/auth/capability_guard.dart';
import '../../../shared/widgets/shared_widgets.dart';

class OrganizerQaModerationScreen extends StatefulWidget {
  const OrganizerQaModerationScreen({super.key});

  @override
  State<OrganizerQaModerationScreen> createState() =>
      _OrganizerQaModerationScreenState();
}

class _OrganizerQaModerationScreenState
    extends State<OrganizerQaModerationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OrganizerDashboardState>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final dashboard = context.watch<OrganizerDashboardState>();
    final event = context.watch<EventState>();
    final pendingBySession = dashboard.stats?.pendingBySession ?? {};

    return CapabilityGuard(
      capability: AppCapability.moderateQa,
      authState: auth,
      child: Scaffold(
        appBar: AppBar(title: const Text('Q&A moderation')),
        body: ResponsiveLayout(
          child: dashboard.loading && dashboard.stats == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      '${dashboard.stats?.pendingCount ?? 0} unanswered questions across ${pendingBySession.length} sessions',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    if (pendingBySession.isEmpty)
                      const Card(
                        child: ListTile(
                          leading: Icon(Icons.check_circle_outline),
                          title: Text('No pending questions'),
                          subtitle: Text(
                            'Open any session detail to pin, hide, or mark answered.',
                          ),
                        ),
                      )
                    else
                      ...pendingBySession.entries.map((entry) {
                        final session = event.sessionById(entry.key);
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.forum_outlined),
                            title: Text(session?.title ?? entry.key),
                            subtitle: Text('${entry.value} pending'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push(
                              '${AppRoutes.session(entry.key)}?focus=qa',
                            ),
                          ),
                        );
                      }),
                  ],
                ),
        ),
      ),
    );
  }
}
