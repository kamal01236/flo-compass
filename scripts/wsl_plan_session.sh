#!/usr/bin/env bash
# Parallel Plans Lifecycle — shared helpers.
# Sourced (never executed) by:
#   scripts/wsl_new_plan_worktree.sh          (start)
#   scripts/wsl_plan_worktree_finish.sh       (finish)
#   scripts/wsl_plan_worktree_merge.sh        (merge)
#   scripts/wsl_plan_worktree_cleanup.sh      (cleanup)
#   scripts/wsl_sprint_integrate.sh           (integrate)
#
# See .cursor/plans/parallel_plans_lifecycle_8f81133b.plan.md (Phase 8) and
# .cursor/rules/parallel-plans-workflow.mdc.
#
# Conventions:
#   - Callers set PLAN_LIFECYCLE_SCRIPT (finish|merge|cleanup|integrate|start)
#     and (when known) PLAN_LIFECYCLE_BRANCH before emitting events.
#   - DRY_RUN=1 (or PLAN_LIFECYCLE_DRY_RUN=1) disables side effects wrapped
#     in `dry ...`.
#   - PLAN_LIFECYCLE_QUIET=1 suppresses optional notifications on launchers.
#
# NOTE: do not `set -e` here — callers already do that; setting it in a sourced
# file makes some helpers (that intentionally return non-zero) hard to use.

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

PLAN_SESSION_LIB_VERSION="1.0.0"
PLAN_SESSION_FILE_REL=".cursor/plan-session.json"
PLAN_LIFECYCLE_LOG_REL=".cursor/plan-lifecycle.log.jsonl"

# Forbidden shared files — mirrors .cursor/rules/parallel-agents.mdc
# Exact paths first, then path prefixes (globs collapsed to prefix match).
PLAN_FORBIDDEN_PATHS=(
  "lib/app.dart"
  "lib/features/shell/main_shell.dart"
  "lib/routing/app_router.dart"
  "pubspec.yaml"
  "web/manifest.json"
  "README.md"
  "fly.toml"
  ".gitignore"
  ".dockerignore"
)
PLAN_FORBIDDEN_PREFIXES=(
  "lib/providers/"
  "docker/"
  ".github/workflows/"
)

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

# `log` may already be defined by wsl_common.sh — only define if missing.
if ! declare -F log >/dev/null 2>&1; then
  log() { echo "[wsl] $*"; }
fi

# Semantic alias so lifecycle scripts read a bit more naturally.
plan_log() { log "$@"; }

# ---------------------------------------------------------------------------
# Version gate (Phase 8.9)
# ---------------------------------------------------------------------------

version_gate() {
  local bash_major
  bash_major="${BASH_VERSION%%.*}"
  if [[ -z "${bash_major}" || "${bash_major}" -lt 4 ]]; then
    log "FAILED: bash >= 4 required (found: ${BASH_VERSION:-unknown})"
    log "Install: sudo apt install bash"
    return 1
  fi

  local git_version_line git_major git_minor
  git_version_line="$(git --version 2>/dev/null || echo "git version 0.0.0")"
  git_major="$(echo "${git_version_line}" | awk '{print $3}' | awk -F. '{print $1}')"
  git_minor="$(echo "${git_version_line}" | awk '{print $3}' | awk -F. '{print $2}')"
  if [[ -z "${git_major}" || "${git_major}" -lt 2 ]] \
     || { [[ "${git_major}" -eq 2 ]] && [[ -z "${git_minor}" || "${git_minor}" -lt 25 ]]; }; then
    log "FAILED: git >= 2.25 required (found: ${git_version_line})"
    log "Install: sudo apt install git"
    return 1
  fi
  return 0
}

# print_script_version <version> — used by --version flag.
print_script_version() {
  local ver="${1:-${PLAN_SESSION_LIB_VERSION}}"
  local hash
  hash="$(git -C "${ROOT:-.}" log -1 --format=%h -- scripts/ 2>/dev/null || echo unknown)"
  echo "plan-lifecycle ${ver} (scripts@${hash})"
}

# ---------------------------------------------------------------------------
# Worktree helpers
# ---------------------------------------------------------------------------

main_worktree_root() {
  local common_dir
  common_dir="$(git rev-parse --git-common-dir 2>/dev/null || echo "")"
  if [[ -z "${common_dir}" ]]; then
    echo "${ROOT:-$(pwd)}"
    return 0
  fi
  if [[ "${common_dir}" != /* ]]; then
    common_dir="$(pwd)/${common_dir}"
  fi
  common_dir="${common_dir%/.git}"
  common_dir="${common_dir%/.git/}"
  echo "${common_dir}"
}

is_main_worktree() {
  local dir="${1:-${ROOT:-.}}"
  local git_dir common_dir
  git_dir="$(git -C "${dir}" rev-parse --git-dir 2>/dev/null || echo "")"
  common_dir="$(git -C "${dir}" rev-parse --git-common-dir 2>/dev/null || echo "")"
  [[ -z "${git_dir}" || -z "${common_dir}" ]] && return 1
  if [[ "${git_dir}" != /* ]]; then
    git_dir="$(cd "${dir}" && pwd)/${git_dir}"
  fi
  if [[ "${common_dir}" != /* ]]; then
    common_dir="$(cd "${dir}" && pwd)/${common_dir}"
  fi
  git_dir="${git_dir%/}"
  common_dir="${common_dir%/}"
  [[ "${git_dir}" == "${common_dir}" ]]
}

# find_worktree_path_for_branch <branch> [root] — echoes the worktree path or
# nothing if the branch is not checked out in any worktree.
find_worktree_path_for_branch() {
  local branch="$1"
  local root="${2:-${ROOT:-.}}"
  [[ -z "${branch}" ]] && return 1
  git -C "${root}" worktree list --porcelain 2>/dev/null | awk -v b="refs/heads/${branch}" '
    /^worktree / { wt = substr($0, 10) }
    /^branch /   { br = substr($0, 8); if (br == b) print wt }
  ' | head -1
}

# load_session_for_branch <branch> [root] — populates SESSION_* globals for merge/cleanup.
load_session_for_branch() {
  local branch="$1"
  local root="${2:-${ROOT:-.}}"
  SESSION_WORKTREE_PATH="$(find_worktree_path_for_branch "${branch}" "${root}")"
  if [[ -z "${SESSION_WORKTREE_PATH}" ]]; then
    log "FAILED: no worktree found for branch ${branch}"
    return 1
  fi
  read_session "${SESSION_WORKTREE_PATH}/${PLAN_SESSION_FILE_REL}" || return 1
  SESSION_BRANCH="$(session_field branch)"
  SESSION_BASE="$(session_field base)"
  SESSION_SLOT="$(session_field slot)"
  SESSION_FLUTTER_PORT="$(session_field flutter_port)"
  SESSION_DOCKER_PORT="$(session_field docker_port)"
  SESSION_PLAN_FILE="$(session_field plan_file)"
  SESSION_READY="$(session_field ready)"
  SESSION_TIER1_PASS="$(session_field tier1_pass)"
  SESSION_PATCH_NOTES_COUNT="$(session_field patch_notes_count)"
  PLAN_LIFECYCLE_BRANCH="${SESSION_BRANCH}"
  return 0
}

# ---------------------------------------------------------------------------
# Dry-run wrapper (Phase 8.2)
# ---------------------------------------------------------------------------

is_dry_run() {
  [[ "${DRY_RUN:-0}" == "1" || "${PLAN_LIFECYCLE_DRY_RUN:-0}" == "1" ]]
}

dry_run_msg() {
  log "[dry-run] $*"
}

# dry <command> [args...]
#   is_dry_run → prints "[dry-run] <command>" and returns 0 without executing.
#   otherwise runs the command with all args.
dry() {
  if is_dry_run; then
    echo "[dry-run] $*"
    return 0
  fi
  "$@"
}

# confirm_or_yes <prompt> <auto_yes_flag>
#   auto_yes_flag=1 → return 0 without prompting (used by --yes).
#   otherwise read one line; return 0 on y/Y, 1 on anything else.
confirm_or_yes() {
  local prompt="$1"
  local auto_yes="${2:-0}"
  if [[ "${auto_yes}" == "1" ]]; then
    return 0
  fi
  local reply=""
  read -r -p "${prompt} " reply || return 1
  [[ "${reply}" =~ ^[Yy]([Ee][Ss])?$ ]]
}

# ---------------------------------------------------------------------------
# Structured event log (Phase 8.1)
# ---------------------------------------------------------------------------

_now_ms() {
  local ms
  ms="$(date +%s%3N 2>/dev/null || echo "")"
  if [[ -z "${ms}" || "${ms}" == *N ]]; then
    ms="$(( $(date +%s) * 1000 ))"
  fi
  echo "${ms}"
}

_now_iso_utc() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

_json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  echo "${s}"
}

lifecycle_log_path() {
  local root="${1:-}"
  if [[ -n "${PLAN_LIFECYCLE_LOG:-}" ]]; then
    echo "${PLAN_LIFECYCLE_LOG}"
    return 0
  fi
  if [[ -z "${root}" ]]; then
    root="$(main_worktree_root)"
  fi
  echo "${root}/${PLAN_LIFECYCLE_LOG_REL}"
}

# ensure_lifecycle_log_excluded [root] — adds .cursor/plan-lifecycle.log.jsonl
# to the main worktree's info/exclude if not present. Best-effort.
ensure_lifecycle_log_excluded() {
  local root="${1:-$(main_worktree_root)}"
  local exclude_file="${root}/.git/info/exclude"
  [[ -d "${root}/.git" ]] || return 0
  mkdir -p "$(dirname "${exclude_file}")" 2>/dev/null || true
  if [[ ! -f "${exclude_file}" ]] || ! grep -qxF "${PLAN_LIFECYCLE_LOG_REL}" "${exclude_file}" 2>/dev/null; then
    echo "${PLAN_LIFECYCLE_LOG_REL}" >> "${exclude_file}" 2>/dev/null || true
  fi
}

phase_start() {
  _PHASE_START_MS="$(_now_ms)"
  export _PHASE_START_MS
}

# emit_event <phase> <action> <exit_code> [duration_ms_override]
#
# Appends one JSON line to lifecycle_log_path. Best-effort — never fails the
# caller.
emit_event() {
  local phase="${1:-unknown}"
  local action="${2:-unknown}"
  local exit_code="${3:-0}"
  local duration_ms="${4:-}"

  local script="${PLAN_LIFECYCLE_SCRIPT:-unknown}"
  local branch="${PLAN_LIFECYCLE_BRANCH:-}"
  local ts
  ts="$(_now_iso_utc)"

  if [[ -z "${duration_ms}" ]]; then
    if [[ -n "${_PHASE_START_MS:-}" ]]; then
      duration_ms="$(( $(_now_ms) - _PHASE_START_MS ))"
    else
      duration_ms="0"
    fi
  fi

  local log_path
  log_path="$(lifecycle_log_path)"
  mkdir -p "$(dirname "${log_path}")" 2>/dev/null || true

  local line
  line="{\"ts\":\"$(_json_escape "${ts}")\","
  line+="\"script\":\"$(_json_escape "${script}")\","
  line+="\"phase\":\"$(_json_escape "${phase}")\","
  line+="\"branch\":\"$(_json_escape "${branch}")\","
  line+="\"action\":\"$(_json_escape "${action}")\","
  line+="\"duration_ms\":${duration_ms},"
  line+="\"exit_code\":${exit_code}}"

  echo "${line}" >> "${log_path}" 2>/dev/null || true
  ensure_lifecycle_log_excluded "$(main_worktree_root)" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Locking (Phase 8.4)
# ---------------------------------------------------------------------------

LIFECYCLE_LOCKFILE=""
LIFECYCLE_LOCK_MODE=""  # "flock" or "mkdir"

_write_lock_metadata() {
  local target="$1"
  local host started
  host="$(hostname 2>/dev/null || echo unknown)"
  started="$(_now_iso_utc)"
  {
    echo "PID=$$"
    echo "HOST=${host}"
    echo "STARTED_AT=${started}"
    echo "COMMAND=${PLAN_LIFECYCLE_SCRIPT:-unknown} ${PLAN_LIFECYCLE_BRANCH:-}"
  } > "${target}" 2>/dev/null || true
}

_clear_stale_lock() {
  local lockfile="$1"
  rm -f "${lockfile}" 2>/dev/null || true
  rm -f "${lockfile}.d/owner" 2>/dev/null || true
  rmdir "${lockfile}.d" 2>/dev/null || true
}

_lock_is_stale() {
  local owner_file="$1"
  [[ -s "${owner_file}" ]] || return 0
  local pid host_line started_line host age_sec=0
  pid="$(grep -E '^PID=' "${owner_file}" 2>/dev/null | head -1 | cut -d= -f2)"
  host_line="$(grep -E '^HOST=' "${owner_file}" 2>/dev/null | head -1 | cut -d= -f2)"
  started_line="$(grep -E '^STARTED_AT=' "${owner_file}" 2>/dev/null | head -1 | cut -d= -f2)"
  host="$(hostname 2>/dev/null || echo unknown)"
  if [[ -n "${started_line}" ]]; then
    local started_epoch now_epoch
    started_epoch="$(date -u -d "${started_line}" +%s 2>/dev/null || echo 0)"
    now_epoch="$(date -u +%s)"
    age_sec=$(( now_epoch - started_epoch ))
  fi
  if [[ -n "${host_line}" && "${host_line}" == "${host}" && -n "${pid}" ]] \
     && ! kill -0 "${pid}" 2>/dev/null; then
    return 0
  fi
  (( age_sec > 21600 )) && return 0
  return 1
}

# acquire_lock <lockfile-path>
acquire_lock() {
  local lockfile="$1"
  if [[ -z "${lockfile}" ]]; then
    log "FAILED: acquire_lock requires a path"
    return 1
  fi
  mkdir -p "$(dirname "${lockfile}")" 2>/dev/null || true

  local tries owner_file
  for tries in 1 2; do
    if command -v flock >/dev/null 2>&1; then
      exec 200>"${lockfile}"
      if flock -w 30 200; then
        _write_lock_metadata "${lockfile}"
        LIFECYCLE_LOCKFILE="${lockfile}"
        LIFECYCLE_LOCK_MODE="flock"
        return 0
      fi
      exec 200>&-
      owner_file="${lockfile}"
    else
      local lockdir="${lockfile}.d"
      if mkdir "${lockdir}" 2>/dev/null; then
        _write_lock_metadata "${lockdir}/owner"
        LIFECYCLE_LOCKFILE="${lockdir}"
        LIFECYCLE_LOCK_MODE="mkdir"
        return 0
      fi
      owner_file="${lockfile}.d/owner"
    fi

    if [[ -e "${owner_file}" ]] && _lock_is_stale "${owner_file}"; then
      local pid host_line started_line
      pid="$(grep -E '^PID=' "${owner_file}" 2>/dev/null | head -1 | cut -d= -f2)"
      host_line="$(grep -E '^HOST=' "${owner_file}" 2>/dev/null | head -1 | cut -d= -f2)"
      started_line="$(grep -E '^STARTED_AT=' "${owner_file}" 2>/dev/null | head -1 | cut -d= -f2)"
      log "Detected stale lock owned by PID ${pid:-?} (${host_line:-?}) at ${started_line:-?}; clearing and retrying"
      _clear_stale_lock "${lockfile}"
      continue
    fi

    log "FAILED: could not acquire lock ${lockfile} within 30s"
    if [[ -s "${owner_file}" ]]; then
      log "Lock holder:"
      sed 's/^/  /' "${owner_file}"
    fi
    log "If the holder is dead, run:"
    log "  rm -f ${lockfile} ${lockfile}.d/owner; rmdir ${lockfile}.d 2>/dev/null"
    return 1
  done
  return 1
}

release_lock() {
  if [[ -z "${LIFECYCLE_LOCKFILE:-}" ]]; then
    return 0
  fi
  case "${LIFECYCLE_LOCK_MODE:-}" in
    flock)
      exec 200>&- 2>/dev/null || true
      rm -f "${LIFECYCLE_LOCKFILE}" 2>/dev/null || true
      ;;
    mkdir)
      rm -f "${LIFECYCLE_LOCKFILE}/owner" 2>/dev/null || true
      rmdir "${LIFECYCLE_LOCKFILE}" 2>/dev/null || true
      ;;
  esac
  LIFECYCLE_LOCKFILE=""
  LIFECYCLE_LOCK_MODE=""
}

# ---------------------------------------------------------------------------
# Signal handling (Phase 8.3)
# ---------------------------------------------------------------------------

LIFECYCLE_CLEANUP_HOOKS=()

# register_cleanup_hook <shell-command>
register_cleanup_hook() {
  LIFECYCLE_CLEANUP_HOOKS+=("$1")
}

# lifecycle_cleanup — trap handler. Releases lock, runs registered hooks,
# emits `interrupted` event unless LIFECYCLE_COMPLETED=1.
lifecycle_cleanup() {
  local trap_exit="${?:-0}"
  if [[ "${LIFECYCLE_COMPLETED:-0}" != "1" ]]; then
    emit_event "signal" "interrupted" "${trap_exit}" 2>/dev/null || true
  fi
  release_lock
  local hook
  for hook in "${LIFECYCLE_CLEANUP_HOOKS[@]:-}"; do
    [[ -n "${hook}" ]] && eval "${hook}" 2>/dev/null || true
  done
}

# ---------------------------------------------------------------------------
# Session metadata — .cursor/plan-session.json
# ---------------------------------------------------------------------------

# read_session [path] — sets _SESSION_JSON to the file contents.
read_session() {
  local path="${1:-${PLAN_SESSION_FILE_REL}}"
  if [[ ! -f "${path}" ]]; then
    _SESSION_JSON=""
    return 1
  fi
  _SESSION_JSON="$(cat "${path}")"
  export _SESSION_JSON
  return 0
}

# session_field <field> [path]
session_field() {
  local field="$1"
  local path="${2:-}"
  local json
  if [[ -n "${_SESSION_JSON:-}" && -z "${path}" ]]; then
    json="${_SESSION_JSON}"
  else
    path="${path:-${PLAN_SESSION_FILE_REL}}"
    [[ -f "${path}" ]] || return 1
    json="$(cat "${path}")"
  fi
  local val
  val="$(echo "${json}" | grep -oE "\"${field}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed -E "s/.*:[[:space:]]*\"([^\"]*)\"/\1/")"
  if [[ -n "${val}" ]]; then
    echo "${val}"
    return 0
  fi
  val="$(echo "${json}" | grep -oE "\"${field}\"[[:space:]]*:[[:space:]]*[^,\"}]+" | head -1 | sed -E "s/.*:[[:space:]]*//" | tr -d ' ')"
  if [[ -n "${val}" ]]; then
    echo "${val}"
    return 0
  fi
  return 1
}

# write_session <path> [key=value ...]
#
# Values with `bool:` / `int:` prefixes are emitted unquoted; everything else
# is quoted as a JSON string. Overwrites the file — for partial updates,
# combine with read_session / session_field to preserve unspecified fields.
write_session() {
  local path="$1"
  shift
  mkdir -p "$(dirname "${path}")" 2>/dev/null || true

  local first=1 kv key val json_val
  {
    printf '{\n'
    for kv in "$@"; do
      key="${kv%%=*}"
      val="${kv#*=}"
      if [[ "${val}" == bool:* ]]; then
        json_val="${val#bool:}"
      elif [[ "${val}" == int:* ]]; then
        json_val="${val#int:}"
      else
        json_val="\"$(_json_escape "${val}")\""
      fi
      if [[ ${first} -eq 1 ]]; then
        first=0
      else
        printf ',\n'
      fi
      printf '  "%s": %s' "$(_json_escape "${key}")" "${json_val}"
    done
    printf '\n}\n'
  } > "${path}"
}

# update_session_field <path> <key> <value>  (value: bool:true | int:1 | plain string)
update_session_field() {
  local path="$1" key="$2" val="$3"
  [[ -f "${path}" ]] || return 1
  read_session "${path}" || return 1
  local json_val
  if [[ "${val}" == bool:* ]]; then
    json_val="${val#bool:}"
  elif [[ "${val}" == int:* ]]; then
    json_val="${val#int:}"
  else
    json_val="\"$(_json_escape "${val}")\""
  fi
  if grep -qE "\"${key}\"[[:space:]]*:" "${path}"; then
    sed -i -E "s|(\"${key}\"[[:space:]]*:[[:space:]]*)([^,}]+)|\\1${json_val}|" "${path}"
  else
    sed -i "s|}$|  ,\"${key}\": ${json_val}\n}|" "${path}"
  fi
}

# ---------------------------------------------------------------------------
# Forbidden-file gate (Phase 2 finish, parallel-agents.mdc lines 21-29)
# ---------------------------------------------------------------------------

# forbidden_files_in_diff <base_ref> [worktree_root]
#
# Echoes every diff path (one per line) that matches the forbidden shared list.
forbidden_files_in_diff() {
  local base="${1:-}"
  local root="${2:-.}"
  if [[ -z "${base}" ]]; then
    log "FAILED: forbidden_files_in_diff requires a base ref"
    return 1
  fi
  local diff_paths
  diff_paths="$(git -C "${root}" diff --name-only "${base}...HEAD" 2>/dev/null || true)"
  if [[ -z "${diff_paths}" ]]; then
    return 0
  fi
  local path exact prefix
  while IFS= read -r path; do
    [[ -z "${path}" ]] && continue
    for exact in "${PLAN_FORBIDDEN_PATHS[@]}"; do
      if [[ "${path}" == "${exact}" ]]; then
        echo "${path}"
        continue 2
      fi
    done
    for prefix in "${PLAN_FORBIDDEN_PREFIXES[@]}"; do
      if [[ "${path}" == "${prefix}"* ]]; then
        echo "${path}"
        continue 2
      fi
    done
  done <<< "${diff_paths}"
  return 0
}

# ---------------------------------------------------------------------------
# Grep guardrails (Phase 3 merge, mirrors parallel-agents.mdc lines 38-42)
# ---------------------------------------------------------------------------

# grep_guardrails [worktree_root]
#
# Checks the merged tree for silently-resolved duplicates. Prints offending
# lines. Returns 0 clean, 1 if any duplicate is found.
grep_guardrails() {
  local root="${1:-.}"
  local failed=0

  local app_router="${root}/lib/routing/app_router.dart"
  if [[ -f "${app_router}" ]]; then
    local dups
    dups="$(grep -oE "GoRoute\(path:[[:space:]]*['\"][^'\"]+['\"]" "${app_router}" 2>/dev/null \
      | sort | uniq -d)"
    if [[ -n "${dups}" ]]; then
      log "FAILED: duplicate GoRoute(path: ...) in ${app_router#${root}/}:"
      echo "${dups}"
      failed=1
    fi
  fi

  local app_file="${root}/lib/app.dart"
  if [[ -f "${app_file}" ]]; then
    local dups
    dups="$(grep -oE "ChangeNotifierProvider(\.value)?[[:space:]]*(<[A-Z][A-Za-z0-9_]*>)?[[:space:]]*\(" "${app_file}" 2>/dev/null \
      | sort | uniq -d)"
    if [[ -n "${dups}" ]]; then
      log "FAILED: duplicate ChangeNotifierProvider entries in ${app_file#${root}/}:"
      echo "${dups}"
      failed=1
    fi
  fi

  local manifest="${root}/web/manifest.json"
  if [[ -f "${manifest}" ]]; then
    local dups
    dups="$(grep -oE "\"url\"[[:space:]]*:[[:space:]]*\"[^\"]+\"" "${manifest}" 2>/dev/null \
      | sort | uniq -d)"
    if [[ -n "${dups}" ]]; then
      log "FAILED: duplicate \"url\" entries in ${manifest#${root}/}:"
      echo "${dups}"
      failed=1
    fi
  fi

  local aug_log="${root}/hackathon-docs/augmentation-log.md"
  if [[ -f "${aug_log}" ]]; then
    local dups
    dups="$(grep -oE "story-[0-9]+-[0-9]+" "${aug_log}" 2>/dev/null \
      | sort | uniq -c | awk '$1 > 2 { print $0 }')"
    if [[ -n "${dups}" ]]; then
      log "FAILED: story slice id appears >2 times in ${aug_log#${root}/}:"
      echo "${dups}"
      failed=1
    fi
  fi

  if [[ ${failed} -eq 0 ]]; then
    log "OK: grep guardrails clean (routes, providers, manifest, aug-log)"
  fi
  return ${failed}
}

# ---------------------------------------------------------------------------
# Serial-merge patch notes parser
# ---------------------------------------------------------------------------

# print_patch_notes <plan_file>
#
# Extracts bullets in the `### Serial-merge patch notes` section. Skips lines
# inside HTML comments and the literal `- <patch note>` placeholder.
print_patch_notes() {
  local plan="$1"
  [[ -f "${plan}" ]] || return 0
  awk '
    /^### Serial-merge patch notes/ { inside=1; next }
    inside && /^<!--/ { in_comment=1 }
    inside && in_comment && /-->/ { in_comment=0; next }
    inside && in_comment { next }
    inside && /^###[[:space:]]/ { inside=0 }
    inside && /^##[[:space:]]/ { inside=0 }
    inside && /^[[:space:]]*-[[:space:]]+/ { print }
  ' "${plan}" | grep -vE '^[[:space:]]*-[[:space:]]*<patch note>[[:space:]]*$' || true
}

patch_notes_count() {
  local plan="$1"
  [[ -f "${plan}" ]] || { echo 0; return 0; }
  local n
  n="$(print_patch_notes "${plan}" | grep -cE '^[[:space:]]*-[[:space:]]+' || true)"
  echo "${n:-0}"
}

# ---------------------------------------------------------------------------
# Secret scan (Phase 8.6)
# ---------------------------------------------------------------------------

# scan_secrets — stdin scanner. Returns 1 with matches on stdout when a pattern
# hits (after allowlist filtering), 0 when clean.
scan_secrets() {
  local pattern='(AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|password[[:space:]]*=[[:space:]]*[^[:space:]]+|api[_-]?key[[:space:]]*=[[:space:]]*[^[:space:]]+|Bearer[[:space:]]+[A-Za-z0-9_.\-]+)'
  local ignore_file="${PLAN_LIFECYCLE_IGNORE_FILE:-.cursor/plan-lifecycle-ignore}"

  local hits
  hits="$(grep -nE "${pattern}" 2>/dev/null || true)"
  if [[ -z "${hits}" ]]; then
    return 0
  fi

  if [[ -f "${ignore_file}" ]]; then
    local allow
    while IFS= read -r allow; do
      [[ -z "${allow}" || "${allow}" == \#* ]] && continue
      hits="$(echo "${hits}" | grep -vE "${allow}" || true)"
    done < "${ignore_file}"
  fi

  if [[ -z "${hits}" ]]; then
    return 0
  fi
  echo "${hits}"
  return 1
}

# run_secret_scan <base_ref> [mode]
#   mode=since_base (default) → git diff ${base}...HEAD
#   mode=head_only            → git diff HEAD^..HEAD (post-merge)
#
# Runs gitleaks first if installed, then the regex scan as a defense-in-depth
# fallback. Returns 1 on any finding from either tool.
run_secret_scan() {
  local base="$1"
  local mode="${2:-since_base}"
  local range
  case "${mode}" in
    since_base) range="${base}...HEAD" ;;
    head_only)  range="HEAD^..HEAD" ;;
    *) log "FAILED: unknown scan mode: ${mode}"; return 1 ;;
  esac

  if command -v gitleaks >/dev/null 2>&1; then
    log "gitleaks detect --log-opts=${range}"
    if ! gitleaks detect --no-banner --redact --log-opts="${range}" 2>&1; then
      log "FAILED: gitleaks reported findings in ${range}"
      return 1
    fi
  fi

  local hits diff_output
  diff_output="$(git diff "${range}" 2>/dev/null || true)"
  hits="$(printf '%s\n' "${diff_output}" | scan_secrets || true)"
  if [[ -n "${hits}" ]]; then
    log "FAILED: secret pattern detected in diff for ${range}"
    log "Matches:"
    printf '%s\n' "${hits}"
    log "Add a regex to .cursor/plan-lifecycle-ignore to allowlist a false positive."
    return 1
  fi

  log "OK: secret scan clean (${range})"
  return 0
}

# ---------------------------------------------------------------------------
# Pre-flight checks (Phase 8.5)
# ---------------------------------------------------------------------------

# preflight_merge <base> [force_behind]
preflight_merge() {
  local base="${1:-}"
  local force_behind="${2:-0}"
  local failed=0

  local free_kb
  free_kb="$(df -k . 2>/dev/null | awk 'NR==2 { print $4 }')"
  if [[ -n "${free_kb}" ]] && (( free_kb < 1048576 )); then
    log "FAILED: less than 1 GB free on $(pwd) (available: ${free_kb} kB)"
    log "Cleanup hint: docker system prune -f; rm -rf build/ .dart_tool/"
    failed=1
  fi

  log "git fsck --no-progress --no-dangling"
  if ! git fsck --no-progress --no-dangling 2>&1; then
    log "FAILED: git fsck reported errors"
    failed=1
  fi

  if [[ -n "${base}" ]] && git show-ref --verify --quiet "refs/remotes/origin/${base}"; then
    local behind
    behind="$(git rev-list --count "${base}..origin/${base}" 2>/dev/null || echo 0)"
    if (( behind > 0 )) && [[ "${force_behind}" != "1" ]]; then
      log "FAILED: local ${base} is ${behind} commit(s) behind origin/${base}"
      log "Fix: git checkout ${base} && git pull --ff-only origin ${base}"
      log "Or bypass with --force-behind (creates divergent history — be sure)"
      failed=1
    fi
  fi

  if (( failed == 0 )); then
    log "OK: pre-flight clean (disk / fsck / remote-sync)"
  fi
  return ${failed}
}

# ---------------------------------------------------------------------------
# Duration rollup for sprint-integrate augmentation draft
# ---------------------------------------------------------------------------

# rollup_durations [log_path] — awk-based summary; no python dependency.
rollup_durations() {
  local log_path="${1:-}"
  if [[ -z "${log_path}" ]]; then
    log_path="$(lifecycle_log_path)"
  fi
  if [[ ! -s "${log_path}" ]]; then
    echo "  - (no lifecycle events recorded for this sprint)"
    return 0
  fi
  awk '
    {
      s = ""; p = ""; d = 0
      if (match($0, /"script"[[:space:]]*:[[:space:]]*"[^"]+"/)) {
        v = substr($0, RSTART, RLENGTH)
        sub(/.*"script"[[:space:]]*:[[:space:]]*"/, "", v)
        sub(/"$/, "", v)
        s = v
      }
      if (match($0, /"phase"[[:space:]]*:[[:space:]]*"[^"]+"/)) {
        v = substr($0, RSTART, RLENGTH)
        sub(/.*"phase"[[:space:]]*:[[:space:]]*"/, "", v)
        sub(/"$/, "", v)
        p = v
      }
      if (match($0, /"duration_ms"[[:space:]]*:[[:space:]]*[0-9]+/)) {
        v = substr($0, RSTART, RLENGTH)
        sub(/.*:[[:space:]]*/, "", v)
        d = v + 0
      }
      if (s != "") {
        key = s ":" (p ? p : "?")
        totals[key] += d
        counts[key] += 1
        script_totals[s] += d
      }
    }
    END {
      any = 0
      for (k in totals) { any = 1 }
      if (!any) {
        print "  - (no parseable events in lifecycle log)"
      } else {
        n = 0
        for (k in totals) { keys[n++] = k }
        # simple bubble sort — the number of unique phases is small
        for (i = 0; i < n; i++) for (j = i + 1; j < n; j++) if (keys[j] < keys[i]) { t = keys[i]; keys[i] = keys[j]; keys[j] = t }
        for (i = 0; i < n; i++) {
          printf "  - %s: %d ms across %d events\n", keys[i], totals[keys[i]], counts[keys[i]]
        }
        grand = 0
        for (s in script_totals) grand += script_totals[s]
        printf "  - TOTAL: %d ms\n", grand
      }
    }
  ' "${log_path}"
}

# ---------------------------------------------------------------------------
# Rollback recipe banners (Phase 8.11)
# ---------------------------------------------------------------------------

# rollback_hint <stage> [base]
#   stage: merge | push | cleanup | integrate
rollback_hint() {
  local stage="$1"
  local base="${2:-<integration-branch>}"
  case "${stage}" in
    merge)
      echo "Rollback:  git merge --abort  # (or) git reset --hard ORIG_HEAD; git reflog show ${base}"
      ;;
    push)
      echo "Rollback:  git reset --hard ORIG_HEAD@{1}   # step back before the merge commit"
      ;;
    cleanup)
      echo "Recover:   git checkout -b <branch> <sha-from-reflog> && git worktree add ../ai-avengers-<slug> <branch>"
      ;;
    integrate)
      echo "Rollback:  docker compose down; fuser -k \${DOCKER_PORT}/tcp; git status"
      ;;
    *)
      echo "Rollback:  see scripts/README.md for stage-specific recovery"
      ;;
  esac
}

# Aliases used by the lifecycle scripts.
print_rollback_merge_failure()    { rollback_hint merge "${1:-<integration>}"; }
print_rollback_push_failure()     { rollback_hint push; }
print_rollback_cleanup_mistake()  { rollback_hint cleanup; }
print_rollback_integrate_tier2()  { rollback_hint integrate; }
