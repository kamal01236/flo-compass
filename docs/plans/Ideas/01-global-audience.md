# Global audience

Flo Compass complements Accelevents — no registration, ticketing, check-in, badge printing, or official agenda CRUD. See [flo-compass-product.mdc](../../../.cursor/rules/flo-compass-product.mdc).

Ideas for ~10K attendees across Germany, Israel, India, and remote hubs.

---

### IDEA-GA-001 Dual timezone display

- **Tier:** now
- **Status:** partial
- **Implemented so far:** [lib/shared/utils/session_time_display.dart](../../../lib/shared/utils/session_time_display.dart) on session detail Logistics only.
- **Remaining:** dual line on Discover/My Plan cards; use profile IANA TZ instead of browser offset.
- **Problem:** Session times are venue-local (IST). Attendees in CET (Germany) or Israel misread schedules and miss live streams or hybrid join windows.
- **Approach:** Show venue time plus attendee local time on session cards, detail, and My Plan. Read IANA timezone from profile; venue timezone from event meta (`Asia/Kolkata`).
- **Touches:** `assets/data/flo2026_meta.json`, `lib/features/discover/widgets/discover_session_list.dart`, `lib/features/session_detail/session_detail_screen.dart`, `lib/features/my_plan/my_plan_screen.dart`
- **Depends on:** IDEA-GA-005 (region/timezone in profile) or browser timezone fallback
- **Related backlog:** none
- **Future plan slug:** `dual-timezone-display`
- **Out of scope (Accelevents):** none

---

### IDEA-GA-002 Remote attendee mode

- **Tier:** now
- **Status:** partial
- **Implemented so far:** `AttendanceMode` in [lib/data/models/user_profile.dart](../../../lib/data/models/user_profile.dart), banner + stream CTAs.
- **Remaining:** Discover filter/ranking boost for remote users.
- **Problem:** Most participants are not on-site in Gurgaon; full agenda and directions UX assumes physical attendance.
- **Approach:** Profile flag `attendanceMode: onSite | remote`. Filter Discover to hybrid/stream sessions; hide or soften walk directions; Companion answers reference stream links instead of room walks.
- **Touches:** `lib/data/models/user_profile.dart`, `lib/features/discover/discover_filters.dart`, `lib/features/directions/directions_screen.dart`, `lib/features/companion/companion_screen.dart`
- **Depends on:** session `format` or tags for hybrid/stream in mock data (new field or tag convention)
- **Related backlog:** [full-remote-sync](../backlog/full-remote-sync.md) (for live stream URLs later)
- **Future plan slug:** `remote-attendee-mode`
- **Out of scope (Accelevents):** none

---

### IDEA-GA-003 Language-aware Companion

- **Tier:** next
- **Status:** rejected
- **Rejected:** Hindi not in scope for Flo 2026
- **Problem:** Global audience asks questions in German, Hebrew, Hindi, and English; English-only Companion limits adoption.
- **Approach:** Detect or select UI language; pass locale to Companion provider; answers in user language while grounding session titles in original + translation where available.
- **Touches:** `lib/features/companion/companion_screen.dart`, `lib/providers/companion_provider.dart`, `lib/providers/app_settings_provider.dart`
- **Depends on:** IDEA-PE-009 (platform i18n) or minimal string tables for Companion only
- **Related backlog:** [i18n-hindi-rtl](../backlog/i18n-hindi-rtl.md)
- **Future plan slug:** `language-aware-companion`
- **Out of scope (Accelevents):** none

---

### IDEA-GA-004 Low-bandwidth mode

- **Tier:** next
- **Status:** partial
- **Implemented so far:** photo/animation defer toggle in [lib/providers/app_settings_provider.dart](../../../lib/providers/app_settings_provider.dart).
- **Remaining:** map-tile reduction, offline pack.
- **Problem:** Mobile networks in India and VPN users on international links need a lighter UI; images and animations hurt first paint.
- **Approach:** Settings toggle: defer speaker images, reduce map tile detail, text-first session list, explicit “save pack for offline” CTA. Respect existing offline banner pattern.
- **Touches:** `lib/providers/app_settings_provider.dart`, `lib/features/discover/discover_screen.dart`, `lib/shared/utils/connectivity.dart`
- **Depends on:** IDEA-PE-006 (offline event pack) for full cold-start offline
- **Related backlog:** none
- **Future plan slug:** `low-bandwidth-mode`
- **Out of scope (Accelevents):** none

---

### IDEA-GA-005 Region-aware onboarding

- **Tier:** now
- **Status:** partial
- **Implemented so far:** role/interests/attendance in [lib/features/onboarding/onboarding_screen.dart](../../../lib/features/onboarding/onboarding_screen.dart).
- **Remaining:** region bucket + IANA field.
- **Problem:** Role and interests alone do not capture where someone joins from; rankings and timezone defaults stay wrong.
- **Approach:** Onboarding step: region bucket (India / EU / Israel / Other) + attendance mode + optional IANA timezone. Feed into recommendations (“popular with architects in EU”) and IDEA-GA-001.
- **Touches:** `lib/features/onboarding/onboarding_screen.dart`, `lib/data/models/user_profile.dart`, `lib/providers/profile_provider.dart`
- **Depends on:** none
- **Related backlog:** none
- **Future plan slug:** `region-aware-onboarding`
- **Out of scope (Accelevents):** none

---

### IDEA-GA-006 Quiet hours and notification respect

- **Tier:** next
- **Status:** idea
- **Problem:** Push or in-app nudges at 2am local time for a Gurgaon keynote alienate EU attendees.
- **Approach:** Batch reminders per user local time (“your day starts in 2h”); suppress non-urgent alerts outside waking window. Start with in-app-only before any push layer.
- **Touches:** `lib/providers/profile_provider.dart`, future notification service
- **Depends on:** IDEA-GA-005, IDEA-GA-001
- **Related backlog:** [live-announcements-feed](../backlog/live-announcements-feed.md) (urgent venue-wide alerts)
- **Future plan slug:** `quiet-hours-notifications`
- **Out of scope (Accelevents):** official mass email from organizer CRM
