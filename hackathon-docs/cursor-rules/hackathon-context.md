# Hackathon Context

| Field | Value |
|-------|-------|
| **File** | `.cursor/rules/hackathon-context.mdc` |
| **Purpose** | Always-on project context, balanced shipping style |
| **Scope** | `alwaysApply: true` |
| **When to @cite** | Any new feature, refactor, or architecture decision; when scope or stack assumptions are unclear |

## Key guardrails

- Team ai-avengers; Flutter 3.44.0 web, Docker/nginx, GitLab CI → Azure Container Apps
- WSL2 for local dev only; production path unchanged
- Ship smallest working slice first; no premature abstractions
- Do not create git commits unless explicitly asked
- Do not add markdown/docs unless requested (except `hackathon-docs/` deliverables)
- Backend undecided — do not assume an API exists
- HTTP calls belong in `lib/data/` or `lib/services/`, not widgets

## Source

[`.cursor/rules/hackathon-context.mdc`](../../.cursor/rules/hackathon-context.mdc)
