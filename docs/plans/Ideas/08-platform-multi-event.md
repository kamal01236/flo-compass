# Platform and multi-event

Flo Compass complements Accelevents — no registration, ticketing, check-in, badge printing, or official agenda CRUD. See [flo-compass-product.mdc](../../../.cursor/rules/flo-compass-product.mdc).

**Event Compass** vision: white-label attendee intelligence layer reusable across events worldwide.

Shipped platform roles (PE-011) are archived in [SHIPPED.md](SHIPPED.md).

---

### IDEA-PE-001 Event picker (multi-event home)

- **Tier:** platform
- **Status:** idea
- **Problem:** Single-event hardcoding (`Flo 2026`) blocks reuse for Client Summit APAC, Tech Day EU, etc.
- **Approach:** Home or deep link selects event id; route prefix `/e/:eventId/discover`; QR opens one event directly.
- **Touches:** `lib/routing/app_router.dart`, `lib/app.dart`, `assets/config/`
- **Depends on:** IDEA-PE-007, IDEA-PE-008
- **Related backlog:** none
- **Future plan slug:** `multi-event-picker`
- **Out of scope (Accelevents):** multi-event registration account

---

### IDEA-PE-002 White-label theming

- **Tier:** platform
- **Status:** idea
- **Problem:** Each customer needs logo, accent color, and event name without forking the repo.
- **Approach:** Event pack includes `branding: { name, logoUrl, primaryGradient }`; `app_theme.dart` reads from loaded config.
- **Touches:** `lib/shared/theme/app_theme.dart`, event pack JSON, `web/manifest.json` (serial-merge patch on promotion)
- **Depends on:** IDEA-PE-007
- **Related backlog:** [design-tokens-storybook](../backlog/design-tokens-storybook.md)
- **Future plan slug:** `white-label-theming`
- **Out of scope (Accelevents):** none

---

### IDEA-PE-003 Universal profile, per-event plans

- **Tier:** platform
- **Status:** idea
- **Problem:** Interests persist across events but My Plan must not mix Flo 2026 with another conference.
- **Approach:** Profile global in `shared_preferences`; plan keys namespaced `plan:{eventId}`; import/export per event.
- **Touches:** `lib/providers/plan_provider.dart`, `lib/providers/profile_provider.dart`, `lib/features/my_plan/plan_import_screen.dart`
- **Depends on:** IDEA-PE-001
- **Related backlog:** [cross-device-sync](../backlog/cross-device-sync.md)
- **Future plan slug:** `universal-profile-event-plans`
- **Out of scope (Accelevents):** none

---

### IDEA-PE-004 Timezone engine (IANA)

- **Tier:** platform
- **Status:** partial
- **Implemented so far:** `timezone` field on entities.
- **Remaining:** `timezone` package + drop hardcoded `+5:30` in [lib/shared/utils/session_time_display.dart](../../../lib/shared/utils/session_time_display.dart).
- **Problem:** `flo2026_meta.json` uses human-readable IST string; global events need `Asia/Kolkata`, `Europe/Berlin`, etc.
- **Approach:** Event meta field `timezone: "Asia/Kolkata"`; all UI uses `timezone` package; never hardcode venue offset in widgets.
- **Touches:** `assets/data/flo2026_meta.json`, `assets/data/schema/`, all time display widgets
- **Depends on:** none
- **Related backlog:** none
- **Future plan slug:** `iana-timezone-engine`
- **Out of scope (Accelevents):** none

---

### IDEA-PE-005 Integration adapters (read-only)

- **Tier:** platform
- **Status:** idea
- **Problem:** Organizers use Accelevents, Eventbrite, Hopin — Compass needs read-only session/stream sync without owning CRUD.
- **Approach:** Thin `lib/data/adapters/` per platform; map to internal event pack schema; refresh on schedule.
- **Touches:** `lib/data/`, `assets/config/config.*.json`
- **Depends on:** IDEA-PE-007, [api-contract-openapi](../backlog/api-contract-openapi.md)
- **Related backlog:** [full-remote-sync](../backlog/full-remote-sync.md), [api-contract-openapi](../backlog/api-contract-openapi.md)
- **Future plan slug:** `integration-adapters`
- **Out of scope (Accelevents):** write API to official agenda

---

### IDEA-PE-006 Offline-first event pack

- **Tier:** platform
- **Status:** partial
- **Implemented so far:** [lib/shared/widgets/offline_banner.dart](../../../lib/shared/widgets/offline_banner.dart) + SW cache clear in [web/shell.js](../../../web/shell.js).
- **Remaining:** IndexedDB event-pack download layer.
- **Problem:** Convention centers and international travel mean unreliable Wi‑Fi; cold start offline fails today.
- **Approach:** Download full event pack on first visit; service worker or IndexedDB cache list; Companion FAQ fallback offline.
- **Touches:** `web/`, `lib/data/services/`, `lib/shared/utils/connectivity.dart`
- **Depends on:** IDEA-PE-007
- **Related backlog:** none
- **Future plan slug:** `offline-event-pack`
- **Out of scope (Accelevents):** none

---

### IDEA-PE-007 Event pack schema

- **Tier:** platform
- **Status:** partial
- **Implemented so far:** per-entity schemas in [assets/data/schema/](../../../assets/data/schema/).
- **Remaining:** unified `event.pack.json` manifest + generator.
- **Problem:** Sessions, venues, speakers, meta, paths, amenities are Flo-specific files; multi-event needs one versioned bundle format.
- **Approach:** `event.pack.json` manifest + referenced chunks; JSON Schema validation; generator outputs per event slug.
- **Touches:** `assets/data/schema/`, `tool/` or `scripts/` generator
- **Depends on:** none
- **Related backlog:** [api-contract-openapi](../backlog/api-contract-openapi.md)
- **Future plan slug:** `event-pack-schema`
- **Out of scope (Accelevents):** none

---

### IDEA-PE-008 Config per event

- **Tier:** platform
- **Status:** partial
- **Implemented so far:** [assets/config/config.default.json](../../../assets/config/config.default.json) + `CONFIG_PROFILE` in [lib/core/config/runtime_config.dart](../../../lib/core/config/runtime_config.dart).
- **Remaining:** `config.{eventId}.json` + `EVENT_ID` overlay.
- **Problem:** `config.prod.json` is single-tenant; feature flags and Accelevents URLs differ per customer event.
- **Approach:** `config.{eventId}.json` or overlay on base config; `--dart-define=EVENT_ID=` for build targets.
- **Touches:** `assets/config/`, `lib/config/app_config.dart`
- **Depends on:** IDEA-PE-001
- **Related backlog:** none
- **Future plan slug:** `per-event-config`
- **Out of scope (Accelevents):** none

---

### IDEA-PE-009 i18n and RTL platform-wide

- **Tier:** platform
- **Status:** partial
- **Implemented so far:** EN/DE/ES ARBs + profile locale picker.
- **Remaining:** Hebrew/Hindi ARBs + RTL layout tests.
- **Problem:** Hebrew RTL and Hindi UI require Flutter l10n arb files, not one-off Companion strings.
- **Approach:** `flutter gen-l10n`; locale from profile/browser; RTL layout test on shell and Discover.
- **Touches:** `lib/l10n/`, `lib/app.dart`, all feature screens
- **Depends on:** none
- **Related backlog:** [i18n-hindi-rtl](../backlog/i18n-hindi-rtl.md) (rejected — Hindi out of scope)
- **Future plan slug:** `platform-i18n-rtl`
- **Out of scope (Accelevents):** none

---

### IDEA-PE-010 Event type templates

- **Tier:** platform
- **Status:** idea
- **Problem:** Summit vs hackathon vs virtual-only need different default features and copy.
- **Approach:** Template presets in event pack: `eventType: summit | clientConf | hackathon | roadshow | virtual` toggles map, bingo, directions emphasis.
- **Touches:** event pack manifest, feature flags in `app_config.dart`
- **Depends on:** IDEA-PE-007, IDEA-PE-008
- **Related backlog:** none
- **Future plan slug:** `event-type-templates`
- **Out of scope (Accelevents):** none

---

## Event type matrix (reference)

| Event type | Compass emphasis | De-emphasize |
|------------|------------------|--------------|
| Large internal summit (Flo) | Learning paths, hybrid, overwhelm | — |
| Client conference | Executive summaries, industry tracks | Internal bingo |
| University / hackathon | Team plans, judging, mentors | Floor maps |
| Multi-city roadshow | Per-city venue packs | Single building map |
| Fully virtual | Streams, co-watch, timezone rooms | Indoor navigation |

## Platform positioning (one-liner)

Event Compass is the attendee intelligence layer — personalized discovery, explainable recommendations, and AI Q&A over any event’s agenda, in your language and timezone, while the registration platform stays in charge.
