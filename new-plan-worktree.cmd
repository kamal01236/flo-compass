@echo off
REM ===================================================================
REM  Flo Compass - new plan worktree helper (Windows)
REM  Creates a git worktree on a new branch with allocated Flutter/Docker
REM  ports so multiple Cursor agents can iterate on separate plans in
REM  parallel on the same machine.
REM  See .cursor/rules/parallel-plans-workflow.mdc.
REM
REM  Usage:
REM    new-plan-worktree.cmd ^<branch^> ^<slot^> [--base ^<base-branch^>]
REM  Example:
REM    new-plan-worktree.cmd feat/plan-security 1 --base feat/sprint-N-integration
REM ===================================================================

echo.
echo [new-plan-worktree] Creating a parallel worktree in WSL2...
echo [new-plan-worktree] Args: %*
echo.

REM Self-heal CRLF endings on the WSL scripts (in case Windows autocrlf touched them), then run.
wsl -e bash -lc "cd /mnt/c/Nagarro/ai-avengers && sed -i 's/\r$//' scripts/wsl_new_plan_worktree.sh scripts/wsl_common.sh 2>/dev/null; bash scripts/wsl_new_plan_worktree.sh %*"

echo.
echo ===============================================================
echo  Worktree created. Next steps:
echo.
echo    1. Open the new worktree in a new Cursor window. It is a sibling
echo       folder of C:\Nagarro\ai-avengers, e.g. C:\Nagarro\ai-avengers-^<slug^>.
echo       From PowerShell / CMD:  cursor "C:\Nagarro\ai-avengers-^<slug^>"
echo.
echo    2. In WSL inside the new worktree, source the port env first:
echo         cd /mnt/c/Nagarro/ai-avengers-^<slug^>
echo         source .worktree.env
echo         echo $FLUTTER_PORT     ^(sanity check^)
echo         bash scripts/wsl_dev.sh
echo.
echo       Or (from Windows in the new worktree folder): dev-local.cmd
echo       Note: dev-local.cmd starts a fresh WSL shell, so it only picks
echo       up the per-worktree port pair if you run
echo         wsl -e bash -lc "source .worktree.env && bash scripts/wsl_dev.sh"
echo       or invoke dev-local.cmd from a WSL shell that already sourced
echo       .worktree.env. Otherwise it will default to 3000/8080 and
echo       collide with the main worktree.
echo.
echo  See .cursor/rules/parallel-plans-workflow.mdc for the full workflow.
echo ===============================================================
echo.
pause
