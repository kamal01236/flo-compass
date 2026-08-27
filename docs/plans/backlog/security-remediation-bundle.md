# Security remediation bundle

- **Status:** shortlisted
- **Sprint 2 priority:** yes
- **Problem:** Public GitHub Pages deploy still exposes demo admin/organizer login (`mockUsers` in prod config), trusts client-stored platform roles, lacks Pages security headers, and has no Dependabot/SBOM scanning. Full findings and phases live in [`.cursor/plans/security_remediation_887c.plan.md`](../../../.cursor/plans/security_remediation_887c.plan.md).
- **Approach:** Ship phases in order:
  | Phase | Scope | Child / related |
  |-------|--------|-----------------|
  | P0 | Empty prod `mockUsers`; dev-only mock login; CI prod-config guard | [prod-config-profile-hardening.md](prod-config-profile-hardening.md) |
  | P1 | Session trust + OAuth returnUrl sanitize | auth restore / `LocalUserStore` |
  | P2 | Pages headers strategy; signed share tokens; tighter CSP | nginx + connect-card |
  | P3 | Dependabot + SBOM; encrypted storage triage; LLM guards | [dependency-scanning-sbom.md](dependency-scanning-sbom.md), [encrypted-web-storage.md](encrypted-web-storage.md) |
- **Depends on:** none for P0; IdP/backend for full RBAC
- **Promotion criteria:** P0 merged and verified on prod-profile build; plan phases marked done incrementally
- **Future plan slug:** `security-remediation`
