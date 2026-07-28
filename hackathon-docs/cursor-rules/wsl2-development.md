# WSL2 Local Development

| Field | Value |
|-------|-------|
| **File** | `.cursor/rules/wsl2-development.mdc` |
| **Purpose** | WSL2 local dev & Tier 2 smoke only — does not change ARM/CI production |
| **Scope** | `alwaysApply: true` |
| **When to @cite** | Running flutter/docker/git locally; Windows host command prefix; port binding |

## Key guardrails

- WSL2 for Tier 1 & Tier 2 local testing only — production: GitLab CI → Dockerfile → ARM → Azure
- Run flutter, dart, docker, git inside WSL; Windows prefix: `wsl -e bash -lc 'cd <repo> && …'`
- Flutter dev: port 3000 (or 8080), bind `0.0.0.0` for Windows localhost forwarding
- Docker Tier 2: port 8080; verify `/` and `/session/s-001`
- Do not change ARM template, `.gitlab-ci.yml`, or rely on Docker Desktop for Windows

## Source

[`.cursor/rules/wsl2-development.mdc`](../../.cursor/rules/wsl2-development.mdc)
