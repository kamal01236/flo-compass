import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';

/// Pops the Discover branch stack and returns to the feed.
class DiscoverHomeAction extends StatelessWidget {
  const DiscoverHomeAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Back to Discover',
      button: true,
      child: IconButton(
        tooltip: 'Back to Discover',
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        icon: const Icon(Icons.explore_outlined),
        onPressed: () => context.go(AppRoutes.discover),
      ),
    );
  }
}
