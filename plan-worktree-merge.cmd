@echo off
REM ===================================================================
REM  Flo Compass - merge per-plan branch into integration (main worktree)
REM  See scripts/README.md
REM ===================================================================

echo.
echo [plan-worktree-merge] Merging per-plan branch into integration (WSL2)...
echo [plan-worktree-merge] Args: %*
echo.

wsl -e bash -lc "cd /mnt/c/Nagarro/ai-avengers && sed -i 's/\r$//' scripts/wsl_plan_worktree_merge.sh scripts/wsl_plan_session.sh scripts/wsl_common.sh 2>/dev/null; bash scripts/wsl_plan_worktree_merge.sh %*"
if errorlevel 1 (
  echo.
  echo [plan-worktree-merge] FAILED — see output above.
  exit /b 1
)

echo.
echo ===============================================================
echo  Merge complete. Next: plan-worktree-cleanup.cmd ^<branch^>
echo ===============================================================
echo.
pause
