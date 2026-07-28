@echo off
REM ===================================================================
REM  Flo Compass - plan worktree finish (Windows)
REM  Tier 1 + gates in a per-plan linked worktree. Run FROM the worktree.
REM  See scripts/README.md and .cursor/rules/parallel-plans-workflow.mdc
REM ===================================================================

echo.
echo [plan-worktree-finish] Running finish gates in WSL2 from this worktree...
echo [plan-worktree-finish] Args: %*
echo.

for %%I in (.) do set "WT_DIR=%%~fI"
set "WT_WSL=%WT_DIR:\=/%"
set "WT_WSL=/mnt/%WT_WSL::=%"

wsl -e bash -lc "cd '%WT_WSL%' && sed -i 's/\r$//' scripts/wsl_plan_worktree_finish.sh scripts/wsl_plan_session.sh scripts/wsl_common.sh 2>/dev/null; source .worktree.env 2>/dev/null; bash scripts/wsl_plan_worktree_finish.sh %*"
if errorlevel 1 (
  echo.
  echo [plan-worktree-finish] FAILED — see output above.
  exit /b 1
)

echo.
echo ===============================================================
echo  Finish gates passed. From the MAIN worktree run:
echo    plan-worktree-merge.cmd ^<branch^>
echo ===============================================================
echo.
pause
