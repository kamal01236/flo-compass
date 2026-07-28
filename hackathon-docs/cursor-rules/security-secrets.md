# Security & Secrets

| Field | Value |
|-------|-------|
| **File** | `.cursor/rules/security-secrets.mdc` |
| **Purpose** | No secrets/PII; `--dart-define` for local API config |
| **Scope** | `alwaysApply: true` |
| **When to @cite** | Env config, CI variables, demo credentials, API keys, attendee data |

## Key guardrails

- Never commit: `.env`, API keys, Azure credentials, `.cursor/mcp.json`, `.worktree.env`, CI secret values, PII
- GitLab CI variables: reference by name only, never paste values
- Demo credentials: fake/sample data in HACKATHON-README section 2
- External APIs locally: `--dart-define=API_URL=...`; document in README section 3
- Runtime Cursor files and build artifacts stay git-excluded

## Source

[`.cursor/rules/security-secrets.mdc`](../../.cursor/rules/security-secrets.mdc)
