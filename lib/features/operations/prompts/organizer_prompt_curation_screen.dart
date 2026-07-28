import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/app_capability.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/prompt_curation_provider.dart';
import '../../../shared/auth/capability_guard.dart';
import '../../../shared/widgets/shared_widgets.dart';

class OrganizerPromptCurationScreen extends StatefulWidget {
  const OrganizerPromptCurationScreen({super.key});

  @override
  State<OrganizerPromptCurationScreen> createState() =>
      _OrganizerPromptCurationScreenState();
}

class _OrganizerPromptCurationScreenState
    extends State<OrganizerPromptCurationScreen> {
  String? _selectedSessionId;
  final _controllers = <int, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<PromptCurationState>().load();
      _selectFirstSession();
    });
  }

  void _selectFirstSession() {
    final sets = context.read<PromptCurationState>().promptSets;
    if (sets.isEmpty) return;
    _selectSession(sets.keys.first);
  }

  void _selectSession(String sessionId) {
    final prompts =
        context.read<PromptCurationState>().promptSets[sessionId] ?? const [];
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    for (var i = 0; i < prompts.length; i++) {
      _controllers[i] = TextEditingController(text: prompts[i]);
    }
    if (_controllers.isEmpty) {
      _controllers[0] = TextEditingController();
    }
    setState(() => _selectedSessionId = sessionId);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final curation = context.watch<PromptCurationState>();
    final event = context.watch<EventState>();
    final sessionIds = curation.promptSets.keys.toList()..sort();

    return CapabilityGuard(
      capability: AppCapability.moderateQa,
      authState: auth,
      child: Scaffold(
        appBar: AppBar(title: const Text('Prompt curation')),
        body: ResponsiveLayout(
          child: curation.loading && sessionIds.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 280,
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          const Text(
                            'Sessions with prompts',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          for (final sessionId in sessionIds)
                            ListTile(
                              selected: _selectedSessionId == sessionId,
                              title: Text(
                                event.sessionById(sessionId)?.title ??
                                    sessionId,
                              ),
                              subtitle: Text(
                                '${curation.promptSets[sessionId]?.length ?? 0} prompts',
                              ),
                              onTap: () => _selectSession(sessionId),
                            ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: _buildEditor(context, curation)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEditor(BuildContext context, PromptCurationState curation) {
    final sessionId = _selectedSessionId;
    if (sessionId == null) {
      return const Center(child: Text('Select a session to edit prompts'));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Guided prompts appear in Session Q&A chips. Changes stay in Flo overlays only.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        for (final entry
            in _controllers.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key)))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: entry.value,
              decoration: InputDecoration(
                labelText: 'Prompt ${entry.key + 1}',
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              final nextIndex = _controllers.isEmpty
                  ? 0
                  : _controllers.keys.reduce((a, b) => a > b ? a : b) + 1;
              _controllers[nextIndex] = TextEditingController();
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Add prompt'),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: () => _save(context, sessionId),
              child: const Text('Save prompts'),
            ),
            OutlinedButton(
              onPressed: () async {
                await curation.resetSessionPrompts(sessionId);
                if (!context.mounted) return;
                _selectSession(sessionId);
              },
              child: const Text('Reset to seed'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context, String sessionId) async {
    final prompts = _controllers.values
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    await context.read<PromptCurationState>().saveSessionPrompts(
      sessionId,
      prompts,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Prompts saved')));
  }
}
