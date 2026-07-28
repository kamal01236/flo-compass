# Venue and logistics

Flo Compass complements Accelevents — no registration, ticketing, check-in, badge printing, or official agenda CRUD. See [flo-compass-product.mdc](../../../.cursor/rules/flo-compass-product.mdc).

On-site navigation, amenities, travel, and safety for Nagarro Gurgaon and hybrid hubs.

Shipped amenity expansion (VL-002) is archived in [SHIPPED.md](SHIPPED.md).

---

### IDEA-VL-001 Indoor navigation lite

- **Tier:** next
- **Status:** shortlisted
- **Sprint 2 priority:** yes
- **Implemented so far:** [lib/features/directions/directions_screen.dart](../../../lib/features/directions/directions_screen.dart), `floorStories` in [assets/data/flo2026_meta.json](../../../assets/data/flo2026_meta.json).
- **Remaining:** step-by-step path overlay on floor map (finish floor-map path overlay).
- **Problem:** ~90 spaces across Ground + floors 6–13 (N/S wings) confuse first-time on-site attendees.
- **Approach:** Step-by-step directions from Directions screen + floor stories: “North wing, Floor 8, Room 803” with landmark text; optional simple path on floor map.
- **Touches:** `lib/features/directions/directions_screen.dart`, `lib/features/venue_map/floor_story_panel.dart`, `assets/data/flo2026_meta.json`
- **Depends on:** none
- **Related backlog:** none
- **Future plan slug:** `indoor-navigation-lite`
- **Out of scope (Accelevents):** none

---

### IDEA-VL-003 Crowd-aware suggestions

- **Tier:** next
- **Status:** shortlisted
- **Sprint 2 priority:** yes
- **Problem:** Keynote rooms overfill while cafeteria screens stay empty; attendees waste time in queues.
- **Approach:** Mock utilization tiers first (“filling fast”) using existing `occupancyPercent` and DS-005 capacity hints; later ingest occupancy sensors or staff toggles; suggest stream from alternate space.
- **Touches:** `lib/features/discover/discover_screen.dart`, session detail badges
- **Depends on:** live feed or staff CMS (mock tiers first)
- **Related backlog:** [live-announcements-feed](../backlog/live-announcements-feed.md)
- **Future plan slug:** `crowd-aware-suggestions`
- **Out of scope (Accelevents):** crowd control and security operations

---

### IDEA-VL-004 Travel and visa helper

- **Tier:** later
- **Status:** idea
- **Problem:** International attendees (Germany, Israel) need static logistics: metro, airport, visa checklist — not in session agenda.
- **Approach:** Curated content page + Companion FAQ grounded in `travel_guide.json` (mock). Links only, no PII.
- **Touches:** new `lib/features/travel/` or profile-adjacent info screen, `assets/data/`
- **Depends on:** content from event ops team
- **Related backlog:** none
- **Future plan slug:** `travel-visa-helper`
- **Out of scope (Accelevents):** visa application and travel booking

---

### IDEA-VL-005 Emergency and safety card

- **Tier:** later
- **Status:** idea
- **Problem:** Large venue + international attendees need one-tap safety info (medical, security, embassy links by nationality).
- **Approach:** Single offline-friendly screen; static JSON by region; no live tracking.
- **Touches:** new safety feature module, `assets/data/`
- **Depends on:** organizer-approved content
- **Related backlog:** none
- **Future plan slug:** `emergency-safety-card`
- **Out of scope (Accelevents):** incident reporting to authorities
