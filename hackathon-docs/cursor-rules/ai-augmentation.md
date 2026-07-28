# AI Augmentation Log

| Field | Value |
|-------|-------|
| **File** | `.cursor/rules/ai-augmentation.mdc` |
| **Purpose** | One batched augmentation entry after full plan run + validation + agents idle |
| **Scope** | `alwaysApply: true` |
| **When to @cite** | End of any plan run or standalone task; before reporting "done" |

## Key guardrails

- Exactly **one** `## [` entry per completed plan run — never per phase or mid-execution
- Plan run not complete until entry exists and agents are idle
- WSL Tier 1 (and Tier 2 when required) must finish before logging implementation runs
- Use full template: Attempted, Cursor did, Accepted/Modified/Rejected, Hallucinations (`none` if clean), Steering, Local validation, Outcome
- Subagents on forbidden branches return log text to parent for batched append

## Source

[`.cursor/rules/ai-augmentation.mdc`](../../.cursor/rules/ai-augmentation.mdc)
