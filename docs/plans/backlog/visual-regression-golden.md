# Golden visual regression tests

- **Status:** partial
- **Implemented so far:** `test/golden/` scaffold exists (e.g. [test/golden/session_card_golden_test.dart](../../../test/golden/session_card_golden_test.dart), [test/golden/achievement_badge_golden_test.dart](../../../test/golden/achievement_badge_golden_test.dart)) but only as placeholder tests — no `matchesGoldenFile` baselines yet.
- **Remaining:** Real golden PNG baselines plus a documented `flutter test --update-goldens` workflow and CI diff-report step.
- **Problem:** Golden visual regression tests is out of scope for the Enterprise Foundation Sprint.
- **Approach:** Capture requirements and promote when foundations (auth, API layer, i18n) are stable.
- **Depends on:** enterprise-foundation-sprint completion
- **Promotion criteria:** Product owner prioritizes; technical prerequisites met; Tier 1/2 validation plan exists.
- **Future plan slug:** `visual-regression-golden`
