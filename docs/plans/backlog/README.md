# Backlog

Items here are **not** implemented on the active branch. Use when scope is deferred.

## Template

Copy `_TEMPLATE.md` or use this structure:

```markdown
# Title
- **Status:** backlog
- **Problem:** ...
- **Approach:** ...
- **Depends on:** ...
- **Promotion criteria:** ...
- **Future plan slug:** `slug`
```

## Promotion rules

1. Product owner approves priority
2. Technical prerequisites met (see **Depends on**)
3. Create executable plan in `.cursor/plans/` from `_TEMPLATE_parallel_plan.md`
4. Update this index and [../README.md](../README.md)
5. Do **not** implement backlog scope during an active sprint unless explicitly promoted

## Sprint 2 shortlist (engineering)

| Slug | One-line value |
|------|----------------|
| [design-tokens-storybook.md](design-tokens-storybook.md) | Widgetbook/Storybook catalog for `AppColors`, `SessionCard`, `FloPicksHero`, track chips |
| [production-pipeline-bundle.md](production-pipeline-bundle.md) | Rollup: Sentry + post-deploy smoke + prod config hardening |
| [security-remediation-bundle.md](security-remediation-bundle.md) | Rollup: prod mockUsers lockout + session trust + Pages headers + Dependabot |

Child items under the pipeline bundle: [observability-sentry-logging.md](observability-sentry-logging.md), [post-deploy-smoke-ci.md](post-deploy-smoke-ci.md), [prod-config-profile-hardening.md](prod-config-profile-hardening.md).

Paired product backlog: [flo-moments-ugc-gallery.md](flo-moments-ugc-gallery.md) (with IDEA-EN-007).

## Seed items

See individual `.md` files in this directory.

- [prod-config-profile-hardening.md](prod-config-profile-hardening.md) — CI `CONFIG_PROFILE=dev` prod risk (now shortlisted under pipeline bundle)

## Recently promoted

- [contextual-help-tour.md](contextual-help-tour.md) — graduated to `Status: promoted`; 8-step spotlight tour shipped under [`../../../lib/shared/tour/`](../../../lib/shared/tour/).

## Rejected (out of scope)

- [i18n-hindi-rtl.md](i18n-hindi-rtl.md) — Hindi + RTL not in scope for Flo 2026 (EN/DE/ES remain)
