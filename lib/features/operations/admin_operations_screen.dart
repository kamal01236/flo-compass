import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import 'admin_operations_panel.dart';

class AdminOperationsScreen extends StatelessWidget {
  const AdminOperationsScreen({super.key});

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin operations'),
        actions: [
          Semantics(
            label: 'Close',
            button: true,
            child: IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close),
              onPressed: () => _close(context),
            ),
          ),
        ],
      ),
      body: const AdminOperationsPanel(),
    );
  }
}
