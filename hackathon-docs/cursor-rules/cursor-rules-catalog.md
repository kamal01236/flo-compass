# Cursor Rules Catalog

| Field | Value |
|-------|-------|
| **File** | `.cursor/rules/cursor-rules-catalog.mdc` |
| **Purpose** | Meta-rule — keep catalog parity when adding or changing rules |
| **Scope** | `globs: .cursor/rules/**,hackathon-docs/cursor-rules/**` |
| **When to @cite** | Adding, renaming, or materially editing any Cursor rule; README Section 5 updates |

## Key guardrails

- **Do not move** `.mdc` sources out of `.cursor/rules/` — catalog `.md` files are mirrors only
- On rule change: update `.mdc`, matching `<slug>.md`, README category index, HACKATHON-README Section 5, count strings
- Run parity bash commands: mdc count = slug.md count; no missing or orphan catalog files
- If catalog diverges from `.mdc`, the `.mdc` wins

## Source

[`.cursor/rules/cursor-rules-catalog.mdc`](../../.cursor/rules/cursor-rules-catalog.mdc)
