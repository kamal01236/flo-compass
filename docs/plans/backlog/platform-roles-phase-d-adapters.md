# Platform roles Phase D — read-only external adapters

- **Status:** backlog
- **Problem:** Flo overlays are local/mock today; production may need read-only sync from Accelevents or similar without agenda CRUD in Flo.
- **Approach:** Define adapter interface for sessions/speakers/venues read path; organizer/admin continue editing overlays only; canonical records remain external.
- **Depends on:** Phase A+B platform roles; backend/event-system decision
- **Promotion criteria:** External read API or export available; explicit non-goals for write path documented
- **Future plan slug:** `platform-roles-phase-d-adapters`
