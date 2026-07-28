# Parallel Plans Lifecycle — Manual Test Matrix

Short PR-review checklist for the lifecycle automation shipped by `.cursor/plans/parallel_plans_lifecycle_8f81133b.plan.md`. Complements the automated `bats-core` tests under `tests/scripts/`; every item here has a matching bats case, but this list is what a reviewer runs in WSL2 before approving the plan's MR.

Owner: whoever opens the MR for the plan run. Kick off the checklist inside the main worktree at `C:/Nagarro/ai-avengers` unless a row says otherwise.

For each row: mark `PASS`, `FAIL`, or `N/A` with a one-line note. If any row fails, block the MR and open a follow-up commit or new plan — do not paper over.

## Prerequisites

- WSL2 shell open at `/mnt/c/Nagarro/ai-avengers`
- `bash --version` reports major >= 4 and `git --version` >= 2.25 (the scripts' version gate expects these)
- Nothing running in the main worktree ports 3000 / 8080
- `.cursor/plan-lifecycle.log.jsonl` starts empty (or move it aside: `mv .cursor/plan-lifecycle.log.jsonl .cursor/plan-lifecycle.log.jsonl.pretest.bak`) so the log grows only from the test run

## Checklist

| # | Check | How to reproduce | Expected outcome |
|---|---|---|---|
| 1 | Forbidden-file gate fires | Create disposable worktree via `new-plan-worktree.cmd chore/lifecycle-smoke-a 1`; inside it, touch `lib/routing/app_router.dart` and stage it; run `bash scripts/wsl_plan_worktree_finish.sh` | Finish exits `1`; banner names `lib/routing/app_router.dart` with a citation of `parallel-agents.mdc` lines 21-29; session `ready` stays `false` |
| 2 | Merge lock serializes two concurrent invocations | From main worktree, start `bash scripts/wsl_plan_worktree_merge.sh chore/lifecycle-smoke-a --yes` in one WSL shell; before it acquires the lock output, start the same command in a second shell | Second invocation prints `waiting for lock owned by PID <n> (<host>) started <ts>`; runs after the first releases; both eventually exit `0` (or the second reports first's failure and skips) |
| 3 | Stale-lock detection auto-clears | Write a fake lockfile: `printf 'PID=1\nHOST=%s\nSTARTED_AT=2020-01-01T00:00:00Z\nCOMMAND=fake\n' "$(hostname)" > .git/integration-merge.lock`; run `bash scripts/wsl_plan_worktree_merge.sh chore/lifecycle-smoke-a --yes` | Merge prints `Detected stale lock owned by PID 1 (<host>) at 2020-01-01T00:00:00Z; clearing and retrying`; proceeds without operator intervention; log records `lock_stale_clear:pass` |
| 4 | `--dry-run` prints planned actions and does not modify the tree | With `chore/lifecycle-smoke-a` staged for merge, run `bash scripts/wsl_plan_worktree_merge.sh chore/lifecycle-smoke-a --dry-run`; also try `wsl_plan_worktree_cleanup.sh` and `wsl_sprint_integrate.sh` in `--dry-run` | Each prints `[dry-run] ...` lines for every step; `git status`, `git worktree list`, and docker state are unchanged after each run; the event log records `action:"dry-run"` for the top-level phase |
| 5 | Cleanup refuses unpushed commits | On the smoke branch, commit an empty change: `git commit --allow-empty -m "test"`; from the main worktree run `bash scripts/wsl_plan_worktree_cleanup.sh chore/lifecycle-smoke-a --yes` | Cleanup exits `1` with `Branch chore/lifecycle-smoke-a has N commits not on any remote; push first or pass --force to discard`; worktree and branch survive |
| 6 | Secret scan blocks a fake API key | Inside the smoke worktree, append `# demo AKIA0123456789ABCDEF` to any tracked file and stage it; run `bash scripts/wsl_plan_worktree_finish.sh` | Finish exits `1`; banner cites the file path and line number of the `AKIA` match with a remediation hint (rotate the key, then rebase-remove); no session flag change; log records `secret_scan:fail` |
| 7 | Version gate fails on `bash 3` / `git 2.20` | Simulate with `bash --version` masking or run inside a stripped Ubuntu container that ships `bash 3.2` / `git 2.20`. Alternatively, edit `scripts/wsl_plan_session.sh` temporarily to demand `>= 999` and confirm the same error path fires | Every lifecycle script (`finish`, `merge`, `cleanup`, `sprint-integrate`) exits `1` at startup with `Detected bash <ver>; need >= 4.0. Install via: apt install bash` and analogous `git` copy; no filesystem side effects; log receives no line (fail happens before `emit_event`) |
| 8 | Signal handling (Ctrl+C mid-merge) releases the flock | Run `bash scripts/wsl_plan_worktree_merge.sh chore/lifecycle-smoke-a --yes` and press Ctrl+C after `Acquired lock` prints but before `git checkout` completes | Trap fires: prints `Interrupted — releasing lock`; `.git/integration-merge.lock` is gone (`ls .git/integration-merge.lock` returns no such file); the event log's last line for the merge run is `{"action":"interrupted","exit_code":130,...}`; a follow-up merge in another shell acquires the lock immediately |

## Post-run tidy-up

After running the matrix, restore state:

```bash
# From main worktree:
git worktree remove --force ../ai-avengers-lifecycle-smoke-a || true
git worktree remove --force ../ai-avengers-lifecycle-smoke-b || true
git branch -D chore/lifecycle-smoke-a 2>/dev/null || true
git branch -D chore/lifecycle-smoke-b 2>/dev/null || true
git worktree prune
rm -f .git/integration-merge.lock
mv .cursor/plan-lifecycle.log.jsonl .cursor/plan-lifecycle.log.jsonl.$(date -u +%Y%m%d).testbak 2>/dev/null || true
```

## Cross-references

- [scripts/README.md](README.md) — full script argument reference, rollback recipes, event log format
- [.cursor/rules/parallel-plans-workflow.mdc](../.cursor/rules/parallel-plans-workflow.mdc) — Lifecycle scripts section
- [.cursor/rules/parallel-agents.mdc](../.cursor/rules/parallel-agents.mdc) — forbidden shared files used by the finish gate and merge grep guardrails
- [.cursor/plans/parallel_plans_lifecycle_8f81133b.plan.md](../.cursor/plans/parallel_plans_lifecycle_8f81133b.plan.md) — plan of record; Phase 9.2 originally placed this document in hackathon-docs; now lives alongside the lifecycle scripts; Phase 10 is the plan-level validation gate
