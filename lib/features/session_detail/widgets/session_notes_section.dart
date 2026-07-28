import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/engagement_provider.dart';
import '../../../shared/utils/session_note_excerpt.dart';

class SessionNoteEditor extends StatefulWidget {
  const SessionNoteEditor({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<SessionNoteEditor> createState() => _SessionNoteEditorState();
}

class _SessionNoteEditorState extends State<SessionNoteEditor> {
  final _noteController = TextEditingController();
  Timer? _noteDebounce;

  @override
  void initState() {
    super.initState();
    final note = context.read<EngagementState>().noteForSession(
      widget.sessionId,
    );
    if (note != null) _noteController.text = note;
  }

  @override
  void dispose() {
    _noteDebounce?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engagement = context.watch<EngagementState>();

    return Semantics(
      label: 'Personal session notes',
      child: TextField(
        controller: _noteController,
        maxLines: 3,
        maxLength: 500,
        decoration: const InputDecoration(
          hintText: 'Scratchpad — saved locally',
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          _noteDebounce?.cancel();
          _noteDebounce = Timer(const Duration(milliseconds: 500), () async {
            final hadNote =
                engagement
                    .noteForSession(widget.sessionId)
                    ?.trim()
                    .isNotEmpty ??
                false;
            await engagement.setSessionNote(widget.sessionId, value);
            if (!context.mounted) return;
            if (!hadNote && value.trim().isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to your recap')),
              );
            }
          });
        },
      ),
    );
  }
}

class SessionNotesExpandable extends StatefulWidget {
  const SessionNotesExpandable({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<SessionNotesExpandable> createState() => _SessionNotesExpandableState();
}

class _SessionNotesExpandableState extends State<SessionNotesExpandable> {
  bool _expanded = false;

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final engagement = context.watch<EngagementState>();
    final note = engagement.noteForSession(widget.sessionId) ?? '';
    final excerpt = excerptSessionNote(note);
    final hasNote = excerpt.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _toggleExpanded,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
              child: Row(
                children: [
                  const Icon(Icons.note_alt_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('Notes', style: theme.textTheme.titleSmall),
                  if (!_expanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        hasNote ? excerpt : 'Add a note',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 13,
                          color: hasNote ? null : theme.hintColor,
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  Semantics(
                    label: _expanded ? 'Collapse notes' : 'Expand notes',
                    button: true,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      tooltip: _expanded ? 'Collapse notes' : 'Expand notes',
                      onPressed: _toggleExpanded,
                      icon: Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SessionNoteEditor(sessionId: widget.sessionId),
            ),
        ],
      ),
    );
  }
}
