# Production observability with Sentry and structured logging

- **Status:** shortlisted
- **Sprint 2 priority:** yes (child of [production-pipeline-bundle.md](production-pipeline-bundle.md))
- **Implemented so far:** [lib/core/logging/app_logger.dart](../../../lib/core/logging/app_logger.dart) provides structured logging and [lib/core/observability/crash_reporter.dart](../../../lib/core/observability/crash_reporter.dart) captures uncaught errors locally.
- **Remaining:** `sentry_flutter` integration (DSN wiring, release/environment tagging, source-map upload) and production dashboards/alerting on top.
- **Problem:** Production observability with Sentry and structured logging is out of scope for the Enterprise Foundation Sprint.
- **Approach:** Capture requirements and promote when foundations (auth, API layer, i18n) are stable.
- **Depends on:** enterprise-foundation-sprint completion
- **Promotion criteria:** Product owner prioritizes; technical prerequisites met; Tier 1/2 validation plan exists.
- **Future plan slug:** `observability-sentry-logging`
