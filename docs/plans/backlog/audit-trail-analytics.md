# Audit trail and product analytics

- **Status:** partial
- **Implemented so far:** [lib/core/analytics/analytics_service.dart](../../../lib/core/analytics/analytics_service.dart), [lib/data/services/ops_audit_service.dart](../../../lib/data/services/ops_audit_service.dart); local analytics buffer + mock ops audit log wired into organizer surfaces.
- **Remaining:** Server-side immutable audit store and a production analytics pipeline (ingest, retention, dashboards).
- **Problem:** Audit trail and product analytics is out of scope for the Enterprise Foundation Sprint.
- **Approach:** Capture requirements and promote when foundations (auth, API layer, i18n) are stable.
- **Depends on:** enterprise-foundation-sprint completion
- **Promotion criteria:** Product owner prioritizes; technical prerequisites met; Tier 1/2 validation plan exists.
- **Future plan slug:** `audit-trail-analytics`
