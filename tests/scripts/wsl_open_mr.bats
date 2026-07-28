#!/usr/bin/env bats
# bats-core tests for scripts/wsl_open_mr.sh
# Run: bats tests/scripts/wsl_open_mr.bats

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  export ROOT="${BATS_TEST_TMPDIR}/repo"
  mkdir -p "${ROOT}/scripts"
  cp "${REPO_ROOT}/scripts/wsl_open_mr.sh" "${ROOT}/scripts/"
  cp "${REPO_ROOT}/scripts/wsl_common.sh" "${ROOT}/scripts/"
  cd "${ROOT}"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"
  git commit --allow-empty -m "init" -q
  git branch -M main
  git checkout -b feat/test-ship -q
  git commit --allow-empty -m "feat: test commit" -q
  git remote add origin "https://gitlab.example.com/group/flo-compass.git"
}

@test "wsl_open_mr refuses to run on main branch" {
  git checkout main -q
  run bash "${ROOT}/scripts/wsl_open_mr.sh"
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"refuse"* ]]
}

@test "wsl_open_mr skips create when open MR exists (glab mock)" {
  mkdir -p "${BATS_TEST_TMPDIR}/bin"
  cat > "${BATS_TEST_TMPDIR}/bin/glab" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "auth" && "$2" == "status" ]]; then exit 0; fi
if [[ "$1" == "mr" && "$2" == "list" ]]; then
  if [[ "$*" == *"-F json"* ]]; then
    echo '[{"iid":42,"source_branch":"feat/test-ship","state":"opened"}]'
  else
    echo "42  Open MR  feat/test-ship"
  fi
  exit 0
fi
if [[ "$1" == "mr" && "$2" == "view" ]]; then exit 0; fi
echo "unexpected glab: $*" >&2
exit 1
EOF
  chmod +x "${BATS_TEST_TMPDIR}/bin/glab"
  export PATH="${BATS_TEST_TMPDIR}/bin:${PATH}"

  git() {
    if [[ "$1" == "push" ]]; then return 0; fi
    command git "$@"
  }
  export -f git

  run bash "${ROOT}/scripts/wsl_open_mr.sh" --skip-push
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"already exists"* ]]

  unset -f git
}

@test "wsl_open_mr falls back to git push options when glab missing" {
  export PATH="${BATS_TEST_TMPDIR}/empty-bin:${PATH}"
  mkdir -p "${BATS_TEST_TMPDIR}/empty-bin"

  git() {
    if [[ "$1" == "push" ]]; then
      [[ "$*" == *"merge_request.create"* ]] || return 1
      [[ "$*" == *"merge_request.target=main"* ]] || return 1
      return 0
    fi
    command git "$@"
  }
  export -f git

  run bash "${ROOT}/scripts/wsl_open_mr.sh"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"git push options"* ]]

  unset -f git
}
