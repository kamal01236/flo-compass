# Platform roles Phase C — admin operations

- **Status:** partial
- **Implemented so far:** [lib/features/operations/admin_operations_panel.dart](../../../lib/features/operations/admin_operations_panel.dart) delivers allowlist editing, an audit-log listing, and read-only feature-flag tiles gated by `AppCapability.manageOpsConfig`.
- **Remaining:** Editable feature-flag management (write path with confirmation + audit entry) beyond the current read-only tiles.
- **Problem:** Admin role exists in RBAC but lacks dedicated ops UI for roster, feature flags, and audit trails.
- **Approach:** Mock-first admin screens: role assignment from allowlist, event-level feature toggles, append-only ops audit log. Gate with `AppCapability.manageOpsConfig`.
- **Depends on:** Phase A+B platform roles (`platform-roles-rbac.md`)
- **Promotion criteria:** Admin workflows prioritized; mock allowlist contract agreed; Tier 1 tests for admin-only routes
- **Future plan slug:** `platform-roles-phase-c-admin`
