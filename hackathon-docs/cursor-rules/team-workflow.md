# Team Workflow

| Field | Value |
|-------|-------|
| **File** | `.cursor/rules/team-workflow.mdc` |
| **Purpose** | Solo-driver + squad model, augmentation triggers |
| **Scope** | `alwaysApply: true` |
| **When to @cite** | Branching, MR gates, prompt hygiene, review before merge |

## Key guardrails

- Solo-driver + squad: Lead Developer drives Cursor; Data QA on dataset/a11y; Ship & Story on deploy/deliverables
- One augmentation-log entry per completed plan run — MR blocked until entry exists
- Prompt hygiene: cite relevant `.mdc` rules; "do not break docker/CI" on pubspec/docker; "web-only" on packages
- Review hygiene: verify paths, lockfile versions, routes, dataset fields, test counts
- After rule changes, verify catalog parity per `cursor-rules-catalog.mdc`
- Forbidden shared files → serial-merge patch notes

## Source

[`.cursor/rules/team-workflow.mdc`](../../.cursor/rules/team-workflow.mdc)
