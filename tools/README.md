# Flo Compass — data tools

Deterministic generator + validator for the Flo 2026 dataset at **Nagarro Gurgaon Office**.

Everything lives under `tools/` and writes JSON into `assets/data/`.

## Files

| File | Purpose |
|------|---------|
| `generate_flo_data.dart` | Self-contained Dart script (`dart:io`, `dart:convert`, `dart:math`) that generates the full dataset. Uses a portable LCG seeded with `20260709`, so runs are byte-identical across machines. |
| `validate_dataset.dart` | Referential + business-rule validator. Exits 0 on success; prints violations and exits 1 on failure. |
| `README.md` | This file. |

The generated JSON files (`flo2026_meta.json`, `flo2026_venues.json`, `flo2026_tracks.json`, `flo2026_speakers.json`, `flo2026_sessions.json`) and the JSON Schemas under `assets/data/schema/` are the source of truth for the Flutter app. Regenerate whenever the plan's dataset section changes.

## Regenerate

Run from the repo root:

```bash
dart run tools/generate_flo_data.dart
```

This writes five JSON files into `assets/data/`. The generator prints per-file paths and a final count summary.

## Validate

```bash
dart run tools/validate_dataset.dart
```

The validator enforces (per the plan's "Data integrity & schema validation" section):

- every `speakerId`, `venueId`, `trackId` referenced from `sessions.json` resolves to a record
- no speaker appears in two sessions with the same `day + startTime`
- `session.capacity <= venue.capacity`
- `12:00` is cafeteria-only (`ven-C601`) lightning-talk slot
- **exactly 10** sessions with `featured=true`
- every `session.building` and `venue.building` is `"Nagarro Gurgaon Office"`
- required fields present on every entity; `format`, `level`, `day` respect their enums
- speakers contain no email/phone-shaped PII

Exit code:

- `0` — all checks pass
- `1` — one or more violations printed to `stderr`
- `2` — dataset files could not be read

## Determinism

The generator uses a self-contained Linear Congruential Generator (`state = (state * 1103515245 + 12345) & 0x7FFFFFFF`) seeded with `20260709`. This makes output stable across Dart versions and easy to mirror in other tooling if a Dart runtime isn't available on a given machine. **No wall-clock or environment inputs affect the output.**

## Data shape summary

- **Meta** — event name, venue, timezone, slots, three days.
- **Venues** — 90 spaces across Ground + 6th-13th floors with `building = "Nagarro Gurgaon Office"`, including `wing`, `floor`, `zone`, `capacity`, `description`.
- **Tracks** — the 10 tracks from the plan.
- **Speakers** — 20 curated C-suite/leadership personas (exact names/titles from the plan, including parenthetical acronyms) + 60 generated Tier 3–4 personas.
- **Sessions** — the 10 hardcoded featured sessions + generated sessions filling the day/slot targets with 12:00 cafeteria lightning talks only.

## When to change what

- **Change speaker roster / titles** → edit `_curatedSpeakers()` and rerun the generator.
- **Change a featured session** → edit `_featuredSessionsSeed()` (also update the plan's *Featured sessions* table).
- **Change track catalog** → edit `buildTracks()`.
- **Change slot / room activity** → edit `_activeRoomsPerSlot()`.
- **Change session title / abstract style** → edit `_titleTemplatesByTrack()` / `_abstractPatternsFor()`.

After any change, always re-run the validator.
