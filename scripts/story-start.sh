#!/usr/bin/env bash
# story-start.sh — Stage 0 setup automation for the Story Cycle workflow (v6.4).
#
# Performs the preflight + setup steps that begin every new story:
#   1. Refuse if VS Code app is running, uv is missing, working tree dirty,
#      not on main, stale Stage 6 marker present, or target branch exists.
#   2. Update main from origin.
#   3. Create new feature branch story/<x-x>-<slug>.
#   4. Launch a fresh VS Code window. The window's tasks.json runs automatically
#      on folder open and spawns 6 named terminals (plan, spec-review,
#      implement, review, fix, ops). Each terminal derives the story slug from
#      the current git branch at run time — no env var dependency.
#
# Out of scope by design:
#   - Spec creation: handled inside Stage 2 by bmad-build (steps 01-02).
#   - Slash command execution: terminals open at a normal shell prompt; the
#     user starts each Claude Code session manually when ready.
#
# Usage:
#   ./scripts/story-start.sh <story-number> <slug>            # run setup
#   ./scripts/story-start.sh <story-number> <slug> --dry-run  # show actions
#
# Examples:
#   ./scripts/story-start.sh 1-1 project-scaffold
#   ./scripts/story-start.sh 2-3 export-csv-endpoint
#
# Conventions:
#   - <story-number> uses dash form (e.g. 1-1). Display form (1.1) is derived.
#   - <slug>         lowercase, dash-separated (e.g. project-scaffold).
#   - Branch name    story/<story-number>-<slug>.
#   - Spec file      _bmad-output/implementation-artifacts/spec-<story-number>-<slug>.md
#
# Exits non-zero on any failure. No interactive prompts.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
  cat <<USAGE
Usage: ${SCRIPT_NAME} <story-number> <slug> [--dry-run]

Arguments:
  <story-number>   Dash form, e.g. 1-1 (becomes 1.1 in displays)
  <slug>           Lowercase dash-separated, e.g. project-scaffold

Options:
  --dry-run        Print actions without executing them.
  -h, --help       Show this help.

Preflight checks (script refuses to proceed if any fail):
  - VS Code app must NOT be running. Quit it first (Cmd+Q).
  - 'uv' must be installed. bmad-build halts without it.
  - No stale Stage 6 marker at .claude/.stage-6-active.
  - Working tree must be clean.
  - Current branch must be 'main'.
  - Target branch must not already exist locally.

Example:
  ${SCRIPT_NAME} 1-1 project-scaffold
  ${SCRIPT_NAME} 1-1 project-scaffold --dry-run
USAGE
}

# --- Parse args ---------------------------------------------------------------

DRY_RUN=0
STORY_NUM=""
SLUG=""

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --*)
      echo "ERROR: unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      if [[ -z "$STORY_NUM" ]]; then
        STORY_NUM="$1"
      elif [[ -z "$SLUG" ]]; then
        SLUG="$1"
      else
        echo "ERROR: unexpected extra argument: $1" >&2
        usage
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$STORY_NUM" || -z "$SLUG" ]]; then
  echo "ERROR: both <story-number> and <slug> are required" >&2
  usage
  exit 1
fi

# Validate format: <story-number> must be N-N (digits-dash-digits)
if ! [[ "$STORY_NUM" =~ ^[0-9]+-[0-9]+$ ]]; then
  echo "ERROR: <story-number> must be in form N-N (e.g. 1-1). Got: ${STORY_NUM}" >&2
  exit 1
fi

# Validate format: <slug> must be lowercase letters, digits, dashes
if ! [[ "$SLUG" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "ERROR: <slug> must be lowercase, dash-separated (e.g. project-scaffold). Got: ${SLUG}" >&2
  exit 1
fi

# Derive display form: 1-1 -> 1.1
STORY_SHORT="${STORY_NUM/-/.}"
STORY_SLUG="${STORY_NUM}-${SLUG}"
BRANCH="story/${STORY_SLUG}"

# --- Helpers ------------------------------------------------------------------

log() {
  echo "[${SCRIPT_NAME}] $*"
}

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] $*"
  else
    eval "$@"
  fi
}

# --- Preflight ----------------------------------------------------------------

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "ERROR: not inside a git repository" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"

if ! command -v code >/dev/null 2>&1; then
  echo "ERROR: 'code' (VS Code CLI) is required but not found in PATH" >&2
  echo "       Install: VS Code -> Command Palette -> 'Shell Command: Install code command in PATH'" >&2
  exit 1
fi

# Refuse if uv is missing. bmad-build's SKILL.md runs
# 'uv run --no-cache _bmad/scripts/render_skill.py' as its first action and
# HALTs on failure with no interpreter fallback. The BMAD installer only WARNS
# when uv is absent, so an install can look healthy and fail at first build.
# Fail here, at Stage 0, rather than mid-Stage-2.
if ! command -v uv >/dev/null 2>&1; then
  echo "ERROR: 'uv' is required but not found in PATH." >&2
  echo "       bmad-build halts without it. Install: brew install uv" >&2
  exit 1
fi

# Refuse if a Stage 6 marker exists. Indicates a leftover from a prior story.
# The marker authorizes a single commit then auto-clears post-commit; a present
# marker at story start means something went wrong (interrupted commit, missing
# post-commit hook). Stale marker is a footgun — clear it before proceeding.
if [[ -f ".claude/.stage-6-active" ]]; then
  echo "ERROR: stale Stage 6 marker found at .claude/.stage-6-active." >&2
  echo "       Remove it manually (rm .claude/.stage-6-active) before starting a new story." >&2
  exit 1
fi

# Refuse if VS Code app is running. Required so the new window opens cleanly
# and the spawn task fires via runOn:folderOpen.
if pgrep -x "Code" >/dev/null 2>&1; then
  echo "ERROR: Visual Studio Code is currently running." >&2
  echo "       Quit VS Code (Cmd+Q) before starting a new story." >&2
  echo "       This ensures the new window opens cleanly and the 6-terminal" >&2
  echo "       spawn task fires automatically via runOn:folderOpen." >&2
  exit 1
fi

CURRENT_BRANCH="$(git branch --show-current)"
if [[ "$CURRENT_BRANCH" != "main" ]]; then
  echo "ERROR: must be on 'main' to start a new story. Current branch: ${CURRENT_BRANCH}" >&2
  echo "       Switch with: git checkout main" >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: working tree is not clean. Commit or stash before starting a new story." >&2
  git status --short >&2
  exit 1
fi

if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  echo "ERROR: branch already exists locally: ${BRANCH}" >&2
  echo "       Delete it first or pick a different slug." >&2
  exit 1
fi

log "Mode: $([[ $DRY_RUN -eq 1 ]] && echo 'DRY RUN' || echo 'EXECUTE')"
log "Story:  ${STORY_SHORT} (${STORY_SLUG})"
log "Branch: ${BRANCH}"
log "Repo:   ${REPO_ROOT}"

# --- Step 1: Update main ------------------------------------------------------

log "Step 1/3: update main from origin"

run "git pull --ff-only"

# --- Step 2: Create and checkout new branch -----------------------------------

log "Step 2/3: create branch ${BRANCH}"

run "git checkout -b ${BRANCH}"

# --- Step 3: Launch VS Code --------------------------------------------------

log "Step 3/3: launch VS Code on ${REPO_ROOT}"

# No env vars needed: tasks.json derives the slug from 'git branch --show-current'.
# VS Code is guaranteed not running (preflight checked), so 'code' opens fresh.
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[dry-run] code ${REPO_ROOT}"
else
  code "${REPO_ROOT}"
fi

log "Done. VS Code is launching."
log "First-run note: VS Code may prompt to allow automatic tasks for this workspace. Accept once."
