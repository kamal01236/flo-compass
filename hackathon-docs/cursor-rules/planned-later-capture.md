# Planned-Later Capture

| Field | Value |
|-------|-------|
| **File** | `.cursor/rules/planned-later-capture.mdc` |
| **Purpose** | Capture deferred work in `docs/plans/backlog` instead of on active branch |
| **Scope** | Agent-requestable (`alwaysApply: false`) |
| **When to @cite** | User says defer, backlog, out of scope, plan later, not for now |

## Key guardrails

- Triggers: "plan later", "backlog", "implement later", "not for now", "defer", "out of scope"
- Create/append `docs/plans/backlog/<slug>.md` from backlog README template
- Update `docs/plans/README.md` backlog index if new
- **Do not** implement deferred scope on current branch
- Promote via backlog README when ready — create `.cursor/plans/` child plan before coding

## Source

[`.cursor/rules/planned-later-capture.mdc`](../../.cursor/rules/planned-later-capture.mdc)
