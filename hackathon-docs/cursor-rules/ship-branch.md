# Ship Branch

| Field | Value |
|-------|-------|
| **File** | `.cursor/rules/ship-branch.mdc` |
| **Purpose** | Ship-branch pipeline before MR — Tier 1 + Tier 2 smoke + push + GitLab MR |
| **Scope** | Agent-requestable (`alwaysApply: false`) |
| **When to @cite** | Before opening MR; commits ready for review; plan worktree finish with `--ship` |

## Key guardrails

- Run `ship-branch.cmd` / `wsl_ship_branch.sh` — not on every commit
- Pipeline: branch guard → clean tree → Tier 1 → Tier 2 smoke (teardown) → push → MR
- Never suggest MR without Tier 1 + Tier 2 green
- `deploy-local.cmd` leaves Docker running; `ship-branch.cmd` tears it down
- Plan worktrees: `source .worktree.env` then `wsl_plan_worktree_finish.sh --push --ship`
- `glab auth login` is one-time local; never commit tokens

## Source

[`.cursor/rules/ship-branch.mdc`](../../.cursor/rules/ship-branch.mdc)
