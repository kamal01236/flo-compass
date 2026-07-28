# Dev Loops

| Field | Value |
|-------|-------|
| **File** | `.cursor/rules/dev-loops.mdc` |
| **Purpose** | Fast / feature / pre-push / ship / CI tiers with time budgets and scripts |
| **Scope** | `alwaysApply: true` |
| **When to @cite** | Choosing which validation script to run; inner-loop vs pre-push vs ship |

## Key guardrails

- **Fast** (&lt;15s): `flutter test test/data test/shared` — no Docker
- **Feature** (&lt;90s cold): `wsl_dev.sh` / `dev-local.cmd` — Flutter :3000
- **Pre-push** (&lt;15m): `wsl_deploy.sh` — build web + docker + coverage gate
- **Ship** (&lt;15m): `wsl_ship_branch.sh` — Tier 1 + Tier 2 smoke + push + MR
- Docker forbidden in Fast and Feature tiers
- Coverage thresholds: services ≥60%, utils ≥60%, lib overall ≥45%

## Source

[`.cursor/rules/dev-loops.mdc`](../../.cursor/rules/dev-loops.mdc)
