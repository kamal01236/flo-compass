@echo off
REM ===================================================================
REM  Flo Compass - Tier 2 pre-push deploy launcher (Windows)
REM  Runs full Tier 1 + build web + docker/nginx :8080 + deep-link smoke
REM  + coverage gate in WSL2. Assumes Tier 1 dev has been used recently.
REM  Local WSL deploy only - production stays GitLab CI + ARM per
REM  wsl2-development.mdc. Do not use this for production releases.
REM  See .cursor/rules/dev-loops.mdc.
REM ===================================================================

echo.
echo [deploy-local] Launching Flo Compass Tier 2 deploy in WSL2 (Ubuntu)...
echo [deploy-local] Steps: pub get + analyze + test + build web + docker/nginx :8080 + coverage gate
echo [deploy-local] Requires docker group membership (see wsl_deploy.sh output if it fails).
echo [deploy-local] First run may take several minutes while Flutter + assets prepare.
echo.

REM Self-heal CRLF endings on the WSL scripts (in case Windows autocrlf touched them), then run.
wsl -e bash -lc "cd /mnt/c/Nagarro/ai-avengers && sed -i 's/\r$//' scripts/wsl_deploy.sh scripts/wsl_common.sh scripts/wsl_coverage.sh scripts/check_no_emoji_in_lib.sh 2>/dev/null; bash scripts/wsl_deploy.sh"
if errorlevel 1 (
  echo.
  echo [deploy-local] FAILED — Tier 2 deploy did not complete. See output above.
  exit /b 1
)

echo.
echo ===============================================================
echo  Flo Compass Tier 2 is up. Open in your Windows browser:
echo.
echo    http://localhost:8080                        (Docker/nginx)
echo    http://localhost:8080/session/s-001          (Deep link smoke)
echo    http://localhost:8080/directions?session=s-001
echo.
echo  For fast Tier 1 dev iteration, use dev-local.cmd instead.
echo.
echo  To stop everything later, run in WSL:
echo    wsl -e bash -lc "docker compose down 2^>/dev/null; fuser -k 8080/tcp 2^>/dev/null; true"
echo ===============================================================
echo.
pause
