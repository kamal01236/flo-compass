import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/analytics/analytics_tracker.dart';
import '../../data/services/feedback_service.dart';
import '../../providers/auth_provider.dart';
import '../../shared/a11y/modal_focus_trap.dart';

Future<void> showFeedbackSheet(
  BuildContext context, {
  String? initialMessage,
  String? errorSummary,
  String? category,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => ModalFocusTrap(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
        ),
        child: _FeedbackSheetBody(
          initialMessage: initialMessage,
          errorSummary: errorSummary,
          category: category,
        ),
      ),
    ),
  );
}

class _FeedbackSheetBody extends StatefulWidget {
  const _FeedbackSheetBody({
    this.initialMessage,
    this.errorSummary,
    this.category,
  });

  final String? initialMessage;
  final String? errorSummary;
  final String? category;

  @override
  State<_FeedbackSheetBody> createState() => _FeedbackSheetBodyState();
}

class _FeedbackSheetBodyState extends State<_FeedbackSheetBody> {
  late final TextEditingController _controller;
  final _service = FeedbackService();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialMessage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;
    setState(() => _submitting = true);
    final auth = context.read<AuthState>();
    final route = GoRouter.of(context).state.matchedLocation;
    final success = await _service.submit(
      FeedbackPayload(
        message: message,
        category: widget.category,
        route: route,
        userId: auth.isAuthenticated ? auth.service.session?.subject : null,
        errorSummary: widget.errorSummary,
      ),
    );
    await trackAnalytics(
      'feedback_submitted',
      properties: {if (widget.category != null) 'category': widget.category!},
      route: route,
    );
    await flushAnalytics();
    if (!mounted) return;
    Navigator.pop(context);
    final snackMessage = success
        ? 'Thanks for your feedback!'
        : 'Saved offline — will retry when online.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(snackMessage)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Send feedback', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Anonymous feedback is welcome. Sign in to attach your identity.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'What happened? What would help?',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
