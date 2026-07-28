# Trust and privacy

Flo Compass complements Accelevents — no registration, ticketing, check-in, badge printing, or official agenda CRUD. See [flo-compass-product.mdc](../../../.cursor/rules/flo-compass-product.mdc).

Privacy, compliance, and clear platform boundaries — especially relevant for EU (Germany) attendees.

---

### IDEA-TP-001 Privacy-first profile

- **Tier:** later
- **Status:** partial
- **Implemented so far:** "Data stays on device" copy + [lib/features/consent/privacy_consent_screen.dart](../../../lib/features/consent/privacy_consent_screen.dart) + [lib/features/legal/privacy_policy_screen.dart](../../../lib/features/legal/privacy_policy_screen.dart).
- **Remaining:** dedicated privacy diagram/section.
- **Problem:** Global enterprise users expect clarity on what data leaves the device; interests and plan today use `shared_preferences` but UX does not state it.
- **Approach:** Profile/settings copy: “Interests and My Plan stay on this device”; optional diagram in privacy section; no account required for MVP.
- **Touches:** `lib/features/profile/profile_screen.dart`, `lib/providers/profile_provider.dart`, `lib/providers/plan_provider.dart`
- **Depends on:** none
- **Related backlog:** [encrypted-web-storage](../backlog/encrypted-web-storage.md)
- **Future plan slug:** `privacy-first-profile`
- **Out of scope (Accelevents):** attendee PII in registration system

---

### IDEA-TP-002 GDPR-style controls

- **Tier:** later
- **Status:** partial
- **Implemented so far:** reset progress + analytics buffer export/clear ([lib/features/profile/widgets/analytics_diagnostics_panel.dart](../../../lib/features/profile/widgets/analytics_diagnostics_panel.dart)).
- **Remaining:** unified profile+plan JSON export + one-shot "clear all local data".
- **Problem:** German and EU users need export/delete and analytics opt-in before any telemetry ships.
- **Approach:** Export profile + plan JSON; clear all local data; analytics opt-in toggle default off; document in HACKATHON-README privacy section.
- **Touches:** `lib/features/profile/profile_screen.dart`, `lib/providers/app_settings_provider.dart`
- **Depends on:** IDEA-TP-001
- **Related backlog:** [audit-trail-analytics](../backlog/audit-trail-analytics.md)
- **Future plan slug:** `gdpr-style-controls`
- **Out of scope (Accelevents):** GDPR for registration data in Accelevents

---

### IDEA-TP-003 No real PII in mock data

- **Tier:** later
- **Status:** partial
- **Implemented so far:** [.cursor/rules/flo-compass-data.mdc](../../../.cursor/rules/flo-compass-data.mdc) enforced by review.
- **Remaining:** CI grep guard against email/phone in `assets/data/`.
- **Problem:** Global rollout and demos must never leak real Nagarro employees or attendee data in fixtures.
- **Approach:** Document as enforceable product rule (already in `flo-compass-data.mdc`); CI grep guard for email/phone patterns in `assets/data/`; idea tracks audit not feature code.
- **Touches:** `assets/data/`, `.cursor/rules/flo-compass-data.mdc`, CI lint script (future)
- **Depends on:** none
- **Related backlog:** none
- **Future plan slug:** `pii-mock-data-guard`
- **Out of scope (Accelevents):** real attendee imports

---

### IDEA-TP-004 Accelevents deep-link boundary

- **Tier:** now
- **Status:** partial
- **Implemented so far:** complement copy in onboarding + connect + ARBs.
- **Remaining:** configurable Accelevents URL + session-detail/shell handoff link.
- **Problem:** Users confuse Flo Compass with official registration/networking; need explicit handoff to Accelevents for badge and official features.
- **Approach:** Session detail and shell footer: “Open in Accelevents for badge and networking” with configurable URL template; demo copy states complement positioning.
- **Touches:** `lib/features/session_detail/session_detail_screen.dart`, `lib/features/shell/main_shell.dart`, `assets/config/config.*.json`
- **Depends on:** none
- **Related backlog:** none
- **Future plan slug:** `accelevents-deep-link-boundary`
- **Out of scope (Accelevents):** we do not build those features — link only
