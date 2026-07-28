# ===================================================================
#  Flo Compass - Tier 1 dev launcher (PowerShell)
#  Runs pub get + analyze + test + flutter dev on :3000 in WSL2.
#  No docker, no build web. Target: < 90s cold, < 15s warm.
#  See .cursor/rules/dev-loops.mdc.
# ===================================================================

Write-Host ""
Write-Host "[dev-local] Launching Flo Compass Tier 1 dev in WSL2..." -ForegroundColor Cyan
Write-Host "[dev-local] Steps: pub get + analyze + test + flutter dev on :3000" -ForegroundColor Cyan
Write-Host ""

wsl -e bash -lc "cd /mnt/c/Nagarro/ai-avengers && sed -i 's/\r`$//' scripts/wsl_dev.sh scripts/wsl_common.sh 2>/dev/null; bash scripts/wsl_dev.sh"

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Green
Write-Host " Flo Compass dev (Tier 1) is up. Open in your Windows browser:" -ForegroundColor Green
Write-Host ""
Write-Host "   http://localhost:3000    (Flutter dev)" -ForegroundColor Yellow
Write-Host ""
Write-Host " Run deploy-local.ps1 before pushing for Tier 2 nginx smoke." -ForegroundColor Green
Write-Host ""
Write-Host " To stop, run in WSL:" -ForegroundColor Green
Write-Host "   wsl -e bash -lc `"fuser -k 3000/tcp 2>/dev/null; pkill -f 'flutter run' 2>/dev/null; true`"" -ForegroundColor Gray
Write-Host "===============================================================" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to close"
