// Fixture — a clean router (no duplicate GoRoute paths). Used to verify that
// grep_guardrails returns 0 on well-formed input.

import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/home', builder: (_, __) => const Placeholder()),
    GoRoute(path: '/discover', builder: (_, __) => const Placeholder()),
    GoRoute(path: '/session/:id', builder: (_, __) => const Placeholder()),
  ],
);
