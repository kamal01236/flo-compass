# Playwright browser E2E test suite

- **Status:** partial
- **Implemented so far:** Demo walkthrough script at [tools/demo/walkthrough.mjs](../../../tools/demo/walkthrough.mjs) drives a scripted browser session for the recorded demo.
- **Remaining:** Regression-grade E2E suite wired into CI (per-PR gate, retries, screenshots on failure) covering the critical flows beyond the demo path.
- **Problem:** Playwright browser E2E test suite is out of scope for the Enterprise Foundation Sprint.
- **Approach:** Capture requirements and promote when foundations (auth, API layer, i18n) are stable.
- **Depends on:** enterprise-foundation-sprint completion
- **Promotion criteria:** Product owner prioritizes; technical prerequisites met; Tier 1/2 validation plan exists.
- **Future plan slug:** `browser-e2e-playwright`
