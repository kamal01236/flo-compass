# ===================================================================
#  Flo Compass - plan worktree finish (PowerShell)
#  Tier 1 + gates in a per-plan linked worktree. Run FROM the worktree.
# ===================================================================

Write-Host ""
Write-Host "[plan-worktree-finish] Running finish gates in WSL2..." -ForegroundColor Cyan
Write-Host "[plan-worktree-finish] Args: $($args -join ' ')" -ForegroundColor Cyan
Write-Host ""

$wtDir = (Get-Location).Path -replace '\\', '/'
$wtWsl = "/mnt/" + ($wtDir -replace ':', '')
$argString = ($args -join ' ')

wsl -e bash -lc "cd '$wtWsl' && sed -i 's/\r`$//' scripts/wsl_plan_worktree_finish.sh scripts/wsl_plan_session.sh scripts/wsl_common.sh 2>/dev/null; source .worktree.env 2>/dev/null; bash scripts/wsl_plan_worktree_finish.sh $argString"
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "[plan-worktree-finish] FAILED — see output above." -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Green
Write-Host " Finish gates passed. From the MAIN worktree run:" -ForegroundColor Green
Write-Host "   plan-worktree-merge.cmd <branch>" -ForegroundColor Yellow
Write-Host "===============================================================" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to close"
