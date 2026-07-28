# Parallel Agents

| Field | Value |
|-------|-------|
| **File** | `.cursor/rules/parallel-agents.mdc` |
| **Purpose** | File-level ownership contract + merge discipline for parallel subagents |
| **Scope** | `alwaysApply: true` |
| **When to @cite** | Dispatching parallel subagents; serial merge after parallel run |

## Key guardrails

- Explicit file-level ownership contract in plan before parallel dispatch — else run serially
- Forbidden shared files: `app_router.dart`, `main_shell.dart`, `app.dart`, `lib/providers/**`, `pubspec.yaml`, `web/manifest.json`, hackathon docs, CI/docker/gitignore
- Parent runs serial merge: `git status`, grep for duplicate routes/providers/manifest/log entries
- One batched augmentation-log entry only — parallel agents do not append individually
- Grep-verify shared files; do not assume last writer wins

## Source

[`.cursor/rules/parallel-agents.mdc`](../../.cursor/rules/parallel-agents.mdc)
