# Local WSL Auto-Validation

| Field | Value |
|-------|-------|
| **File** | `.cursor/rules/local-wsl-auto-validation.mdc` |
| **Purpose** | Always-on WSL Tier 1/2 runs + Tier 1/2/3 reference appendix; plan-gap logging |
| **Scope** | `alwaysApply: true` |
| **When to @cite** | After any code/data edit; before marking work complete or opening MR |

## Key guardrails

- After edits to `lib/**`, `test/**`, `web/**`, `docker/**`, `pubspec.yaml`, `assets/data/**`: run WSL validation
- Code change: `flutter pub get && flutter analyze && flutter test`
- UI/routing: + `wsl_dev.sh`; smoke `http://localhost:3000/`
- docker/nginx/deploy: Tier 2 `wsl_deploy.sh`; verify deep-link refresh
- Do not write augmentation-log until full plan completes
- Skip only for read-only Q&A or pure `hackathon-docs/` prose with no code impact
- Tier 3 (Azure ARM) unchanged — triggered by default-branch CI push

## Source

[`.cursor/rules/local-wsl-auto-validation.mdc`](../../.cursor/rules/local-wsl-auto-validation.mdc)
