# Flo Compass Data

| Field | Value |
|-------|-------|
| **File** | `.cursor/rules/flo-compass-data.mdc` |
| **Purpose** | ~650 sessions, Gurgaon venue topology, wing and cafeteria integrity rules |
| **Scope** | `globs: assets/data/**,tools/**,lib/data/**` |
| **When to @cite** | Generator changes, session/speaker/venue models, dataset validation, mock data scale |

## Key guardrails

- ~90 spaces, Ground + floors 6–13; ~650 sessions over 3 days; ~80 fictional speakers
- Required session fields: id, title, abstract, day, times, venueId, trackId, speakerIds, tags, format, level, featured, capacity, building
- Integrity: resolve all foreign keys; no double-booked speakers; capacity ≤ venue; 12:00 slot cafeteria-only (`ven-C601`)
- Every venue has `wing` (N/S/central) matching id convention
- No PII — fictional speakers only, no real Nagarro employees or attendee data

## Source

[`.cursor/rules/flo-compass-data.mdc`](../../.cursor/rules/flo-compass-data.mdc)
