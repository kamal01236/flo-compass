// Fixture — mirrors the shape of lib/routing/app_router.dart just enough for
// grep_guardrails to exercise the duplicate-GoRoute detector.
//
// The two `GoRoute(path: '/fixture-duplicate')` entries below are intentional
// and represent the exact silent-merge-conflict case the guardrail catches.
// Do NOT deduplicate.

import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/home', builder: (_, __) => const Placeholder()),
    GoRoute(path: '/discover', builder: (_, __) => const Placeholder()),
    GoRoute(
      path: '/fixture-duplicate',
      builder: (_, __) => const Placeholder(),
    ),
    GoRoute(path: '/session/:id', builder: (_, __) => const Placeholder()),
    GoRoute(
      path: '/fixture-duplicate',
      builder: (_, __) => const Placeholder(),
    ),
  ],
);
