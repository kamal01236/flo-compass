# Plan Auto-Continue

| Field | Value |
|-------|-------|
| **File** | `.cursor/rules/plan-auto-continue.mdc` |
| **Purpose** | Checkpoint + auto-continue for long-running plan runs (interrupt-safe handoff) |
| **Scope** | `alwaysApply: true` |
| **When to @cite** | Multi-turn plans; timeout/interrupt recovery; checkpoint handoff |

## Key guardrails

- Checkpoint file: `.cursor/plan-checkpoint.json` (git-excluded) with `done`, `remaining`, `auto_continue`, loop caps
- Update checkpoint after every phase; `remaining` empty = complete
- On interrupt: read checkpoint; narrow finish prompt from `remaining` — never redo `done` items
- Write augmentation-log before clearing `remaining`; set `augmentation_logged: true`
- Hooks opt-in via `.cursor/hooks.json` from template
- Do not dispatch duplicate full-plan workers while `remaining` is non-empty

## Source

[`.cursor/rules/plan-auto-continue.mdc`](../../.cursor/rules/plan-auto-continue.mdc)
