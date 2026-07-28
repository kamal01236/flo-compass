---
name: Sample Plan (fixture)
overview: Fixture used by tests/scripts/wsl_plan_session.bats to exercise print_patch_notes and patch_notes_count.
todos:
  - id: fixture-only
    content: This plan is a test fixture; do not merge or execute.
    status: pending
isProject: false
---

# Sample Plan (fixture)

## Ownership contract (parallel-agents.mdc + parallel-plans-workflow.mdc)

- **Agent id:** `fixture/plan-a`
- **Branch:** `fixture/plan-a`
- **Worktree:** `/tmp/fixture-worktree`
- **Slot:** `1`
- **Ports:** `FLUTTER_PORT=3001`, `DOCKER_PORT=8081`

### Files this agent MAY write

- `fixtures/only.dart`

### Files this agent MUST NOT touch (forbidden shared surface)

- `lib/routing/app_router.dart`
- `lib/app.dart`

### Serial-merge patch notes

<!-- One bullet per change the parent must apply to a forbidden shared file on the integration branch after this plan merges. -->

- `lib/routing/app_router.dart` — register the new `/fixture` route: add `GoRoute(path: '/fixture', builder: (_, __) => const FixtureScreen())` after the existing `/session/:id` entry; import `fixture_screen.dart`.
- `lib/app.dart` — insert `ChangeNotifierProvider(create: (_) => FixtureProvider())` after `EventProvider` in the provider list.
- `web/manifest.json` — add `{"name": "Fixture", "url": "/fixture"}` to `shortcuts` array.

## Scope

- Purely test-fixture content.

## Phases

- **Phase 1 — Fixture only** — no-op.

## Success criteria

- The parser extracts exactly three bullets from the Serial-merge patch notes section above.
