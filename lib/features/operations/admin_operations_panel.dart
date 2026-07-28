import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/platform_role.dart';
import '../../core/config/app_config.dart';
import '../../core/config/feature_flags.dart';
import '../../core/config/runtime_config.dart';
import '../../data/services/ops_audit_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ops_config_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/common/common_widgets.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'widgets/audit_event_tile.dart';

class AdminOperationsPanel extends StatefulWidget {
  const AdminOperationsPanel({
    super.key,
    this.scrollController,
    this.auditService,
  });

  final ScrollController? scrollController;
  final OpsAuditService? auditService;

  @override
  State<AdminOperationsPanel> createState() => _AdminOperationsPanelState();
}

class _AdminOperationsPanelState extends State<AdminOperationsPanel> {
  late final ScrollController _scrollController;
  late final TextEditingController _organizerController;
  late final TextEditingController _adminController;
  late final OpsAuditService _auditService;
  List<AuditEvent> _auditEntries = [];
  bool _auditLoading = true;
  bool _controllersSynced = false;

  ScrollController get _effectiveController =>
      widget.scrollController ?? _scrollController;

  @override
  void initState() {
    super.initState();
    _auditService = widget.auditService ?? OpsAuditService();
    _scrollController = ScrollController();
    _organizerController = TextEditingController();
    _adminController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _reloadAudit();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllersSynced) return;
    final opsConfig = context.read<OpsConfigState>();
    _organizerController.text = opsConfig.organizerAllowlist.join('\n');
    _adminController.text = opsConfig.adminAllowlist.join('\n');
    _controllersSynced = true;
  }

  @override
  void dispose() {
    _organizerController.dispose();
    _adminController.dispose();
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  Future<void> _reloadAudit() async {
    setState(() => _auditLoading = true);
    final entries = await _auditService.loadRecent();
    if (!mounted) return;
    setState(() {
      _auditEntries = entries;
      _auditLoading = false;
    });
  }

  Set<String> _parseLines(String raw) {
    return raw
        .split(RegExp(r'[\n,;]+'))
        .map((entry) => entry.trim().toLowerCase())
        .where((entry) => entry.isNotEmpty)
        .toSet();
  }

  Future<void> _saveAllowlists() async {
    final auth = context.read<AuthState>();
    final opsConfig = context.read<OpsConfigState>();
    final actor = auth.displayName ?? auth.platformRole.label;
    await opsConfig.saveAllowlists(
      organizer: _parseLines(_organizerController.text),
      admin: _parseLines(_adminController.text),
      actor: actor,
    );
    if (!mounted) return;
    if (opsConfig.error == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Role allowlists saved')));
      await _reloadAudit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final opsConfig = context.watch<OpsConfigState>();
    final flags = RuntimeConfig.flags;
    final isProd = AppConfig.configProfile == 'prod';

    return ResponsiveLayout(
      child: ListView(
        controller: _effectiveController,
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Flo Compass admin tools',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Admin actions are limited to Flo overlay governance and never edit the official agenda.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Current role: ${auth.platformRole.label}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Text(
            'Role allowlists',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'One email or user id per line. Dev/demo overrides only — production roles come from identity provider claims.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _organizerController,
            decoration: const InputDecoration(
              labelText: 'Organizer allowlist',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            minLines: 3,
            maxLines: 6,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _adminController,
            decoration: const InputDecoration(
              labelText: 'Admin allowlist',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            minLines: 3,
            maxLines: 6,
          ),
          const SizedBox(height: 12),
          if (opsConfig.error != null) ...[
            ErrorView(technicalDetail: opsConfig.error),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            onPressed: opsConfig.loading ? null : _saveAllowlists,
            icon: opsConfig.loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Save allowlists'),
          ),
          const SizedBox(height: 24),
          Text('Feature flags', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Read-only summary from the active config profile.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ..._featureFlagTiles(context, flags, prodLocked: isProd),
          const SizedBox(height: 24),
          Text('Audit log', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Recent overlay ops actions (last ${OpsAuditService.maxEntries}).',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 12),
          if (_auditLoading)
            const Center(child: CircularProgressIndicator())
          else if (_auditEntries.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.history_outlined),
                title: Text('No audit entries yet'),
                subtitle: Text(
                  'Moderation, announcements, and allowlist saves appear here.',
                ),
              ),
            )
          else
            ..._auditEntries.map((entry) => AuditEventTile(entry: entry)),
        ],
      ),
    );
  }
}

List<Widget> _featureFlagTiles(
  BuildContext context,
  FeatureFlags flags, {
  required bool prodLocked,
}) {
  final muted = Theme.of(context).colorScheme.onSurfaceVariant;
  final entries = <MapEntry<String, bool>>[
    MapEntry('leaderboard', flags.leaderboard),
    MapEntry('bingo', flags.bingo),
    MapEntry('recap', flags.recap),
    MapEntry('companionLlm', flags.companionLlm),
    MapEntry('lowBandwidthDefault', flags.lowBandwidthDefault),
  ];
  return entries
      .map(
        (entry) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              entry.value ? Icons.toggle_on : Icons.toggle_off_outlined,
              color: entry.value ? AppColors.accentStart : muted,
            ),
            title: Text(entry.key),
            subtitle: Text(
              prodLocked
                  ? 'Locked in production config'
                  : (entry.value ? 'Enabled' : 'Disabled'),
            ),
          ),
        ),
      )
      .toList();
}
