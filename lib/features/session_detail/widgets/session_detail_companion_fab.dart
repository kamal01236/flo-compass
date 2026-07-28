import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SessionDetailCompanionFab extends StatelessWidget {
  const SessionDetailCompanionFab({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
  });

  final String sessionId;
  final String sessionTitle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ask Flo about this session',
      button: true,
      child: FloatingActionButton.extended(
        onPressed: () => context.push(
          '/companion?q=${Uri.encodeComponent('Tell me about $sessionTitle')}&sessionId=$sessionId',
        ),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Ask Flo'),
      ),
    );
  }
}
