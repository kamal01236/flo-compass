# ===================================================================
#  Flo Compass - merge per-plan branch into integration (PowerShell)
# ===================================================================

Write-Host ""
Write-Host "[plan-worktree-merge] Merging per-plan branch into integration..." -ForegroundColor Cyan
Write-Host "[plan-worktree-merge] Args: $($args -join ' ')" -ForegroundColor Cyan
Write-Host ""

$argString = ($args -join ' ')

wsl -e bash -lc "cd /mnt/c/Nagarro/ai-avengers && sed -i 's/\r`$//' scripts/wsl_plan_worktree_merge.sh scripts/wsl_plan_session.sh scripts/wsl_common.sh 2>/dev/null; bash scripts/wsl_plan_worktree_merge.sh $argString"
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "[plan-worktree-merge] FAILED — see output above." -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Green
Write-Host " Merge complete. Next: plan-worktree-cleanup.cmd <branch>" -ForegroundColor Yellow
Write-Host "===============================================================" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to close"
