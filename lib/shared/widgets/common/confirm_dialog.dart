import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shows a destructive confirmation [AlertDialog]; returns `true` only on confirm.
Future<bool> confirmDestructiveAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Reset',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => ctx.pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => ctx.pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
