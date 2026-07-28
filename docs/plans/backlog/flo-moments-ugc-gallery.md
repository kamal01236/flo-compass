# Flo Moments — attendee photo gallery (UGC + curation)

- **Status:** shortlisted
- **Sprint 2 priority:** yes (paired with [IDEA-EN-007](../Ideas/05-engagement.md))
- **Problem:** During a 3-day event with ~640 sessions, attendees capture memorable moments on the floor but have no in-app way to share them or see a curated community highlight reel. A personal recap alone (`recap_screen.dart`) does not surface collective “Flo Moments.”
- **Approach:** Phased delivery — mock-first read-only gallery, then signed-in uploads (max 4 per user per event), then moderator curation into a featured feed. Position as **community highlights** in Flo Compass; not official photo management or full organizer admin (Accelevents complement boundary).
  - **Phase 0 (demo):** `assets/data/flo2026_moments.json` + schema; read-only carousel on Recap or Discover; static curated URLs or bundled assets.
  - **Phase 1 (submit):** Web image pick, client resize (e.g. JPEG, ~2 MB cap), `POST /events/{eventId}/moments` with per-user cap of 4; Azure Blob storage + metadata (`pending` | `featured` | `rejected`); gate on sign-in (`AppCapability`).
  - **Phase 2 (moderate):** Lightweight moderator surface (separate internal tool or manifest — avoid a full admin app inside Flo Compass); approve/reject queue; soft-delete rejected items.
  - **Phase 3 (feed):** `GET /events/{eventId}/moments?featured=true` for public carousel; optional deep link to session/venue context.
- **Depends on:** enterprise-foundation-sprint completion (auth), [api-contract-openapi.md](api-contract-openapi.md), [full-remote-sync.md](full-remote-sync.md) or equivalent API layer, blob storage (Azure Blob — same pattern as CI hackathon-docs upload), human moderation owner; optional tie-in [live-announcements-feed.md](live-announcements-feed.md) for CMS-style curation patterns
- **Promotion criteria:** Product owner prioritizes; moderation policy and consent copy approved; auth + blob API available; Tier 1/2 validation plan exists (including abuse/rate-limit smoke). Phase 0 may promote independently for demo-only scope.
- **Future plan slug:** `flo-moments-ugc-gallery`
- **Touches (when promoted):** `lib/features/recap/` or new `lib/features/moments/`, `lib/data/repositories/`, `lib/routing/app_router.dart` (serial merge), `assets/data/schema/moment.schema.json`, `lib/providers/` (submission state only)
- **Out of scope (Accelevents):** official attendee media management, registration-linked photo albums, badge/PII processing
- **Non-negotiables:** human moderation before publish; sign-in required for upload; rate limits (4/user/event); consent (“rights to share”; no badges/faces without permission in guidelines); no auto-publish
- **Related idea:** [IDEA-EN-007](../Ideas/05-engagement.md) in engagement ideas
