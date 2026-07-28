# ===================================================================
#  Flo Compass - cleanup merged per-plan worktree (PowerShell)
# ===================================================================

Write-Host ""
Write-Host "[plan-worktree-cleanup] Removing merged worktree..." -ForegroundColor Cyan
Write-Host "[plan-worktree-cleanup] Args: $($args -join ' ')" -ForegroundColor Cyan
Write-Host ""

$argString = ($args -join ' ')

wsl -e bash -lc "cd /mnt/c/Nagarro/ai-avengers && sed -i 's/\r`$//' scripts/wsl_plan_worktree_cleanup.sh scripts/wsl_plan_session.sh scripts/wsl_common.sh 2>/dev/null; bash scripts/wsl_plan_worktree_cleanup.sh $argString"
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "[plan-worktree-cleanup] FAILED — see output above." -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Green
Write-Host " Worktree cleanup complete. Port slot freed." -ForegroundColor Green
Write-Host "===============================================================" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to close"
