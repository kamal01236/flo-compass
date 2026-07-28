# Live CMS-driven announcements feed

- **Status:** partial
- **Implemented so far:** Mock organizer overlay under [lib/features/operations/announcements/](../../../lib/features/operations/announcements/) (draft/publish/archive) with the attendee-facing [lib/shared/widgets/published_announcement_banner.dart](../../../lib/shared/widgets/published_announcement_banner.dart).
- **Remaining:** CMS-driven live sync — replace the local mock store with a real feed source (push/poll), auth-scoped publish, and moderation history.
- **Problem:** Live CMS-driven announcements feed is out of scope for the Enterprise Foundation Sprint.
- **Approach:** Capture requirements and promote when foundations (auth, API layer, i18n) are stable.
- **Depends on:** enterprise-foundation-sprint completion
- **Promotion criteria:** Product owner prioritizes; technical prerequisites met; Tier 1/2 validation plan exists.
- **Future plan slug:** `live-announcements-feed`
