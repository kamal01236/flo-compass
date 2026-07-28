# Hindi locale and RTL layout support

- **Status:** rejected
- **Rejected:** Hindi + RTL out of scope for Flo 2026 (EN/DE/ES remain)
- **Implemented so far:** gen-l10n wiring in [l10n.yaml](../../../l10n.yaml), EN/DE/ES ARBs under [lib/l10n/](../../../lib/l10n/), and a Profile locale picker are already in place.
- **Remaining:** Hindi ARB (`app_hi.arb`) plus RTL layout support — including replacing the hardcoded LTR assumption in [lib/shared/widgets/error_boundary/error_boundary.dart](../../../lib/shared/widgets/error_boundary/error_boundary.dart) and adding RTL widget tests.
- **Problem:** Hindi locale and RTL layout support is out of scope for the Enterprise Foundation Sprint.
- **Approach:** Capture requirements and promote when foundations (auth, API layer, i18n) are stable.
- **Depends on:** enterprise-foundation-sprint completion
- **Promotion criteria:** Product owner prioritizes; technical prerequisites met; Tier 1/2 validation plan exists.
- **Future plan slug:** `i18n-hindi-rtl`
