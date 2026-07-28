# Platform roles RBAC (organizer/admin overlays)

- **Status:** partial — Phase A+B complete (see **Completed** below); Phase C now partial via the admin operations panel and Phase D still absent (see the **Deferred — Phase C** and **Deferred — Phase D** sections below).
- **Implemented so far:** Phase A+B foundations in [lib/core/auth/platform_role.dart](../../../lib/core/auth/platform_role.dart) plus the organizer surfaces enumerated under **Completed** below; Phase C now partial via [lib/features/operations/admin_operations_panel.dart](../../../lib/features/operations/admin_operations_panel.dart) (allowlist edit + audit list + read-only feature-flag tiles).
- **Remaining:** Phase C editable feature-flag management (see **Deferred — Phase C (admin operations)** below); the Phase D read-only external adapter contract is still absent (see **Deferred — Phase D (read-only external adapters)** below).
- **Problem:** Flo needed organizer overlay tools beyond Q&A moderation — announcements, prompt curation, and a lightweight ops dashboard — without crossing into Accelevents-owned agenda CRUD.
- **Approach:** Phase A delivered RBAC scaffold + Q&A moderation. Phase B added mock-first announcements, prompt curation wired into Session Q&A, and organizer dashboard counts. Phase C/D remain deferred (see below).
- **Depends on:** `platform-roles-organizer-admin_6c16bef3.plan.md` Phase A merged and validated
- **Promotion criteria:** Product owner prioritizes remaining admin/platform work; Accelevents boundary checks explicit; Tier 1 + Tier 2 validation plan included before coding
- **Future plan slug:** `platform-roles-rbac`

## Completed

- **Phase A:** `PlatformRole` RBAC, route gates, Session Q&A moderation (answered/pin/hide)
- **Phase B:** Announcements workflow (draft/publish/archive), prompt curation with prefs overrides, organizer dashboard counts + sub-routes

## Deferred — Phase C (admin operations)

- Admin roster / role assignment UI (mock allowlist first)
- Feature-flag management for event-level ops controls
- Audit trail for moderation and ops actions (mock log first)

**Stub plan:** promote via `platform-roles-phase-c-admin` when prioritized.

## Deferred — Phase D (read-only external adapters)

- Read-only adapter contract for external event systems (Accelevents/Eventbrite)
- Organizer/admin surfaces edit Flo overlays only; never canonical session records

**Stub plan:** promote via `platform-roles-phase-d-adapters` when backend integration is scoped.
