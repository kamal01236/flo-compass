# Flo Meets — match rooms + mutual Connect



### IDEA-09-001 Flo Meets rooms hub (current)



- **Tier:** now

- **Status:** promoted

- **Problem:** Attendees want serendipitous peer meet-ups without exposing full profiles, without request/accept choreography, and with organizer-controlled rooms.

- **Approach:** Flo Meets is for everyone (no opt-in/opt-out). Onboarding is interests-only; matching preferences are collected on first Meets tab open (`/meets/preferences`) and editable later from the same screen / Profile. Bottom-nav **Meets** hub with seeded + organizer match rooms; always-on match %; symmetric **Connect** only (match when both sides Connect); demo reciprocity for mock partners; post-match unlock of Connect share / contact.

- **Touches:** `lib/features/flo_meets/`, `lib/features/operations/meet_rooms/`, `lib/features/shell/main_shell.dart`, `lib/data/models/flo_meet_*.dart`, `lib/data/services/flo_meets_*.dart`, `assets/data/flo_meets_*.json`

- **Depends on:** onboarding interests, Networking Card ShareFields, `flo2026_amenities.json`

- **Related backlog:** none

- **Future plan slug:** `flo-meets-backend-pool`

- **Out of scope (Accelevents):** registration / ticketing / check-in / badge / official attendee directory / official room booking



## Shipped



- Preferences screen on first Meets open when `!isSetupComplete` (nickname, identity/open-to, purposes, personal interests, personality, slots, amenity, optional contact); same screen for later edits

- Bottom nav 5 tabs: Discover | Ask Flo | **Meets** | My Plan | Profile

- Hub segments: **Rooms | Waiting | Matches** (gated until preferences complete)

- Room detail with join/leave, occupancy, people ranked by match %

- Match window with single **Connect** CTA (no Request / Accept / Decline)

- Match only when `iConnected && theyConnected`; mock partners reciprocate for demo

- After Match: meet detail + Connect share / contact unlock

- Organizer Operations → Match rooms CRUD (draft / publish / archive) via `publishAnnouncement` capability

- Seeded `flo_meets_rooms.json` + prefs overlay catalog



## Demo script



1. Complete onboarding (pick 3–7 interests) → Discover.

2. Open bottom nav **Meets** → preferences setup appears → fill required fields → **Save**.

3. Hub **Rooms** → open a room → **Join room**.

4. Tap a person → match window shows nickname + match % + overlap chips → tap **Connect**.

5. Demo reciprocity: after a short wait the mock partner Connects back → status becomes **Matched** → **View meet details** / **Open Connect share**.

6. Edit prefs anytime: hub AppBar Preferences or Profile → Flo Meets card.

7. Organizer path: Profile → Organizer Operations → **Match rooms** → compose → **Publish now** → room appears in attendee hub.



## Explicitly not shipped



- Request / Accept / Decline handshake UI

- Real multi-user sync / push / WebSocket

- T−30 auto-match as primary UX (`runRoundTick` is a no-op)

- Handshake codes; Connect QR / contact **before** mutual Connect

- User-created (attendee) rooms

- Domain email restriction (`useFloMeets` capability)

- Opt-in / opt-out / Skip Flo Meets (feature is for all authenticated attendees)
