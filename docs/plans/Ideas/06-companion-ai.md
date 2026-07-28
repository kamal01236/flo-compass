# Companion AI

Flo Compass complements Accelevents — no registration, ticketing, check-in, badge printing, or official agenda CRUD. See [flo-compass-product.mdc](../../../.cursor/rules/flo-compass-product.mdc).

AI Q&A polish for global, multilingual, accessibility-aware event assistance.

Shipped plan-aware chat and RAG (CA-003/006) are archived in [SHIPPED.md](SHIPPED.md).

---

### IDEA-CA-001 Grounded answers only

- **Tier:** next
- **Status:** partial
- **Implemented so far:** post-validated citations in [lib/data/services/llm_companion_service.dart](../../../lib/data/services/llm_companion_service.dart).
- **Remaining:** uniform refuse/defer when ungrounded (fallback suggestions still returned).
- **Problem:** At 10K scale, hallucinated session or speaker facts destroy trust in the Companion.
- **Approach:** Every answer cites session id, speaker id, or venue id from dataset; refuse or defer when not grounded; show source chips linking to detail routes.
- **Touches:** `lib/providers/companion_provider.dart`, `lib/features/companion/companion_screen.dart`
- **Depends on:** none (harden existing rule-based / RAG path)
- **Related backlog:** none
- **Future plan slug:** `grounded-companion-answers`
- **Out of scope (Accelevents):** none

---

### IDEA-CA-002 Multilingual prompts

- **Tier:** next
- **Status:** rejected
- **Rejected:** Hindi not in scope for Flo 2026
- **Problem:** Users ask “Welche Sessions zu Kubernetes?” or Hebrew/Hindi equivalents; English-only input handling limits reach.
- **Approach:** Accept queries in DE/HE/HI/EN; same grounding layer; localized reply strings. Overlaps IDEA-GA-003 — implement together when promoted.
- **Touches:** `lib/providers/companion_provider.dart`, `lib/features/companion/companion_screen.dart`
- **Depends on:** IDEA-GA-003
- **Related backlog:** [i18n-hindi-rtl](../backlog/i18n-hindi-rtl.md) (rejected)
- **Future plan slug:** `multilingual-companion-prompts`
- **Out of scope (Accelevents):** none

---

### IDEA-CA-004 Role-based tone

- **Tier:** later
- **Status:** idea
- **Problem:** Executives want bullets; engineers want lab prerequisites and links — one tone fits poorly.
- **Approach:** System prompt varies by `AttendeeRole`: executive = concise outcomes; engineer = technical depth and prerequisites.
- **Touches:** `lib/providers/companion_provider.dart`, `lib/data/models/user_profile.dart`
- **Depends on:** none
- **Related backlog:** none
- **Future plan slug:** `role-based-companion-tone`
- **Out of scope (Accelevents):** none

---

### IDEA-CA-005 Accessibility Q&A

- **Tier:** later
- **Status:** partial
- **Implemented so far:** [assets/data/session_a11y.json](../../../assets/data/session_a11y.json), [lib/features/session_detail/widgets/session_detail_a11y_section.dart](../../../lib/features/session_detail/widgets/session_detail_a11y_section.dart).
- **Remaining:** `a11y_faq.json` + Companion caption/route Q&A.
- **Problem:** Attendees ask “Is this session captioned?” or “wheelchair route to Hall B?” — answers are not in free-form agenda text.
- **Approach:** Curated FAQ index per session/venue (captioning, hearing loop, step-free route); Companion retrieves from `a11y_faq.json` mock.
- **Touches:** `assets/data/`, `lib/providers/companion_provider.dart`, `lib/features/session_detail/session_detail_screen.dart`
- **Depends on:** organizer a11y metadata
- **Related backlog:** none
- **Future plan slug:** `accessibility-companion-qa`
- **Out of scope (Accelevents):** official accessibility service requests
