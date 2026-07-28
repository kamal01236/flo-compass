@echo off
REM ===================================================================
REM  Flo Compass - sprint integrate (Tier 1 + Tier 2 + augmentation draft)
REM  Run from main worktree on integration branch. See scripts/README.md
REM ===================================================================

echo.
echo [sprint-integrate] Running sprint close-out in WSL2...
echo [sprint-integrate] Args: %*
echo.

wsl -e bash -lc "cd /mnt/c/Nagarro/ai-avengers && sed -i 's/\r$//' scripts/wsl_sprint_integrate.sh scripts/wsl_plan_session.sh scripts/wsl_common.sh scripts/wsl_deploy.sh 2>/dev/null; bash scripts/wsl_sprint_integrate.sh %*"
if errorlevel 1 (
  echo.
  echo [sprint-integrate] FAILED — see output above.
  exit /b 1
)

if not defined PLAN_LIFECYCLE_QUIET msg %USERNAME% /TIME:10 "Flo Compass sprint-integrate finished successfully. Open MR: feat/sprint-N-integration -> main" 2>NUL

echo.
echo ===============================================================
echo  Sprint integrate complete. Open MR: integration -^> main
echo ===============================================================
echo.
pause
