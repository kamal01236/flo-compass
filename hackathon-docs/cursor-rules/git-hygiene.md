# Git Hygiene

| Field | Value |
|-------|-------|
| **File** | `.cursor/rules/git-hygiene.mdc` |
| **Purpose** | Branch-per-plan, Conventional Commits, working-tree hygiene |
| **Scope** | `alwaysApply: true` |
| **When to @cite** | Commits, branches, MRs, untracked file cleanup |

## Key guardrails

- Never end session with more than 20 untracked files
- One branch per plan run: `<type>/<plan-slug>`; branch off default before first edit
- Conventional Commits with scope; one logical slice per commit; every commit passes Tier 1
- MRs only after Tier 1 + Tier 2 green; reference plan file; assign Ship & Story for deploy review
- Do not `--amend` pushed commits, force-push default, or commit secrets/PII

## Source

[`.cursor/rules/git-hygiene.mdc`](../../.cursor/rules/git-hygiene.mdc)
