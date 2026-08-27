# Production config profile hardening

- **Status:** shortlisted
- **Sprint 2 priority:** yes (child of [production-pipeline-bundle.md](production-pipeline-bundle.md); also P0 of [security remediation plan](../../../.cursor/plans/security_remediation_887c.plan.md))
- **Implemented so far:**
  - `_resolvePlatformRoleOverride` / `resolvePlatformRoleOverride` in [lib/core/config/runtime_config.dart](../../../lib/core/config/runtime_config.dart) returns `null` outside the `dev` profile, so a stray `mockRole` cannot elevate a prod build.
  - GitHub Actions [ci-deploy.yml](../../../.github/workflows/ci-deploy.yml) sets `CONFIG_PROFILE: prod` (GitLab CI path retired).
- **Remaining (security audit 2026-08-27):**
  1. **Critical gap vs live risk:** `config.prod.json` still ships non-empty **`mockUsers`** (admin/organizer). `mockLoginEnabled` is true whenever that list is non-empty on **any** profile — visitors can elevate via Profile demo picker. Empty `mockUsers` in prod/default; gate parsing + `signInMock` to `dev` only.
  2. Add CI guard (`scripts/check_prod_config.sh`) that fails when `assets/config/config.prod.json` has non-empty `mockRole`, `mockUsers`, or populated organizer/admin allowlists.
  3. Once real Azure AD login is configured (`AuthConfig.enabled = true`), remove `platformRoleOverride` fallback and stop trusting stored `platformRole` without re-resolution ([encrypted-web-storage.md](encrypted-web-storage.md), session-trust slice in security plan).
- **Problem:** Demo privilege paths (`mockRole` historically; **`mockUsers` currently**) + auth disabled mean organizer/admin moderation UI is reachable by any public Pages visitor without a real identity provider.
- **Depends on:** none for P0 mockUsers removal; real IdP for full auth cutover
- **Promotion criteria:** P0 merged; CI guard green; prod Pages smoke shows no demo user picker
- **Future plan slug:** `prod-config-profile-hardening`
