import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/models.dart';
import '../../data/services/plan_share_service.dart';
import '../../providers/event_provider.dart';
import '../../providers/plan_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/friendly_error_messages.dart';
import '../../shared/widgets/shared_widgets.dart';

enum _ImportChoice { merge, replace, cancel }

class PlanImportScreen extends StatefulWidget {
  const PlanImportScreen({super.key, required this.payload});

  final String payload;

  @override
  State<PlanImportScreen> createState() => _PlanImportScreenState();
}

class _PlanImportScreenState extends State<PlanImportScreen> {
  final _shareService = PlanShareService();
  bool _dialogShown = false;

  List<String> get _ids => _shareService.decodeSessionIds(widget.payload);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _promptImportChoice());
  }

  Future<void> _promptImportChoice() async {
    if (!mounted || _dialogShown || _ids.isEmpty) return;
    _dialogShown = true;
    final event = context.read<EventState>();
    final ids = _ids;
    final previewTitles = ids
        .map(event.sessionById)
        .whereType<Session>()
        .take(3)
        .map((session) => session.title)
        .toList();
    final choice = await showDialog<_ImportChoice>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Import plan from a shared link?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${ids.length} session${ids.length == 1 ? '' : 's'} in this share. '
              'Merge adds to your bookmarks; Replace overwrites your current plan.',
            ),
            if (previewTitles.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final title in previewTitles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $title'),
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(ctx, _ImportChoice.cancel),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, _ImportChoice.merge),
            child: const Text('Merge'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _ImportChoice.replace),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    if (!mounted || choice == null || choice == _ImportChoice.cancel) return;
    await _applyImport(choice);
  }

  Future<void> _applyImport(_ImportChoice choice) async {
    final plan = context.read<PlanState>();
    final event = context.read<EventState>();
    final result = switch (choice) {
      _ImportChoice.merge => await plan.mergeSessions(_ids),
      _ImportChoice.replace => await plan.replaceSessions(_ids),
      _ImportChoice.cancel => null,
    };
    if (!mounted || result == null) return;

    final messenger = ScaffoldMessenger.of(context);
    if (choice == _ImportChoice.merge) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Added ${result.importedCount} session'
            '${result.importedCount == 1 ? '' : 's'} '
            '(${result.newCount} new)',
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Replaced plan with ${result.importedCount} session'
            '${result.importedCount == 1 ? '' : 's'}',
          ),
        ),
      );
    }

    final conflicts = plan.conflicts(event.sessions);
    if (conflicts.isNotEmpty && mounted) {
      await showPlanConflictSummarySheet(context, conflicts: conflicts);
    }
  }

  Widget _invalidShareEmptyState() {
    final copy = FriendlyErrorCopy.random(FriendlyErrorKind.invalidShareLink);
    return EmptyState(
      title: copy.title,
      message: copy.message,
      icon: Icons.link_off,
      semanticsLabel: copy.semanticLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = context.watch<EventState>();
    final ids = _ids;
    final sessions = ids.map(event.sessionById).whereType().toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Import shared plan')),
      body: ResponsiveLayout(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ids.isEmpty
              ? _invalidShareEmptyState()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('A colleague shared their plan.'),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        children: [
                          for (final session in sessions)
                            ListTile(
                              title: Text(session.title),
                              subtitle: Text(
                                '${session.day} · ${session.startTime}',
                              ),
                              onTap: () =>
                                  context.push('/session/${session.id}'),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _applyImport(_ImportChoice.merge),
                            child: const Text('Merge'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () =>
                                _applyImport(_ImportChoice.replace),
                            child: const Text('Replace'),
                          ),
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

Future<void> showPlanConflictSummarySheet(
  BuildContext context, {
  required List<PlanConflict> conflicts,
}) async {
  final count = conflicts.length;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final conflictTheme = AppTheme.conflictTheme(ctx);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(conflictTheme.icon, color: conflictTheme.border),
                  const SizedBox(width: 8),
                  Text(
                    '$count time conflict${count == 1 ? '' : 's'} detected',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final conflict in conflicts.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '• ${conflict.sessionA.title} overlaps ${conflict.sessionB.title}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              if (count > 5)
                Text(
                  '…and ${count - 5} more',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    ctx.pop();
                    context.go('/my-plan');
                  },
                  child: const Text('Review in My Plan'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
