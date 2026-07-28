# Shipped ideas (archived)

Twelve product ideas were **promoted and shipped** in `lib/` during the hackathon sprint. They are removed from the active brainstorm index to keep [README.md](README.md) focused on unscheduled work.

**Removed from active index on 2026-07-13;** see [Promoted](../README.md#promoted) for the canonical promotion table.

| ID | Title | Summary | Lib touchpoints |
|----|-------|---------|-----------------|
| IDEA-DS-001 | Explain-why on recommendations | Surface 1–3 reason chips on ranked sessions so sorting is explainable, not black-box. | `recommendation_service.dart` `_matchReasons`, `session_card.dart`, `flo_picks_hero.dart` |
| IDEA-DS-002 | My Plan conflict resolver | Detect overlapping slots in My Plan; show conflict groups and swap/simulator suggestions. | `conflict_detector.dart`, `my_plan_screen.dart`, `discovery_delight_sheets.dart` |
| IDEA-DS-004 | Micro-agenda (next 2 hours) | “What now” carousel: sessions in the next 120 minutes from plan + top picks. | `micro_agenda_service.dart`, `discover_screen.dart` `_MicroAgendaRow`, `now_next_bar.dart` |
| IDEA-DS-005 | Session capacity and waitlist hint | “Likely full — stream instead” when utilization is high from mock `occupancyPercent`. | `session_capacity.dart`, `session_detail_assembler.dart`, `flo2026_sessions.json` |
| IDEA-DS-006 | Similar sessions | “If you miss this” block with same-track/tag alternatives on session detail. | `recommendation_service.dart` `findMissedAlternatives`, `session_detail_related_section.dart` |
| IDEA-CG-007 | Networking card (QR contact exchange) | Opt-in digital card with QR token URL, vCard download, and channel visibility toggles. | `connect_card_screen.dart`, `networking_card_editor_screen.dart`, `networking_card_share_service.dart` |
| IDEA-VL-002 | Amenity layer expansion | Enriched amenities index on venue map and Companion “nearest quiet zone” answers. | `flo2026_amenities.json`, `venue_map_screen.dart`, `rule_based_companion_service.dart` `_amenityQuery` |
| IDEA-EN-004 | Post-session pulse | One-tap “worth it?” after sessions; local pulse feeds engagement signals. | `session_detail_engagement_panel.dart` `SessionDetailPulseSection`, `engagement_provider.dart` `setPulse` |
| IDEA-EN-005 | Recap shareable summary | “My Flo 2026 in 60 seconds” share card with PNG/text export. | `recap_screen.dart`, `recap_share_card.dart`, `web_download.dart` |
| IDEA-CA-003 | Plan-aware chat | Companion injects plan, conflicts, and clock for contextual “what next” coaching. | `companion_provider.dart`, `companion_context_builder.dart` `PLAN_NEXT`, `rule_based_companion_service.dart` `_planCoachQuery` |
| IDEA-CA-006 | Client-side event knowledge RAG | Client-side retriever + context builder; rule engine owns truth; LLM rephrases with citations. | `companion_knowledge_retriever.dart`, `companion_context_builder.dart`, `llm_companion_service.dart` |
| IDEA-PE-011 | Platform roles for organizer/admin overlays | `PlatformRole` RBAC for Q&A moderation, announcements, prompt curation, and ops audit. | `platform_role.dart`, `app_capability.dart`, `app_router.dart`, `lib/features/operations/` |
