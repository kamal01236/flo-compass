# ===================================================================
#  Flo Compass - new plan worktree helper (PowerShell)
#  Creates a git worktree on a new branch with allocated Flutter/Docker
#  ports so multiple Cursor agents can iterate on separate plans in
#  parallel on the same machine.
#  See .cursor/rules/parallel-plans-workflow.mdc.
#
#  Usage:
#    .\new-plan-worktree.ps1 <branch> <slot> [--base <base-branch>]
#  Example:
#    .\new-plan-worktree.ps1 feat/plan-security 1 --base feat/sprint-N-integration
# ===================================================================

Write-Host ""
Write-Host "[new-plan-worktree] Creating a parallel worktree in WSL2..." -ForegroundColor Cyan
Write-Host "[new-plan-worktree] Args: $($args -join ' ')" -ForegroundColor Cyan
Write-Host ""

$argString = ($args -join ' ')

wsl -e bash -lc "cd /mnt/c/Nagarro/ai-avengers && sed -i 's/\r`$//' scripts/wsl_new_plan_worktree.sh scripts/wsl_common.sh 2>/dev/null; bash scripts/wsl_new_plan_worktree.sh $argString"

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Green
Write-Host " Worktree created. Next steps:" -ForegroundColor Green
Write-Host ""
Write-Host "   1. Open the new worktree in a new Cursor window." -ForegroundColor Yellow
Write-Host "      It is a sibling folder of C:\Nagarro\ai-avengers,"
Write-Host "      e.g. C:\Nagarro\ai-avengers-<slug>."
Write-Host "      From PowerShell / CMD:  cursor `"C:\Nagarro\ai-avengers-<slug>`"" -ForegroundColor Gray
Write-Host ""
Write-Host "   2. In WSL inside the new worktree, source the port env first:" -ForegroundColor Yellow
Write-Host "        cd /mnt/c/Nagarro/ai-avengers-<slug>" -ForegroundColor Gray
Write-Host "        source .worktree.env" -ForegroundColor Gray
Write-Host "        echo `$FLUTTER_PORT     (sanity check)" -ForegroundColor Gray
Write-Host "        bash scripts/wsl_dev.sh" -ForegroundColor Gray
Write-Host ""
Write-Host "      Or (from Windows in the new worktree folder): dev-local.ps1"
Write-Host "      Note: dev-local.ps1 starts a fresh WSL shell, so it only picks"
Write-Host "      up the per-worktree port pair if you run"
Write-Host "        wsl -e bash -lc `"source .worktree.env && bash scripts/wsl_dev.sh`"" -ForegroundColor Gray
Write-Host "      or invoke dev-local.ps1 from a WSL shell that already sourced"
Write-Host "      .worktree.env. Otherwise it will default to 3000/8080 and"
Write-Host "      collide with the main worktree."
Write-Host ""
Write-Host " See .cursor/rules/parallel-plans-workflow.mdc for the full workflow." -ForegroundColor Green
Write-Host "===============================================================" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to close"
