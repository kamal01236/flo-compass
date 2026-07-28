---
name: <PLAN NAME>
overview: <one-sentence overview>
todos:
  - id: example-todo
    content: <describe the todo>
    status: pending
  - id: augmentation-log
    content: Append one augmentation-log entry per ai-augmentation.mdc
    status: pending
isProject: false
---

# <Plan title>

## Ownership contract (parallel-agents.mdc + parallel-plans-workflow.mdc)

- **Agent id:** `{{BRANCH}}`
- **Branch:** `{{BRANCH}}`
- **Worktree:** `{{WORKTREE_PATH}}`
- **Slot:** `{{SLOT}}`
- **Ports:** `FLUTTER_PORT={{FLUTTER_PORT}}`, `DOCKER_PORT={{DOCKER_PORT}}`

### Files this agent MAY write

- <exact path or narrow glob>

### Files this agent MUST NOT touch (forbidden shared surface)

- `lib/routing/app_router.dart`
- `lib/features/shell/main_shell.dart`
- `lib/app.dart`
- `lib/providers/**` (esp. `app_settings_provider.dart`, `event_provider.dart`, `plan_provider.dart`, `engagement_provider.dart`)
- `pubspec.yaml`
- `web/manifest.json`
- `hackathon-docs/HACKATHON-README.md`
- `hackathon-docs/augmentation-log.md`
- `.gitlab-ci.yml`, `docker/**`, `.gitignore`, `.dockerignore`

### Serial-merge patch notes (parent applies on integration)

<!-- One bullet per change the parent must apply to a forbidden shared file on the integration branch after this plan merges. Format: `path` — one-line intent, plus the exact snippet or diff the parent should apply. Example:
- `lib/routing/app_router.dart` — register the new `/example` route: add `GoRoute(path: '/example', builder: (_, __) => const ExampleScreen())` after the existing `/session/:id` entry; import `example_screen.dart`.
-->

- <patch note>

## Scope

- <in-scope bullet>
- <deliberate exclusion so neighbouring parallel plans do not fight over adjacent surface>

## Phases

- **Phase 1 — <short title>** — <one-line description>
- **Phase 2 — <short title>** — <one-line description>

## Validation gate

Per [.cursor/rules/local-wsl-auto-validation.mdc](.cursor/rules/local-wsl-auto-validation.mdc), run Tier 1 **inside this worktree** using the slot's ports:

```bash
source .worktree.env
echo "$FLUTTER_PORT $DOCKER_PORT"   # sanity check: must be non-empty and match the header above
bash scripts/wsl_dev.sh
```

- Tier 2 (Docker) is pre-push only and single-worktree at a time (`dev-loops.mdc`); run only when this plan is ready to merge into integration.
- Do not write to `hackathon-docs/augmentation-log.md` from this per-plan branch; the parent batches one entry on integration (`ai-augmentation.mdc`).

## Completion gate

- Tier 1 green → parent appends `hackathon-docs/augmentation-log.md` entry on integration → mark `augmentation-log` todo complete.

## Success criteria

- <verifiable outcome>

## File touch summary

- <path> — <one-line rationale>

## Risks

- <risk> — <mitigation>

## Not in scope

- <deliberate exclusion, referencing the plan/rule that covers it if applicable>
