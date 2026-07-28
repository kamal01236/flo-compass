# Cursor Rules Catalog

Human-readable index of all **22** Cursor project rules. Authoritative sources remain in [`.cursor/rules/`](../../.cursor/rules/) as `.mdc` files — this folder is a mirror for judging, onboarding, and review.

When adding or changing a rule, follow [cursor-rules-catalog.mdc](../../.cursor/rules/cursor-rules-catalog.mdc).

**Judging summary:** [HACKATHON-README.md](../HACKATHON-README.md) Section 5 (compact table + link here).

---

## Project context

| Slug | Purpose |
|------|---------|
| [hackathon-context.md](hackathon-context.md) | Always-on project context, balanced shipping style |
| [flo-compass-product.md](flo-compass-product.md) | Product boundaries, MVP order, Accelevents complement |
| [flo-compass-data.md](flo-compass-data.md) | ~650 sessions, Gurgaon venue topology, wing and cafeteria integrity rules |
| [flutter-dart.md](flutter-dart.md) | Flutter web conventions, theme palette, web-first |

## Deliverables & AI log

| Slug | Purpose |
|------|---------|
| [hackathon-docs.md](hackathon-docs.md) | Mandatory deliverable filenames and README standards |
| [ai-augmentation.md](ai-augmentation.md) | One batched augmentation entry after full plan run + validation + agents idle |
| [ai-verification.md](ai-verification.md) | Pre-accept checks + hallucination category tags for augmentation log |
| [cursor-rules-catalog.md](cursor-rules-catalog.md) | Meta-rule — keep catalog parity when adding or changing rules |

## Local dev & validation

| Slug | Purpose |
|------|---------|
| [wsl2-development.md](wsl2-development.md) | WSL2 local dev & Tier 2 smoke only — does not change ARM/CI production |
| [local-wsl-auto-validation.md](local-wsl-auto-validation.md) | Always-on WSL Tier 1/2 runs + Tier 1/2/3 reference appendix; plan-gap logging |
| [dev-loops.md](dev-loops.md) | Fast / feature / pre-push / ship / CI tiers with time budgets and scripts |

## Deploy & infra

| Slug | Purpose |
|------|---------|
| [deployment-cicd.md](deployment-cicd.md) | Docker/CI guardrails — Flutter 3.44.0, GitLab variable names |
| [web-nginx-config.md](web-nginx-config.md) | nginx SPA fallback, CSP, cache headers |
| [ship-branch.md](ship-branch.md) | Ship-branch pipeline before MR — Tier 1 + Tier 2 smoke + push + GitLab MR |

## Team & parallel work

| Slug | Purpose |
|------|---------|
| [team-workflow.md](team-workflow.md) | Solo-driver + squad model, augmentation triggers |
| [parallel-agents.md](parallel-agents.md) | File-level ownership contract + merge discipline for parallel subagents |
| [parallel-plans-workflow.md](parallel-plans-workflow.md) | Worktree slots, port table, lifecycle scripts, three-layer branch model |
| [plan-auto-continue.md](plan-auto-continue.md) | Checkpoint + auto-continue for long-running plan runs (interrupt-safe handoff) |

## Quality & safety

| Slug | Purpose |
|------|---------|
| [accessibility.md](accessibility.md) | WCAG AA checks for keyboard, semantics, contrast, skip links |
| [security-secrets.md](security-secrets.md) | No secrets/PII; `--dart-define` for local API config |
| [git-hygiene.md](git-hygiene.md) | Branch-per-plan, Conventional Commits, working-tree hygiene |
| [planned-later-capture.md](planned-later-capture.md) | Capture deferred work in `docs/plans/backlog` instead of on active branch |

---

## Adding a rule

1. Create `.cursor/rules/<slug>.mdc`
2. Copy this folder's `_TEMPLATE.md` → `<slug>.md` and fill in
3. Add a row to the correct category table above
4. Update HACKATHON-README Section 5 and count strings
5. Run parity commands in [cursor-rules-catalog.mdc](../../.cursor/rules/cursor-rules-catalog.mdc)
