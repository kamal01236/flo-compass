# Production-grade pipeline bundle

- **Status:** shortlisted
- **Sprint 2 priority:** yes
- **Problem:** Demo-ready local stack (Tier 1/2) is solid, but production needs monitored deploys, post-deploy smoke checks, and prod-safe config — not a demo `CONFIG_PROFILE=dev` build with elevated mock roles.
- **Approach:** Promote and ship the three child backlog items as one coordinated pipeline slice:
  | Child slug | Scope |
  |------------|-------|
  | [observability-sentry-logging.md](observability-sentry-logging.md) | Sentry + release/environment tagging + source maps |
  | [post-deploy-smoke-ci.md](post-deploy-smoke-ci.md) | HTTP smoke against deployed FQDN in GitLab CI |
  | [prod-config-profile-hardening.md](prod-config-profile-hardening.md) | `CONFIG_PROFILE=prod`, CI guardrails against mock roles |
- **Depends on:** enterprise-foundation-sprint completion; one staging FQDN for smoke validation
- **Promotion criteria:** Tier 2 green + one successful post-deploy smoke on staging FQDN
- **Future plan slug:** `production-pipeline-bundle`
