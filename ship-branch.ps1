# ===================================================================
#  Flo Compass - Ship branch launcher (PowerShell)
#  Tier 1 + Tier 2 smoke (teardown) + push + GitLab MR to main.
#  Run after commits are ready for review — not on every commit.
#  See .cursor/rules/ship-branch.mdc and scripts/README.md.
# ===================================================================

param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$RemainingArgs
)

Write-Host ""
Write-Host "[ship-branch] Launching ship-branch pipeline in WSL2 (Ubuntu)..." -ForegroundColor Cyan
Write-Host "[ship-branch] Steps: Tier 1 + Tier 2 smoke + push + MR to main" -ForegroundColor Cyan
Write-Host "[ship-branch] Use deploy-local.ps1 instead to leave Docker running for manual smoke." -ForegroundColor Cyan
Write-Host ""

$argString = ""
if ($RemainingArgs) {
  $argString = " " + ($RemainingArgs -join " ")
}

wsl -e bash -lc "cd /mnt/c/Nagarro/ai-avengers && sed -i 's/\r`$//' scripts/wsl_ship_branch.sh scripts/wsl_tier2_smoke.sh scripts/wsl_open_mr.sh scripts/wsl_common.sh scripts/wsl_coverage.sh scripts/check_no_emoji_in_lib.sh 2>/dev/null; bash scripts/wsl_ship_branch.sh${argString}"
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "[ship-branch] FAILED — ship pipeline did not complete. See output above." -ForegroundColor Red
  exit $LASTEXITCODE
}

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Green
Write-Host " Ship branch complete. Check GitLab for the merge request link." -ForegroundColor Green
Write-Host "===============================================================" -ForegroundColor Green
Write-Host ""
