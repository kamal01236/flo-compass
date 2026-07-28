# ===================================================================
#  Flo Compass - sprint integrate (PowerShell)
# ===================================================================

Write-Host ""
Write-Host "[sprint-integrate] Running sprint close-out in WSL2..." -ForegroundColor Cyan
Write-Host "[sprint-integrate] Args: $($args -join ' ')" -ForegroundColor Cyan
Write-Host ""

$argString = ($args -join ' ')

wsl -e bash -lc "cd /mnt/c/Nagarro/ai-avengers && sed -i 's/\r`$//' scripts/wsl_sprint_integrate.sh scripts/wsl_plan_session.sh scripts/wsl_common.sh scripts/wsl_deploy.sh 2>/dev/null; bash scripts/wsl_sprint_integrate.sh $argString"
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "[sprint-integrate] FAILED — see output above." -ForegroundColor Red
  exit 1
}

if (-not $env:PLAN_LIFECYCLE_QUIET) {
  try {
    msg $env:USERNAME /TIME:10 "Flo Compass sprint-integrate finished successfully. Open MR: feat/sprint-N-integration -> main" 2>$null
  } catch { }
}

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Green
Write-Host " Sprint integrate complete. Open MR: integration -> main" -ForegroundColor Green
Write-Host "===============================================================" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to close"
