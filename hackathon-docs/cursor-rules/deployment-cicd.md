# Deployment & CI/CD

| Field | Value |
|-------|-------|
| **File** | `.cursor/rules/deployment-cicd.mdc` |
| **Purpose** | Docker/CI guardrails — Flutter 3.44.0, GitLab variable names |
| **Scope** | `globs: docker/**,.gitlab-ci.yml,.dockerignore,pubspec.yaml` |
| **When to @cite** | Dockerfile, CI pipeline, pubspec deploy impact, pre-push Tier 2 |

## Key guardrails

- Production: `flutter build web --release` → nginx serves `build/web`
- Base image: `ghcr.io/cirruslabs/flutter:3.44.0` in `docker/Dockerfile`
- Preserve CI variable names: `DOCKER_REGISTRY`, Azure SP vars, `FOLDER_TO_ZIP: hackathon-docs`
- Default-branch push: Docker build → Azure Container Apps → `hackathon-docs` blob upload
- Never hardcode secrets; use `--dart-define` or runtime config
- Do not alter `docker/arm-template.json` or `.gitlab-ci.yml` for local WSL testing

## Source

[`.cursor/rules/deployment-cicd.mdc`](../../.cursor/rules/deployment-cicd.mdc)
