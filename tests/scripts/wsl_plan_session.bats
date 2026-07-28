#!/usr/bin/env bats
# bats-core tests for scripts/wsl_plan_session.sh helpers.
# See .cursor/plans/parallel_plans_lifecycle_8f81133b.plan.md Phase 9.1.
#
# Run:   bats tests/scripts/
# Skips gracefully when bats is not installed (parent script prints a note).

# Resolve the repo root regardless of where bats is invoked from.
setup() {
  # BATS_TEST_DIRNAME is the directory of this .bats file.
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  FIXTURES="${BATS_TEST_DIRNAME}/fixtures"

  # Source the helpers under test. Silence version_gate output for cleanliness.
  # shellcheck source=../../scripts/wsl_plan_session.sh
  source "${REPO_ROOT}/scripts/wsl_plan_session.sh"

  # Isolate the event log so tests don't pollute the real log.
  export PLAN_LIFECYCLE_LOG="${BATS_TEST_TMPDIR}/plan-lifecycle.log.jsonl"
  export PLAN_LIFECYCLE_IGNORE_FILE="${BATS_TEST_TMPDIR}/plan-lifecycle-ignore"
  rm -f "${PLAN_LIFECYCLE_LOG}" "${PLAN_LIFECYCLE_IGNORE_FILE}"

  export PLAN_LIFECYCLE_SCRIPT="test"
  export PLAN_LIFECYCLE_BRANCH="fixture/plan-a"
}

teardown() {
  rm -f "${PLAN_LIFECYCLE_LOG}" "${PLAN_LIFECYCLE_IGNORE_FILE}"
}

# ---------------------------------------------------------------------------
# version_gate
# ---------------------------------------------------------------------------

@test "version_gate passes on this dev box (bash >= 4, git >= 2.25)" {
  run version_gate
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# forbidden_files_in_diff — mocked git
# ---------------------------------------------------------------------------

@test "forbidden_files_in_diff returns forbidden paths present in diff" {
  # Mock git to return a fixed diff for a specific ref.
  git() {
    if [[ "$*" == "-C . diff --name-only main...HEAD" ]]; then
      cat <<EOF
lib/routing/app_router.dart
lib/some_new_screen.dart
lib/providers/foo_provider.dart
web/manifest.json
docker/nginx.conf
docs/README.md
EOF
      return 0
    fi
    command git "$@"
  }
  export -f git

  run forbidden_files_in_diff main .
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"lib/routing/app_router.dart"* ]]
  [[ "${output}" == *"lib/providers/foo_provider.dart"* ]]
  [[ "${output}" == *"web/manifest.json"* ]]
  [[ "${output}" == *"docker/nginx.conf"* ]]
  # Non-forbidden paths must NOT appear in the output.
  [[ "${output}" != *"lib/some_new_screen.dart"* ]]
  [[ "${output}" != *"docs/README.md"* ]]

  unset -f git
}

@test "forbidden_files_in_diff returns empty when diff is clean" {
  git() {
    if [[ "$*" == "-C . diff --name-only main...HEAD" ]]; then
      cat <<EOF
lib/features/discover/discover_page.dart
lib/data/services/session_service.dart
test/discover_test.dart
EOF
      return 0
    fi
    command git "$@"
  }
  export -f git

  run forbidden_files_in_diff main .
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]

  unset -f git
}

# ---------------------------------------------------------------------------
# grep_guardrails
# ---------------------------------------------------------------------------

@test "grep_guardrails fires on duplicate GoRoute in fixture app_router.dart" {
  local tmp="${BATS_TEST_TMPDIR}/wt-dup"
  mkdir -p "${tmp}/lib/routing"
  cp "${FIXTURES}/sample_app_router.dart" "${tmp}/lib/routing/app_router.dart"

  run grep_guardrails "${tmp}"
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"duplicate GoRoute"* ]]
  [[ "${output}" == *"/fixture-duplicate"* ]]
}

@test "grep_guardrails passes on clean app_router.dart fixture" {
  local tmp="${BATS_TEST_TMPDIR}/wt-clean"
  mkdir -p "${tmp}/lib/routing"
  cp "${FIXTURES}/sample_app_router_clean.dart" "${tmp}/lib/routing/app_router.dart"

  run grep_guardrails "${tmp}"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"OK: grep guardrails clean"* ]]
}

@test "grep_guardrails fires on duplicate \"url\" in web/manifest.json" {
  local tmp="${BATS_TEST_TMPDIR}/wt-manifest-dup"
  mkdir -p "${tmp}/web"
  cp "${FIXTURES}/sample_manifest.json" "${tmp}/web/manifest.json"

  run grep_guardrails "${tmp}"
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"duplicate"* ]]
  [[ "${output}" == *"url"* ]]
  [[ "${output}" == *"/discover"* ]]
}

# ---------------------------------------------------------------------------
# print_patch_notes / patch_notes_count
# ---------------------------------------------------------------------------

@test "print_patch_notes extracts three bullets from fixture plan" {
  run print_patch_notes "${FIXTURES}/sample_plan.plan.md"
  [ "${status}" -eq 0 ]
  local n
  n="$(echo "${output}" | grep -cE '^[[:space:]]*-[[:space:]]+' || true)"
  [ "${n}" -eq 3 ]
  [[ "${output}" == *"lib/routing/app_router.dart"* ]]
  [[ "${output}" == *"lib/app.dart"* ]]
  [[ "${output}" == *"web/manifest.json"* ]]
}

@test "print_patch_notes skips the placeholder bullet inside HTML comments" {
  # Create a plan file whose section only contains the literal placeholder.
  local placeholder="${BATS_TEST_TMPDIR}/placeholder.plan.md"
  cat > "${placeholder}" <<'EOF'
### Serial-merge patch notes

<!-- Example bullet lives inside a comment and should not be counted. -->

- <patch note>
EOF
  run print_patch_notes "${placeholder}"
  [ "${status}" -eq 0 ]
  [ -z "$(echo "${output}" | grep -E '^[[:space:]]*-[[:space:]]+' || true)" ]
}

@test "patch_notes_count returns 3 for fixture plan" {
  run patch_notes_count "${FIXTURES}/sample_plan.plan.md"
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}

@test "patch_notes_count returns 0 for missing plan file" {
  run patch_notes_count "${BATS_TEST_TMPDIR}/does-not-exist.md"
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

# ---------------------------------------------------------------------------
# scan_secrets — regex + allowlist
# ---------------------------------------------------------------------------

@test "scan_secrets blocks synthetic AKIA key" {
  run bash -c 'source "'"${REPO_ROOT}"'"/scripts/wsl_plan_session.sh; cat "'"${FIXTURES}"'"/sample_diff_with_secret.txt | scan_secrets'
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"AKIA0123456789ABCDEF"* ]]
}

@test "scan_secrets passes on clean diff" {
  run bash -c 'source "'"${REPO_ROOT}"'"/scripts/wsl_plan_session.sh; cat "'"${FIXTURES}"'"/sample_diff_clean.txt | scan_secrets'
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}

@test "scan_secrets honours allowlist file" {
  # Copy the sample allowlist into the location scan_secrets checks.
  cp "${FIXTURES}/sample_ignore_allowlist.txt" "${PLAN_LIFECYCLE_IGNORE_FILE}"

  # Even with the AKIA line in the diff, the allowlist should filter it out.
  # But the diff also contains `password = ...` which is NOT allowlisted, so
  # scan_secrets should STILL fail — proving the allowlist is per-pattern,
  # not a whole-diff bypass.
  run bash -c 'source "'"${REPO_ROOT}"'"/scripts/wsl_plan_session.sh; export PLAN_LIFECYCLE_IGNORE_FILE="'"${PLAN_LIFECYCLE_IGNORE_FILE}"'"; cat "'"${FIXTURES}"'"/sample_diff_with_secret.txt | scan_secrets'
  [ "${status}" -ne 0 ]
  # AKIA line filtered by allowlist:
  [[ "${output}" != *"AKIA0123456789ABCDEF"* ]]
  # password line still flagged:
  [[ "${output}" == *"password"* ]]
}

@test "scan_secrets allowlist can whitelist every hit → returns 0" {
  # Write an allowlist that matches every possible finding in the fixture.
  cat > "${PLAN_LIFECYCLE_IGNORE_FILE}" <<'EOF'
AKIA[0-9A-Z]+
password\s*=\s*
EOF
  run bash -c 'source "'"${REPO_ROOT}"'"/scripts/wsl_plan_session.sh; export PLAN_LIFECYCLE_IGNORE_FILE="'"${PLAN_LIFECYCLE_IGNORE_FILE}"'"; cat "'"${FIXTURES}"'"/sample_diff_with_secret.txt | scan_secrets'
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}

# ---------------------------------------------------------------------------
# write_session / read_session / session_field / update via re-write
# ---------------------------------------------------------------------------

@test "write_session then session_field roundtrip preserves values and types" {
  local path="${BATS_TEST_TMPDIR}/session.json"
  write_session "${path}" \
    branch=feat/plan-a \
    base=feat/sprint-1-integration \
    slot=int:2 \
    flutter_port=int:3002 \
    docker_port=int:8082 \
    ready=bool:false \
    tier1_pass=bool:false \
    patch_notes_count=int:0

  [ -f "${path}" ]

  run session_field branch "${path}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "feat/plan-a" ]

  run session_field slot "${path}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "2" ]

  run session_field ready "${path}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "false" ]
}

# ---------------------------------------------------------------------------
# emit_event — smoke
# ---------------------------------------------------------------------------

@test "emit_event appends a well-formed JSON line" {
  phase_start
  emit_event "smoke" "pass" 0 42

  [ -f "${PLAN_LIFECYCLE_LOG}" ]
  local line
  line="$(tail -1 "${PLAN_LIFECYCLE_LOG}")"
  [[ "${line}" == *'"script":"test"'* ]]
  [[ "${line}" == *'"phase":"smoke"'* ]]
  [[ "${line}" == *'"action":"pass"'* ]]
  [[ "${line}" == *'"branch":"fixture/plan-a"'* ]]
  [[ "${line}" == *'"exit_code":0'* ]]
  [[ "${line}" == *'"duration_ms":42'* ]]
}

# ---------------------------------------------------------------------------
# is_dry_run / dry
# ---------------------------------------------------------------------------

@test "dry with DRY_RUN=1 prefixes and skips execution" {
  DRY_RUN=1 run dry echo "should not run"
  [ "${status}" -eq 0 ]
  [[ "${output}" == "[dry-run] echo should not run" ]]
}

@test "dry without DRY_RUN executes the command" {
  DRY_RUN=0 run dry echo "hi"
  [ "${status}" -eq 0 ]
  [ "${output}" = "hi" ]
}
