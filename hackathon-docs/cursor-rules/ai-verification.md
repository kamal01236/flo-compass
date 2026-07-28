# AI Verification

| Field | Value |
|-------|-------|
| **File** | `.cursor/rules/ai-verification.mdc` |
| **Purpose** | Pre-accept checks + hallucination category tags for augmentation log |
| **Scope** | Agent-requestable (`alwaysApply: false`) |
| **When to @cite** | Reviewing diffs before merge; verifying Cursor-produced paths, versions, routes, dataset fields |

## Key guardrails

- Verify cited file paths exist; package versions match `pubspec.lock`
- Routes must appear in `lib/routing/app_router.dart`; dataset fields in `assets/data/schema/*.json`
- Test counts must match `flutter test` output
- Forbidden shared surface → serial-merge patch notes, not direct per-plan edits
- Log hallucinations in augmentation-log even when `Outcome` is `accepted`
- New/changed `.mdc` must have matching `hackathon-docs/cursor-rules/<slug>.md` per `cursor-rules-catalog.mdc`
- Tag categories: `api-hallucination`, `wrong-version`, `wrong-path`, `stale-docs`, `scope-drift`, `dataset-drift`, `security-miss`

## Source

[`.cursor/rules/ai-verification.mdc`](../../.cursor/rules/ai-verification.mdc)
