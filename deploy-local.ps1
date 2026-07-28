# ===================================================================
#  Flo Compass - Tier 2 pre-push deploy launcher (PowerShell)
#  Runs full Tier 1 + build web + docker/nginx :8080 + deep-link smoke
#  + coverage gate in WSL2. Assumes Tier 1 dev has been used recently.
#  Local WSL deploy only - production stays GitLab CI + ARM per
#  wsl2-development.mdc. Do not use this for production releases.
#  See .cursor/rules/dev-loops.mdc.
# ===================================================================

Write-Host ""
Write-Host "[deploy-local] Launching Flo Compass Tier 2 deploy in WSL2 (Ubuntu)..." -ForegroundColor Cyan
Write-Host "[deploy-local] Steps: pub get + analyze + test + build web + docker/nginx :8080 + coverage gate." -ForegroundColor Cyan
Write-Host "[deploy-local] Requires docker group membership (see wsl_deploy.sh output if it fails)." -ForegroundColor Cyan
Write-Host "[deploy-local] First run may take several minutes while Flutter + assets prepare." -ForegroundColor Cyan
Write-Host ""

wsl -e bash -lc "cd /mnt/c/Nagarro/ai-avengers && sed -i 's/\r`$//' scripts/wsl_deploy.sh scripts/wsl_common.sh scripts/wsl_coverage.sh scripts/check_no_emoji_in_lib.sh 2>/dev/null; bash scripts/wsl_deploy.sh"
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[deploy-local] FAILED — Tier 2 deploy did not complete. See output above." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Green
Write-Host " Flo Compass Tier 2 is up. Open in your Windows browser:" -ForegroundColor Green
Write-Host ""
Write-Host "   http://localhost:8080                        (Docker/nginx)" -ForegroundColor Yellow
Write-Host "   http://localhost:8080/session/s-001          (Deep link smoke)" -ForegroundColor Yellow
Write-Host "   http://localhost:8080/directions?session=s-001" -ForegroundColor Yellow
Write-Host ""
Write-Host " For fast Tier 1 dev iteration, use dev-local.ps1 instead." -ForegroundColor Green
Write-Host ""
Write-Host " To stop everything later, run in WSL:" -ForegroundColor Green
Write-Host "   wsl -e bash -lc `"docker compose down 2>/dev/null; fuser -k 8080/tcp 2>/dev/null; true`"" -ForegroundColor Gray
Write-Host "===============================================================" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to close"
