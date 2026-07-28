# Cross-geography connection

Flo Compass complements Accelevents — no registration, ticketing, check-in, badge printing, or official agenda CRUD. See [flo-compass-product.mdc](../../../.cursor/rules/flo-compass-product.mdc).

Lightweight networking and hybrid participation across Germany, Israel, India, and remote hubs — without becoming a social network.

Shipped networking card (CG-007) is archived in [SHIPPED.md](SHIPPED.md).

---

### IDEA-CG-001 Interest rooms (async)

- **Tier:** next
- **Status:** shortlisted
- **Sprint 2 priority:** yes
- **Problem:** Attendees want topic discussion (GenAI, platform engineering EU) without DMs or full social graph.
- **Approach:** Per-track or per-tag async walls: threaded Q&A or notes, moderated, no PII display. Start read-only curated threads in mock data (mock-first async wall / topic rooms).
- **Touches:** new `lib/features/interest_rooms/` or extend Companion context
- **Depends on:** backend or static JSON feed; [live-announcements-feed](../backlog/live-announcements-feed.md) patterns
- **Related backlog:** [live-announcements-feed](../backlog/live-announcements-feed.md)
- **Future plan slug:** `interest-rooms-async`
- **Out of scope (Accelevents):** official attendee messaging and meeting scheduler

---

### IDEA-CG-002 Find timezone peers

- **Tier:** next
- **Status:** shortlisted
- **Sprint 2 priority:** yes
- **Problem:** Remote attendees in CET feel isolated; hard to find others with same interests and sleep schedule.
- **Approach:** Opt-in aggregate: “3 others in CET interested in security” — role + interests + region bucket only, no names until Accelevents networking. Anonymous aggregation only; no PII in aggregates.
- **Touches:** `lib/data/models/user_profile.dart`, future anonymous aggregation service
- **Depends on:** mock region bucket first; auth or privacy-preserving analytics for production
- **Related backlog:** [audit-trail-analytics](../backlog/audit-trail-analytics.md), [cross-device-sync](../backlog/cross-device-sync.md)
- **Future plan slug:** `timezone-peers`
- **Out of scope (Accelevents):** attendee directory and 1:1 chat

---

### IDEA-CG-003 Session co-watch

- **Tier:** later
- **Status:** partial
- **Implemented so far:** `coWatchCount` demo counter in [lib/data/services/session_detail_assembler.dart](../../../lib/data/services/session_detail_assembler.dart).
- **Remaining:** shared live notes + backend.
- **Problem:** Remote viewing is passive; no sense of shared experience across geographies.
- **Approach:** “12 people watching this stream” counter + shared live notes (moderated). Mock counter first; WebSocket or poll later.
- **Touches:** `lib/features/session_detail/session_detail_screen.dart`, stream embed area
- **Depends on:** IDEA-GA-002, stream URLs, real-time backend
- **Related backlog:** [full-remote-sync](../backlog/full-remote-sync.md)
- **Future plan slug:** `session-co-watch`
- **Out of scope (Accelevents):** video hosting and DRM

---

### IDEA-CG-004 Office and hub map

- **Tier:** next
- **Status:** shortlisted
- **Sprint 2 priority:** yes
- **Problem:** Hybrid event includes watch parties and regional hubs, not only Gurgaon floors.
- **Approach:** Extend venue model with `venueType: campus | hub | stream`; show Berlin/Tel Aviv hubs on map or list with local contact and stream relay info. Sketch `venueType: hub` entries in `flo2026_venues.json` first.
- **Touches:** `assets/data/flo2026_venues.json`, `lib/features/venue_map/venue_map_screen.dart`
- **Depends on:** hub data from organizers (mock entries first)
- **Related backlog:** none
- **Future plan slug:** `office-hub-map`
- **Out of scope (Accelevents):** room booking for hub spaces

---

### IDEA-CG-005 Speaker office hours queue

- **Tier:** later
- **Status:** idea
- **Problem:** AMA and office-hour slots span timezones; first-come queues unfair to remote EU/IL attendees.
- **Approach:** Virtual queue with timezone-aware booking windows; read-only slot list from organizer feed initially.
- **Touches:** new feature module, session detail CTA
- **Depends on:** organizer API or manual slot JSON
- **Related backlog:** [api-contract-openapi](../backlog/api-contract-openapi.md)
- **Future plan slug:** `speaker-office-hours-queue`
- **Out of scope (Accelevents):** calendar booking and payments

---

### IDEA-CG-006 QR continue on mobile

- **Tier:** now
- **Status:** partial
- **Implemented so far:** [lib/data/services/plan_share_service.dart](../../../lib/data/services/plan_share_service.dart), [lib/features/my_plan/plan_import_screen.dart](../../../lib/features/my_plan/plan_import_screen.dart).
- **Remaining:** combined plan+session QR.
- **Problem:** Attendees switch laptop → phone between sessions; deep links and plan state do not follow easily.
- **Approach:** Extend existing QR flow to encode session id + plan export token or URL; scan opens same session/plan on mobile web.
- **Touches:** `lib/features/qr/qr_url_builder.dart`, `lib/features/qr/qr_generator_screen.dart`, `lib/features/my_plan/plan_import_screen.dart`
- **Depends on:** none (local plan import exists)
- **Related backlog:** [cross-device-sync](../backlog/cross-device-sync.md) (for automatic sync later)
- **Future plan slug:** `qr-continue-mobile`
- **Out of scope (Accelevents):** none
