#!/usr/bin/env bats
# bats-core tests for scripts/wsl_ship_branch.sh dry-run mode
# Run: bats tests/scripts/wsl_ship_branch.bats

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  export ROOT="${BATS_TEST_TMPDIR}/repo"
  mkdir -p "${ROOT}/scripts"
  cp "${REPO_ROOT}/scripts/wsl_ship_branch.sh" "${ROOT}/scripts/"
  cp "${REPO_ROOT}/scripts/wsl_common.sh" "${ROOT}/scripts/"
  cd "${ROOT}"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"
  git commit --allow-empty -m "init" -q
  git branch -M main
  git checkout -b feat/ship-dry-run -q
  git commit --allow-empty -m "feat: ship dry run" -q
  git remote add origin "https://gitlab.example.com/group/flo-compass.git"
  git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main 2>/dev/null || true
}

@test "wsl_ship_branch --dry-run prints planned steps without side effects" {
  run bash "${ROOT}/scripts/wsl_ship_branch.sh" --dry-run
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"[dry-run]"* ]]
  [[ "${output}" == *"flutter_pub_analyze_test"* ]]
  [[ "${output}" == *"wsl_tier2_smoke.sh"* ]]
  [[ "${output}" == *"wsl_open_mr.sh"* ]]
  [[ "${output}" == *"Ship branch complete"* ]]
}

@test "wsl_ship_branch --dry-run refuses main branch" {
  git checkout main -q
  run bash "${ROOT}/scripts/wsl_ship_branch.sh" --dry-run
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"feature branch"* ]]
}

@test "wsl_ship_branch --dry-run --no-tier2 skips tier2 step" {
  run bash "${ROOT}/scripts/wsl_ship_branch.sh" --dry-run --no-tier2
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"skipping Tier 2"* ]]
  [[ "${output}" != *"TEARDOWN=1 bash scripts/wsl_tier2_smoke.sh"* ]]
}

@test "wsl_ship_branch --dry-run --no-mr skips MR step" {
  run bash "${ROOT}/scripts/wsl_ship_branch.sh" --dry-run --no-mr
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"skipping MR"* ]]
  [[ "${output}" != *"wsl_open_mr.sh"* ]]
}
