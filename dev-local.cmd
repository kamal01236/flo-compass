@echo off
REM ===================================================================
REM  Flo Compass - Tier 1 dev launcher (Windows)
REM  Runs pub get + analyze + test + flutter dev on :3000 in WSL2.
REM  No docker, no build web. Target: < 90s cold, < 15s warm.
REM  See .cursor/rules/dev-loops.mdc.
REM ===================================================================

echo.
echo [dev-local] Launching Flo Compass Tier 1 dev in WSL2...
echo [dev-local] Steps: pub get + analyze + test + flutter dev on :3000
echo.

REM Self-heal CRLF endings on the WSL scripts (in case Windows autocrlf touched them), then run.
wsl -e bash -lc "cd /mnt/c/Nagarro/ai-avengers && sed -i 's/\r$//' scripts/wsl_dev.sh scripts/wsl_common.sh 2>/dev/null; bash scripts/wsl_dev.sh"

echo.
echo ===============================================================
echo  Flo Compass dev (Tier 1) is up. Open in your Windows browser:
echo.
echo    http://localhost:3000    (Flutter dev)
echo.
echo  Run deploy-local.cmd before pushing for Tier 2 nginx smoke.
echo.
echo  To stop, run in WSL:
echo    wsl -e bash -lc "fuser -k 3000/tcp 2^>/dev/null; pkill -f 'flutter run' 2^>/dev/null; true"
echo ===============================================================
echo.
pause
