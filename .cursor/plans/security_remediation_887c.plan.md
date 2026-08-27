---
name: Security remediation
overview: Close High/Medium security gaps found in the Flo Compass static Pages deploy — starting with prod mockUsers privilege UI, then session trust, Pages headers, and dependency scanning.
todos:
  - id: p0-mock-users
    content: "P0: Remove prod mockUsers; gate mock login to dev; CI prod-config guard"
    status: pending
  - id: p1-session-trust
    content: "P1: Stop trusting stored platformRole; sanitize OAuth returnUrl; tighten token persistence"
    status: pending
  - id: p2-pages-headers-tokens
    content: "P2: Pages security headers path; signed/opaque connect-card tokens; tighten CSP"
    status: pending
  - id: p3-deps-sbom
    content: "P3: Enable Dependabot + OSV/pub outdated CI; promote encrypted-storage after threat model"
    status: pending
isProject: false
---

# Security remediation plan

Audit date: 2026-08-27. Scope: Flo Compass Flutter web + GitHub Actions → GitHub Pages + local nginx Docker.

## Executive summary

| Severity | Count | Top issue |
|----------|-------|-----------|
| Critical | 0* | *Becomes Critical once a real API trusts client roles/tokens |
| High | 3 | Prod ships demo admin/organizer `mockUsers` |
| Medium | 5 | No Pages security headers; forgeable share tokens; OAuth returnUrl |
| Low / Info | 6 | No Dependabot; CSP `connect-src https:`; LLM filters dormant |

**Highest-confidence production finding:** `assets/config/config.prod.json` still contains `mockUsers` with `admin` / `organizer`. `RuntimeConfig.mockLoginEnabled` is true whenever that list is non-empty **on any profile**, so any visitor can elevate via Profile → demo user picker. `mockRole` was already hard-gated to `dev`; **`mockUsers` was not**.

Blast radius today is mostly UI/local mock backends (ops/Q&A in `shared_preferences`), not multi-user server compromise — still a real privilege-UI failure for a public Pages URL.

---

## Findings

### High

#### H1 — Prod demo `mockUsers` enables organizer/admin UI
- **Evidence:** [`assets/config/config.prod.json`](assets/config/config.prod.json) `platformRoles.mockUsers` (Kamlesh=admin, Kishan=organizer). [`lib/core/config/runtime_config.dart`](lib/core/config/runtime_config.dart) `mockLoginEnabled => mockUsers.isNotEmpty`. Profile + Flo Meets call `showMockUserPicker` → `AuthService.signInMock`.
- **Exploit:** Open prod site → onboarding → Profile demo picker → pick admin → `/admin`, `/organizer/*` pass capability/route gates.
- **Fix (P0):** Empty `mockUsers` in prod (and default) config; parse/enable mock users **only** when `configProfile == 'dev'`; refuse `signInMock` outside `dev`; CI script fails if prod JSON has non-empty `mockUsers` / `mockRole` / allowlists.

#### H2 — Client-trusted `platformRole` in browser storage
- **Evidence:** [`lib/data/local/local_user_store.dart`](lib/data/local/local_user_store.dart) keys `flo_auth_access_token`, `flo_auth_platform_role`. `AuthService.restoreSession` rebuilds elevated session from stored values while `auth.enabled: false`.
- **Exploit:** Set localStorage/prefs to fake token + `platform_role=admin` → refresh → admin without picker.
- **Fix (P1):** Outside verified OAuth (or outside `dev`): never restore elevated roles; ignore stored role unless re-derived from allowlists/claims after auth is on.

#### H3 — OAuth tokens + PII in unencrypted `localStorage`
- **Evidence:** `LocalUserStore` documents web = unencrypted SharedPreferences; persists access/refresh/id tokens, email, role. Backlog: [`encrypted-web-storage.md`](docs/plans/backlog/encrypted-web-storage.md).
- **Exploit:** XSS, extension, or shared device steals refresh tokens / contact PII (relevant once `auth.enabled: true`).
- **Fix (P1/P3):** Prefer memory + short-lived access; refresh via BFF/httpOnly cookie when API exists; encrypted-at-rest is defense-in-depth only (does not stop XSS).

### Medium

#### M1 — GitHub Pages lacks nginx security headers
- **Evidence:** Headers only in [`docker/nginx/snippets/security-headers.conf`](docker/nginx/snippets/security-headers.conf). Prod path is static Pages ([`ci-deploy.yml`](.github/workflows/ci-deploy.yml)); `web/index.html` has no CSP/XFO meta.
- **Exploit:** Clickjacking; weaker XSS containment; no HSTS/COOP/CORP on live URL.
- **Fix (P2):** Document Pages header limits; add meta CSP where feasible; optional Cloudflare/Netlify headers; keep nginx as Tier-2 parity.

#### M2 — Connect-card (and plan-share) tokens are unsigned base64url JSON
- **Evidence:** [`networking_card_share_service.dart`](lib/data/services/networking_card_share_service.dart), [`plan_share_service.dart`](lib/data/services/plan_share_service.dart) — no MAC/TTL. LinkedIn host allowlist is good; email not equivalently validated.
- **Exploit:** Forge spoofed name/email → phishing vCard/`mailto:`; PII in URL history/logs.
- **Fix (P2):** HMAC or opaque IDs + TTL; email validation; strip dangerous mailto query.

#### M3 — OAuth callback `returnUrl` not sanitized
- **Evidence:** Consent uses `AppRoutes.sanitizeReturnTo`; auth callback uses `consumeReturnUrl()` without sanitize.
- **Fix (P1):** Always sanitize/allowlist before `context.go`.

#### M4 — JWT payload decoded without signature verification
- **Evidence:** `AuthService._decodeJwtPayload` base64-only.
- **Fix (P1):** Treat client JWT as untrusted display; re-resolve role via userinfo/allowlist when auth is on.

#### M5 — Prod-config hardening backlog incomplete
- **Evidence:** [`prod-config-profile-hardening.md`](docs/plans/backlog/prod-config-profile-hardening.md) addresses `mockRole` but not live **`mockUsers`** path; CI already sets `CONFIG_PROFILE=prod`.
- **Fix (P0):** Extend backlog + CI guard for `mockUsers`.

### Low / Info

| ID | Issue | Fix phase |
|----|--------|-----------|
| L1 | Dependabot alerts disabled; no `dependabot.yml` / SBOM | P3 |
| L2 | nginx `connect-src 'self' https: wss:` too broad | P2 |
| L3 | Weak LLM injection/PII filters (`companionLlm: false` in prod) | Keep off until P3 |
| L4 | `gh-pages` publish uses `contents: write` | Prefer Actions Pages when enabled |
| I1 | Classic HTML XSS largely mitigated (Flutter `Text`) | Maintain |
| I2 | Launch scheme allowlist blocks `javascript:` / `data:` | Maintain |
| I3 | `auth.enabled: false` everywhere — OAuth surface dormant | OK until real IdP |

### Already mitigated
- `mockRole` ignored outside `dev` (`resolvePlatformRoleOverride`)
- CI `CONFIG_PROFILE=prod`
- PKCE S256 + state; verifier in `sessionStorage`
- Route + capability guards for organizer/admin
- LinkedIn URL normalization + tests
- Analytics property allowlist
- Tier-2 nginx CSP/HSTS/XFO/COOP/CORP
- No secrets in workflow; validate job `contents: read`

---

## Phased remediation

### P0 — Stop prod privilege UI (ship first)
**Files**
- `assets/config/config.prod.json` — `"mockUsers": []`
- `assets/config/config.default.json` — same if present
- `lib/core/config/runtime_config.dart` — parse/enable mock users only for `dev`
- `lib/core/auth/auth_service.dart` — refuse `signInMock` when profile ≠ `dev`
- `scripts/check_prod_config.sh` (new) + wire into `.github/workflows/ci-deploy.yml` validate job
- Tests: extend `test/core/config/runtime_config_test.dart`

**Done when:** Prod build has no demo picker; CI fails if prod config regains `mockUsers`/`mockRole`.

### P1 — Session trust model
- Restore session without trusting stored elevated `platformRole` when auth is off / unverified
- Sanitize OAuth `returnUrl` on callback
- Document client RBAC as UX-only until backend enforces

### P2 — Pages / sharing / CSP
- Security headers strategy for Pages (meta CSP + docs; CDN optional)
- Signed or opaque connect-card tokens + email validation
- Tighten Docker CSP `connect-src` to known hosts

### P3 — Hygiene
- `.github/dependabot.yml` for `pub` + GitHub Actions
- OSV / `dart pub outdated` in CI (`dependency-scanning-sbom`)
- Encrypted storage spike only after XSS threat model
- Stronger LLM guards before enabling `companionLlm` in prod

---

## Ownership / serial-merge notes

Shared files likely touched in P0 (serial if parallelized):
- `pubspec.yaml` — only if new deps (prefer none for P0)
- `.github/workflows/**` — CI guard wire-up
- Prefer single agent for P0 (config + runtime + CI + tests)

## Validation
- Tier 1: `flutter analyze && flutter test` (esp. runtime_config + profile mock-login tests)
- CI: new prod-config check on PR
- Manual: prod-profile web build — Profile must **not** show demo user picker

## Out of scope for this plan
- Enabling real Azure AD / backend RBAC (separate platform-roles work)
- Enabling GitHub Pages hosting toggle (ops; already documented)
- Rewriting mock Q&A/ops to a real multi-tenant API
