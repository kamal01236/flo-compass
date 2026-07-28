# Engagement

Flo Compass complements Accelevents — no registration, ticketing, check-in, badge printing, or official agenda CRUD. See [flo-compass-product.mdc](../../../.cursor/rules/flo-compass-product.mdc).

Gamification and recap features to make ~10K global attendees feel part of one event.

Shipped pulse and recap (EN-004/005) are archived in [SHIPPED.md](SHIPPED.md).

---

### IDEA-EN-001 Regional leaderboards

- **Tier:** next
- **Status:** shortlisted
- **Sprint 2 priority:** yes
- **Problem:** A single global leaderboard demotivates smaller regions; India/EU/Israel/Remote need fair competition.
- **Approach:** Extend existing leaderboard with region buckets; aggregate points from bingo, paths, Companion usage — anonymized team totals. Mock region bucket first before full profile capture.
- **Touches:** `lib/features/leaderboard/leaderboard_screen.dart`, `lib/features/leaderboard/leaderboard_entries.dart`, `lib/providers/engagement_provider.dart`
- **Depends on:** mock region bucket in leaderboard data (GA-005 optional for production profile sync)
- **Related backlog:** [audit-trail-analytics](../backlog/audit-trail-analytics.md)
- **Future plan slug:** `regional-leaderboards`
- **Out of scope (Accelevents):** none

---

### IDEA-EN-002 Team and guild challenges

- **Tier:** later
- **Status:** idea
- **Problem:** Practice and guild identity drives participation; solo points feel thin at enterprise scale.
- **Approach:** “Your practice completes 5 learning-path sessions” — aggregate anonymized progress; opt-in guild selection at onboarding.
- **Touches:** `lib/providers/engagement_provider.dart`, `lib/features/leaderboard/`
- **Depends on:** IDEA-EN-001, backend aggregation
- **Related backlog:** [audit-trail-analytics](../backlog/audit-trail-analytics.md)
- **Future plan slug:** `team-guild-challenges`
- **Out of scope (Accelevents):** HR org chart sync

---

### IDEA-EN-003 Session bingo v2

- **Tier:** next
- **Status:** partial
- **Implemented so far:** [lib/features/bingo/bingo_screen.dart](../../../lib/features/bingo/bingo_screen.dart), [lib/data/services/bingo_service.dart](../../../lib/data/services/bingo_service.dart).
- **Remaining:** track/day/remote card templates + picker.
- **Problem:** Current bingo card is generic; remote and track-specific cards increase relevance.
- **Approach:** Multiple card templates: by track, by day, “remote attendee” (stream 3 labs, ask Companion 5 questions). Reuse `bingo_screen.dart` data model.
- **Touches:** `lib/features/bingo/bingo_screen.dart`, `lib/providers/engagement_provider.dart`
- **Depends on:** IDEA-GA-002 for remote card rules
- **Related backlog:** none
- **Future plan slug:** `session-bingo-v2`
- **Out of scope (Accelevents):** none

---

### IDEA-EN-006 Innovation vote follow-through

- **Tier:** next
- **Status:** idea
- **Problem:** Innovation path and closing vote lack a results moment in-app.
- **Approach:** Tie `path-innovation` learning path to closing poll results page; static mock results for demo, live tally when API exists.
- **Touches:** `assets/data/learning_paths.json`, `lib/features/recap/recap_screen.dart` or new vote results screen
- **Depends on:** organizer poll feed
- **Related backlog:** [live-announcements-feed](../backlog/live-announcements-feed.md)
- **Future plan slug:** `innovation-vote-follow-through`
- **Out of scope (Accelevents):** official voting and audit trail for awards

---

### IDEA-EN-007 Flo Moments (UGC photo gallery)

- **Tier:** next
- **Status:** shortlisted
- **Sprint 2 priority:** yes
- **Problem:** Attendees capture event memories but cannot contribute to or browse a curated community highlight reel in-app; recap is personal stats only.
- **Approach:** **Phase 0 (mock):** read-only carousel from `assets/data/flo2026_moments.json` on Recap or Discover. **Phase 1+:** attendee uploads (max 4/event), moderator curation, featured feed — see [flo-moments-ugc-gallery](../backlog/flo-moments-ugc-gallery.md).
- **Touches:** `lib/features/recap/recap_screen.dart` or new `lib/features/moments/`, `assets/data/flo2026_moments.json`, `lib/data/repositories/`, `lib/routing/app_router.dart`
- **Depends on:** auth, blob storage API, moderation policy (Phase 0 is mock-only)
- **Related backlog:** [flo-moments-ugc-gallery](../backlog/flo-moments-ugc-gallery.md), [api-contract-openapi](../backlog/api-contract-openapi.md), [live-announcements-feed](../backlog/live-announcements-feed.md)
- **Future plan slug:** `flo-moments-ugc-gallery`
- **Out of scope (Accelevents):** official photo albums, organizer media CMS, registration-linked galleries
