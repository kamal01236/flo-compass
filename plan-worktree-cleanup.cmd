@echo off
REM ===================================================================
REM  Flo Compass - cleanup merged per-plan worktree (main worktree)
REM  See scripts/README.md
REM ===================================================================

echo.
echo [plan-worktree-cleanup] Removing merged worktree in WSL2...
echo [plan-worktree-cleanup] Args: %*
echo.

wsl -e bash -lc "cd /mnt/c/Nagarro/ai-avengers && sed -i 's/\r$//' scripts/wsl_plan_worktree_cleanup.sh scripts/wsl_plan_session.sh scripts/wsl_common.sh 2>/dev/null; bash scripts/wsl_plan_worktree_cleanup.sh %*"
if errorlevel 1 (
  echo.
  echo [plan-worktree-cleanup] FAILED — see output above.
  exit /b 1
)

echo.
echo ===============================================================
echo  Worktree cleanup complete. Port slot freed.
echo ===============================================================
echo.
pause
