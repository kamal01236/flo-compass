@echo off
REM ===================================================================
REM  Flo Compass - Ship branch launcher (Windows)
REM  Tier 1 + Tier 2 smoke (teardown) + push + GitLab MR to main.
REM  Run after commits are ready for review — not on every commit.
REM  See .cursor/rules/ship-branch.mdc and scripts/README.md.
REM ===================================================================

echo.
echo [ship-branch] Launching ship-branch pipeline in WSL2 (Ubuntu)...
echo [ship-branch] Steps: Tier 1 + Tier 2 smoke + push + MR to main
echo [ship-branch] Use deploy-local.cmd instead to leave Docker running for manual smoke.
echo.

wsl -e bash -lc "cd /mnt/c/Nagarro/ai-avengers && sed -i 's/\r$//' scripts/wsl_ship_branch.sh scripts/wsl_tier2_smoke.sh scripts/wsl_open_mr.sh scripts/wsl_common.sh scripts/wsl_coverage.sh scripts/check_no_emoji_in_lib.sh 2>/dev/null; bash scripts/wsl_ship_branch.sh %*"
if errorlevel 1 (
  echo.
  echo [ship-branch] FAILED — ship pipeline did not complete. See output above.
  exit /b 1
)

echo.
echo ===============================================================
echo  Ship branch complete. Check GitLab for the merge request link.
echo ===============================================================
echo.
