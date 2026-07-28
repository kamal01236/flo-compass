import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/app_capability.dart';
import '../../../data/models/models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/engagement_provider.dart';
import '../../../providers/session_qa_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/shared_widgets.dart';

class SessionQaSection extends StatelessWidget {
  const SessionQaSection({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
    this.sessionAbstract,
  });

  final String sessionId;
  final String sessionTitle;
  final String? sessionAbstract;

  @override
  Widget build(BuildContext context) {
    final body = _SessionQaSectionBody(
      sessionId: sessionId,
      sessionTitle: sessionTitle,
      sessionAbstract: sessionAbstract,
    );
    if (_hasSessionQaProvider(context)) {
      return body;
    }
    return ChangeNotifierProvider(create: (_) => SessionQaState(), child: body);
  }

  static bool _hasSessionQaProvider(BuildContext context) {
    try {
      Provider.of<SessionQaState>(context, listen: false);
      return true;
    } on ProviderNotFoundException {
      return false;
    }
  }
}

class _SessionQaSectionBody extends StatefulWidget {
  const _SessionQaSectionBody({
    required this.sessionId,
    required this.sessionTitle,
    this.sessionAbstract,
  });

  final String sessionId;
  final String sessionTitle;
  final String? sessionAbstract;

  @override
  State<_SessionQaSectionBody> createState() => _SessionQaSectionBodyState();
}

class _SessionQaSectionBodyState extends State<_SessionQaSectionBody> {
  final _questionController = TextEditingController();
  final _dateFormat = DateFormat('MMM d · HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(_SessionQaSectionBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId) {
      _load();
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void _load() {
    if (!mounted) return;
    context.read<SessionQaState>().load(widget.sessionId);
  }

  @override
  Widget build(BuildContext context) {
    final qa = context.watch<SessionQaState>();
    final canModerateQa = _canModerateQa(context);
    final questions = qa.visibleQuestionsForRole(includeHidden: canModerateQa);
    final questionCount = questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Questions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Ask the room or scan what others want answered.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        if (qa.prompts.isNotEmpty) _promptChips(context, qa),
        _askField(context, qa),
        const SizedBox(height: 12),
        if (qa.loading && questions.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Loading questions…',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          )
        else if (qa.error != null && questions.isEmpty)
          ErrorView(
            technicalDetail: qa.error,
            onRetry: qa.refresh,
            retryLabel: 'Reload Q&A',
          )
        else if (questions.isEmpty)
          const EmptyState(
            title: 'Be the first to ask',
            message: 'Start the discussion for this session.',
            icon: Icons.forum_outlined,
          )
        else
          Column(
            children: [
              _sortRow(qa, questionCount),
              const SizedBox(height: 8),
              for (final question in questions)
                _questionCard(context, qa, question, canModerateQa),
            ],
          ),
      ],
    );
  }

  bool _canModerateQa(BuildContext context) {
    try {
      return context.watch<AuthState>().hasCapability(AppCapability.moderateQa);
    } on ProviderNotFoundException {
      return false;
    }
  }

  Widget _sortRow(SessionQaState qa, int questionCount) {
    return Row(
      children: [
        Semantics(
          label: 'Sort questions by ${qa.sort.label}',
          button: true,
          child: PopupMenuButton<SessionQaSort>(
            tooltip: qa.sort.label,
            icon: const Icon(Icons.sort),
            onSelected: qa.setSort,
            itemBuilder: (context) => [
              for (final mode in sessionQaSortModes)
                PopupMenuItem(value: mode, child: _sortMenuRow(qa.sort, mode)),
            ],
          ),
        ),
        const Spacer(),
        Text(
          '$questionCount ${questionCount == 1 ? 'question' : 'questions'}',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _sortMenuRow(SessionQaSort current, SessionQaSort mode) {
    return Row(
      children: [
        Expanded(child: Text(mode.label)),
        if (mode == current) const Icon(Icons.check, size: 18),
      ],
    );
  }

  Widget _promptChips(BuildContext context, SessionQaState qa) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Try a prompt',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final prompt in qa.prompts)
              ActionChip(
                label: Text(prompt),
                onPressed: () => _handlePrompt(context, qa, prompt),
              ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _askField(BuildContext context, SessionQaState qa) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Semantics(
            label: 'Ask a question',
            child: TextField(
              controller: _questionController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'What should the speaker address?',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _submitQuestion(qa),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          tooltip: 'Post question',
          onPressed: qa.loading ? null : () => _submitQuestion(qa),
          icon: const Icon(Icons.send),
        ),
      ],
    );
  }

  Widget _questionCard(
    BuildContext context,
    SessionQaState qa,
    SessionQuestion question,
    bool canModerateQa,
  ) {
    final expanded = qa.expandedQuestionIds.contains(question.id);
    final answered = question.answered;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    question.authorName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  _dateFormat.format(question.createdAt),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(question.question),
            if (question.hidden) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.visibility_off_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Hidden from attendees',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Semantics(
                  button: true,
                  label: question.viewerHasUpvoted
                      ? 'Remove upvote'
                      : 'Upvote question',
                  child: IconButton(
                    onPressed: () => _toggleVote(context, qa, question),
                    icon: Icon(
                      question.viewerHasUpvoted
                          ? Icons.thumb_up
                          : Icons.thumb_up_outlined,
                      color: question.viewerHasUpvoted
                          ? AppColors.accentStart
                          : null,
                    ),
                  ),
                ),
                Text('${question.upvotes}'),
                const SizedBox(width: 16),
                Icon(
                  answered ? Icons.check_circle : Icons.chat_bubble_outline,
                  size: 16,
                  color: answered
                      ? AppColors.accentStart
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  answered ? 'Answered' : 'Awaiting reply',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                if (canModerateQa)
                  _moderationActionsMenu(context, qa, question),
                const Spacer(),
                Semantics(
                  button: true,
                  label: expanded
                      ? 'Hide replies'
                      : 'Show replies ${question.replyCount}',
                  child: TextButton(
                    onPressed: () => qa.toggleExpanded(question.id),
                    child: Text(
                      expanded
                          ? 'Hide replies'
                          : 'Show replies (${question.replyCount})',
                    ),
                  ),
                ),
              ],
            ),
            if (expanded) ...[
              const Divider(),
              if (question.replies.isEmpty) ...[
                if (widget.sessionAbstract != null &&
                    widget.sessionAbstract!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: AppColors.accentStart,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _groundedHint(widget.sessionAbstract!),
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'No replies yet. Be the first to chime in.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
              ] else
                for (final reply in question.replies)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          reply.fromFlo ? Icons.auto_awesome : Icons.chat,
                          size: 16,
                          color: reply.fromFlo
                              ? AppColors.accentStart
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reply.authorName,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              Text(reply.message),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _addReply(context, qa, question.id),
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Add reply'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _moderationActionsMenu(
    BuildContext context,
    SessionQaState qa,
    SessionQuestion question,
  ) {
    return PopupMenuButton<_ModerationAction>(
      tooltip: 'Moderation actions',
      icon: const Icon(Icons.shield_outlined),
      onSelected: (action) =>
          _applyModerationAction(context, qa, question, action),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: question.answered
              ? _ModerationAction.markUnanswered
              : _ModerationAction.markAnswered,
          child: Text(question.answered ? 'Mark unanswered' : 'Mark answered'),
        ),
        PopupMenuItem(
          value: question.pinned
              ? _ModerationAction.unpin
              : _ModerationAction.pin,
          child: Text(question.pinned ? 'Unpin question' : 'Pin question'),
        ),
        PopupMenuItem(
          value: question.hidden
              ? _ModerationAction.unhide
              : _ModerationAction.hide,
          child: Text(question.hidden ? 'Unhide question' : 'Hide question'),
        ),
      ],
    );
  }

  Future<void> _applyModerationAction(
    BuildContext context,
    SessionQaState qa,
    SessionQuestion question,
    _ModerationAction action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    var feedback = '';
    switch (action) {
      case _ModerationAction.markAnswered:
        await qa.setQuestionAnswered(question.id, true);
        feedback = 'Marked as answered';
      case _ModerationAction.markUnanswered:
        await qa.setQuestionAnswered(question.id, false);
        feedback = 'Marked as unanswered';
      case _ModerationAction.pin:
        await qa.setQuestionPinned(question.id, true);
        feedback = 'Pinned question';
      case _ModerationAction.unpin:
        await qa.setQuestionPinned(question.id, false);
        feedback = 'Unpinned question';
      case _ModerationAction.hide:
        await qa.setQuestionHidden(question.id, true);
        feedback = 'Question hidden from attendees';
      case _ModerationAction.unhide:
        await qa.setQuestionHidden(question.id, false);
        feedback = 'Question visible to attendees';
    }
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(feedback)));
  }

  Future<void> _submitQuestion(SessionQaState qa) async {
    final text = _questionController.text.trim();
    if (text.isEmpty) return;
    _questionController.clear();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final engagement = context.read<EngagementState>();
    await qa.addQuestion(text);
    if (!mounted) return;
    final delta = await engagement.onSessionQuestionAsked();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('+$delta XP · Question posted')),
    );
  }

  Future<void> _toggleVote(
    BuildContext context,
    SessionQaState qa,
    SessionQuestion question,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final engagement = context.read<EngagementState>();
    final nowUpvoted = await qa.toggleVote(question.id);
    if (!mounted) return;
    if (nowUpvoted) {
      final delta = await engagement.onSessionQuestionUpvoted();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('+$delta XP · Upvoted')));
    }
  }

  Future<void> _addReply(
    BuildContext context,
    SessionQaState qa,
    String questionId,
  ) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add reply'),
          content: TextField(
            controller: controller,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Share a quick answer or resource…',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => context.pop(controller.text.trim()),
              child: const Text('Post reply'),
            ),
          ],
        );
      },
    );
    if (result == null || result.trim().isEmpty || !mounted) return;
    await qa.addReply(questionId, result.trim());
  }

  Future<void> _handlePrompt(
    BuildContext context,
    SessionQaState qa,
    String prompt,
  ) async {
    final router = GoRouter.of(context);
    final action = await showModalBottomSheet<_PromptAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.forum_outlined),
                title: const Text('Post to the Q&A'),
                subtitle: Text(prompt),
                onTap: () => context.pop(_PromptAction.askHere),
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('Ask Flo instead'),
                subtitle: const Text('Prefill Companion with this prompt'),
                onTap: () => context.pop(_PromptAction.askCompanion),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted) return;
    if (action == null) return;
    if (action == _PromptAction.askHere) {
      _questionController.text = prompt;
      await _submitQuestion(qa);
      return;
    }
    final query = Uri.encodeComponent('$prompt — ${widget.sessionTitle}');
    router.push('/companion?q=$query');
  }

  String _groundedHint(String abstract) {
    final sentence = abstract.split(RegExp(r'[.!?]')).first.trim();
    if (sentence.length <= 120) return 'From the abstract: $sentence.';
    return 'From the abstract: ${sentence.substring(0, 117)}…';
  }
}

enum _PromptAction { askHere, askCompanion }

enum _ModerationAction {
  markAnswered,
  markUnanswered,
  pin,
  unpin,
  hide,
  unhide,
}
