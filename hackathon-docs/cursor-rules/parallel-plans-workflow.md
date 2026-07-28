# Parallel Plans Workflow

| Field | Value |
|-------|-------|
| **File** | `.cursor/rules/parallel-plans-workflow.mdc` |
| **Purpose** | Worktree slots, port table, lifecycle scripts, three-layer branch model |
| **Scope** | `alwaysApply: true` |
| **When to @cite** | Multiple plans on one machine; worktree start/finish/merge/cleanup; port slots |

## Key guardrails

- Three-layer branches: per-plan → `feat/sprint-N-integration` → `main`
- Slots 0–5 with fixed FLUTTER_PORT / DOCKER_PORT; `source .worktree.env` before dev/deploy
- Lifecycle: `new-plan-worktree` → finish → merge (integration only) → cleanup → `sprint-integrate`
- Merge uses `flock` lock; serial-merge patch notes applied on integration by parent
- Do not edit forbidden shared files on per-plan branches
- One batched augmentation-log entry on sprint integrate — not per-plan

## Source

[`.cursor/rules/parallel-plans-workflow.mdc`](../../.cursor/rules/parallel-plans-workflow.mdc)
