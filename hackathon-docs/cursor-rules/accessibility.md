# Accessibility Baseline

| Field | Value |
|-------|-------|
| **File** | `.cursor/rules/accessibility.mdc` |
| **Purpose** | WCAG AA checks for keyboard, semantics, contrast, skip links |
| **Scope** | `globs: lib/**,web/**` |
| **When to @cite** | UI polish, theme changes, icon-only controls, motion, text scaling |

## Key guardrails

- WCAG AA contrast (4.5:1) on dark and light themes
- Keyboard navigation for major actions; visible 2px focus ring
- Semantic labels for icon-only controls; route announcements and live regions
- Respect reduced motion and text scaling
- Skip-to-content on `web/index.html`
- Avoid color-only status indicators; keep empty/error states actionable

## Source

[`.cursor/rules/accessibility.mdc`](../../.cursor/rules/accessibility.mdc)
